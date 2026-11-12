local ns={Modules={},state={loggedIn=true},char={}}
function ns:RegisterModule(n,m) self.Modules[n]=m end
function ns:Call(n,m,...) local module=self.Modules[n];if not module or not module[m] then return false end;return true,module[m](module,...) end
function ns:Print() end
local settings={zoneSuggestions=true}
ns.Modules.Database={Get=function(_,k) return settings[k] end}
local level=10
UnitLevel=function() return level end
local active,ready,done={},{},{}
local guides={
    home={id="home",title="Home",zone="Home",continent="Kalimdor",levelMin=1,levelMax=10,steps={
        {id="a",questId=1,action="accept",title="First",level=1},
        {id="w",questId=1,action="objective",title="First work",level=1},
        {id="t",questId=1,action="turnin",title="First turnin",level=1},
        {id="b",questId=2,action="accept",title="Second",level=2,requires={1}},
        {id="c",questId=3,action="objective",title="Other work",level=3},
    }},
    next={id="next",title="Next",zone="Next",continent="Kalimdor",levelMin=10,levelMax=20,steps={{id="n",questId=4,level=10,action="accept"}}},
    elsewhere={id="elsewhere",title="Elsewhere",zone="Elsewhere",continent="Eastern Kingdoms",levelMin=10,levelMax=20,steps={{id="e",questId=5,action="accept"}}},
    optional={id="optional",title="Optional",isOptional=true,levelMin=10,levelMax=20,steps={{id="o",action="manual"}}},
}
local progress={}
for id in pairs(guides) do progress[id]={current=4,completed={},skipped={}} end
local current="home"
local g={GetGuide=function(_,id) return guides[id or current] end,GetSteps=function(_,id) return guides[id or current].steps end,
    GetProgress=function(_,id) return progress[id or current] end,
    CurrentStep=function() return guides[current].steps[progress[current].current],progress[current].current end,
    SetCurrent=function(_,i) progress[current].current=i end}
ns.Modules.Guides=g
local routes={QuestState=function(_,id) return {active=active[id],ready=ready[id],turnedIn=done[id]} end,
    BlockedReason=function(_,s) if active[s.questId] or done[s.questId] then return end
        if s.minLevel and level<s.minLevel then return "Requires level "..s.minLevel end
        for _,req in ipairs(s.requires or {}) do if not done[req] then return "Complete prerequisite "..req end end
        if s.action=="objective" then return "Not in quest log" end
    end,
    ConcurrentQuestSteps=function() return active[3] and {{index=5,step=guides.home.steps[5]}} or {} end,
    ListGuides=function() return {guides.home,guides.next,guides.elsewhere,guides.optional} end,
    Preview=function(_,id) return 1 end,
    Switch=function(_,id) current=id;return true end}
ns.Modules.SmartRoutes=routes
local nav={SetOverride=function(self,i) self.overrideIndex=i;return true end,Refresh=function() end}
ns.Modules.Navigator=nav
assert(loadfile('shared/core/QuestAssistance.lua'))('WayForth',ns)
local help=ns.Modules.QuestAssistance
active[3]=true
local proposal=help:Recovery()
assert(proposal.message:find('prerequisite') and #proposal.options==2)
assert(proposal.options[1].questId==1 and proposal.options[2].questId==3)
assert(next(progress.home.completed)==nil and progress.home.current==4,'Recovery proposals must not change progress')
assert(help:Choose(proposal,proposal.options[1]) and nav.overrideIndex==1)
assert(next(progress.home.completed)==nil and next(progress.home.skipped)==nil)
nav.overrideIndex=nil;progress.home.current=4
current="next"
assert(not help:Choose(proposal,proposal.options[1]),'Reject stale guide choice')
current="home";guides.home.steps[1].minLevel=12
proposal=help:Recovery()
assert(#proposal.options==1 and proposal.options[1].questId==3,'Do not route to a level-blocked prerequisite')
guides.home.steps[1].minLevel=nil
active[3]=nil
-- Cycle and unknown prerequisite cannot create invented completion.
guides.home.steps[1].requires={2}
proposal=help:Recovery()
assert(#proposal.options==0 and next(progress.home.completed)==nil)
guides.home.steps[1].requires=nil

assert(loadfile('shared/core/NextZone.lua'))('WayForth',ns)
local zones=ns.Modules.NextZone
level=5
assert(#zones:Options()==0,'No premature zone switch')
for _,s in ipairs(guides.home.steps) do progress.home.completed[s.id]=true end
level=10
local options=zones:Options()
assert(#options==2 and options[1].id=='next','Recommend both continents but prefer current region')
assert(current=='home','Recommendation must not switch automatically')
assert(zones:Switch('next') and current=='next')
current='home';settings.zoneSuggestions=false
assert(#zones:Options()==0 and not zones:Switch('next'))
settings.zoneSuggestions=true;progress.home.completed={}
level=20
options=zones:Options()
assert(#options>0,'Outleveled remaining quest steps should offer another zone')
active[3]=true
assert(#zones:Options()==0,'Active quest work must not be abandoned by a level recommendation')
active[3]=nil
progress.home.skipped.a=true
assert(next(progress.home.completed)==nil,'Skipped steps must not become completion')
progress.home.skipped={}

-- Every supported authored travel type uses its own leg. Transport never fabricates a waypoint.
progress.home.current=1
local step=guides.home.steps[1]
step.travel={{kind='boat',text='Board at the documented dock',mapId=1,x=20,y=30},
 {kind='zeppelin',text='Wait until landing'}, {kind='portal',text='Use the authored portal'},
 {kind='flight',text='Take the learned route'}, {kind='entrance',text='Enter the dungeon',mapId=2,x=40,y=50}}
assert(loadfile('shared/core/Travel.lua'))('WayForth',ns)
local travel=ns.Modules.Travel
assert(travel:Start() and travel:Current().kind=='boat')
ns.Modules.Theme={}
C_Map={GetBestMapForUnit=function() return 1 end}
assert(loadfile('shared/navigation/Navigator.lua'))('WayForth',ns)
nav=ns.Modules.Navigator
assert(nav:TargetForStep(step).x==.2)
assert(travel:Next() and travel:Current().kind=='zeppelin')
assert(nav:TargetForStep(step)==nil,'Never point across a transport leg without a verified waypoint')
assert(travel:Next() and travel:Next() and travel:Next())
assert(nav:TargetForStep(step).mapId==2)
assert(travel:Next() and not travel:Current() and next(progress.home.completed)==nil)
travel:Start();progress.home.current=4
assert(not travel:Current(),'Changing objective must clear the travel override')
step.travel=nil;progress.home.current=1
assert(not travel:Start(),'Unknown routes need instructions, not guessed legs')

-- Quest automation: explicit settings, current guide IDs, no reward selection.
assert(loadfile('shared/core/QuestInteractions.lua'))('WayForth',ns)
local interact=ns.Modules.QuestInteractions
local questID=1
local calls={}
GetQuestID=function() return questID end
AcceptQuest=function() calls.accept=(calls.accept or 0)+1 end
CompleteQuest=function() calls.complete=(calls.complete or 0)+1 end
local choices=0
GetNumQuestChoices=function() return choices end
GetQuestReward=function(choice) calls.reward=choice;calls.rewardCount=(calls.rewardCount or 0)+1 end
IsQuestCompletable=function() return true end
interact:Event('QUEST_DETAIL')
assert(not calls.accept,'Disabled by default')
settings.autoAcceptQuests=true;settings.autoTurnInQuests=true
interact:Event('QUEST_DETAIL');interact:Event('QUEST_DETAIL')
assert(calls.accept==1,'Duplicate event must not repeat accept')
questID=999;interact:Event('QUEST_DETAIL');interact:Event('QUEST_COMPLETE')
assert(calls.accept==1 and not calls.rewardCount,'Never handle a quest outside the guide')
questID=1
interact:Event('QUEST_PROGRESS');interact:Event('QUEST_COMPLETE')
assert(calls.complete==1 and calls.reward==0)
interact:Event('QUEST_FINISHED');choices=1;interact:Event('QUEST_COMPLETE')
assert(calls.reward==1 and calls.rewardCount==2)
interact:Event('QUEST_FINISHED');choices=2;interact:Event('QUEST_COMPLETE')
assert(calls.rewardCount==2,'Leave multiple reward choices manual')
choices=0
settings.guidePaused=true;interact:Event('QUEST_COMPLETE');assert(calls.rewardCount==2)
settings.guidePaused=false;IsShiftKeyDown=function() return true end
interact:Event('QUEST_DETAIL');assert(calls.accept==1)
IsShiftKeyDown=nil;InCombatLockdown=function() return true end
interact:Event('QUEST_COMPLETE');assert(calls.rewardCount==2)
InCombatLockdown=nil
progress.home.skipped.a=true;interact:Event('QUEST_DETAIL');assert(calls.accept==1)
progress.home.skipped={};GetQuestID=nil
interact:Event('QUEST_COMPLETE');assert(calls.rewardCount==2,'Unknown IDs must never auto turn in')
C_GossipInfo={GetAvailableQuests=function() return {{questID=999},{questID=1}} end,
    SelectAvailableQuest=function(id) calls.selected=id end,
    GetActiveQuests=function() return {{questID=1,isComplete=0}} end}
interact:Event('GOSSIP_SHOW');assert(calls.selected==1)
C_GossipInfo.GetAvailableQuests=nil;C_GossipInfo.GetActiveQuests=nil
interact:Event('GOSSIP_SHOW')
print('Recovery, stale selections, zone recommendations, travel stages and optional quest interactions passed')

-- Settings are opt-in and per-character.
local dbns={Modules={},schemaVersion=1}
function dbns:RegisterModule(n,m) self.Modules[n]=m end
WoWForeverDB=nil;WoWForeverCharDB=nil
assert(loadfile('shared/core/Database.lua'))('WayForth',dbns)
local db=dbns.Modules.Database
db:Initialize()
assert(db:Get('autoAcceptQuests')==false and db:Get('autoTurnInQuests')==false)
db:Set('autoAcceptQuests',true)
assert(dbns.char.settings.autoAcceptQuests==true and dbns.db.settings.autoAcceptQuests==false)
WoWForeverCharDB={};db:Initialize()
assert(db:Get('autoAcceptQuests')==false,'New alts must not inherit automation')
