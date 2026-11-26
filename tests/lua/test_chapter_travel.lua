local ns={Modules={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local map=1436
C_Map={GetBestMapForUnit=function() return map end}
GetBindLocation=function() return "Sentinel Hill" end
assert(loadfile("shared/core/Travel.lua"))("WayForth",ns)
local travel=ns.Modules.Travel
local origin={continent="Eastern Kingdoms"}
local target={id="test",zone="Duskwood",continent="Eastern Kingdoms"}
local step={id="pickup",mapId=1431,x=73.8,y=43.6,hub="Chef Grual"}
local plan=assert(travel:ChapterPlan(origin,target,step))
assert(#plan.legs==2 and plan.legs[1].kind=="arriveZone")
assert(plan.legs[1].destinationMapId==1431)
assert(plan.legs[1].text:find("Sentinel Hill",1,true))
assert(plan.legs[2].x==73.8 and plan.legs[2].mapId==1431)
assert(travel:CheckpointStatus(plan.legs[1])==false)
map=1431
assert(travel:CheckpointStatus(plan.legs[1])==true)
assert(not travel:ChapterPlan(origin,target,step))
map=nil
assert(travel:CheckpointStatus(plan.legs[1])==nil)
assert(not travel:ChapterPlan(origin,target,step))
map=1436
target.continent="Kalimdor"
local cross=assert(travel:ChapterPlan(origin,target,step))
assert(cross.legs[1].text:find("boat",1,true))
assert(not travel:ChapterPlan(origin,target,{id="unknown"}))
print("Chapter travel planning and arrival checks passed")
