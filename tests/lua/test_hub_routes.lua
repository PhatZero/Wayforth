-- Pickup -> field loop -> grouped turn-ins using real Guides and route state.
local ns={Modules={},state={},char={activeGuide="hub-test",guideProgress={},turnedInQuests={}},
    starterGuides={},foreverQuestCatalog={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call(name,method,...)
    local module=self.Modules[name]
    if module and module[method] then return true,module[method](module,...) end
    return false
end
local level,faction,race=10,"Alliance","HUMAN"
UnitLevel=function() return level end
UnitFactionGroup=function() return faction end
UnitClass=function() return "Mage","MAGE" end
UnitRace=function() return race,race end
local active,done,ready={},{},{}
C_QuestLog={
    IsOnQuest=function(id) return active[id]==true end,
    GetLogIndexForQuestID=function(id) return active[id] and 1 or 0 end,
    IsQuestFlaggedCompleted=function(id) return done[id]==true end,
    ReadyForTurnIn=function(id) return ready[id]==true end,
}
local settings={autoAdvance=true,autoRecovery=true,smartRouting=true,guidePaused=false}
ns.Modules.Database={Get=function(_,k) return settings[k] end}
for _,path in ipairs({
    "clients/forever/guides/StarterGuide.lua","clients/forever/guides/ZephrasLocations.lua",
    "clients/forever/guides/ZephrasIsle.lua","clients/forever/guides/AllianceStarters.lua",
    "clients/forever/guides/ForeverQuestCatalog.lua","clients/forever/guides/KalimdorAlliance.lua",
    "clients/forever/guides/HordeKalimdor.lua","clients/forever/guides/EasternEarly.lua",
    "clients/forever/guides/EasternHigh.lua","clients/forever/guides/HordeRaceStarterExtras.lua",
    "clients/forever/guides/ForeverQuestLocations.lua","shared/core/QuestLocations.lua",
}) do assert(loadfile(path))("WayForth",ns) end

local synthetic={id="hub-test",faction="Alliance",title="Hub test",zone="Test zone",steps={}}
local function addQuest(id,properties)
    properties=properties or {}
    for _,action in ipairs({"accept","objective","turnin"}) do
        local step={id=id.."-"..action,questId=id,title=tostring(id),text="Quest instruction",action=action,
            hub=action=="objective" and "Field" or "Camp",zone="Test zone",mapId=1,
            x=action=="objective" and 40 or 10,y=action=="objective" and 40 or 10,level=10}
        for k,v in pairs(properties) do step[k]=v end
        synthetic.steps[#synthetic.steps+1]=step
    end
end
for id=9901001,9901008 do addQuest(id) end
table.insert(synthetic.steps,4,{id="trainer-checkpoint",action="manual",title="Visit your trainer",text="Train before leaving."})
addQuest(9902001,{requires={9901001}}) -- unlocks only after an actual turn-in
addQuest(9903001,{minLevel=20})
addQuest(9903002,{level=30})
addQuest(9903003,{mapId=2})
addQuest(9903004,{x=80,y=80})
addQuest(9903005,{class="HUNTER"})
addQuest(9903006,{requires={999999}})
addQuest(9903007)
ns.foreverQuestLocations[9903007]={startItem=700000}
ns.starterGuides[#ns.starterGuides+1]=synthetic
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/core/HubRoutes.lua"))("WayForth",ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth",ns)
local guides,routes,hubs=ns.Modules.Guides,ns.Modules.SmartRoutes,ns.Modules.HubRoutes
local function reset(id)
    active,done,ready={},{},{}
    ns.state.acceptedQuestIDs={}
    ns.char.turnedInQuests={}
    ns.char.guideProgress[id]=nil
    guides:SetActive(id)
    local saved=guides:GetProgress()
    saved.routeMode="recommended"
    return saved
end
local function find(id)
    for index,step in ipairs(guides:GetSteps()) do if step.id==id then return index end end
    error("Missing step "..id)
end
local function accept(id)
    active[id]=true
    guides:RecordQuestEvent("QUEST_ACCEPTED",id)
    guides:Sync()
    routes:Recalculate()
end
local function turnin(id)
    active[id],ready[id],done[id]=nil,nil,true
    guides:RecordQuestEvent("QUEST_TURNED_IN",id)
    guides:Sync()
    routes:Recalculate()
end

local saved=reset("hub-test")
guides:Sync()
assert(saved.hubVisit and #saved.hubVisit.quests==8, "Scan the whole hub, beyond the old 12-step/5-quest limits")
assert(#routes:NearbyGroup()==8)
local visit=saved.hubVisit
local phase,count=visit.phase,#visit.quests
routes:Preview("hub-test","recommended")
assert(visit.phase==phase and #visit.quests==count and next(saved.completed)==nil,
    "Previews and planning must not forge completions or mutate visit state")
for id=9901001,9901008 do
    local step=guides:CurrentStep()
    assert(step.action=="accept" and step.questId==id,
        "Collect every eligible pickup before any field objective: "..tostring(step.questId))
    accept(id)
    if id<9901008 then assert(guides:CurrentStep().action=="accept") end
end
assert(saved.hubVisit.phase=="objectives" and guides:CurrentStep().action=="objective")
ready[9901001]=true
guides:Sync()
routes:Recalculate()
assert(guides:CurrentStep().action=="objective" and guides:CurrentStep().questId~=9901001,
    "One ready quest must not send the player back while the hub has unfinished objectives")
for id=9901002,9901008 do ready[id]=true end
guides:Sync()
routes:Recalculate()
assert(saved.hubVisit.phase=="turnins" and #routes:NearbyGroup()==8)
turnin(9901001)
assert(guides:CurrentStep().action=="turnin" and guides:CurrentStep().questId==9901002,
    "Finish the return visit's ready turn-ins before leaving for a newly unlocked follow-up")
for id=9901002,9901008 do turnin(id) end
assert(guides:CurrentStep().action=="accept" and guides:CurrentStep().questId==9902001,
    "Collect a follow-up only after its required turn-in is recorded")
assert(not saved.completed["9902001-accept"], "Routing is not quest acceptance")
accept(9902001)
ready[9902001]=true
guides:Sync()
saved.routeMode="beginning"
turnin(9902001)
assert(not saved.hubVisit, "A finished visit must release normal route recovery")
assert(guides:CurrentStep().id=="trainer-checkpoint" and not saved.completed["trainer-checkpoint"],
    "A hub batch must preserve unfinished manual checkpoints in From Beginning mode")

-- State survives module reloads by storing quest and step IDs, not transient indices.
saved=reset("hub-test")
guides:Sync()
accept(9901001)
assert(loadfile("shared/core/HubRoutes.lua"))("WayForth",ns)
hubs=ns.Modules.HubRoutes
assert(routes:Preview("hub-test","recommended")==find("9901002-accept"))
active[9901001]=nil
ns.state.acceptedQuestIDs[9901001]=nil
guides:RecordQuestEvent("QUEST_REMOVED",9901001)
guides:Sync()
assert(guides:CurrentStep().questId==9901002, "Abandonment must not trap the visit on an old accepted pickup")

for _,setting in ipairs({"guidePaused","autoAdvance","smartRouting","autoRecovery"}) do
    saved=reset("hub-test")
    settings[setting]=setting=="guidePaused"
    active[9901001]=true
    guides:Sync()
    assert(not saved.hubVisit, setting.." must retain user control")
    settings[setting]=setting~="guidePaused"
end
saved=reset("hub-test")
saved.skipped["9901002-accept"]=true
guides:Sync()
accept(9901001)
assert(guides:CurrentStep().questId==9901003 and not saved.completed["9901002-accept"],
    "Skipping an unavailable pickup must not mark it complete or keep requesting it")

-- Real Zephras case: both Yorana quests share a hub and the Tower Defense gate.
saved=reset("zephras-alliance")
done[93320]=true
guides:SetCurrent(find("breaker-92645-accept"))
guides:Sync()
assert(saved.hubVisit and #saved.hubVisit.quests==2)
accept(92645)
assert(guides:CurrentStep().id=="logistics-92642-accept",
    "Breaking the Breaker must not send the player out before Disrupting Logistics is picked up")
accept(92642)
-- The arrow must describe the task currently shown in the tracker, rather
-- than silently choosing a different member of the hub's objective group.
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth",ns)
local navigator=ns.Modules.Navigator
navigator.frame={IsShown=function() return false end}
C_Map={GetPlayerMapPosition=function() return {x=.657,y=.656} end}
navigator:Refresh()
local current=guides:CurrentStep()
assert(navigator.target and math.abs(navigator.target.x-current.x/100)<.00001)
C_Map=nil
ready[92645]=true
guides:Sync()
routes:Recalculate()
assert(guides:CurrentStep().id=="logistics-92642-objective")
ready[92642]=true
guides:Sync()
turnin(92645)
assert(guides:CurrentStep().id=="logistics-92642-turnin")
turnin(92642)
assert(guides:CurrentStep().id=="return-92880-accept",
    "Return to Valanaar unlocks after BOTH tower quests are handed in")

-- The first hub must not request its follow-ups before the introduction.
saved=reset("zephras-alliance")
level=1
guides:Sync()
assert(not saved.hubVisit and guides:CurrentStep().id=="start-accept")
done[92460]=true
guides:SetCurrent(find("harmony-accept"))
guides:Sync()
assert(saved.hubVisit and #saved.hubVisit.quests==2)
accept(92461)
assert(guides:CurrentStep().id=="flies-accept")
assert(not saved.completed["queen-accept"])

-- An installed update can finish a pickup round at the current hub, but cannot
-- pull a character back when they are already out working on the accepted quest.
level=10
saved=reset("zephras-alliance")
done[93320]=true
active[92645]=true
guides:SetCurrent(find("breaker-92645-objective"))
C_Map={GetPlayerMapPosition=function() return {x=.696,y=.671} end}
guides:Sync()
assert(guides:CurrentStep().id=="logistics-92642-accept")
saved=reset("zephras-alliance")
done[93320]=true
active[92645]=true
guides:SetCurrent(find("breaker-92645-objective"))
C_Map.GetPlayerMapPosition=function() return {x=.40,y=.30} end
guides:Sync()
assert(not saved.hubVisit and guides:CurrentStep().id=="breaker-92645-objective")
C_Map=nil

-- All installed guides participate through the same proximity and quest gates.
local checked=0
for _,guide in ipairs(guides:List()) do
    if guide.id~="first-steps" and guide.id~="hub-test" then
        faction=guide.faction or "Alliance"
        race=faction=="Horde" and "ORC" or "HUMAN"
        level=60
        saved=reset(guide.id)
        local steps=guides:GetSteps()
        for index,step in ipairs(steps) do
            if step.action=="accept" and step.questId then
                for _,required in ipairs(step.requires or {}) do done[required]=true end
                guides:SetCurrent(index)
                guides:Sync()
                if saved.hubVisit then
                    for _,id in ipairs(saved.hubVisit.quests) do
                        local pickup
                        for _,s in ipairs(steps) do if s.questId==id and s.action=="accept" then pickup=s;break end end
                        assert(pickup and hubs:SameHub(step,pickup), "Cross-map/hub pickup leaked into "..guide.id)
                    end
                end
                checked=checked+1
                break
            end
        end
    end
end
assert(checked>=55, "The hub planner must be available across the installed leveling library")
print("Hub pickup batching, field loops, grouped turn-ins, prerequisites and all-guide eligibility passed: "..checked.." guides")

-- Integrate capacity priority with the real Sync / HubRoutes / Preview stack.
assert(loadfile('shared/core/QuestLogSpace.lua'))('WayForth',ns)
active,done,ready={},{},{}
ns.char.turnedInQuests={}
faction,race,level='Alliance','HUMAN',10
settings.guidePaused=false;settings.autoAdvance=true;settings.autoRecovery=true;settings.smartRouting=true
guides:SetActive('hub-test')
local capacitySaved=guides:GetProgress()
capacitySaved.completed={};capacitySaved.skipped={};capacitySaved.hubVisit=nil
capacitySaved.routeMode='recommended'
guides:SetCurrent(1)
active[9901002]=true;ready[9901002]=true
C_QuestLog.GetNumQuestLogEntries=function() return 29,24 end
C_QuestLog.GetMaxNumQuestsCanAccept=function() return 25 end
guides:Sync()
ns.Modules.SmartRoutes:Recalculate()
local capacityStep=guides:CurrentStep()
assert(capacityStep.questId==9901002 and capacityStep.action=='turnin','Sync and Preview must agree on turn-in priority')
assert(not capacitySaved.completed['9901001-accept'],'Unaccepted quest must remain incomplete')
C_QuestLog.GetNumQuestLogEntries=function() return 29,20 end
active[9901002]=nil;ready[9901002]=nil;done[9901002]=true
guides:Sync();ns.Modules.SmartRoutes:Recalculate()
assert(guides:CurrentStep().action=='accept','Resume hub pickups once capacity pressure clears')
