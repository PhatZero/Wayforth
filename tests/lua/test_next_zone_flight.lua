-- Issue #62: no switch prompts while flying or during the 30-second
-- stable-zone grace period. Offline Lua 5.1 test, no WoW installation needed.
local seconds=100
GetTime=function() return seconds end
local taxi,flying=false,false
UnitOnTaxi=function(unit) assert(unit=="player");return taxi end
IsFlying=function() return flying end
local character="character-A"
UnitGUID=function() return character end
UnitLevel=function() return 20 end

local settings={zoneSuggestions=true,guidePaused=false}
local ns={Modules={},char={activeGuide="home",trackerOpenTabs={"home"},
    guideProgress={home={current=2,completed={done=true}}}}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call(name,method,...)
    local m=self.Modules[name]
    if not m or type(m[method])~="function" then return false end
    return true,m[method](m,...)
end
local current="home"
local recipes={
    home={id="home",title="Home",continent="Kalimdor",levelMin=1,levelMax=20,
        steps={{id="done",questId=10,level=10}}},
    nearby={id="nearby",title="Nearby",zone="Nearby",continent="Kalimdor",levelMin=15,levelMax=25,
        steps={{id="one",questId=11,level=15}}},
    far={id="far",title="Far",zone="Far",continent="Eastern Kingdoms",levelMin=15,levelMax=25,
        steps={{id="two",questId=12,level=15}}},
}
local saved={home={completed={done=true}},nearby={completed={}},far={completed={}}}
local guide={
    GetGuide=function(_,id) return recipes[id or current] end,
    GetSteps=function(_,id) return recipes[id or current].steps end,
    GetProgress=function(_,id) return saved[id or current] end,
}
local manualSwitches=0
local routes={
    QuestState=function() return {turnedIn=false,active=false} end,
    Preview=function() return 1 end,
    BlockedReason=function() return nil end,
    ListGuides=function() return {recipes.home,recipes.nearby,recipes.far} end,
    Switch=function(_,id)
        manualSwitches=manualSwitches+1
        current=id
        return true
    end,
}
ns.Modules.Database={Get=function(_,key) return settings[key] end}
ns.Modules.Guides=guide
ns.Modules.SmartRoutes=routes
assert(loadfile("shared/core/NextZone.lua"))("WayForth",ns)
local zones=ns.Modules.NextZone
local function assertHidden(reason)
    assert(#zones:Options()==0,reason)
    assert(#zones:Options(true)==0,"Force must not bypass travel safety: "..reason)
end

-- No prompt on login or immediately after crossing a zone.
zones:OnZoneChanged()
assertHidden("On login")
seconds=129
assertHidden("Still within grace period")
assert(not zones:Tick(),"Before the threshold, no refresh")
seconds=130
assert(zones:Tick(),"At 30 seconds the UI needs one refresh")
assert(not zones:Tick(),"Stable zone must not fire duplicate refreshes")
local options=zones:Options()
assert(#options==1 and options[1].id=="nearby","One best relevant suggestion only")
assert(zones:Options()[1].id=="nearby","Suggestion remains stable on refresh")

-- A new flight immediately removes a previously eligible suggestion.
taxi=true;seconds=131
assert(zones:Tick(),"Flight beginning must hide existing NEXT ZONE")
assertHidden("Flying after having shown a recommendation")
seconds=231
assertHidden("Taxi still in flight after more than 30 seconds")
zones:OnZoneChanged()
seconds=240;zones:OnZoneChanged() -- another intermediate zone while on taxi
seconds=280
assertHidden("Repeated zone crossings during the same flight")
taxi=false
assert(not zones:Tick(),"Landing starts grace but does not show prompt")
seconds=309
assertHidden("Less than 30 seconds after landing")
seconds=310
assert(zones:Tick(),"Landed/stable 30 seconds should show one suggestion")
assert(not zones:Tick(),"Landing should not cause repeated prompts")
assert(#zones:Options()==1)

-- Zone crossing while on the ground restarts the full 30 seconds.
seconds=315;zones:OnZoneChanged()
seconds=339;assertHidden("Must reset the wait after another zone transition")
seconds=345;assert(zones:Tick())
assert(#zones:Options()==1)

-- IsFlying also covers free flying on a mount without being on a taxi.
flying=true;seconds=346
assert(zones:Tick(),"Flying mount must hide a previously shown suggestion")
assertHidden("Flying above a zone")
flying=false;seconds=400;zones:Tick()
seconds=429;assertHidden("Hold from landing, not original zone crossing")
seconds=430;assert(zones:Tick())
assert(#zones:Options()==1)

-- A manual switch is always available through SmartRoutes/guide library,
-- even while the automatic recommendation is suppressed.
taxi=true;seconds=435;assert(zones:Tick())
assert(routes:Switch("far") and current=="far","Manual guide selection must work during flight")
assert(zones:Tick(),"Manual switch invalidates previous prompt")
assertHidden("Manual switch never reuses old recommendation")
assert(manualSwitches==1)
taxi=false;seconds=440;zones:Tick()
seconds=469;assertHidden("Manual selection continues to respect settling")
seconds=470;assert(zones:Tick())
assert(#zones:Options()<=1)

-- Pausing/disabling never shows stale recommendations after enabling.
current="home";seconds=500;zones:Tick()
seconds=530;zones:Tick()
assert(#zones:Options()==1)
settings.guidePaused=true
assert(zones:Tick(),"Pause invalidates visible suggestion")
assertHidden("Paused")
settings.guidePaused=false;seconds=531
assert(zones:Tick(),"Resuming begins a new stable wait")
seconds=560;assertHidden("No immediate suggestion after resume")
seconds=561;assert(zones:Tick());assert(#zones:Options()==1)
settings.zoneSuggestions=false;assert(zones:Tick());assertHidden("Suggestions disabled")
settings.zoneSuggestions=true;seconds=562;assert(zones:Tick())
seconds=591;assertHidden("New setting resets grace period")
seconds=592;assert(zones:Tick());assert(#zones:Options()==1)

-- Changing characters invalidates pending options and does not touch progress.
character="character-B";seconds=600
assert(zones:Tick(),"Character switch resets suggestion timer")
assertHidden("No leaked recommendations from the old character")
assert(ns.char.guideProgress.home.completed.done
    and ns.char.trackerOpenTabs[1]=="home","Travel checks must never alter saved state")

-- API absence/failure should not crash the addon or invent flight state.
UnitOnTaxi=function() error("not available") end
IsFlying=nil
seconds=630
assert(zones:Tick(),"Clock can still settle if flight APIs fail")
assert(#zones:Options()==1)
print("Flight-aware 30-second zone suggestion tests passed")

-- Bootstrap should tick at most once per second even without quest updates
-- and should reset the guard on zone/player-world events.
local checks,refreshes,resets=0,0,0
local frame
CreateFrame=function()
    local f={scripts={},events={}}
    function f:SetScript(name,fn) self.scripts[name]=fn end
    function f:RegisterEvent(name) self.events[name]=true end
    frame=f
    return f
end
local boot={Modules={},state={loaded=true,loggedIn=true,initialized={}}}
function boot:Call(name,method,...)
    local module=self.Modules[name]
    if not module or type(module[method])~="function" then return false end
    return true,module[method](module,...)
end
boot.Modules.Diagnostics={Error=function(_,event,err) error(event..": "..tostring(err)) end}
boot.Modules.UI={frame={IsShown=function() return false end}}
boot.Modules.NextZone={
    Tick=function() checks=checks+1;return checks==1 end,
    OnZoneChanged=function() resets=resets+1 end,
}
boot.Modules.Tracker={
    frame={IsShown=function() return true end},
    Refresh=function() refreshes=refreshes+1 end,
}
assert(loadfile("shared/core/Bootstrap.lua"))("WayForth",boot)
assert(frame.events.ZONE_CHANGED_NEW_AREA)
frame.scripts.OnUpdate(frame,.5)
assert(checks==0 and refreshes==0)
frame.scripts.OnUpdate(frame,.5)
assert(checks==1 and refreshes==1,"OnUpdate must refresh exactly once on a guard transition")
frame.scripts.OnUpdate(frame,1)
assert(checks==2 and refreshes==1,"Stable checks must not repaint the tracker")
frame.scripts.OnEvent(frame,"ZONE_CHANGED_NEW_AREA")
assert(resets==1,"Zone boundary must reset settling state")
frame.scripts.OnEvent(frame,"PLAYER_ENTERING_WORLD")
assert(resets==2,"World entry must reset settling state")
print("Flight-aware Bootstrap event/tick integration tests passed")
