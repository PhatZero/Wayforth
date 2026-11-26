local ns={Modules={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local level,xp,maxXP,rested=20,750,1000,500
UnitLevel=function() return level end
UnitXP=function() return xp end
UnitXPMax=function() return maxXP end
GetXPExhaustion=function() return rested end
UnitFactionGroup=function() return "Alliance" end
assert(loadfile("shared/core/NextZone.lua"))("WayForth",ns)
local zones=ns.Modules.NextZone
local state=zones:XPState()
assert(state.fraction==0.75 and state.remainingXP==250 and state.rested==500)
local current={id="old",faction="Alliance",generatedChapter=true,levelMin=10,levelMax=15,zone="A"}
local target={id="new",faction="Alliance",generatedChapter=true,levelMin=20,levelMax=24,zone="B"}
local active=false
local steps={old={{id="a",questId=1,level=14,action="accept"}},new={{id="b",questId=2,level=20,action="accept"}}}
local saved={completed={},skipped={}}
ns.Modules.Guides={GetProgress=function() return saved end,GetSteps=function(_,id) return steps[id] end}
ns.Modules.SmartRoutes={QuestState=function(_,id) return {active=id==1 and active,turnedIn=false} end,ListGuides=function() return {current,target} end,Preview=function() return 1 end,BlockedReason=function() return nil end}
assert(zones:OptimizedChapter(current,level).id=="new")
active=true
assert(not zones:OptimizedChapter(current,level))
active=false
level=60
assert(zones:XPState().atCap and not zones:OptimizedChapter(current,level))
maxXP=0
assert(zones:XPState().fraction==0 and zones:XPState().remainingXP==nil)
print("XP progression checks passed")
