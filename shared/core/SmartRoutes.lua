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
local function key(step, index)
    return step.id or index
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
    local minScore, bestIndex
    for index, step in ipairs(steps) do
        local audit = ns.Modules.QuestAudit
        local mismatch = audit and step.questId and audit:IsMismatched(step.questId)
        if not mismatch and not completed(step, index, saved) then
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
    if not saved then return {} end
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
function Routes:Recalculate()
    local guides = ns.Modules.Guides
    local id = guides:GetGuide().id
    local saved = guides:GetProgress(id)
    local settings = ns.Modules.Database
    if not saved or saved.routeMode ~= "recommended"
        or (settings and settings:Get("smartRouting") == false)
        or (settings and settings:Get("guidePaused") == true)
        or (settings and settings:Get("autoRecovery") == false) then return false end
    local index = self:Preview(id, "recommended")
    if not index then return false end
    if index == saved.current then return false end
    guides:SetCurrent(index, id)
    return true
end
