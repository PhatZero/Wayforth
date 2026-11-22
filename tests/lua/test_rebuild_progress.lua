-- Lua 5.1 end-to-end regression for issue #80.
-- These are synthetic quest APIs, not claims about live Forever quest IDs.
local ns = {
    Modules={}, state={},
    char={
        activeGuide="westfall-test",
        guideProgress={
            ["other-guide"]={current=3,completed={safe=true},skipped={keep=true}},
            tailoring={current=7,completed={craft=true}},
        },
        turnedInQuests={[20]=true,[30]=true}, -- deliberately stale addon-only cache
        trackerOpenTabs={"westfall-test","other-guide"},
        professionSuccessfulCrafts={tailoring={[12345]=7}},
        favorites={["westfall-test"]=true},
        settings={trackerWidth=620},
    },
    starterGuides={
        {id="westfall-test",title="Westfall test",steps={
            {id="intro",action="manual",title="Introduction"},
            {id="q10-accept",action="accept",questId=10},
            {id="q10-work",action="objective",questId=10},
            {id="q10-turnin",action="turnin",questId=10},
            {id="q20-accept",action="accept",questId=20},
            {id="q20-work",action="objective",questId=20},
            {id="q20-turnin",action="turnin",questId=20},
            {id="trainer",action="manual",questId=20},
            {id="travel",action="travel",questId=20},
            {id="q30-accept",action="accept",questId=30},
            {id="q30-work",action="objective",questId=30},
            {id="q30-turnin",action="turnin",questId=30},
            {id="finish",action="manual"},
        }},
        {id="other-guide",title="Other guide",steps={
            {id="q40-accept",questId=40,action="accept"},
            {id="q40-work",questId=40,action="objective"},
            {id="q40-turnin",questId=40,action="turnin"},
        }},
        {id="tailoring",title="Tailoring",isProfession=true,steps={
            {id="craft",action="manual"},
        }},
    },
}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local flagged={[10]=true}
local active={[20]=true}
local ready={}
local errorFor={}
local checked=0
C_QuestLog={
    IsQuestFlaggedCompleted=function(id)
        checked=checked+1
        if errorFor[id] then error("quest flag not available") end
        return flagged[id]==true
    end,
    IsOnQuest=function(id) return active[id]==true end,
    GetLogIndexForQuestID=function(id) return active[id] and 1 or nil end,
    ReadyForTurnIn=function(id) return ready[id]==true end,
}
ns.Modules.Database={Get=function(_,key)
    if key=="simpleStepReader" or key=="autoAdvance" then return true end
    return nil
end}
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
local guides=ns.Modules.Guides
local old=guides:GetProgress("westfall-test")
old.current=12
old.currentStepId="q30-turnin"
old.routeMode="resume"
old.completed={
    intro=true,["q10-accept"]=true,["q10-work"]=true,["q10-turnin"]=true,
    ["q20-accept"]=true,["q20-work"]=true,["q20-turnin"]=true,
    trainer=true,travel=true,["q30-accept"]=true,["q30-work"]=true,
    ["q30-turnin"]=true,finish=true,
}
old.skipped={["q20-work"]=true}
old.history={important={keep=42}}
old.lastSkippedIndex=6
local originalOther=ns.char.guideProgress["other-guide"]
local originalProf=ns.char.guideProgress.tailoring
local originalTabs=ns.char.trackerOpenTabs
local otherCrafts=ns.char.professionSuccessfulCrafts

local ok,report=guides:RebuildProgress()
assert(ok and report:find("13 -> 4 verified steps",1,true),report)
assert(report:find("Previous progress backed up",1,true))
local rebuilt=guides:GetProgress()
assert(rebuilt~=old and rebuilt.rebuiltFromGame==true)
assert(rebuilt.current==6 and rebuilt.currentStepId=="q20-work",
    "Rebuild should select the active objective rather than a stale saved cursor")
assert(rebuilt.completed["q10-accept"] and rebuilt.completed["q10-work"]
    and rebuilt.completed["q10-turnin"] and rebuilt.completed["q20-accept"])
assert(not rebuilt.completed["q20-work"] and not rebuilt.completed["q20-turnin"]
    and not rebuilt.completed["q30-turnin"],
    "Old cached quest history cannot be treated as real quest evidence")
assert(not rebuilt.completed.intro and not rebuilt.completed.trainer
    and not rebuilt.completed.travel and not rebuilt.completed.finish,
    "Manual, travel and trainer checkpoints must remain unverified")
assert(not next(rebuilt.skipped), "Stale skipped flags must be cleared")
assert(guides:HasProgressBackup(), "Full old record must be backed up")
assert(ns.char.guideProgressBackups["westfall-test"]~=old)
assert(ns.char.guideProgressBackups["westfall-test"].history.important.keep==42)
assert(ns.char.guideProgressBackups["westfall-test"].skipped["q20-work"])
assert(ns.char.guideProgress["other-guide"]==originalOther
    and ns.char.guideProgress.tailoring==originalProf
    and ns.char.trackerOpenTabs==originalTabs
    and ns.char.professionSuccessfulCrafts==otherCrafts
    and ns.char.favorites["westfall-test"]
    and ns.char.settings.trackerWidth==620,
    "Rebuild must not touch other character state")

-- Every tracker refresh calls Sync. It must NOT re-import old local cache data.
guides:Sync()
rebuilt=guides:GetProgress()
assert(rebuilt.current==6 and not rebuilt.completed["q20-turnin"]
    and not rebuilt.completed["q30-accept"],
    "Ordinary Sync must not reintroduce pre-rebuild addon cache")

ready[20]=true
assert(guides:Sync()==true and guides:GetProgress().current==7,
    "Real ready-to-turn-in evidence should advance the rebuilt reader")
assert(guides:GetProgress().completed["q20-work"])
-- The QUEST_TURNED_IN event is first-party live evidence even before flags update.
ready[20],active[20]=nil,nil
guides:RecordQuestEvent("QUEST_TURNED_IN",20)
assert(guides:Sync()==true and guides:GetProgress().current==8,
    "New observed turn-in events may complete a rebuilt guide after the rebuild")
assert(guides:GetProgress().rebuiltTurnInEvents[20])
assert(not guides:GetProgress().completed.trainer)

-- The backup and reconstruction mode survive /reload.
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
guides=ns.Modules.Guides
assert(guides:HasProgressBackup())
assert(guides:GetProgress().rebuiltFromGame)

local restored,restoreReport=guides:RestorePreviousProgress()
assert(restored and restoreReport:find("previous progress restored",1,true))
local previous=guides:GetProgress()
assert(previous.current==12 and previous.currentStepId=="q30-turnin")
assert(previous.completed.trainer and previous.completed["q30-work"])
assert(previous.skipped["q20-work"] and previous.lastSkippedIndex==6)
assert(previous.history.important.keep==42)
assert(previous.routeMode=="resume")
assert(not guides:HasProgressBackup())
assert(not guides:RestorePreviousProgress())
assert(ns.char.guideProgress["other-guide"]==originalOther)

-- API outage must fail safely without changing records or backup history.
local before=guides:GetProgress()
C_QuestLog=nil
IsQuestFlaggedCompleted=nil
GetQuestLogIndexByID=nil
local denied,reason=guides:RebuildProgress()
assert(not denied and reason:find("verification is unavailable",1,true))
assert(guides:GetProgress()==before and not guides:HasProgressBackup(),
    "No API must not reset or back up progress")
C_QuestLog={
    IsQuestFlaggedCompleted=function(id)
        if id==30 then error("quest API fault") end
        return flagged[id]==true
    end,
    IsOnQuest=function(id) return active[id]==true end,
}
denied,reason=guides:RebuildProgress()
assert(not denied and reason:find("verification is unavailable",1,true))
assert(guides:GetProgress()==before and not guides:HasProgressBackup(),
    "Partial quest flag failures must abort without touching the record")

-- Global quest-flag and quest-log aliases work without C_QuestLog.
C_QuestLog=nil
IsQuestFlaggedCompleted=function(id) return flagged[id]==true end
GetQuestLogIndexByID=function(id) return active[id] and 9 or 0 end
flagged[30]=true
local rerun,rerunReport=guides:RebuildProgress()
assert(rerun and rerunReport:find("verified steps",1,true))
assert(guides:GetProgress().completed["q30-turnin"],
    "Confirmed game flags can rebuild even without C_QuestLog")
assert(not guides:GetProgress().completed.trainer)
-- Rebuilding again is safe and replaces the most recent backup only.
local curr=guides:GetProgress()
assert(guides:RebuildProgress())
assert(guides:GetProgress()~=curr)
assert(guides:RestorePreviousProgress())
assert(guides:GetProgress().rebuiltFromGame==true)

-- No active quest: first unverified authored step, not a guessed future route.
active={}
flagged={}
assert(guides:RebuildProgress())
assert(guides:GetProgress().current==1
    and not guides:GetProgress().completed.intro)

local keepTailoring=ns.char.guideProgress.tailoring
assert(not guides:RebuildProgress("tailoring"))
assert(ns.char.guideProgress.tailoring==keepTailoring,
    "Professional progress must be unaffected by this quest repair")
assert(not guides:RebuildProgress("does-not-exist"),
    "Unknown guide IDs must never be mapped to the fallback tutorial")
assert(not guides:RestorePreviousProgress("does-not-exist"),
    "Restore must not silently target a different guide")

-- A repeatable quest with an old completed flag and a currently active run
-- must not skip its new objective/turn-in.
flagged[10]=true
active[10]=true
assert(guides:RebuildProgress())
assert(guides:GetProgress().current==3,
    "Live repeatable quest progress must take precedence over old turn-in flags")
assert(guides:GetProgress().completed["q10-accept"])
assert(not guides:GetProgress().completed["q10-work"]
    and not guides:GetProgress().completed["q10-turnin"])

print("WayForth verified guide rebuild, backup, restore and strict sync tests passed")
