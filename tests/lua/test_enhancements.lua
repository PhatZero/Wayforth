local ns={Modules={},state={},char={},version="1.0b5",client={label="Forever",build="16001",interface=16001}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local level=10
UnitLevel=function() return level end
local active,ready,done={},{},{}
C_QuestLog={IsOnQuest=function(id) return active[id] end,ReadyForTurnIn=function(id) return ready[id] end,
    IsQuestFlaggedCompleted=function(id) return done[id] end}
local steps={
    {id="a",questId=10,action="accept",title="Pick up: First quest",minLevel=12,mapId=1,x=20,y=30},
    {id="b",questId=20,action="accept",title="Second quest",requires={10}},
    {id="c",questId=20,action="objective",title="Second objective"},
}
local saved={current=1,routeMode="recommended"}
ns.Modules.Guides={GetProgress=function() return saved end,GetSteps=function() return steps end,
    GetGuide=function() return {id="test",title="Test guide"} end,CurrentStep=function() return steps[1],1 end}
assert(loadfile('shared/core/SmartRoutes.lua'))('WayForth',ns)
local routes=ns.Modules.SmartRoutes
assert(routes:BlockedReason(steps[1],steps):find('Requires level 12',1,true))
level=12
assert(not routes:BlockedReason(steps[1],steps))
assert(routes:BlockedReason(steps[3],steps):find('Pick up and complete First quest',1,true))
active[10]=true
assert(routes:BlockedReason(steps[2],steps):find('Complete and turn in',1,true))
ready[10]=true
assert(routes:BlockedReason(steps[2],steps):find('Turn in First quest',1,true))
done[10]=true
assert(not routes:BlockedReason(steps[2],steps))
assert(routes:BlockedReason(steps[3],steps):find('Quest not in your log',1,true))
active[20]=true
assert(not routes:BlockedReason(steps[3],steps))
C_Map={GetBestMapForUnit=function() return 1 end,GetMapInfo=function(id) return {name='Zone '..id,mapType=id==3 and 4 or 3} end,
    GetPlayerMapPosition=function() return {x=.25,y=.5} end}
assert(loadfile('shared/navigation/Navigator.lua'))('WayForth',ns)
local nav=ns.Modules.Navigator
assert(nav:NavigationFeedback({mapId=2,x=30,y=40}):find('Travel to Zone 2',1,true))
assert(nav:NavigationFeedback({mapId=3,x=30,y=40}):find('Enter Zone 3',1,true))
assert(nav:NavigationFeedback({}):find('No verified waypoint',1,true))
assert(nav:NavigationFeedback({mapId=1,x=30,y=40}):find('30.0, 40.0',1,true))
assert(nav:NavigationFeedback({mapId=1,x=30,y=40},'Facing unavailable'):find('Follow guide instructions',1,true))
level=10;active[10]=nil;done[10]=nil
assert(nav:SetMapPin(steps[1])==false,'Known blocked pickup must not place a misleading pin')
saved.awaitingQuestMatch=true
assert(nav:NavigationFeedback(steps[1]):find('Resolve quest prerequisite',1,true))
saved.awaitingQuestMatch=false
assert(loadfile('shared/core/Diagnostics.lua'))('WayForth',ns)
local report=ns.Modules.Diagnostics:BugReport()
assert(report:find('Version: 1.0b5',1,true) and report:find('Quest ID: 10',1,true))
assert(report:find('25.00, 50.00',1,true) and report:find('Step: 1 [a]',1,true))
nav.overrideIndex=3
assert(ns.Modules.Diagnostics:BugReport():find('Step: 3 [c]',1,true),'Report must describe selected side objective')
C_Map=nil
assert(ns.Modules.Diagnostics:BugReport():find('coordinates: unavailable',1,true))
print('Blocked quest explanations, navigation feedback and bug report context passed')
