-- Regression coverage for guide-tab lifecycle independent of the WoW UI.
-- Tab removal must never delete per-guide route or profession progress.
local ns={Modules={},char={
    activeGuide="tailoring",
    trackerOpenTabs={"tailoring","level","tailoring","missing"},
    guideProgress={tailoring={current=4,completed={stepA=true}}},
    professionSuccessfulCrafts={tailoring={[1234]=7}},
}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call(name,method,...)
    local module=self.Modules[name]
    if module and module[method] then return module[method](module,...) end
end
local entries={
    tailoring={id="tailoring",title="Tailoring Profession Guide"},
    level={id="level",title="Alliance Leveling"},
    alchemy={id="alchemy",title="Alchemy"},
}
for i=1,12 do entries["guide"..i]={id="guide"..i,title="Test Guide "..i} end
local guides={}
function guides:GetGuide(id) return entries[id or ns.char.activeGuide] or entries.level end
function guides:SetActive(id)
    if not entries[id] then return false end
    ns.char.activeGuide=id
    return true
end
ns.Modules.Guides=guides
ns.Modules.Theme={teal={0,1,1,1},ivory={1,1,1,1},
    elevated={0.1,0.2,0.3,1},panel={0.1,0.1,0.1,1}}
ns.Modules.Database={Get=function() return nil end}
assert(loadfile("shared/tracker/Tracker.lua"))("WayForth",ns)
local tracker=ns.Modules.Tracker
local paints,hides=0,0
function tracker:Refresh() paints=paints+1 end
function tracker:Hide() hides=hides+1 end

local tabs=tracker:EnsureOpenTabs("alchemy")
assert(#tabs==3 and tabs[1]=="tailoring" and tabs[2]=="level" and tabs[3]=="alchemy",
    "Tabs should deduplicate, validate and add new guides")
tracker:ActivateGuideTab("level")
assert(ns.char.activeGuide=="level" and paints==1)
tracker:CloseGuideTab("tailoring")
assert(#ns.char.trackerOpenTabs==2 and ns.char.activeGuide=="level",
    "Closing a background tab must not replace the active guide")
tracker:CloseGuideTab("level")
assert(ns.char.activeGuide=="alchemy" and paints==2,
    "Closing the active tab should select another open guide")
tracker:CloseGuideTab("alchemy")
assert(hides==1 and #ns.char.trackerOpenTabs==0,
    "Closing the last tab should hide the tracker")
assert(ns.char.guideProgress.tailoring.completed.stepA)
assert(ns.char.professionSuccessfulCrafts.tailoring[1234]==7,
    "Closing tabs must preserve per-character crafting progress")

ns.char.trackerOpenTabs={}
local many={}
for i=1,12 do many[#many+1]="guide"..i end
ns.char.trackerOpenTabs=many
local trimmed=tracker:EnsureOpenTabs("tailoring")
assert(#trimmed==8 and trimmed[#trimmed]=="tailoring",
    "Tab capacity should preserve the newly active guide")

-- Verify paging doesn't snap to the active guide on every tracker refresh.
local function fake()
    local f={}
    function f:SetWidth(n) self.width=n end
    function f:SetTextColor(...) self.color={...} end
    function f:SetColorTexture(...) self.color={...} end
    function f:SetLabel(v) self.text=v end
    function f:ClearAllPoints() end
    function f:SetPoint() end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    return f
end
tracker.tabStrip=fake()
tracker.frame={GetWidth=function() return 480 end}
tracker.guideTabs={}
for i=1,3 do
    local button=fake()
    button.label=fake()
    button.surface=fake()
    tracker.guideTabs[i]={button=button}
end
tracker.tabPrevious=fake()
tracker.tabNext=fake()
tracker.tabStart=1
tracker.tabActiveId=nil
tracker:RefreshTabs()
assert(tracker.tabStart>=1,"Tab strip must render even when guides overflow")
local page=2
tracker.tabStart=page
tracker:RefreshTabs()
assert(tracker.tabStart==page,"Manual tab paging must survive regular refreshes")
print("WayForth closable guide tab lifecycle and paging tests passed")
