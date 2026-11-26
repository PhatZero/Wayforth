-- Phase-specific locations for the bundled Forever guides.
local _, ns = ...
local Locations = {}
ns:RegisterModule("QuestLocations", Locations)

local function recordFor(step)
    return (ns.foreverQuestLocations or {})[step.questId]
end

local function choosePoint(points, guide, currentMap)
    local best, bestScore
    for _, point in ipairs(points or {}) do
        if not point.faction or point.faction == guide.faction then
            local score = point.mapId == currentMap and 2 or 0
            if (ns.foreverLocationMaps or {})[point.mapId] == guide.zone then score = score + 1 end
            if not bestScore or score > bestScore then best, bestScore = point, score end
        end
    end
    return best
end

-- Insert the work phase before catalog turn-ins. Keep every existing step key.
function Locations:Prepare(guide)
    if guide.id == "first-steps" or guide.id:find("^zephras%-") then return end
    local objectives = {}
    for _, step in ipairs(guide.steps) do
        if step.action == "objective" then objectives[step.questId] = true end
    end
    local steps, changed = {}, false
    for _, original in ipairs(guide.steps) do
        local step = original
        local record = recordFor(step)
        if record and (record.hidden or record.faction and not step.faction) then
            step = {}
            for key, value in pairs(original) do step[key] = value end
            step.hidden = record.hidden
            step.faction = step.faction or record.faction
            changed = true
        end
        if step.action == "turnin" and record and record.hasObjective and not objectives[step.questId] then
            local objective = {}
            for key, value in pairs(step) do objective[key] = value end
            objective.id = step.id .. "-objective"
            objective.action = "objective"
            objective.title = "Work on: " .. step.title:gsub("^Complete: ", "")
            objective.text = "Complete the quest objectives. Check your quest log for the remaining requirements."
            objective.x, objective.y, objective.mapId = nil, nil, nil
            steps[#steps + 1] = objective
            objectives[step.questId] = true
        end
        steps[#steps + 1] = step
    end
    if changed or #steps ~= #guide.steps then
        -- An authored route may already retain the former catalog order for
        -- numeric-only SavedVariables from an older release.
        guide.legacySteps = guide.legacySteps or guide.steps
        guide.steps = steps
    end
end

-- Use phase-specific data only. NPC/object names and coordinates identify
-- destinations, not necessarily kill or collection targets.
local function destination(point,guide)
    local zone=(ns.foreverLocationMaps or {})[point.mapId] or guide.zone
    local name=point.name or zone or "the marked area"
    local text=tostring(name)
    if zone and zone~=name then text=text.." in "..zone end
    if type(point.x)=="number" and type(point.y)=="number" then
        text=text..string.format(" (%.1f, %.1f)",point.x,point.y)
    end
    return text
end

-- Static requirements are factual identities, not an invented count or kill
-- instruction. The live log supplies the precise action and quantity.
function Locations:RequirementText(record)
    local names,seen={},{}
    for _,row in ipairs(record and record.objectiveRequirements or {}) do
        if type(row.name)=="string" and row.name~="" and not seen[row.name] then
            seen[row.name]=true
            names[#names+1]=row.name
        end
    end
    if #names==0 then return nil end
    return "Quest requirements: "..table.concat(names,", ")..". Follow the live objective counters."
end

function Locations:Apply(step, guide, currentMap)
    local role = step.locationRole or (step.action == "accept" and "pickup" or step.action)
    if role ~= "pickup" and role ~= "objective" and role ~= "turnin" then return end
    local record = recordFor(step)
    local catalog=(ns.foreverDBQuests or {})[step.questId]
    if record then step.questName = record.name end
    if not step.questName and catalog then step.questName=catalog.name end
    -- Authoritative observed Forever dungeon phase points must never be
    -- replaced by older general-catalog coordinates for another NPC/phase.
    -- Dungeon pins require explicit Forever-observed phase verification.
    -- Never fall back to speculative generic source coordinates, including
    -- for quests whose location is not yet observed.
    if guide.isDungeon then return end
    -- The authored Zephras route also has deliberate cave entrances and ship stops.
    if step.x and step.y and guide.id:find("^zephras%-") then return end
    if role == "pickup" and record and record.pickupText then step.text = record.pickupText; step.instructionSource=record.pickupSource or "Bundled quest metadata" end
    if role == "objective" and record and record.objectiveText then
        step.text = record.objectiveText .. " Check your quest log for current requirements and quantities."
        step.objectiveKind = record.objectiveKind
        step.objectiveSource = record.objectiveSource
    end
    local instruction = role == "objective" and ns.walkthroughObjectives and ns.walkthroughObjectives[step.questId]
    if instruction and not (record and record.objectiveText) then
        step.text = instruction.text
        step.objectiveSource = instruction.source
    elseif role == "objective" and not (record and record.objectiveText) then
        step.useLiveInstructions = true
        local requirements=self:RequirementText(record)
        if requirements then
            step.text=requirements
            step.objectiveSource="Corrected Forever objective entity table"
        else
            step.instructionNeedsObjectives=true
        end
    end
    local point = record and choosePoint(record[role], guide, currentMap)
    if not point then
        step.instructionNeedsLocation=true
        if role=="objective" then step.useLiveInstructions=true end
        local name = record and record[role .. "Name"]
        if name and role ~= "objective" then
            step.hub = name
            step.text = (role == "pickup" and "Accept the quest from " or "Return to ") .. name ..
                ". Follow the live quest marker for its location."
        end
        if step.x and step.y and not step.mapId then
            for mapId, zone in pairs(ns.foreverLocationMaps or {}) do
                if zone == step.zone then step.mapId = mapId; break end
            end
        end
        return
    end
    step.x, step.y, step.mapId = point.x, point.y, point.mapId
    step.zone = (ns.foreverLocationMaps or {})[point.mapId] or step.zone
    step.hub = point.name or step.hub
    step.locationSource = point.source or "QuestieDB"
    step.locationKind = point.kind
    step.instructionSource=step.objectiveSource or point.source or "Bundled quest metadata"
    if role == "pickup" and record.startItem then
        step.text = "Obtain the quest-starting item from " .. tostring(point.name or step.zone) ..
            ". Use the item to accept the quest."
    elseif role == "pickup" then
        local quest = tostring(record.name or step.questName or step.title or "the quest")
        local verb = point.kind == "object" and "Interact with " or "Talk to "
        if not record.pickupText then step.text = verb .. destination(point,guide) .. ". Accept " .. quest .. " if offered." end
    elseif role == "objective" and point.requiredQuest then
        step.text = "Complete quest " .. point.requiredQuest .. " with " .. tostring(point.name or step.zone) ..
            " to obtain the required item."
    elseif role == "objective" and not record.objectiveText and not instruction then
        -- A navigation point is not proof of the required target.
        local requirements=self:RequirementText(record)
        step.text = "Travel to " .. destination(point,guide) .. ". " .. (requirements or "Complete the remaining requirements shown in your live quest log.")
        step.instructionNeedsObjectives=not requirements or nil
    elseif role == "turnin" then
        local verb=point.kind=="object" and "Interact with " or "Speak with "
        step.text = verb .. destination(point,guide) .. ". Turn in " .. tostring(record.name or step.questName or step.title or "the quest") .. " when ready."
    end
end
