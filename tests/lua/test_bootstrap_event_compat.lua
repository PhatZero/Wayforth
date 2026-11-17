-- Forever-style client fixture: some trade-skill events are undefined.
-- The addon must still load and refresh profession data via TRADE_SKILL_SHOW.
local unsupported={
    TRADE_SKILL_UPDATE=true,
    TRADE_SKILL_LIST_UPDATE=true,
    SKILL_LINES_CHANGED=true,
}
local frame={scripts={},events={}}
function frame:SetScript(name,callback) self.scripts[name]=callback end
function frame:RegisterEvent(event)
    if unsupported[event] then error('Frame:RegisterEvent(): unknown event "'..event..'"') end
    self.events[event]=true
end
function CreateFrame(kind)
    assert(kind=="Frame")
    return frame
end

local calls={}
local ns={
    state={loaded=true,initialized={}},
    Modules={
        Diagnostics={Error=function(_,event,message) error(event..": "..message) end},
        UI={},
        Guides={GetGuide=function() return {isProfession=true} end},
    },
}
function ns:Call(name,method)
    local key=name.."."..method
    calls[key]=(calls[key] or 0)+1
    return true,false
end
assert(loadfile("shared/core/Bootstrap.lua"))("WayForth",ns)
assert(frame.events.PLAYER_LOGIN and frame.events.QUEST_LOG_UPDATE)
assert(frame.events.TRADE_SKILL_SHOW, "Profession window refresh fallback must be registered")
for event in pairs(unsupported) do
    assert(not frame.events[event], "Unsupported "..event.." must be ignored")
end
frame.scripts.OnEvent(frame,"TRADE_SKILL_SHOW")
assert(calls["ProfessionGuides.Sync"]==1, "Profession sync must run when the window opens")
assert(calls["ProfessionGuides.CaptureOpenProfession"]==1, "Capture recipes when the window opens")
assert(calls["Tracker.Refresh"]==1, "Refresh the active profession guide")
print("Forever unsupported trade-skill event compatibility: OK")
