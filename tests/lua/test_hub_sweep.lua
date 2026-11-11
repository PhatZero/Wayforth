-- Hub Sweep regression: complete same-hub collection, eligibility, and arrow focus.
-- Offline Lua 5.1 fixture; these are fictional test quests, not gameplay data.
local ns = {
    Modules = {}, state = {},
    char = { guideProgress = {}, activeGuide = "hub-fixture" },
    starterGuides = {
        { id = "hub-fixture", title = "Hub fixture", faction = "Alliance",
          zone = "Test Vale", levelMin = 1, levelMax = 30, steps = {
            {id="a", questId=100, action="accept", title="First", hub="Market", zone="Test Vale", level=10, mapId=101, x=40, y=40},
            {id="b", questId=100, action="objective", title="Do First", hub="Forest", zone="Test Vale", level=10, mapId=101, x=75, y=80},
            {id="c", questId=100, action="turnin", title="Finish First", hub="Market", zone="Test Vale", level=10, mapId=101, x=40, y=40},
            {id="d", questId=200, action="accept", title="Other village", hub="Valley", zone="Test Vale", level=10, mapId=101, x=80, y=80},
            {id="e", questId=200, action="turnin", title="Other turnin", hub="Valley", zone="Test Vale", level=10, mapId=101, x=80, y=80},
            {id="f", questId=300, action="accept", title="Another pickup", hub="Market", zone="Test Vale", level=10, mapId=101, x=41, y=39},
            {id="g", questId=400, action="accept", title="Named hub", hub="Market", zone="Test Vale", level=10},
            {id="h", questId=500, action="accept", title="Locked pickup", hub="Market", zone="Test Vale", level=10, mapId=101, x=40, y=40, requires={999}},
            {id="i", questId=600, action="accept", title="Too high", hub="Market", zone="Test Vale", level=30, mapId=101, x=40, y=40},
            {id="j", questId=700, action="turnin", title="Ready turnin", hub="Market", zone="Test Vale", level=10, mapId=101, x=40, y=40},
            {id="k", questId=800, action="objective", title="Active task", hub="Market", zone="Test Vale", level=10, mapId=101, x=42, y=39},
            {id="l", questId=900, action="accept", title="Different map", hub="Market", zone="Test Vale", level=10, mapId=999, x=40, y=40},
            {id="m", questId=950, action="accept", title="Different zone", hub="Market", zone="Other Zone", level=10, mapId=101, x=40, y=40},
          } }
    },
}
function ns:RegisterModule(name, value) self.Modules[name] = value end
function ns:Call() return true end
UnitLevel = function() return 10 end
UnitFactionGroup = function() return "Alliance" end
UnitClass = function() return "Hunter", "HUNTER" end
local active, ready, complete = { [700] = true, [800] = true }, { [700] = true }, {}
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return complete[id] == true end,
    IsOnQuest = function(id) return active[id] == true end,
    GetLogIndexForQuestID = function(id) return active[id] and 1 or nil end,
    ReadyForTurnIn = function(id) return ready[id] == true end,
}
ns.Modules.Database = { Get = function(_, name)
    if name == "smartRouting" then return true end
    if name == "guidePaused" then return false end
end }
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth", ns)
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth", ns)
local guides, routes, nav = ns.Modules.Guides, ns.Modules.SmartRoutes, ns.Modules.Navigator
local group = routes:NearbyGroup()
local found = {}
for _, item in ipairs(group) do found[item.step.questId] = true end
assert(#group == 5, "All eligible same-hub actions must be visible beyond the first 12 steps")
for _, id in ipairs({100,300,400,700,800}) do
    assert(found[id], "Missing eligible hub action " .. id)
end
for _, id in ipairs({200,500,600,900,950}) do
    assert(not found[id], "An ineligible/cross-zone/cross-map action leaked into the hub")
end
assert(group[1].index == 1 and group[2].step.questId == 700,
    "Current action stays first, then ready turn-ins are prioritized")
local concurrent=routes:ConcurrentQuestSteps()
assert(#concurrent==2 and concurrent[1].step.questId==700 and concurrent[2].step.questId==800,
    "Ready and active objectives must remain visible beyond the current hub")
assert(concurrent[1].action=="READY" and concurrent[2].action=="ACTIVE",
    "Concurrent queue reflects real quest phases, not guessed turn-ins")
-- Route selection must favor another eligible pickup after a real accept event.
active[100] = true
guides:RecordQuestEvent("QUEST_ACCEPTED", 100)
local idx, msg = routes:Preview("hub-fixture", "recommended")
assert(idx == 10 and msg:find("Turn in"), "Handle ready same-hub turn-ins before departures")
ready[700] = nil
idx, msg = routes:Preview("hub-fixture", "recommended")
assert(idx == 6 and msg:find("hub"), "Collect other Market pickups after ready turn-ins")
ready[700] = true
assert(not complete[100] and not complete[300], "Suggested pickups never forge completion")
-- If the player enters a new zone, the anchor is cleared by Bootstrap; without
-- a just-accepted event, the route returns to the active quest's objective.
ns.state.lastAcceptedQuestID = nil
idx = routes:Preview("hub-fixture", "recommended")
assert(idx == 2, "Without a fresh accept event, live active objective wins")
-- A real turn-in keeps us at the same hub to finish other ready quests,
-- then check follow-up pickups without synthesizing quest completion.
guides:RecordQuestEvent("QUEST_TURNED_IN",100)
idx = routes:Preview("hub-fixture", "recommended")
assert(idx == 10, "A ready turn-in at the current hub precedes distant objectives")
guides:RecordQuestEvent("QUEST_TURNED_IN",700)
idx = routes:Preview("hub-fixture", "recommended")
assert(idx == 6, "After turning in, collect newly eligible same-hub pickups")
-- Old session hints must expire rather than repeatedly pulling us back.
local clock=100
GetTime=function() return clock end
guides:RecordQuestEvent("QUEST_TURNED_IN",700)
clock=200
idx = routes:Preview("hub-fixture", "recommended")
assert(idx ~= 6, "Expired hub hint must not override normal route matching")
-- Arrow must match the tracker step instead of secretly choosing a nearby one.
ns.Modules.Guides:GetProgress().current = 1
nav.frame = { IsShown = function() return false end }
nav.UpdateDirection = function() end
nav:Refresh()
assert(nav.target and math.abs(nav.target.x - 0.40) < 0.001,
    "Arrow target belongs to displayed step, not a different nearby suggestion")
-- A coordinate-free candidate can still be selected and read.
local ok, notice = nav:SetOverride(7, false)
assert(ok and notice:find("No verified waypoint"), "Missing coordinate cannot block side-step selection")
assert(nav.overrideIndex == 7 and nav.target == nil, "Waypointless selection has no invented arrow")
print("WayForth premium hub sweep and navigation alignment tests passed")
