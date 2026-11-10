-- Kalimdor Alliance integration test on Lua 5.1 (offline; no game client).
local ns = {
    Modules = {}, state = {}, char = { guideProgress = {}, activeGuide = "first-steps" },
    starterGuides = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
function ns:Call() return true end
local level, faction, zone = 42, "Alliance", "Feralas"
UnitLevel = function() return level end
UnitFactionGroup = function() return faction end
UnitClass = function() return "Hunter", "HUNTER" end
local accepted, turnedIn = {}, {}
C_QuestLog = {
    IsOnQuest = function(id) return accepted[id] == true end,
    IsQuestFlaggedCompleted = function(id) return turnedIn[id] == true end,
    GetLogIndexForQuestID = function(id) return accepted[id] and 1 or nil end,
    GetTitleForQuestID = function(id)
        if id == 954 then return "Bashal'Aran" end
    end,
}
assert(loadfile("clients/forever/guides/StarterGuide.lua"))("WayForth",ns)
assert(loadfile("clients/forever/guides/ForeverQuestCatalog.lua"))("WayForth",ns)
assert(loadfile("clients/forever/guides/KalimdorAlliance.lua"))("WayForth",ns)
assert(loadfile("clients/forever/guides/ForeverQuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/QuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth",ns)
assert(loadfile("shared/core/QuestAudit.lua"))("WayForth",ns)
local guides, routes, audit = ns.Modules.Guides, ns.Modules.SmartRoutes, ns.Modules.QuestAudit
local catalog, total, distinct = {}, 0, 0
for _, guide in ipairs(guides:List()) do
    if guide.continent == "Kalimdor" then
        distinct = distinct + 1
        assert(guide.faction == "Alliance")
        local ids = ns.foreverQuestCatalog[guide.zone]
        assert(ids and #ids > 0, "Every new guide has source IDs")
        assert(#guide.steps >= 2 * #ids, "Each quest retains pickup and completion checkpoints")
        for _,step in ipairs(guide.steps) do
            assert(step.questId > 0)
            assert(step.sourceStatus == "public-catalog-match")
            if step.x then
                assert(step.x >= 0 and step.x <= 100 and step.y >= 0 and step.y <= 100)
            end
        end
        total = total + #ids
        catalog[guide.id] = guide
    end
end
assert(distinct == 16, "16 Alliance Kalimdor zone guides including optional hubs")
assert(total == 798, "Expected 798 public-source candidate quests")
assert(#ns.foreverQuestCatalog["Darkshore"] == 78)
assert(#ns.foreverQuestCatalog["Feralas"] == 50)
assert(#ns.foreverQuestCatalog["Un'Goro Crater"] == 48)
assert(#ns.foreverQuestCatalog["Moonglade"] == 40)
assert(#ns.foreverQuestCatalog["The Barrens"] == 70)
local report = audit:Scan()
assert(audit.counts.total == 1237, "439 starter IDs + 798 Kalimdor source candidates")
assert(audit.counts.matched >= 1 and report:find("ID catalog"))
assert(audit:IsMismatched(954) == false, "Numbered chain variants normalize correctly")
local suggestions = routes:ZoneSuggestions(3)
assert(#suggestions == 3 and suggestions[1].id, "Level-specific zone recommendations")
assert(routes:Preview("alliance-darkshore","recommended") == nil, "High levels skip low XP Darkshore")
assert(routes:Switch("alliance-darkshore","beginning"), "Story mode allows low-level questing")
local dark = guides:GetProgress("alliance-darkshore")
local done = guides:GetSteps("alliance-darkshore")[dark.current]
assert(done and done.questId, "Story mode locates an actionable quest")
guides:CompleteCurrent()
assert(dark.completed[done.id], "Completed step is retained")
assert(routes:Switch("alliance-feralas","recommended"), "Recommended player can use Feralas")
assert(guides:GetGuide().id == "alliance-feralas")
local feralas = guides:GetProgress()
local current = guides:GetSteps()[feralas.current]
assert(current.level >= 38, "Level hint respects Feralas band")
assert(routes:Switch("alliance-tanaris","recommended"), "Can switch from Feralas to Tanaris")
assert(routes:Switch("alliance-feralas","resume"), "Feralas progress can be resumed")
assert(guides:GetProgress("alliance-darkshore").completed[done.id], "Other zone progress remains intact")
assert(guides:GetGuide("alliance-feralas").travelHint, "Guide includes travel instructions")
assert(not catalog["alliance-moonglade"].levelMin == nil or catalog["alliance-moonglade"].isOptional)
-- Navigation map safety with no fabricated off-zone arrow.
ns.Modules.Theme = {}
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth",ns)
local map = 1439
C_Map = {
    GetBestMapForUnit = function() return map end,
    GetMapInfo = function(id)
        if id == 1439 then return {name="Darkshore",parentMapID=1} end
        if id == 1444 then return {name="Feralas",parentMapID=1} end
        if id == 1 then return {name="Kalimdor",parentMapID=0} end
    end,
}
local darkStep
for _,step in ipairs(guides:GetSteps("alliance-darkshore")) do
    if step.action == "accept" and step.x then darkStep = step; break end
end
assert(darkStep, "Pickup coordinate present")
local nav = ns.Modules.Navigator
assert(nav:TargetForStep(darkStep).mapId == 1439, "Correct zone map resolves")
map = 1444
assert(nav:TargetForStep(darkStep).mapId == 1439, "Changing zones may not reinterpret destination coordinates")
print("WayForth Kalimdor Alliance quests, audit, progress and map safety passed")
