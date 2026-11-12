local ns={Modules={},state={loggedIn=true},char={}}
function ns:RegisterModule(n,m) self.Modules[n]=m end
local settings={smartRouting=true,autoAdvance=true,autoRecovery=true}
ns.Modules.Database={Get=function(_,k) return settings[k] end}
local states={[1]={active=true,ready=true},[2]={active=true,ready=true},[3]={active=true,ready=false}}
ns.Modules.SmartRoutes={QuestState=function(_,id) return states[id] or {} end,BlockedReason=function() end}
ns.Modules.Navigator={DistanceForStep=function(_,s) return s.questId==1 and 90 or 15 end}
local steps={
 {id="pickup",questId=10,action="accept",title="Pick up: Missing Scholar",text="Speak with Fillion Flamebreeze",hub="Valanaar"},
 {id="turn1",questId=1,action="turnin",title="Return to Rorian",text="Bring the letters",hub="Thendal"},
 {id="turn2",questId=2,action="turnin",title="Report",text="Finish the event",hub="Village"},
 {id="work",questId=3,action="objective",title="Gather flowers",text="Collect 100% of the flowers"},
}
local saved={current=1,completed={},skipped={}}
local guide={id="test",title="Test"}
ns.Modules.Guides={GetGuide=function() return guide end,GetSteps=function() return steps end,GetProgress=function() return saved end}
local count,max=22,25
C_QuestLog={GetNumQuestLogEntries=function() return 30,count end,GetMaxNumQuestsCanAccept=function() return max end,
    GetMaxNumQuests=function() return 1000 end}
assert(loadfile('shared/core/QuestLogSpace.lua'))('WayForth',ns)
local space=ns.Modules.QuestLogSpace
local status=space:Status()
assert(status.count==22 and status.maximum==25 and status.free==3 and status.near,'Use quests, not headers or the all-quests cap')
assert(space:Message():find('3 slots left',1,true))
assert(space:Priority(steps,saved)==3,'Prioritize nearest ready turn-in before a pickup')
assert(not space:CanAccept(),'Near-full log should finish known turn-ins before automated pickup')
assert(saved.current==1 and next(saved.completed)==nil and next(saved.skipped)==nil,'Proposals never mutate progress')
count=21
assert(not space:Priority(steps,saved) and space:CanAccept() and not space:Message())
count=25
assert(space:Status().full and not space:CanAccept())
saved.current=4
assert(not space:Priority(steps,saved),'Do not interrupt an established field loop')
saved.hubVisit={phase='pickups'}
assert(space:Priority(steps,saved)==3,'Pickup round takes turn-in priority')
saved.hubVisit=nil;saved.current=1
saved.skipped.turn2=true
assert(space:Priority(steps,saved)==2)
saved.completed.turn1=true
assert(not space:Priority(steps,saved) and not space:CanAccept(),'No ready turn-ins must never cause abandonment')
saved.skipped={};saved.completed={}
for _,k in ipairs({'autoAdvance','autoRecovery','smartRouting'}) do
 settings[k]=false;assert(not space:Priority(steps,saved));settings[k]=true
end
settings.guidePaused=true;assert(not space:Priority(steps,saved));settings.guidePaused=false
C_QuestLog.GetNumQuestLogEntries=function() error('unavailable') end
GetNumQuestLogEntries=function() return 27,24 end
C_QuestLog.GetMaxNumQuestsCanAccept=nil;MAX_QUESTLOG_QUESTS=30
assert(space:Status().free==6,'Client legacy limit fallback must remain accurate')
MAX_QUESTLOG_QUESTS=nil
assert(not space:Status().known and space:CanAccept(),'Unknown cap must not fabricate a full log')
GetNumQuestLogEntries=nil
C_QuestLog.GetNumQuestLogEntries=function() return 4,0/0 end
assert(not space:Status().known)
local hidden={}
issecretvalue=function(v) return v==hidden end
C_QuestLog.GetNumQuestLogEntries=function() return 4,hidden end
assert(not space:Status().known)
issecretvalue=nil
C_QuestLog.GetNumQuestLogEntries=function() return 0,0 end
C_QuestLog.GetMaxNumQuestsCanAccept=function() return 25 end
assert(space:Status().free==25)

assert(loadfile('shared/core/GuideSearch.lua'))('WayForth',ns)
local search=ns.Modules.GuideSearch
saved.completed.pickup=true;saved.skipped.turn2=true
ns.foreverQuestLocations={[10]={name="The Missing Scholar",turnin={{name="Lorekeeper",x=1,y=2}}}}
assert(#search:Find('missing SCHOLAR')==1)
assert(search:Find('Fillion')[1].index==1 and search:Find('Valanaar')[1].index==1)
assert(search:Find('10')[1].questId==10 and #search:Find('Lorekeeper')==1)
assert(search:Find('100%')[1].index==4,'Queries must be literal, not Lua patterns')
assert(#search:Find('[')==0)
assert(search:Find('Missing')[1].status=='Completed' and search:Find('Report')[1].status=='Skipped')
assert(#search:Find('   ')==4 and #search:Find('no such npc')==0)
local result=search:Find('Rorian')[1]
assert(search:Resolve(result)==steps[2])
assert(saved.current==1 and saved.completed.pickup and saved.skipped.turn2,'Search must preserve route and history')
guide={id='other'}
assert(search:Resolve(result)==nil,'Reject stale results from another guide')
guide={id='test'};steps[2].id='replaced'
assert(search:Resolve(result)==nil,'Reject replaced or filtered step indices')
print('Quest-log limits, turn-in priority, safe fallback and read-only guide search passed')

local notices=0
function ns:Print() notices=notices+1 end
C_QuestLog.GetNumQuestLogEntries=function() return 30,23 end
space:Notify();space:Notify()
assert(notices==1,'Do not spam repeated near-full events')
C_QuestLog.GetNumQuestLogEntries=function() return 30,25 end
space:Notify();assert(notices==2,'Full log gets a distinct warning')
C_QuestLog.GetNumQuestLogEntries=function() return 30,18 end
space:Notify()
C_QuestLog.GetNumQuestLogEntries=function() return 30,23 end
space:Notify();assert(notices==3,'Warn again after space clears and refills')
