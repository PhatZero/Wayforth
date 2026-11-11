local _, ns = ...
local Guides = {}
ns:RegisterModule("Guides", Guides)

local byId = {}
for _, guide in ipairs(ns.starterGuides or {}) do
    if ns.Modules.QuestLocations then ns.Modules.QuestLocations:Prepare(guide) end
    byId[guide.id] = guide
end

local function progressStore()
    if not ns.char then return nil end
    if type(ns.char.guideProgress) ~= "table" then ns.char.guideProgress = {} end
    return ns.char.guideProgress
end

local function defaultGuide()
    if type(UnitRace) == "function" and type(UnitFactionGroup) == "function" then
        local _, token = UnitRace("player")
        if tostring(token or ""):lower():find("skyborne", 1, true) then
            local faction = UnitFactionGroup("player")
            if faction == "Alliance" then return "zephras-alliance" end
            if faction == "Horde" then return "zephras-horde" end
        end
    end
    return "first-steps"
end

local function stepKey(step, index)
    return step.id or index -- Legacy foundation-guide numeric saved keys stay valid.
end

function Guides:GetGuide(id)
    local active = id or (ns.char and ns.char.activeGuide) or defaultGuide()
    return byId[active] or byId["first-steps"]
end

function Guides:List()
    return ns.starterGuides or {}
end

-- Test catalogs can contain quests restricted to one or several races.
-- Forever's Undead race token may appear as SCOURGE on older client APIs.
local function canUseRace(restrictions)
    if not restrictions then return true end
    if type(UnitRace) ~= "function" then return false end
    local ok, displayed, token = pcall(UnitRace, "player")
    if not ok then return false end
    local name = tostring(displayed or ""):upper()
    local code = tostring(token or ""):upper()
    if code == "SCOURGE" then code = "UNDEAD" end
    for _, wanted in ipairs(restrictions) do
        if wanted == name or wanted == code then return true end
    end
    return false
end

function Guides:GetSteps(id, legacy)
    local guide = self:GetGuide(id)
    if not guide then return {} end
    local classToken
    if type(UnitClass) == "function" then
        local _, token = UnitClass("player")
        classToken = token
    end
    local visible = {}
    local locations = ns.Modules.QuestLocations
    local currentMap = C_Map and type(C_Map.GetBestMapForUnit) == "function"
        and C_Map.GetBestMapForUnit("player") or nil
    for _, step in ipairs(legacy and guide.legacySteps or guide.steps or {}) do
        if (legacy or not step.hidden)
            and (not step.faction or step.faction == guide.faction)
            and (not step.class or step.class == classToken)
            and canUseRace(step.races) then
            -- Each visible step gets its own resolved metadata. Shared raw step IDs
            -- remain untouched so old SavedVariables checkpoints keep working.
            local resolved = {}
            for key, value in pairs(step) do resolved[key] = value end
            if step.questIds then resolved.questId = step.questIds[guide.faction] end
            if step.requiresByFaction then resolved.requires = step.requiresByFaction[guide.faction] end
            if step.coordsByFaction and step.coordsByFaction[guide.faction] then
                local loc = step.coordsByFaction[guide.faction]
                resolved.x, resolved.y = loc[1], loc[2]
            end
            -- Quest phase endpoints are explicit. A quest giver's location must
            -- never be silently reused for a different turn-in NPC.
            local catalog = ns.zephrasQuestLocations or {}
            local isZephras = guide.id == "zephras-alliance" or guide.id == "zephras-horde"
            local entry = isZephras and resolved.questId and catalog[resolved.questId] or nil
            local role = resolved.locationRole or (resolved.action == "accept" and "pickup" or resolved.action)
            local pin = entry and entry[role]
            if pin and type(pin[1]) == "number" and type(pin[2]) == "number" then
                resolved.x, resolved.y = pin[1], pin[2]
                resolved.mapId = ns.zephrasMapID or 2521
            end
            if locations then locations:Apply(resolved, guide, currentMap) end
            visible[#visible + 1] = resolved
        end
    end
    return visible
end

function Guides:GetProgress(id)
    local guide = self:GetGuide(id)
    if not guide then return nil end
    local store = progressStore()
    if not store then return nil end
    local saved = store[guide.id]
    if type(saved) ~= "table" then
        saved = { current = 1, completed = {} }
        store[guide.id] = saved
    end
    if type(saved.completed) ~= "table" then saved.completed = {} end
    if type(saved.skipped) ~= "table" then saved.skipped = {} end
    if type(saved.current) ~= "number" or saved.current ~= saved.current then saved.current = 1 end
    local steps = self:GetSteps(guide.id)
    if #steps == 0 then return nil end
    if not saved.currentStepId and guide.legacySteps then
        local previous = self:GetSteps(guide.id, true)[saved.current]
        if previous then saved.currentStepId = stepKey(previous, saved.current) end
    end
    if saved.currentStepId then
        local position
        for index, step in ipairs(steps) do
            if stepKey(step, index) == saved.currentStepId then position = index; break end
        end
        if not position and guide.legacySteps then
            local positions = {}
            for index, step in ipairs(steps) do positions[stepKey(step, index)] = index end
            -- A corrected faction restriction can remove an old cursor target.
            -- Continue with the next surviving legacy step in the same guide.
            local previous = self:GetSteps(guide.id, true)
            local afterCurrent = false
            for index, step in ipairs(previous) do
                local key = stepKey(step, index)
                if key == saved.currentStepId then afterCurrent = true end
                if afterCurrent and positions[key] then position = positions[key]; break end
            end
            position = position or #steps
        end
        saved.current = position or saved.current
    end
    saved.current = math.max(1, math.min(#steps, math.floor(saved.current)))
    saved.currentStepId = stepKey(steps[saved.current], saved.current)
    return saved
end

function Guides:SetActive(id)
    if not byId[id] or not ns.char then return false end
    ns.char.activeGuide = id
    ns.char.recentGuides = type(ns.char.recentGuides) == "table" and ns.char.recentGuides or {}
    local recent = { id }
    for _, past in ipairs(ns.char.recentGuides) do
        if past ~= id and #recent < 8 then recent[#recent + 1] = past end
    end
    ns.char.recentGuides = recent
    return self:GetProgress(id) ~= nil
end

function Guides:NextGuide()
    local all = self:List()
    local current = self:GetGuide()
    for index, guide in ipairs(all) do
        if guide.id == current.id then
            return self:SetActive(all[index % #all + 1].id)
        end
    end
    return false
end

function Guides:SetCurrent(index, id)
    local steps = self:GetSteps(id)
    local saved = self:GetProgress(id)
    if not saved or type(index) ~= "number" or index ~= index then return end
    saved.current = math.max(1, math.min(#steps, math.floor(index)))
    saved.currentStepId = stepKey(steps[saved.current], saved.current)
end

function Guides:CompleteCurrent(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved or #steps == 0 then return end
    saved.completed[stepKey(steps[saved.current], saved.current)] = true
    if saved.current < #steps then self:SetCurrent(saved.current + 1, id) end
end

-- These query helpers are deliberately tolerant of the modern Forever client and
-- older aliases. A missing API never means the player has completed a quest.
local function queryBoolean(func, questID)
    if type(func) ~= "function" then return false end
    local ok, value = pcall(func, questID)
    return ok and value == true
end

local function questCompleted(questID)
    return queryBoolean(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, questID)
        or queryBoolean(IsQuestFlaggedCompleted, questID)
        or (ns.char and ns.char.turnedInQuests and ns.char.turnedInQuests[questID] == true)
end

local function questActive(questID)
    if queryBoolean(C_QuestLog and C_QuestLog.IsOnQuest, questID) then return true end
    if type(C_QuestLog) == "table" and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    if type(GetQuestLogIndexByID) == "function" then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    -- In some builds the quest log has not updated by the time QUEST_ACCEPTED fires.
    return ns.state and ns.state.acceptedQuestIDs and ns.state.acceptedQuestIDs[questID] == true
end

local function questReady(questID)
    return queryBoolean(C_QuestLog and C_QuestLog.ReadyForTurnIn, questID)
        or queryBoolean(C_QuestLog and C_QuestLog.IsComplete, questID)
end

local function hasQuestAPIs()
    return type(C_QuestLog) == "table"
        and (type(C_QuestLog.IsQuestFlaggedCompleted) == "function"
            or type(C_QuestLog.IsOnQuest) == "function"
            or type(C_QuestLog.GetLogIndexForQuestID) == "function")
        or type(IsQuestFlaggedCompleted) == "function"
        or type(GetQuestLogIndexByID) == "function"
end

function Guides:RecordQuestEvent(event, first, second)
    if not ns.char then return end
    local questID = event == "QUEST_ACCEPTED" and (second or first) or first
    if type(questID) ~= "number" or questID < 1 then return end
    ns.state.acceptedQuestIDs = ns.state.acceptedQuestIDs or {}
    if event == "QUEST_ACCEPTED" then
        ns.state.acceptedQuestIDs[questID] = true
        ns.state.lastAcceptedQuestID = questID -- session-only hub sweep anchor
    elseif event == "QUEST_REMOVED" then
        ns.state.acceptedQuestIDs[questID] = nil
        if ns.state.lastAcceptedQuestID == questID then ns.state.lastAcceptedQuestID = nil end
    elseif event == "QUEST_TURNED_IN" then
        ns.state.acceptedQuestIDs[questID] = nil
        ns.state.lastAcceptedQuestID = nil
        -- Turn-in events can arrive before completed quest flags are updated.
        -- This record is local to this character and survives /reload.
        if type(ns.char.turnedInQuests) ~= "table" then ns.char.turnedInQuests = {} end
        ns.char.turnedInQuests[questID] = true
    end
end

local function readQuestStatus(questID, cache)
    if cache[questID] then return cache[questID] end
    local status = {
        turnedIn = questCompleted(questID),
        active = questActive(questID),
        ready = questReady(questID),
    }
    cache[questID] = status
    return status
end

local function satisfied(step, status)
    if not status then return false end
    -- A fully turned-in quest also completes its earlier accept/objective steps.
    if status.turnedIn then return true end
    if step.action == "accept" then return status.active end
    if step.action == "objective" then return status.ready end
    return false -- turn-ins and manual class tasks need real completed quest evidence
end

function Guides:Sync(id, catchUp)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved then return false, "No active guide." end
    local found, newCompletions, anchor = 0, 0, nil
    local foundIDs, cache = {}, {}
    local previous = saved.current

    -- Scan ALL quest-linked steps. The old implementation stopped at the first
    -- manual checkpoint, making Sync appear broken for returning characters.
    for index, step in ipairs(steps) do
        if type(step.questId) == "number" then
            local status = readQuestStatus(step.questId, cache)
            if (status.turnedIn or status.active or status.ready) and not foundIDs[step.questId] then
                foundIDs[step.questId] = true
                found = found + 1
            end
            local key = stepKey(step, index)
            local done = satisfied(step, status)
            if done then
                if not saved.completed[key] then
                    saved.completed[key] = true
                    newCompletions = newCompletions + 1
                end
                -- Only use actual quest evidence as a catch-up anchor.
                -- Manual steps with no quest ID never get marked complete.
                if not anchor or index > anchor then anchor = index end
            end
        end
    end

    -- Automatic event updates only advance through contiguous completed steps.
    -- Explicit "Sync Quests" can catch up to newer proven quests beyond an
    -- unverified manual checkpoint. Those earlier steps stay available via Prev.
    local settings = ns.Modules.Database
    local automatic = (not settings or settings:Get("autoAdvance") ~= false)
        and (not settings or settings:Get("autoRecovery") ~= false)
        and (not settings or settings:Get("guidePaused") ~= true)
    if catchUp and anchor and anchor > saved.current then
        self:SetCurrent(anchor, id)
    end
    while (catchUp or automatic) and saved.current < #steps do
        local step = steps[saved.current]
        if not saved.completed[stepKey(step, saved.current)] then break end
        self:SetCurrent(saved.current + 1, id)
    end
    local recoveryReason
    if catchUp and ns.Modules.SmartRoutes
        and ns.Modules.SmartRoutes:NeedsLiveQuest(self:GetGuide(id).id) then
        -- Explicit Sync means rebuild the cursor from actual quest evidence and
        -- authored prerequisites, even when the player selected Story mode.
        -- We do NOT mark unavailable/older steps complete just to catch up.
        ns.Modules.SmartRoutes:Recalculate(true)
        recoveryReason = saved.recoveryReason
    end
    local moved = saved.current ~= previous
    local changed = newCompletions > 0 or moved
    local report
    if not hasQuestAPIs() and not (ns.char.turnedInQuests or ns.state.acceptedQuestIDs) then
        report = "Quest APIs unavailable. Use Done/Next to advance."
    elseif catchUp and recoveryReason and saved.awaitingQuestMatch ~= true then
        report = recoveryReason .. " Now at " .. saved.current .. "/" .. #steps .. "."
    elseif catchUp and recoveryReason and saved.awaitingQuestMatch == true then
        report = "Quest prerequisite needs review: " .. recoveryReason
    elseif found == 0 then
        report = "No matching active/completed quests. Check selected guide."
    elseif catchUp and moved then
        report = "Synced " .. found .. " quests, +" .. newCompletions
            .. " steps. Now at " .. saved.current .. "/" .. #steps
            .. ". Earlier manual steps are still reviewable."
    elseif moved or newCompletions > 0 then
        report = "Synced " .. found .. " quests, +" .. newCompletions
            .. " steps. Now at " .. saved.current .. "/" .. #steps .. "."
    else
        report = "Checked " .. found .. " quests. No new progress to apply."
    end
    self.syncStatus = { guideId = self:GetGuide(id).id, matched = found, completed = newCompletions }
    if ns.Modules.UI and ns.Modules.UI.RefreshFooter then ns.Modules.UI:RefreshFooter() end
    if catchUp then self.lastSyncReport = report end
    return changed, report
end

function Guides:LastSyncReport()
    return self.lastSyncReport or "Sync checks completed, active and ready quests."
end

function Guides:Reset(id)
    local guide = self:GetGuide(id)
    local store = progressStore()
    if guide and store then store[guide.id] = { current = 1, completed = {} } end
end

function Guides:Summary(id)
    local guide = self:GetGuide(id)
    local saved = self:GetProgress(id)
    if not guide or not saved then return "No guides available" end
    local steps = self:GetSteps(id)
    local done = 0
    for index, step in ipairs(steps) do
        if saved.completed[stepKey(step, index)] then done = done + 1 end
    end
    return guide.title .. ": " .. done .. "/" .. #steps .. " steps"
end

function Guides:CurrentStep(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    return saved and steps[saved.current], saved and saved.current, #steps
end

function Guides:PinCurrent()
    local step = self:CurrentStep()
    local navigator = ns.Modules.Navigator
    if not step or not navigator or type(navigator.TargetForStep) ~= "function" then
        return false, "No waypoint is available for this guide step."
    end
    local resolved, target = pcall(navigator.TargetForStep, navigator, step)
    if not resolved or not target then
        return false, "No verified location or active quest waypoint for this step."
    end
    if not (C_Map and type(C_Map.GetBestMapForUnit) == "function"
        and type(C_Map.GetMapInfo) == "function" and type(C_Map.SetUserWaypoint) == "function"
        and UiMapPoint and type(UiMapPoint.CreateFromCoordinates) == "function") then
        return false, "This client does not expose compatible waypoint APIs."
    end
    -- Do not try to place a pin in a different zone/map coordinate system.
    local mapId = C_Map.GetBestMapForUnit("player")
    local visited, onMap = {}, false
    for _ = 1, 10 do
        if not mapId or visited[mapId] then break end
        if mapId == target.mapId then onMap = true; break end
        visited[mapId] = true
        local info = C_Map.GetMapInfo(mapId)
        mapId = info and info.parentMapID or nil
    end
    if not onMap then return false, "Travel to the target zone before placing this pin." end
    local created, point = pcall(UiMapPoint.CreateFromCoordinates, target.mapId, target.x, target.y)
    if not created or not point then return false, "Could not create the map pin on this client." end
    local ok, wasSet = pcall(C_Map.SetUserWaypoint, point)
    if not ok or wasSet == false then return false, "Could not place the map pin on this client." end
    if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    return true, string.format("Waypoint set: %.1f, %.1f.", target.x * 100, target.y * 100)
end

-- Guide steps may be skipped without ever forging a completed-quest flag.
function Guides:SkipCurrent(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved or #steps == 0 then return false end
    local index = saved.current
    local key = stepKey(steps[index], index)
    saved.skipped = type(saved.skipped) == "table" and saved.skipped or {}
    saved.skipped[key] = true
    saved.lastSkippedIndex = index
    if index < #steps then self:SetCurrent(index + 1, id) end
    return true
end

function Guides:UndoSkip(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    local index = saved and saved.lastSkippedIndex
    if not index or not steps[index] then return false end
    local key = stepKey(steps[index], index)
    if saved.skipped then saved.skipped[key] = nil end
    saved.lastSkippedIndex = nil
    self:SetCurrent(index, id)
    return true
end

function Guides:IsFavorite(id)
    return ns.char and type(ns.char.favorites) == "table" and ns.char.favorites[id] == true
end

function Guides:ToggleFavorite(id)
    if not ns.char or not byId[id] then return false end
    ns.char.favorites = type(ns.char.favorites) == "table" and ns.char.favorites or {}
    ns.char.favorites[id] = not ns.char.favorites[id]
    return ns.char.favorites[id]
end

function Guides:Status(id)
    local saved = self:GetProgress(id)
    if not saved then return "Not Started" end
    local steps = self:GetSteps(id)
    local done = 0
    for index, step in ipairs(steps) do
        if saved.completed[stepKey(step, index)] then done = done + 1 end
    end
    if done == #steps and #steps > 0 then return "Completed" end
    local skipped = type(saved.skipped) == "table" and next(saved.skipped) ~= nil
    if done > 0 or skipped or saved.current > 1 or (ns.char and ns.char.activeGuide == id) then
        return "In Progress"
    end
    return "Not Started"
end

function Guides:View(id)
    self:Sync(id)
    local guide = self:GetGuide(id)
    local saved = self:GetProgress(id)
    if not guide or not saved then return "Guide data unavailable" end
    local steps = self:GetSteps(id)
    local step = steps[saved.current]
    local check = saved.completed[stepKey(step, saved.current)] and "Done" or "Next objective"
    local where = step.hub or "Check your quest log"
    if step.x and step.y then where = where .. " (" .. step.x .. ", " .. step.y .. ")" end
    return table.concat({
        guide.title,
        "Step " .. saved.current .. "/" .. #steps .. " | Level " .. tostring(step.level or "?") .. " | " .. check,
        "",
        step.title,
        step.text,
        "",
        "Location: " .. where,
        step.questId and ("Quest ID: " .. step.questId .. " | " .. (step.action == "manual" and "manual" or "quest sync")) or "Manual checkpoint",
        "",
        self:Summary(id),
        "Switch Guide cycles the addon tutorial and both Skyborne factions.",
    }, "\n")
end
