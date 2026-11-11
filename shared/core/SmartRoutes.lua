-- Smart Route Switching for the existing WayForth guide engine and SavedVariables.
-- No new addon, minimap icon, slash command, or account-wide progress store.
local _, ns = ...
local Routes = {}
ns:RegisterModule("SmartRoutes", Routes)

local MODES = { recommended = true, beginning = true, resume = true }
local function currentLevel()
    if type(UnitLevel) == "function" then
        local n = UnitLevel("player")
        if type(n) == "number" and n > 0 then return n end
    end
    return 1
end
local function playerFaction()
    return type(UnitFactionGroup) == "function" and UnitFactionGroup("player") or nil
end
local function flag(id)
    if type(id) ~= "number" then return false end
    if ns.char and type(ns.char.turnedInQuests) == "table" and ns.char.turnedInQuests[id] then return true end
    local a = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    if type(a) == "function" then
        local ok, value = pcall(a, id)
        if ok and value == true then return true end
    end
    if type(IsQuestFlaggedCompleted) == "function" then
        local ok, value = pcall(IsQuestFlaggedCompleted, id)
        if ok and value == true then return true end
    end
    return false
end
local function active(id)
    if type(id) ~= "number" then return false end
    if C_QuestLog and type(C_QuestLog.IsOnQuest) == "function" then
        local ok, value = pcall(C_QuestLog.IsOnQuest, id)
        if ok and value == true then return true end
    end
    if C_QuestLog and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, id)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    return ns.state and type(ns.state.acceptedQuestIDs) == "table" and ns.state.acceptedQuestIDs[id] == true
end
local function ready(id)
    if type(id) ~= "number" or type(C_QuestLog) ~= "table" then return false end
    for _, name in ipairs({ "ReadyForTurnIn", "IsComplete" }) do
        local func = C_QuestLog[name]
        if type(func) == "function" then
            local ok, value = pcall(func, id)
            if ok and value == true then return true end
        end
    end
    return false
end
local function key(step, index)
    return step.id or index
end
function Routes:QuestState(id)
    return {active=active(id),ready=ready(id),turnedIn=flag(id)}
end
local function completed(step, index, saved)
    if step.questId and flag(step.questId) then return true end
    return type(saved.completed) == "table" and saved.completed[key(step, index)] == true
end
local function findPrerequisite(steps, questID, seen)
    if seen[questID] then return nil end
    seen[questID] = true
    for index, step in ipairs(steps) do
        if step.questId == questID then
            for _, requirement in ipairs(step.requires or {}) do
                if not flag(requirement) then
                    local previous = findPrerequisite(steps, requirement, seen)
                    if previous then return previous end
                end
            end
            return index
        end
    end
    return nil
end
local function prerequisiteIndex(step, steps)
    for _, requirement in ipairs(step.requires or {}) do
        if not flag(requirement) then
            local index = findPrerequisite(steps, requirement, {})
            if index then return index end
            -- Prerequisite outside known route: we cannot claim downstream is available.
            return nil, true
        end
    end
    return nil, false
end
function Routes:ListGuides()
    local list = {}
    for _, guide in ipairs(ns.Modules.Guides:List()) do
        if not guide.faction or not playerFaction() or guide.faction == playerFaction() then
            list[#list + 1] = guide
        end
    end
    return list
end
-- Near-level Kalimdor guide suggestions are calculated from the zone bands.
-- Optional class/neutral zones are excluded from the automatic shortlist.
function Routes:ZoneSuggestions(limit, excludeId)
    local level = currentLevel()
    local choices = {}
    for _, guide in ipairs(self:ListGuides()) do
        if guide.continent == "Kalimdor" and not guide.isOptional
            and guide.id ~= excludeId and guide.levelMin and guide.levelMax then
            local low, high = guide.levelMin, guide.levelMax
            local outside = math.max(low - level, level - high, 0)
            -- Favor appropriate zones over merely nearby ones.
            local score = outside * 100 + math.abs((low + high)/2 - level)
            choices[#choices + 1] = { title = guide.zone, score = score, id = guide.id }
        end
    end
    table.sort(choices, function(a,b)
        if a.score == b.score then return a.title < b.title end
        return a.score < b.score
    end)
    local result = {}
    for i = 1, math.min(limit or 3, #choices) do result[i] = choices[i] end
    return result
end

function Routes:RecommendNextZone(id)
    local n = currentLevel()
    if id == "alliance-elwynn" then
        return n >= 18 and "Duskwood or Redridge Mountains" or "Westfall"
    elseif id == "alliance-teldrassil" then
        return n >= 18 and "Ashenvale" or "Darkshore"
    elseif id == "alliance-dun-morogh" then
        return n >= 20 and "Wetlands" or "Loch Modan"
    elseif id == "zephras-alliance" then
        return n >= 18 and "Westfall, Darkshore, or Loch Modan" or "Alliance mainland"
    end
    local guide = ns.Modules.Guides:GetGuide(id)
    if guide and guide.continent == "Kalimdor" then
        local options = self:ZoneSuggestions(2, id)
        if #options > 0 then
            local titles = {}
            for _, entry in ipairs(options) do titles[#titles+1] = entry.title end
            return table.concat(titles, " or ")
        end
    end
    return nil
end
-- Every leveling guide uses the same recovery contract. The onboarding
-- tutorial is the sole guide that has no quest-log-backed progression.
function Routes:NeedsLiveQuest(id)
    local guide = ns.Modules.Guides:GetGuide(id)
    if not guide or guide.id ~= id or id == "first-steps" then return false end
    if id == "zephras-alliance" or id == "zephras-horde" then
        -- Preserve hand-authored level 1-4 story-mode entry behavior.
        return currentLevel() >= 5
    end
    return type(guide.steps) == "table" and #guide.steps > 0
end

local function isSourceCatalog(guide)
    return guide and guide.id ~= "zephras-alliance"
        and guide.id ~= "zephras-horde" and guide.id ~= "first-steps"
end

-- Find the earliest unfinished, source-backed prerequisite for a quest.
-- Missing a quest from the log is not proof that the route cannot proceed:
-- the player may need to pick it up, or finish an earlier quest first.
local function questHasObjective(questID, steps)
    for _, step in ipairs(steps) do
        if step.questId == questID and step.action == "objective" then return true end
    end
    return false
end

local function activePhase(questID, steps)
    local isReady = ready(questID)
    for index, step in ipairs(steps) do
        if step.questId == questID
            and (isReady and step.action == "turnin"
                or not isReady and step.action == "objective") then
            return index
        end
    end
    if not questHasObjective(questID, steps) then
        for index, step in ipairs(steps) do
            if step.questId == questID and step.action == "turnin" then return index end
        end
    end
end

local function recoveryPickup(questID, steps, visited, allowUnmapped)
    if type(questID) ~= "number" then return nil, "Unknown quest." end
    if flag(questID) or active(questID) then return nil, nil end
    if visited[questID] then return nil, "A quest prerequisite loop was detected." end
    visited[questID] = true
    local pickupIndex, knownStep
    for index, step in ipairs(steps) do
        if step.questId == questID then
            knownStep = knownStep or step
            if step.action == "accept" then pickupIndex, knownStep = index, step; break end
        end
    end
    if not knownStep then
        return nil, "Quest " .. questID .. " is a required prerequisite but its pickup is not authored yet."
    end
    for _, requirement in ipairs(knownStep.requires or {}) do
        if not flag(requirement) then
            if active(requirement) then
                local phase = activePhase(requirement, steps)
                if phase then
                    return phase, "Finish active prerequisite quest " .. requirement ..
                        " before attempting the next pickup."
                end
                return nil, "Finish active prerequisite quest " .. requirement ..
                    "; its remaining objective is not authored yet."
            end
            local earlier, reason = recoveryPickup(requirement, steps, visited, allowUnmapped)
            if earlier then return earlier, reason end
            -- Never tell a player an unavailable downstream quest is offered
            -- when its upstream quest cannot be resolved.
            return nil, reason or ("Finish prerequisite quest " .. requirement .. " first.")
        end
    end
    if pickupIndex then
        local pickup = steps[pickupIndex]
        if type(pickup.x) == "number" and type(pickup.y) == "number" then
            local caution = allowUnmapped and
                " Candidate pickup coordinates are source-indexed, not verified in the game." or ""
            return pickupIndex, "Quest pickup needed: " .. tostring(pickup.title or questID) ..
                ". If it is not offered, check its earlier prerequisites." .. caution
        end
        if allowUnmapped then
            -- A missing coordinate is not a reason to strand the guide.
            -- Show the pickup instruction with NO synthesized arrow.
            return pickupIndex, "Quest pickup needed: " .. tostring(pickup.title or questID) ..
                ". Pickup location unverified; use the zone or hub label and in-game map. No waypoint is available."
        end
        return nil, "Quest " .. questID .. " is unfinished, but no verified pickup location is available."
    end
    return nil, "Quest " .. questID .. " is missing from the log and the guide has no pickup step for it."
end

function Routes:Preview(id, mode)
    mode = MODES[mode] and mode or "recommended"
    if id == "first-steps" and mode == "recommended" then mode = "resume" end
    local guides = ns.Modules.Guides
    local guide = guides:GetGuide(id)
    if not guide or guide.id ~= id then return nil, "Unknown guide." end
    local faction = playerFaction()
    if guide.faction and faction and guide.faction ~= faction then
        return nil, "This guide is not available to your faction."
    end
    local steps, saved = guides:GetSteps(id), guides:GetProgress(id)
    if not saved or #steps == 0 then return nil, "No steps in this guide." end
    if mode == "resume" then
        return saved.current, "Resume the saved position; completed quests remain completed."
    end

    local level = currentLevel()
    if mode == "recommended" then
        local hubs=ns.Modules.HubRoutes
        if hubs and hubs:Enabled() then
            local hubIndex,hubReason=hubs:Selection(steps,saved)
            if hubIndex then return hubIndex,hubReason end
        end
        -- A quest already in the player's log is authoritative for mid-route
        -- recovery. Pick its useful phase, not the nearest unverified quest
        -- from a level-sorted public catalog.
        local matchedIndex, matchedScore
        for index, step in ipairs(steps) do
            local questId = step.questId
            local audit = ns.Modules.QuestAudit
            local mismatched = audit and questId and audit:IsMismatched(questId)
            if type(questId) == "number" and active(questId) and not flag(questId)
                and not completed(step, index, saved)
                and not (saved.skipped and saved.skipped[key(step, index)])
                and not mismatched then
                local isReady = ready(questId)
                -- A quest already accepted cannot need its pickup step, and
                -- an incomplete quest must not point at the turn-in NPC.
                -- On phase-driven Zephras, require the current quest phase.
                local usable = not self:NeedsLiveQuest(id)
                    or (step.action ~= "accept"
                        and (step.action ~= "turnin" or isReady or not questHasObjective(questId, steps))
                        and (step.action ~= "objective" or not isReady))
                if usable then
                    local phase
                    if step.action == "turnin" then phase = isReady and 6 or 3
                    elseif step.action == "objective" then phase = isReady and 2 or 5
                    elseif step.action == "manual" then phase = 4
                    elseif step.action == "accept" then phase = 1
                    else phase = 2 end
                    local score = phase * 1000 - math.abs(level - (step.level or level)) * 10 - index * 0.01
                    if not matchedScore or score > matchedScore then
                        matchedScore, matchedIndex = score, index
                    end
                end
            end
        end
        if matchedIndex then
            return matchedIndex, "Matched a quest in your quest log. WayForth will track its current phase."
        end
        if self:NeedsLiveQuest(id) then
            local catalog = isSourceCatalog(guide)
            -- The optional Smart Start is still level-aware, but only suggests
            -- a candidate PICKUP (or its known prerequisites), never a guessed
            -- turn-in. A large level mismatch should offer a different zone.
            if catalog and type(guide.levelMax) == "number"
                and level > guide.levelMax + 4 then
                local nextZone = self:RecommendNextZone(id)
                return nil, nextZone and
                    ("No level-suitable quests in this guide. Consider " .. nextZone .. ".")
                    or "This guide is below your level. Choose From Beginning to follow its full quest list."
            end
            if catalog and saved.current == 1
                and not next(saved.completed or {}) and not next(saved.skipped or {}) then
                local best, bestScore, bestReason
                for index, step in ipairs(steps) do
                    if step.action == "accept" and type(step.questId) == "number"
                        and not flag(step.questId)
                        and type(step.level) == "number"
                        and step.level <= level + 3 and step.level > level - 5 then
                        local pickup, reason = recoveryPickup(step.questId, steps, {}, true)
                        if pickup then
                            local score = -math.abs(level - step.level) * 10
                                + ((type(steps[pickup].x) == "number") and 1 or 0)
                                - index * 0.001
                            if not bestScore or score > bestScore then
                                best, bestScore, bestReason = pickup, score, reason
                            end
                        end
                    end
                end
                if best then return best, bestReason end
            end
            -- Prefer the currently selected quest chain, not an unrelated
            -- catalog quest at the same level. Recover legacy cursors that
            -- point at a turn-in not accepted by this character.
            local selected = steps[saved.current]
            local targetId = selected and selected.questId
            if type(targetId) ~= "number" or flag(targetId) then
                for index = saved.current, #steps do
                    local candidate = steps[index]
                    if candidate and type(candidate.questId) == "number" and not flag(candidate.questId) then
                        targetId = candidate.questId
                        break
                    end
                end
            end
            if type(targetId) == "number" then
                local pickup, reason = recoveryPickup(targetId, steps, {}, catalog)
                if pickup then return pickup, reason end
                return nil, reason or "Quest prerequisite needs review. No confirmed pickup can be found in this guide."
            end
            return nil, "No recoverable quest in this guide. Check your quest history or choose another guide."
        end
    end

    local minScore, bestIndex
    for index, step in ipairs(steps) do
        local audit = ns.Modules.QuestAudit
        local mismatch = audit and step.questId and audit:IsMismatched(step.questId)
        if not mismatch and not completed(step, index, saved)
            and not (saved.skipped and saved.skipped[key(step, index)]) then
            local relevant = mode == "beginning"
            local questLevel = step.level
            local onQuest = active(step.questId)
            if mode == "recommended" then
                -- The 5-level threshold is an approximate XP filter, not exact Forever XP.
                relevant = onQuest or type(questLevel) == "number"
                    and level - questLevel < 5 and questLevel <= level + 3
            end
            if relevant then
                local required, unknown = prerequisiteIndex(step, steps)
                if not unknown then
                    local candidate = required or index
                    local requiredStep = steps[candidate]
                    if candidate and not completed(requiredStep, candidate, saved) then
                        local score
                        if mode == "beginning" then
                            score = -index
                        else
                            local delta = math.abs(level - (step.level or level))
                            score = (onQuest and 10000 or 0) - delta * 10 - index * 0.01
                        end
                        if not minScore or score > minScore then
                            minScore, bestIndex = score, candidate
                        end
                    end
                end
            end
        end
    end
    if bestIndex then
        local step = steps[bestIndex]
        local reason = mode == "beginning" and "Follow the earliest unfinished step."
            or "Level suitability is estimated; confirm quest availability in game."
        return bestIndex, reason
    end
    if mode == "recommended" then
        local nextZone = self:RecommendNextZone(id)
        return nil, nextZone and ("No suitable quest here. Consider " .. nextZone .. ". Choose another guide if needed.")
            or "No level-appropriate uncompleted quest found in this guide."
    end
    return nil, "All known steps appear complete."
end
function Routes:Switch(id, mode)
    mode = MODES[mode] and mode or "recommended"
    local index, message = self:Preview(id, mode)
    if not index then return false, message end
    local guides = ns.Modules.Guides
    if not guides:SetActive(id) then return false, "Could not activate guide." end
    local saved = guides:GetProgress(id)
    if mode ~= "resume" then guides:SetCurrent(index, id) end
    saved.routeMode = mode
    saved.awaitingQuestMatch = false
    saved.lastLevelAtSwitch = currentLevel()
    -- Every guide retains its own currentStepId and completed map.
    ns:Call("Navigator", "ResetTarget")
    ns:Call("Tracker", "Refresh")
    return true, message
end
function Routes:Mode(id)
    local progress = ns.Modules.Guides:GetProgress(id)
    return progress and progress.routeMode or "recommended"
end
-- Conservative nearby grouping: the addon never guesses a quest is available.
-- Groups are suggestions and waypoint priorities, not forged quest completions.
-- Only the selected guide is scanned, and original guide order remains recoverable.
local function readyForTurnin(questId)
    if type(questId) ~= "number" or not C_QuestLog then return false end
    local func = C_QuestLog.ReadyForTurnIn or C_QuestLog.IsComplete
    if type(func) ~= "function" then return false end
    local ok, result = pcall(func, questId)
    return ok and result == true
end
local function nearby(a, b)
    if not a or not b or a.action ~= b.action then return false end
    if a.zone and b.zone and a.zone ~= b.zone then return false end
    if type(a.x) == "number" and type(a.y) == "number"
        and type(b.x) == "number" and type(b.y) == "number" then
        return math.abs(a.x - b.x) <= 4 and math.abs(a.y - b.y) <= 4
    end
    return a.hub and b.hub and a.hub == b.hub
end
function Routes:NearbyGroup()
    local settings = ns.Modules.Database
    if settings and (settings:Get("smartRouting") == false or settings:Get("guidePaused") == true) then
        return {}
    end
    local guides = ns.Modules.Guides
    local saved = guides:GetProgress()
    local steps = guides:GetSteps()
    if not saved or saved.awaitingQuestMatch then return {} end
    local hubs=ns.Modules.HubRoutes
    local hubGroup=hubs and hubs:Group(steps,saved)
    if hubGroup then return hubGroup end
    local start = saved.current
    local anchor = steps[start]
    if not anchor then return {} end
    local group = { { index = start, step = anchor } }
    if anchor.action ~= "accept" and anchor.action ~= "objective"
        and anchor.action ~= "turnin" then return group end
    for index = start + 1, math.min(#steps, start + 12) do
        local step = steps[index]
        local key = step and (step.id or index)
        if step and not saved.completed[key] and not (saved.skipped and saved.skipped[key])
            and nearby(anchor, step) then
            local allowed = true
            for _, requirement in ipairs(step.requires or {}) do
                if not flag(requirement) then allowed = false; break end
            end
            local audit = ns.Modules.QuestAudit
            if audit and step.questId and audit:IsMismatched(step.questId) then allowed = false end
            if step.action == "objective" and not active(step.questId) then allowed = false end
            if step.action == "turnin" and not readyForTurnin(step.questId) then allowed = false end
            if step.action == "accept" and (active(step.questId) or flag(step.questId)) then allowed = false end
            if allowed then group[#group+1] = { index = index, step = step } end
            if #group >= 5 then break end
        end
    end
    return group
end

function Routes:NearestGroupedStep(group)
    if type(group) ~= "table" or #group < 2 then return nil end
    local navigator = ns.Modules.Navigator
    if not navigator or type(navigator.TargetForStep) ~= "function"
        or not C_Map or type(C_Map.GetPlayerMapPosition) ~= "function" then return nil end
    local bestIndex, bestDistance
    for _, item in ipairs(group) do
        local ok, target = pcall(navigator.TargetForStep, navigator, item.step)
        if ok and target and target.mapId and target.x and target.y then
            local good, pos = pcall(C_Map.GetPlayerMapPosition, target.mapId, "player")
            if good and pos then
                local px, py
                if type(pos.GetXY) == "function" then px, py = pos:GetXY()
                else px, py = pos.x, pos.y end
                if type(px) == "number" and type(py) == "number" then
                    local distance = (target.x - px)^2 + (target.y - py)^2
                    if not bestDistance or distance < bestDistance then
                        bestDistance, bestIndex = distance, item.index
                    end
                end
            end
        end
    end
    return bestIndex
end

-- Keep recommended routes near the player's level after completed quests/level-ups.
-- Does not mark any skipped step complete, and never switches region without consent.
function Routes:Recalculate(force)
    local guides = ns.Modules.Guides
    local id = guides:GetGuide().id
    local saved = guides:GetProgress(id)
    local settings = ns.Modules.Database
    -- Older SavedVariables did not always store a route mode; the
    -- guide UI already interprets a missing mode as Recommended.
    local routeMode = saved and (saved.routeMode or (self:NeedsLiveQuest(id) and "recommended"))
    if not saved or (routeMode ~= "recommended" and not force)
        or (settings and settings:Get("smartRouting") == false and not force)
        or (settings and settings:Get("guidePaused") == true and not force)
        or (settings and settings:Get("autoRecovery") == false and not force) then return false end
    local index, reason = self:Preview(id, "recommended")
    local blocked = not index and self:NeedsLiveQuest(id) or false
    local changed = (saved.awaitingQuestMatch == true) ~= blocked
    saved.awaitingQuestMatch = blocked
    local oldReason = saved.recoveryReason
    saved.recoveryReason = reason
    changed = changed or oldReason ~= reason
    if not index then return changed end
    if index == saved.current then return changed end
    guides:SetCurrent(index, id)
    -- A prior manual navigation target belongs to the old guide step.
    ns:Call("Navigator", "ResetTarget")
    return true
end
