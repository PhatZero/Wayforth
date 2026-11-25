-- Lua 5.1 regression coverage for the default sequential step reader.
-- It must never let advisory routing modules move the current guide step.
local ns = {
    Modules = {}, state = {},
    char = { activeGuide = "step-reader-test", guideProgress = {}, turnedInQuests = {} },
    starterGuides = {{
        id = "step-reader-test", title = "Step reader test",
        steps = {
            {id="q10-accept", action="accept", questId=10, title="Take quest 10", x=40, y=50},
            {id="q10-objective", action="objective", questId=10, title="Do quest 10"},
            {id="q10-turnin", action="turnin", questId=10, title="Hand in quest 10"},
            {id="trainer", action="manual", title="Visit the trainer"},
            {id="q20-accept", action="accept", questId=20, title="Take quest 20", x=45, y=55},
            {id="q20-objective", action="objective", questId=20, title="Do quest 20"},
            {id="q20-turnin", action="turnin", questId=20, title="Hand in quest 20"},
            {id="finish", action="manual", title="All done"},
        },
    }},
}
ns.starterGuides[2]={id="visit-test",title="Visit test",steps={
    {id="visit-a",action="accept",questId=100,title="Pick up: First",visit={id="hub",title="Talk to NPC"}},
    {id="visit-b",action="accept",questId=101,title="Pick up: Second",visit={id="hub",title="Talk to NPC"}},
    {id="visit-end",action="manual",title="Leave hub",concurrentQuestIds={100,101,100,999}},
}}
function ns:RegisterModule(name, module) self.Modules[name] = module end
function ns:Call() return true end
UnitLevel = function() return 10 end
UnitFactionGroup = function() return "Alliance" end
local active, ready, turnedIn = {}, {}, {}
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    GetLogIndexForQuestID = function(id) return active[id] and 1 or nil end,
    IsQuestFlaggedCompleted = function(id) return turnedIn[id] == true end,
    ReadyForTurnIn = function(id) return ready[id] == true end,
}
local settings = {
    simpleStepReader = true, smartRouting = true, autoRecovery = true,
    autoAdvance = true, guidePaused = false,
}
ns.Modules.Database = {Get = function(_, key) return settings[key] end}
local attempts = 0
ns.Modules.HubRoutes = {Update = function() attempts = attempts + 1; return 8, "wrong jump" end}
ns.Modules.QuestLogSpace = {Priority = function() attempts = attempts + 1; return 8, "wrong jump" end}
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth", ns)
local guides, routes = ns.Modules.Guides, ns.Modules.SmartRoutes
local saved = guides:GetProgress()
assert(saved.current == 1)

-- A picked-up quest advances only to its objective, not to a hub guess.
active[10] = true
assert(guides:Sync() == true and saved.current == 2)
assert(saved.completed["q10-accept"] == true)
assert(routes:Recalculate() == false and saved.current == 2)

ready[10] = true
assert(guides:Sync() == true and saved.current == 3)
assert(saved.completed["q10-objective"] == true)
turnedIn[10],active[10],ready[10] = true,nil,nil
assert(guides:Sync() == true and saved.current == 4)

-- A later active quest is recorded but cannot silently skip the manual step.
active[20] = true
assert(guides:Sync() == true and saved.current == 4)
assert(saved.completed["q20-accept"])
assert(not saved.completed["trainer"])
assert(attempts == 0, "Smart hub and log-space heuristics must never run")

local preview = routes:Preview("step-reader-test", "recommended")
assert(preview == 6, "Explicit recommended selection follows the live objective")
assert(routes:Preview("step-reader-test", "beginning") == 1)
assert(routes:Preview("step-reader-test", "resume") == 4)
assert(guides:Sync(nil, true) == true and saved.current == 6,
    "Manual Sync catches up from actual quest evidence")

ready[20] = true
assert(routes:Preview("step-reader-test", "recommended") == 7)
assert(guides:Sync() == true and saved.current == 7)

-- If the quest is abandoned, an explicit Sync returns to its authored pickup.
-- Saved completion markers alone cannot automatically jump past that pickup.
active[20],ready[20] = nil,nil
local moved, report = guides:Sync(nil, true)
assert(moved and saved.current == 5, "Missing quest recovers to authored pickup")
assert(report:find("Quest pickup needed", 1, true), "Recovery tells the player what to collect")
assert(not saved.completed["trainer"], "Recovery must never fabricate manual completion")
guides:Sync()
assert(saved.current == 5, "Stale acceptance markers must not auto-skip abandoned quests")
assert(attempts == 0)

settings.guidePaused = true
active[20] = true
guides:Sync()
assert(saved.current == 5, "Paused guide should retain its cursor")
settings.guidePaused = false
guides:Sync()
assert(saved.current == 6, "Resuming stops at the next objective until verified")
ready[20] = true
assert(guides:Sync() == true and saved.current == 7)

-- The recommended mode is only applied after a player explicitly requests it.
guides:SetCurrent(4)
ready[20] = nil
assert(routes:Switch("step-reader-test", "recommended"))
assert(saved.current == 6, "Explicit switch may jump to a live quest")
assert(not saved.completed["trainer"])

-- A migrated character can have step 1 selected while later quest history is
-- already recorded. Normal quest events cannot guess a new route, but the
-- one-time login recovery may use a real active quest from the same guide.
turnedIn[10]=nil
ready[20]=nil
guides:SetCurrent(1)
saved.routeMode="recommended"
assert(guides:Sync()==false and saved.current==1,
    "Ordinary sync must not jump across unfinished authored steps")
assert(guides:ResumeOnLogin()==true and saved.current==6,
    "Login should recover a stale first-step cursor from a live quest")
assert(guides:ResumeOnLogin()==false,"Login recovery should not re-route a valid cursor")
guides:SetCurrent(1)
saved.routeMode="beginning"
assert(not guides:ResumeOnLogin() and saved.current==1,
    "An explicit From Beginning choice must be preserved across reload")
saved.routeMode="recommended"
active[20]=nil
assert(not guides:ResumeOnLogin() and saved.current==1,
    "No matching live quest must leave the cursor unchanged")

print("WayForth simple step reader regression tests passed")

assert(guides:SetActive("visit-test"))
local v=guides:VisitSnapshot(1)
assert(v and #v.rows==2 and v.completed==0)
active[100]=true
assert(guides:Sync() and guides:GetProgress().current==2)
v=guides:VisitSnapshot(2)
assert(v.first==1 and v.last==2 and v.completed==1 and v.rows[1].finished and not v.rows[2].finished)
active[101]=true
assert(guides:Sync() and guides:GetProgress().current==3)
assert(guides:VisitSnapshot(2).completed==2)
assert(not guides:VisitSnapshot(3))
guides:SetCurrent(1)
active[100]=nil
assert(guides:VisitSnapshot(1).completed==1)
assert(guides:GetProgress().current==1)
print("WayForth grouped visit regression passed")

ns.Modules.QuestProgress={Get=function(_,id)
    if id==100 then return {active=true,rows={{display="Items (2/5)",finished=false},{display="Done",finished=true}}} end
    if id==101 then return {active=true,ready=true,rows={{display="Ready",finished=false}}} end
    return {active=true,rows={{display="Not in guide",finished=false}}}
end}
guides:SetCurrent(3)
local concurrent=guides:ConcurrentSnapshot(3)
assert(#concurrent==1 and concurrent[1].questId==100 and concurrent[1].display=="First: Items (2/5)")
assert(guides:GetProgress().current==3 and not guides:GetProgress().completed["visit-end"])
print("WayForth concurrent objective regression passed")

ns.starterGuides[2].steps[3].condition={minLevel=12,requiresQuests={100},requiresSteps={"visit-a"}}
local conditional=guides:GetSteps()[3]
assert(guides:ConditionReason(conditional):find("level 12",1,true))
UnitLevel=function() return 12 end
assert(guides:ConditionReason(conditional):find("quest 100",1,true))
turnedIn[100]=true
assert(not guides:ConditionReason(conditional))
assert(guides:GetProgress().current==3)
UnitClass=function() return "Mage","MAGE" end
ns.starterGuides[2].steps[3].condition.classes={"WARRIOR"}
assert(#guides:GetSteps()==2 and #guides:GetSteps(nil,true)==3)
ns.starterGuides[2].steps[3].condition.classes={"MAGE"}
assert(#guides:GetSteps()==3)
print("WayForth condition regression passed")
