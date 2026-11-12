-- Run from a pinned QuestieDB checkout. Export only facts needed by WayForth.
-- Arguments: WayForth checkout, output JSON path.
local root, output = assert(arg[1]), assert(arg[2])
local ns = { starterGuides = {} }
local toc = assert(io.open(root .. "/clients/forever/manifest/WayForth.toc"))
for line in toc:lines() do
    local file = line:match("^Data/(.+%.lua)$")
    if file and file ~= "ForeverQuestLocationUpdates.lua" then
        assert(loadfile(root .. "/clients/forever/guides/" .. file))("WayForth", ns)
    end
end
toc:close()
local wanted, guideNames = {}, {}
for _, guide in ipairs(ns.starterGuides) do
    for _, step in ipairs(guide.steps) do
        if step.questId then
            wanted[step.questId] = true
            guideNames[step.questId] = step.title:gsub("^Pick up: ", ""):gsub("^Complete: ", "")
        end
        for _, id in pairs(step.questIds or {}) do wanted[id] = true end
    end
end

-- Use the source project's own correction loader, including Forever traces.
local loaded = dofile("tools/export/inline.lua").loadForever(true)
local fields = {
    Quest = {1, 2, 3, 6, 9, 10, 11, 17, 21, 29},
    Npc = {1, 7, 13}, Object = {1, 4}, Item = {1, 2, 3, 4, 6, 14},
}
local missingLocations={}
for id,record in pairs(ns.foreverQuestLocations or {}) do
    local missing={name=record.name}
    for _,role in ipairs({"pickup","objective","turnin"}) do
        if not record[role] or #record[role]==0 then missing[role]=true end
    end
    missingLocations[id]=missing
end
local data = { wanted = wanted, guideNames = guideNames, missingLocations=missingLocations }
for kind, indices in pairs(fields) do
    local rows = {}
    for id, row in pairs(loaded[kind].entities) do
        do -- Reward-item sources can refer to quests outside the active route.
            local selected = {}
            for _, index in ipairs(indices) do selected[index] = row[index] end
            rows[id] = selected
        end
    end
    data[kind] = rows
end
local file = assert(io.open(output, "w"))
local function writeJSON(value)
    local kind = type(value)
    if kind == "nil" then file:write("null")
    elseif kind == "number" or kind == "boolean" then file:write(tostring(value))
    elseif kind == "string" then
        local escaped = value:gsub('[%z\1-\31\\"]', function(c)
            if c == "\\" then return "\\\\" end
            if c == '"' then return '\\"' end
            return string.format("\\u%04x", c:byte())
        end)
        file:write('"' .. escaped .. '"')
    elseif kind == "table" then
        file:write("{")
        local separator = ""
        for key, item in pairs(value) do
            file:write(separator)
            writeJSON(tostring(key))
            file:write(":")
            writeJSON(item)
            separator = ","
        end
        file:write("}")
    else error("Unsupported exported value: " .. kind) end
end
writeJSON(data)
assert(file:close())
