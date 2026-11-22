-- Authored Westfall quest circuit for WoW Forever.
-- The source catalog remains in EasternEarly.lua; its stable per-quest step
-- IDs are retained so existing SavedVariables and quest evidence still map.
-- Source-backed NPC/map endpoints are resolved later by QuestLocations.
local _, ns = ...
local guide
for _, candidate in ipairs(ns.starterGuides or {}) do
    if candidate.id == "alliance-westfall" then guide = candidate; break end
end
if not guide then return end

local original = guide.steps
local byQuest = {}
for _, step in ipairs(original) do
    if type(step.questId) == "number" then
        local entry = byQuest[step.questId] or {}
        entry[step.action] = step
        byQuest[step.questId] = entry
    end
end

-- These circuits distinguish simultaneously available errands from quests
-- that are unlocked only when an earlier quest has been handed in.
-- No coordinates are guessed: locations come from known phase-specific data.
local circuits = {
    { name="Jansen Stead: collect errands", pickups={151,36,64} },
    { name="Saldean's Farm: pick up nearby quests", pickups={9,22,92909}, turnins={36} },
    { name="Saldean's Farm: stew follow-up", pickups={38} },
    { name="Sentinel Hill: collect the first round", pickups={102,12,153,92742} },
    { name="Northern farms and Sentinel Hill: work then return", turnins={151,64,9,22,92909,38,102,153,92742,12} },
    { name="Militia and the western shore", pickups={13,92744,103,152}, turnins={13,92744,103,152} },
    { name="Militia final patrol and Alba's mines", pickups={14,92745}, turnins={14,92745} },
    { name="Alba Fairmoon: Moonbrook survey", pickups={92747}, turnins={92747} },
    { name="Alba Fairmoon: consult Stormwind", pickups={92748}, turnins={92748} },
    { name="Sentinel Hill: begin the Defias investigation", pickups={65}, turnins={65} },
    { name="Defias Brotherhood: return from Redridge", pickups={132}, turnins={132} },
    { name="Defias Brotherhood: visit Stormwind", pickups={135}, turnins={135} },
    { name="Defias Brotherhood: report back to Sentinel Hill", pickups={141}, turnins={141} },
    { name="Defias Brotherhood: locate the traitor", pickups={142}, turnins={142} },
    { name="Defias Brotherhood: escort the traitor", pickups={155}, turnins={155} },
    { name="Lighthouse and coast: later quests", pickups={104,136}, turnins={104,136} },
    { name="Captain Sander: the next clue", pickups={138}, turnins={138} },
    { name="Captain Sander: follow the coast", pickups={139}, turnins={139} },
    { name="Captain Sander: final treasure", pickups={140}, turnins={140} },

    -- Class/profession, item-found, and external-chain quests are optional
    -- cleanup, not blockers in the core Westfall leveling circuit.
    { name="Optional: engineering-specific harvester chain", pickups={92910}, turnins={92910} },
    { name="Optional: engineering follow-up", pickups={92911}, turnins={92911} },
    { name="Optional: alchemy errands", pickups={92109}, turnins={92109} },
    { name="Optional: alchemy follow-up", pickups={92110}, turnins={92110} },
    { name="Optional: found items and outside-zone chains", pickups={184,109,79008,1076,93928}, turnins={184,109,79008,1076,93928} },

    -- Sweet Amber belongs to a level-40 chain; never put it in a 9-24 lap.
    { name="Optional later: Sweet Amber (level 40)", pickups={48}, turnins={48} },
    { name="Optional later: Sweet Amber follow-up 2", pickups={49}, turnins={49} },
    { name="Optional later: Sweet Amber follow-up 3", pickups={50}, turnins={50} },
    { name="Optional later: Sweet Amber follow-up 4", pickups={51}, turnins={51} },
    { name="Optional later: Sweet Amber conclusion", pickups={53}, turnins={53} },
}

local order, doneAccept, doneTurnIn = {}, {}, {}
local function append(id, kind, circuit)
    local entry = byQuest[id]
    local step = entry and entry[kind]
    if not step then return end
    if kind == "accept" then
        if doneAccept[id] then return end
        doneAccept[id] = true
        -- Known Forever chain facts that were absent from the ATT catalog.
        if id == 92744 then step.requires = {92742} end
        if id == 92745 then step.requires = {92742,92744} end
        if id == 92110 then step.requires = {92109} end
        step.routeChapter = circuit.name
        if circuit.name:find("^Optional") then step.optional = true end
    elseif kind == "turnin" then
        if doneTurnIn[id] or not doneAccept[id] then return end
        doneTurnIn[id] = true
        step.routeChapter = circuit.name
        if circuit.name:find("^Optional") then step.optional = true end
    end
    order[#order+1] = step
end

-- Three distinct phases per circuit: pickups first, then verified field
-- objectives, then hand-ins. Keeps one shared guide engine and avoids a
-- pickup -> turn-in -> return-to-hub pattern for every individual quest.
for _, circuit in ipairs(circuits) do
    for _, id in ipairs(circuit.pickups or {}) do append(id,"accept",circuit) end
    for _, id in ipairs(circuit.turnins or {}) do
        local entry = byQuest[id]
        local turnin = entry and entry.turnin
        local record = (ns.foreverQuestLocations or {})[id]
        if turnin and record and record.hasObjective then
            local work = {}
            for key,value in pairs(turnin) do work[key] = value end
            work.id = turnin.id .. "-objective"
            work.action = "objective"
            work.title = "Work on: " .. tostring(turnin.title or "Quest"):gsub("^Complete: ", "")
            work.text = "Complete the quest objectives. Check your quest log for the remaining requirements."
            work.x, work.y, work.mapId = nil,nil,nil
            work.routeChapter = circuit.name
            if circuit.name:find("^Optional") then work.optional = true end
            order[#order+1] = work
        end
    end
    for _, id in ipairs(circuit.turnins or {}) do append(id,"turnin",circuit) end
end

-- No source quest may silently disappear. Preserve unknown future additions
-- as a separate cleanup tail rather than inserting them into a planned lap.
for _, old in ipairs(original) do
    if not ((old.action == "accept" and doneAccept[old.questId])
        or (old.action == "turnin" and doneTurnIn[old.questId])) then
        order[#order+1] = old
    end
end

-- Keep the pre-upgrade catalog order for numeric-only old SavedVariables.
-- Stable quest IDs are still the primary migration mechanism.
guide.legacySteps = original
guide.steps = order
guide.description = "Westfall route grouped by pickups, field objectives and turn-ins. Optional profession, found-item and level-40 quests are listed after the main story."
guide.contentStatus = "Authored quest circuit using Forever source records; verify quest availability and objectives in-game."
guide.routeStyle = "authored-circuits"
