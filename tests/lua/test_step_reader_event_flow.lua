-- Forever event QA: Step Reader mode must not invoke background rerouting.
local frame={scripts={},events={}}
function frame:SetScript(k,v) self.scripts[k]=v end
function frame:RegisterEvent(e) self.events[e]=true end
function CreateFrame(kind) assert(kind=="Frame"); return frame end
local calls={}
local simple=true
local ns={
    state={loaded=true,initialized={}},
    Modules={
        UI={},
        Database={Get=function(_,key) if key=="simpleStepReader" then return simple end end},
        Diagnostics={
            Error=function(_,event,errorMessage) error(event..": "..tostring(errorMessage)) end,
            Info=function() end,
            Warn=function() end,
        },
    },
}
function ns:Call(module,method,...)
    local key=module.."."..method
    calls[key]=(calls[key] or 0)+1
    return true,false
end
assert(loadfile("shared/core/Bootstrap.lua"))("WayForth",ns)
local function fire(name,...)
    assert(frame.scripts.OnEvent,"Event handler missing")
    frame.scripts.OnEvent(frame,name,...)
end

fire("PLAYER_LOGIN")
assert(calls["Guides.Sync"]==1,"Login must synchronize existing guide")
assert(calls["Guides.ResumeOnLogin"]==1,"Run one safe recovery from saved cursor on login")
assert(not calls["SmartRoutes.Recalculate"],"Login must not silently reroute")
fire("QUEST_ACCEPTED",1,92460)
assert(calls["Guides.RecordQuestEvent"]==1,"Record real accepted quest event")
assert(calls["Guides.Sync"]==2,"Immediate quest event must update step reader")
assert(not calls["SmartRoutes.Recalculate"],"Accepting a quest must not recalculate route")
fire("PLAYER_LEVEL_UP",5)
fire("ZONE_CHANGED_NEW_AREA")
assert(not calls["SmartRoutes.Recalculate"],"Level and zone changes cannot move the reader")
fire("QUEST_LOG_UPDATE")
frame.scripts.OnUpdate(frame,0.16)
assert(calls["Guides.Sync"]==3,"Delayed quest-log scan should occur once")
assert(not calls["SmartRoutes.Recalculate"],"Log update must not reroute")
assert(calls["Guides.ResumeOnLogin"]==1,"Zone and quest events must not re-run login recovery")

-- Compatibility path remains available only when legacy mode is deliberately selected.
simple=false
fire("QUEST_ACCEPTED",1,92461)
assert(calls["SmartRoutes.Recalculate"]==1,"Legacy routing remains available only when selected")

print("Forever event QA: step reader owns progress during login, quests and zone changes")
