-- Verify per-faction quest IDs and vetted WayForth guide coordinates.
local ns = {
    Modules = {},
    state = {},
    char = { activeGuide = "zephras-alliance", guideProgress = {} },
    starterGuides = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
UnitClass = function() return "Hunter", "HUNTER" end

assert(loadfile("clients/forever/guides/ZephrasIsle.lua"))("WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
local guide = ns.Modules.Guides
local function step(id)
    for _, value in ipairs(guide:GetSteps()) do
        if value.id == id then return value end
    end
    return nil
end

assert(step("village-arrival").questId == 93461, "Alliance Shen'dar quest ID")
assert(step("fate").questId == 94369, "Alliance Fate of Zephras ID")
assert(step("next").questId == 93089, "Alliance What Comes Next ID")
assert(step("class-hunter").x == 42.4 and step("class-hunter").y == 23.6, "Wowhead hunter trainer")
assert(step("class-hunter").mapId == 2521, "Use correct Forever UI map ID")
assert(step("leave-alliance").x == 65.9 and step("leave-alliance").y == 83.5, "Dalaran skyboat")
assert(step("class-mage") == nil, "Hide other class trainer steps")
assert(step("leave-horde") == nil, "Hide opposite-faction skyboat")

assert(guide:SetActive("zephras-horde"), "Can select Horde guide")
assert(step("village-arrival").questId == 92514, "Horde Shen'dar quest ID")
assert(step("fate").questId == 93836, "Horde Fate of Zephras ID")
assert(step("next").questId == 93090, "Horde What Comes Next ID")
assert(step("leave-horde").x == 57.9 and step("leave-horde").y == 80.9, "Thunder Bluff skyboat")
assert(step("leave-alliance") == nil, "Hide Alliance skyboat")

print("WayForth faction quest IDs and coordinate tests passed")
