local audit=dofile('scripts/audit_all_guides.lua')
local ns,guides=audit.ns,audit.guides
function ns:Call() return true end
ns.Modules.Database={Get=function() return true end}
local active,done={},{}
UnitLevel=function() return 60 end
C_QuestLog={IsOnQuest=function(id) return active[id] end,IsQuestFlaggedCompleted=function(id) return done[id] end}
assert(loadfile('shared/core/SmartRoutes.lua'))('WayForth',ns)
assert(loadfile('shared/core/Travel.lua'))('WayForth',ns)
assert(loadfile('shared/core/GuideSearch.lua'))('WayForth',ns)
local routes,travel,search=ns.Modules.SmartRoutes,ns.Modules.Travel,ns.Modules.GuideSearch
local q={requires={11},requiresAny={12,13}}
done[13]=true
assert(#routes:Requirements(q)==1,'One completed alternative must satisfy the whole OR group')
done[13]=nil;active[13]=true
assert(routes:Requirements(q)[2]==13,'Recover the already-active alternative first')
active[13]=nil
assert(routes:Requirements(q,{{questId=13,action='accept'}})[2]==13,'Prefer an alternative with a bundled pickup')
assert(ns.foreverQuestLocations[93062].pickup[1].name=='Nerlokh')
assert(ns.foreverQuestLocations[93196].pickup[1].id~=ns.foreverQuestLocations[93196].turnin[1].id,
    'Separate giver and finisher must remain distinct')
assert(routes:BlockedReason({questId=999,minLevel=61,action='accept'},{}):find('Requires level 61',1,true))
active[999]=true
assert(not routes:BlockedReason({questId=999,minLevel=61,action='objective'},{}),'Live log overrides source level requirements')
active[999]=nil
local checked=0
for _,guide in ipairs(guides:List()) do
    if guide.id~='first-steps' then
        ns.char.activeGuide=guide.id
        local steps=guides:GetSteps()
        local candidate
        for i,s in ipairs(steps) do
            if s.questId and s.mapId and s.x and s.y then candidate=i;break end
        end
        local hasDestination=candidate~=nil
        guides:SetCurrent(candidate or 1)
        local step=guides:CurrentStep()
        active[step.questId]=true
        local before=guides:GetProgress().current
        if hasDestination then
        assert(travel:Start(),'Travel must use known destinations in '..guide.id)
        local leg=travel:Current(step)
        assert(leg,'Expected an active travel leg in '..guide.id)
        assert(not travel:Current({id='unrelated-candidate'}) and travel:Current(step)==leg,
            'Distance probes must not cancel current travel')
        travel:Stop()
        else
            assert(not travel:Start(),'Missing coordinates must never create a travel pin: '..guide.id)
        end
        local result=search:Find(tostring(step.questId))
        assert(#result>0,'Quest ID search must work in '..guide.id)
        local built=search.indexBuilds
        search:Find('unmatched additional query')
        assert(search.indexBuilds==built,'Repeated search should reuse unchanged documents')
        assert(guides:GetProgress().current==before,'Travel/search must preserve guide progress')
        assert(next(guides:GetProgress().completed)==nil,'Travel cannot complete quests')
        active[step.questId]=nil;checked=checked+1
    end
end
assert(checked==71)
-- Resolved metadata changes must invalidate search without caching status.
local step={id='test',questId=999,title='Old label'}
assert(search:Document(step,1,'fixture'):find('old label',1,true))
step.title='New label'
assert(search:Document(step,1,'fixture'):find('new label',1,true))
-- Distances are world units when available, not zone percentage comparisons.
C_Map={GetPlayerMapPosition=function() return {x=0,y=0} end,GetBestMapForUnit=function() return 1 end}
ns.Modules.Navigator={TargetForStep=function(_,s) return s end,DistanceForStep=function(_,s) return s.distance end}
local group={{index=1,step={mapId=1,x=.1,y=.1,distance=900}},{index=2,step={mapId=2,x=.9,y=.9,distance=100}}}
assert(routes:NearestGroupedStep(group)==2)
group[1].step.distance=nil;group[2].step.distance=nil
assert(routes:NearestGroupedStep(group)==1,'Fallback may only compare coordinates on one map')

-- Burst coalescing: 100 notifications cause one scan, with no lost trailing work.
local frames,calls={},{}
CreateFrame=function()
    local f={scripts={}};function f:SetScript(k,v) self.scripts[k]=v end;function f:RegisterEvent() end
    frames[#frames+1]=f;return f
end
local eventsNS={state={loaded=true,initialized={}},Modules={UI={}}}
eventsNS.Modules.Diagnostics={Error=function(_,event,err) error(event..': '..err) end}
function eventsNS:Call(name,method) calls[method]=(calls[method] or 0)+1;return true,false end
assert(loadfile('shared/core/Bootstrap.lua'))('WayForth',eventsNS)
local frame=frames[1]
for i=1,100 do frame.scripts.OnEvent(frame,'QUEST_LOG_UPDATE') end
assert(not calls.Sync)
frame.scripts.OnUpdate(frame,.1);assert(not calls.Sync)
frame.scripts.OnUpdate(frame,.06);assert(calls.Sync==1 and calls.Recalculate==1)
frame.scripts.OnEvent(frame,'QUEST_WATCH_UPDATE',1)
frame.scripts.OnEvent(frame,'QUEST_ACCEPTED',1,1)
assert(calls.Sync==2 and calls.RecordQuestEvent==1,'Acceptance must be immediate')
frame.scripts.OnUpdate(frame,.2);assert(calls.Sync==2,'Immediate events absorb pending scans')
frame.scripts.OnEvent(frame,'QUEST_LOG_UPDATE')
frame.scripts.OnUpdate(frame,.2);assert(calls.Sync==3,'Trailing update must not be dropped')
print('All 71 guides: travel, prerequisites, search reuse, route distance and burst coalescing passed')
