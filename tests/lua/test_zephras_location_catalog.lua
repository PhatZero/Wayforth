-- Full route waypoint coverage and Missing Scholar per-phase regression tests.
local ns = {
    Modules = {}, state = {},
    char = { activeGuide = "zephras-alliance", guideProgress = {} },
    starterGuides = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
local chosenClass = "HUNTER"
UnitClass = function() return "Hunter", chosenClass end

assert(loadfile("clients/forever/guides/ZephrasLocations.lua"))("WayForth", ns)
assert(loadfile("clients/forever/guides/ZephrasIsle.lua"))("WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
local guides = ns.Modules.Guides

local function step(id)
    for _, item in ipairs(guides:GetSteps()) do
        if item.id == id then return item end
    end
    return nil
end
local function point(id, qid, x, y)
    local item = assert(step(id), "Missing step " .. id)
    if qid then assert(item.questId == qid, "Quest ID mismatch for " .. id) end
    assert(item.mapId == 2521 and type(item.x) == "number" and type(item.y) == "number", "Missing map waypoint on " .. id)
    assert(math.abs(item.x - x) < 0.005 and math.abs(item.y - y) < 0.005, "Incorrect location for " .. id)
end

point("scholar-92727-accept", 92727, 66.3, 79.8)
point("scholar-92727-turnin", 92727, 53.3, 72.1)
point("scholar-92849-accept", 92849, 53.3, 72.1)
point("scholar-92849-turnin", 92849, 52.1, 69.4)
point("scholar-92850-accept", 92850, 52.1, 69.4)
point("scholar-92850-entrance", 92850, 51.44, 68.99)
point("scholar-92850-objective", 92850, 51.9, 65.6)
point("scholar-92850-turnin", 92850, 66.2, 79.9)
point("alliance-leader", 92699, 66.6, 79.9)
point("next", 93089, 66.6, 79.9)
assert(not step("horde-construct"), "Alliance guide must exclude Horde-only route")

local countAll, countMissing = 0, 0
for _, faction in ipairs({"zephras-alliance", "zephras-horde"}) do
    for _, class in ipairs({"DRUID", "HUNTER", "MAGE", "ROGUE", "SHAMAN", "WARRIOR"}) do
        chosenClass = class
        assert(guides:SetActive(faction))
        for _, item in ipairs(guides:GetSteps()) do
            countAll = countAll + 1
            local located = item.mapId == 2521 and type(item.x) == "number" and type(item.y) == "number"
                and item.x >= 0 and item.x <= 100 and item.y >= 0 and item.y <= 100
            if not located then
                countMissing = countMissing + 1
                error("No authorable coordinate for " .. faction .. "/" .. class .. "/" .. tostring(item.id))
            end
        end
    end
end
assert(countAll > 300 and countMissing == 0, "Every visible curated guide step needs a grounded map destination")

guides:SetActive("zephras-horde")
chosenClass = "SHAMAN"
point("next", 93090, 59.1, 79.8)
point("horde-leader", 92700, 59.1, 79.8)
point("construct-93735-turnin", 93735, 59.1, 73.0)
point("construct-93738-turnin", 93738, 59.1, 79.8)
assert(not step("scholar-92850-accept"), "Horde should not see Alliance Missing Scholar quests")
print("WayForth catalog covers " .. countAll .. " visible faction/class route combinations")
