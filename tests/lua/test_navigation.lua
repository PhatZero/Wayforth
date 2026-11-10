-- Navigator lookup and arrow fallback tests, runnable in plain Lua 5.1.
local ns = { Modules = { Theme = {} }, state = {} }
function ns:RegisterModule(name, module) self.Modules[name] = module end
local active, position = true, { x = 0.4, y = 0.2 }
local mainWaypoint, mapWaypoint, poiWaypoint = true, false, false
C_QuestLog = {
    IsOnQuest = function(id) return active and id == 77 end,
    GetNextWaypoint = function(id)
        if mainWaypoint then return 2521, 0.6, 0.4 end
    end,
    GetNextWaypointForMap = function(id, mapId)
        if mapWaypoint and id == 77 and mapId == 2521 then return 0.55, 0.35 end
    end,
    GetQuestsOnMap = function(mapId)
        if poiWaypoint then return {
            { questID = 999, x = 0.9, y = 0.9 },
            { questID = 77, x = 0.52, y = 0.32 },
        } end
        return {}
    end,
}
C_Map = {
    GetBestMapForUnit = function() return 2521 end,
    GetMapInfo = function(id) return { name = "Zephras Isle", parentMapID = 0 } end,
    GetPlayerMapPosition = function() return position end,
    GetWorldPosFromMapPos = function() error("Distance API unavailable") end,
}
CreateVector2D = function(x, y) return { x = x, y = y } end
GetPlayerFacing = function() return 0 end
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth", ns)
local nav = ns.Modules.Navigator

local turnin = { questId = 77, action = "turnin", x = 42.4, y = 23.6, mapId = 2521 }
local target = nav:TargetForStep(turnin)
assert(target and math.abs(target.x - 0.424) < 0.00001, "NPC turnin should prioritize verified authored position")
local objective = { questId = 77, action = "objective", x = 42.4, y = 23.6, mapId = 2521 }
target = nav:TargetForStep(objective)
assert(target and target.source == "Quest waypoint" and target.x == 0.6, "Prefer live quest objective")
mainWaypoint = false
mapWaypoint = true
target = nav:TargetForStep(objective)
assert(target and target.source == "Quest map waypoint" and target.x == 0.55, "Use map-specific quest waypoint")
mapWaypoint = false
poiWaypoint = true
target = nav:TargetForStep(objective)
assert(target and target.source == "Quest map pin" and target.x == 0.52, "Use matching quest map POI")
poiWaypoint = false
target = nav:TargetForStep(objective)
assert(target and target.source == "Verified guide location", "Use authored coordinate if client quest lookup empty")
target = nav:TargetForStep({ action = "manual", mapId = 2521 })
assert(target == nil, "Do not invent positions for unverified manual steps")

local shown, text = false, ""
nav.target = { mapId = 2521, x = 0.5, y = 0.3 }
nav.frame = { IsShown = function() return true end }
nav.arrow = {
    SetRotation = function() end,
    SetVertexColor = function() end,
    Show = function() shown = true end,
    Hide = function() shown = false end,
}
nav.distanceText = { SetText = function(_, value) text = value end }
nav:UpdateDirection()
assert(shown == true, "Arrow remains visible even if optional distance API throws")
assert(text == "Follow arrow", "Distance error degrades to unobtrusive text")
print("WayForth navigation fallback tests passed")
