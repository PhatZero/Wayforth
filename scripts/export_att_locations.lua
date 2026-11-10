-- Read the compiled Forever catalog through factual quest/NPC collectors.
-- Arguments: AllTheThings checkout, output JSON path.
local root, output = assert(arg[1]), assert(arg[2])
local quests, npcs = {}, {}
local function factory(kind)
    return function(id, properties)
        properties = properties or {}
        properties.entityId, properties.kind = id, kind
        if kind == "quest" then quests[tostring(id)] = properties end
        if kind == "npc" then npcs[tostring(id)] = properties end
        return properties
    end
end
local function stub()
    return setmetatable({}, {
        __index = function(target, key)
            local value = stub()
            rawset(target, key, value)
            return value
        end,
        __call = function() return {} end,
    })
end
local app = stub()
app.CreateQuest = factory("quest")
app.CreateNPC = factory("npc")
app.CreateQuestObjective = factory("objective")
app.AddEventHandler = function(_, callback) callback({}) end
local file = assert(io.open(root .. "/db/Camelot/Categories/Zones.lua"))
local source = file:read("*a"):gsub("^\239\187\191", "")
file:close()
assert(loadstring(source))("AllTheThings", app)
local facts = {quests = {}, npcs = {}, hiddenQuests = {}}
local hiddenFile = assert(io.open(root .. "/db/Camelot/Categories/HiddenQuestTriggers.lua"))
local hiddenSource = hiddenFile:read("*a")
hiddenFile:close()
for id in hiddenSource:gmatch("hqt%((%d+)[,%)]") do facts.hiddenQuests[id] = true end
for id, quest in pairs(quests) do
    local objectives = {}
    for _, child in ipairs(quest.g or {}) do
        if child.kind == "objective" then
            objectives[#objectives + 1] = {coords = child.coords, crs = child.crs, providers = child.providers}
        end
    end
    facts.quests[id] = {coords = quest.coords, qgs = quest.qgs, objectives = objectives}
end
for id, npc in pairs(npcs) do facts.npcs[id] = {coords = npc.coords} end
local out = assert(io.open(output, "w"))
local function writeJSON(value)
    local kind = type(value)
    if kind == "nil" then out:write("null")
    elseif kind == "number" or kind == "boolean" then out:write(tostring(value))
    elseif kind == "string" then
        local escaped = value:gsub('[%z\1-\31\\"]', function(c)
            if c == "\\" then return "\\\\" end
            if c == '"' then return '\\"' end
            return string.format("\\u%04x", c:byte())
        end)
        out:write('"' .. escaped .. '"')
    elseif kind == "table" then
        out:write("{")
        local separator = ""
        for key, item in pairs(value) do
            out:write(separator)
            writeJSON(tostring(key))
            out:write(":")
            writeJSON(item)
            separator = ","
        end
        out:write("}")
    else error("Unsupported exported value: " .. kind) end
end
writeJSON(facts)
assert(out:close())
