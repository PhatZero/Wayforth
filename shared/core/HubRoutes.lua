-- A hub visit is route state only. Quest completion always comes from Guides.
local _, ns = ...
local Hub = {}
ns:RegisterModule("HubRoutes", Hub)

local function key(step, index) return step.id or index end
local function skipped(step, index, saved)
    return saved.skipped and saved.skipped[key(step, index)] == true
end
local function level()
    local ok, value = false, nil
    if type(UnitLevel) == "function" then ok, value = pcall(UnitLevel, "player") end
    return ok and type(value) == "number" and value > 0 and value or 1
end
local function stateReader()
    local cache = {}
    return function(id)
        if not cache[id] then cache[id] = ns.Modules.SmartRoutes:QuestState(id) end
        return cache[id]
    end
end
function Hub:Enabled(force)
    local db = ns.Modules.Database
    if not db then return true end
    return db:Get("smartRouting") ~= false and (force or
        (db:Get("guidePaused") ~= true and db:Get("autoAdvance") ~= false and db:Get("autoRecovery") ~= false))
end
function Hub:SameHub(a, b)
    if not a or not b then return false end
    if a.mapId and b.mapId and a.mapId ~= b.mapId then return false end
    if a.zone and b.zone and a.zone ~= b.zone then return false end
    if type(a.x) == "number" and type(a.y) == "number"
        and type(b.x) == "number" and type(b.y) == "number" then
        return (a.x-b.x)^2 + (a.y-b.y)^2 <= 16
    end
    return type(a.hub) == "string" and a.hub ~= "" and a.hub == b.hub
end
local function atPickup(step)
    if not step.mapId or type(step.x) ~= "number" or type(step.y) ~= "number"
        or not C_Map or type(C_Map.GetPlayerMapPosition) ~= "function" then return false end
    local ok, result = pcall(function()
        local pos = C_Map.GetPlayerMapPosition(step.mapId, "player")
        if not pos then return false end
        local x, y
        if type(pos.GetXY) == "function" then x, y = pos:GetXY() else x, y = pos.x, pos.y end
        return type(x) == "number" and type(y) == "number"
            and (x*100-step.x)^2 + (y*100-step.y)^2 <= 9
    end)
    return ok and result == true
end
local function pickupAllowed(step, index, saved, state, playerLevel)
    if step.action ~= "accept" or type(step.questId) ~= "number" or skipped(step,index,saved) then return false end
    local quest = state(step.questId)
    if quest.turnedIn then return false end
    local audit = ns.Modules.QuestAudit
    if audit and audit:IsMismatched(step.questId) then return false end
    if not quest.active then
        if saved.completed and saved.completed[key(step,index)] then return false end
        if type(step.minLevel) == "number" and step.minLevel > playerLevel then return false end
        if not step.minLevel and type(step.level) == "number" and step.level > playerLevel+1 then return false end
        for _, requirement in ipairs(ns.Modules.SmartRoutes:Requirements(step)) do
            if not state(requirement).turnedIn then return false end
        end
        local record = (ns.foreverQuestLocations or {})[step.questId]
        if record and record.startItem then return false end
    end
    return true
end
local function anchorFor(steps, selected)
    if not selected or not selected.questId then return nil end
    if selected.action == "accept" then return selected end
    -- Installing/reloading while still at a quest giver can recover a pickup
    -- round. Never pull an established field route back solely for a pickup.
    for _, step in ipairs(steps) do
        if step.action == "accept" and step.questId == selected.questId and atPickup(step) then return step end
    end
end
local function findAnchor(steps, visit)
    for index, step in ipairs(steps) do
        if key(step,index) == visit.anchor then return step end
    end
end
local function contains(visit, questID)
    if type(visit.quests) ~= "table" then return false end
    for _, id in ipairs(visit.quests or {}) do if id == questID then return true end end
    return false
end

-- Pure selection: Guide Details previews must never create or mutate a visit.
function Hub:Selection(steps, saved, visit)
    visit = visit or saved.hubVisit
    if type(visit) ~= "table" or type(visit.quests) ~= "table" then return nil end
    local state = stateReader()
    local playerLevel=level()
    local pickups, objectives, turnins = {}, {}, {}
    local byID, wanted = {}, {}
    for _,id in ipairs(visit.quests) do wanted[id]=true end
    for index, step in ipairs(steps) do
        if wanted[step.questId] then
            local entry = byID[step.questId] or {}
            byID[step.questId] = entry
            if not skipped(step,index,saved) then entry[step.action] = {index=index,step=step} end
        end
    end
    for _, id in ipairs(visit.quests) do
        local quest, phases = state(id), byID[id] or {}
        local pickup = phases.accept
        if not quest.turnedIn and pickup then
            if quest.active then
                if not quest.ready then
                    local work = phases.objective or phases.turnin
                    if work then objectives[#objectives+1] = work end
                elseif phases.turnin then turnins[#turnins+1] = phases.turnin end
            elseif pickupAllowed(pickup.step,pickup.index,saved,state,playerLevel) then
                pickups[#pickups+1] = pickup
            end
        end
    end
    local group, phase
    if visit.phase=="turnins" and #turnins>0 then group,phase=turnins,"turnins"
    elseif #pickups > 0 then group,phase=pickups,"pickups"
    elseif #objectives > 0 then group,phase=objectives,"objectives"
    elseif #turnins > 0 then group,phase=turnins,"turnins"
    else return nil end
    local selected
    if phase==visit.phase then
        for _, item in ipairs(group) do if item.index == saved.current then selected=item.index;break end end
    end
    if not selected then
        selected = ns.Modules.SmartRoutes:NearestGroupedStep(group) or group[1].index
    end
    local reason = phase=="pickups" and
        ("Quest pickup group: collect "..#group.." remaining at this hub before heading out.")
        or phase=="objectives" and "Complete this hub's active objectives before returning for turn-ins."
        or "Hub objectives complete. Hand in the ready quests together."
    return selected, reason, phase, group
end

function Hub:Update(id, steps, saved, selected, force)
    if id=="first-steps" or not self:Enabled(force) then return nil end
    local visit = saved.hubVisit
    if type(visit) ~= "table" or not contains(visit,selected and selected.questId) then visit=nil end
    local anchor = visit and findAnchor(steps,visit) or anchorFor(steps,selected)
    local state = stateReader()
    if not anchor or (not visit and state(anchor.questId).turnedIn) then saved.hubVisit=nil;return nil end
    local source=(ns.foreverQuestLocations or {})[anchor.questId]
    if not visit and source and source.startItem and not state(anchor.questId).active then return nil end
    if not visit then visit={anchor=anchor.id,quests={},phase="pickups"} end
    -- New pickups unlock during the return visit. Do not add new work halfway
    -- through a field loop merely because the player gained a level.
    if visit.phase=="pickups" or visit.phase=="turnins" then
        local playerLevel=level()
        for index, step in ipairs(steps) do
            if self:SameHub(anchor,step) and pickupAllowed(step,index,saved,state,playerLevel)
                and not contains(visit,step.questId) then visit.quests[#visit.quests+1]=step.questId end
        end
    end
    if #visit.quests < 2 then saved.hubVisit=nil;return nil end
    local index, reason, phase = self:Selection(steps,saved,visit)
    if not index then
        saved.hubVisit=nil
        -- A batch may jump past a trainer/travel checkpoint in authored
        -- order. Leave it unfinished and reachable when the visit ends.
        local afterAnchor=false
        for position,step in ipairs(steps) do
            if key(step,position)==visit.anchor then afterAnchor=true end
            if afterAnchor and not (saved.completed and saved.completed[key(step,position)])
                and not skipped(step,position,saved) then
                return position,"Hub visit finished. Continue with the next unfinished guide step."
            end
        end
        return nil
    end
    visit.phase=phase
    saved.hubVisit=visit
    saved.awaitingQuestMatch=false
    saved.recoveryReason=reason
    return index,reason
end
function Hub:Group(steps,saved)
    if not self:Enabled() then return nil end
    local _,_,_,group=self:Selection(steps,saved)
    return group
end
