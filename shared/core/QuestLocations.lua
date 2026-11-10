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
        guide.legacySteps = guide.steps
        guide.steps = steps
    end
end

function Locations:Apply(step, guide, currentMap)
    local role = step.locationRole or (step.action == "accept" and "pickup" or step.action)
    if role ~= "pickup" and role ~= "objective" and role ~= "turnin" then return end
    -- The authored Zephras route also has deliberate cave entrances and ship stops.
    if step.x and step.y and guide.id:find("^zephras%-") then return end
    local record = recordFor(step)
    if record then step.questName = record.name end
    if role == "pickup" and record and record.pickupText then step.text = record.pickupText end
    if role == "objective" and record and record.objectiveText then
        step.text = record.objectiveText .. " Check your quest log for current requirements and quantities."
        step.objectiveKind = record.objectiveKind
        step.objectiveSource = record.objectiveSource
    end
    local point = record and choosePoint(record[role], guide, currentMap)
    if not point then
        local name = record and record[role .. "Name"]
        if name then
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
    if role == "pickup" and record.startItem then
        step.text = "Obtain the quest-starting item from " .. tostring(point.name or step.zone) ..
            ". Use the item to accept the quest."
    elseif role == "pickup" then
        step.text = "Accept the quest from " .. tostring(point.name or step.zone) ..
            " if it is available. Check its prerequisites if it is not offered."
    elseif role == "objective" and point.requiredQuest then
        step.text = "Complete quest " .. point.requiredQuest .. " with " .. tostring(point.name or step.zone) ..
            " to obtain the required item."
    elseif role == "objective" and not record.objectiveText then
        step.text = "Work on the quest objectives near " .. tostring(point.name or step.zone) ..
            ". Check your quest log for remaining requirements."
    elseif role == "turnin" then
        step.text = "Return to " .. tostring(point.name or step.zone) .. " when the quest objectives are complete."
    end
end
