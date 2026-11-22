-- Regression test for #61: the overflow menu must have a visible X and
-- closing it must never close the tracker, change guides or clear progress.
-- Run with Lua 5.1. Full layout and clickability still require WoW QA.
local ns={Modules={},char={
    activeGuide="tailoring",
    trackerOpenTabs={"tailoring","alliance-elwynn"},
    guideProgress={tailoring={current=7,completed={craftA=true}}},
    professionSuccessfulCrafts={tailoring={[1234]=3}},
}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
ns.Modules.Theme={}
ns.Modules.Database={Get=function() return nil end}
assert(loadfile("shared/tracker/Tracker.lua"))("WayForth",ns)
local tracker=ns.Modules.Tracker

local function fakeFrame(shown)
    local frame={visible=shown,shows=0,hides=0}
    function frame:Show() self.visible=true;self.shows=self.shows+1 end
    function frame:Hide() self.visible=false;self.hides=self.hides+1 end
    function frame:IsShown() return self.visible end
    return frame
end
tracker.frame=fakeFrame(true)
tracker.menu=fakeFrame(false)
tracker.picker=fakeFrame(true)
local arrow=fakeFrame(true)

-- The overflow button still toggles the menu, dismissing the picker first.
tracker:ToggleMenu()
assert(tracker.menu:IsShown() and not tracker.picker:IsShown(),
    "Three-dot button must open the menu and hide the guide picker")
assert(tracker.frame:IsShown() and arrow:IsShown(),
    "Opening overflow must preserve the tracker and navigation arrow")
tracker:ToggleMenu()
assert(not tracker.menu:IsShown(),"Three-dot button must toggle the menu closed")
tracker:ToggleMenu()
assert(tracker.menu:IsShown(),"Three-dot button must reopen the menu")

-- This is the only action bound to the new X: close menu, not guide/tracker.
local oldFrameHides=tracker.frame.hides
local oldPickerHides=tracker.picker.hides
tracker:CloseMenu()
assert(not tracker.menu:IsShown(),"X must hide the overflow menu")
assert(tracker.frame:IsShown() and tracker.frame.hides==oldFrameHides,
    "X must not close the tracker frame")
assert(tracker.picker.hides==oldPickerHides,
    "X must not mutate unrelated picker state")
assert(arrow:IsShown(),"X must preserve the navigation arrow")
assert(ns.char.activeGuide=="tailoring"
    and ns.char.trackerOpenTabs[1]=="tailoring"
    and ns.char.guideProgress.tailoring.completed.craftA
    and ns.char.professionSuccessfulCrafts.tailoring[1234]==3,
    "X must preserve active guide, tabs, quest and crafting progress")
tracker:CloseMenu()
assert(not tracker.menu:IsShown(),"Closing an already hidden menu should be safe")
tracker.menu=nil
tracker:CloseMenu()
tracker:ToggleMenu() -- Safe when tracker menu has not yet been initialized.

-- Guard the actual widget hierarchy and callback, not just the method.
local source=assert(io.open("shared/tracker/Tracker.lua","r")):read("*a")
assert(source:find('self.menuClose=theme:Button(menu,30,28,"X",function() Tracker:CloseMenu() end,"quiet")',1,true),
    "An X button must be bound to CloseMenu on the overflow menu parent")
assert(source:find('self.menuClose:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-8,-6)',1,true),
    "Close control must be visible at the top right of the menu")
assert(source:find('menu:SetSize(236,548)',1,true),
    "Menu must reserve enough height to avoid clipping the final utility row")
assert(source:find('item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-44-(i-1)*35)',1,true),
    "First toggle row must not overlap the header")
assert(source:find('item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-150-(i-1)*35)',1,true),
    "Utility actions must be moved below the header without overlapping toggles")
assert(source:find('"Rebuild Guide Progress"',1,true)
    and source:find('"Restore Previous Progress"',1,true),
    "Confirmed rebuild and restore actions must be available in the tracker menu")
assert(source:find('local menu=CreateFrame("Frame",nil,panel)',1,true),
    "Overflow close control must belong to the original tracker menu")
assert(source:find('self.moreButton=theme:Button(control,34,34,"..."',1,true),
    "Existing three-dot button must remain usable")
print("WayForth tracker overflow close-menu tests passed")
