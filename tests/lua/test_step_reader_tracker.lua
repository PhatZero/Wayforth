-- Simple Step Reader presentation test: no legacy hub sweep overlays.
-- This exercises the actual Tracker:Refresh code without an in-game client.
local ns = {
    Modules = {}, version = "1.0b19", state = {},
    char = {activeGuide="test",trackerMinimized=false},
}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call() return true end
local function widget()
    local w = {}
    function w:SetText(value) self.text = value end
    function w:SetTextColor(...) self.color = {...} end
    function w:SetLabel(value) self.text = value end
    function w:SetFont() end
    function w:SetTexture() end
    function w:SetTexCoord() end
    function w:SetWidth(n) self.width = n end
    function w:Show() self.visible = true end
    function w:Hide() self.visible = false end
    return w
end
local steps = {
    {id="pickup",title="Pick up the quest",action="accept",questId=5,text="Talk to the giver"},
    {id="objective",title="Finish the quest",action="objective",questId=5,text="Defeat the enemies"},
    {id="turnin",title="Return to the giver",action="turnin",questId=5,text="Hand it in"},
    {id="last",title="Visit your trainer",action="manual",text="Speak to a trainer"},
}
local saved={current=1,completed={last=true},skipped={}}
local guide={id="test",title="Redridge Mountains",zone="Redridge Mountains"}
ns.Modules.Guides = {
    Sync=function() return false end,
    GetGuide=function() return guide end,
    CurrentStep=function() return steps[saved.current],saved.current,#steps end,
    GetProgress=function() return saved end,
    GetSteps=function() return steps end,
}
local simple=true
ns.Modules.Database={Get=function(_,k)
    if k=="simpleStepReader" then return simple end
    return nil
end}
ns.Modules.Theme={teal={0,1,1,1},gold={1,0.8,0.3,1},ivory={1,1,1,1},artAtlas="art",ArtCoords=function() return 0,1,0,1 end}
ns.Modules.SmartRoutes={
    NearbyGroup=function() error("Legacy hub grouping ran during step-reader display") end,
    ConcurrentQuestSteps=function() error("Legacy concurrent quest routing ran during step-reader display") end,
    BlockedReason=function() return nil end,
}
ns.Modules.QuestLogSpace={
    Status=function() return {near=false} end,
    Message=function() return nil end,
    ReadyTurnIns=function() error("Legacy log-space priority ran during step-reader display") end,
}
ns.Modules.NextZone={Options=function() error("Old next-zone routing ran during step-reader display") end}
ns.Modules.Navigator={TargetForStep=function() return nil end,NavigationFeedback=function() return nil end}
ns.Modules.Travel={Current=function() return nil end}
assert(loadfile("shared/tracker/Tracker.lua"))("WayForth",ns)
local tracker=ns.Modules.Tracker
tracker.frame=widget()
tracker.frame.GetWidth=function() return 620 end
tracker.frame.IsShown=function() return true end
tracker.guideTitle=widget()
tracker.guideIcon=widget()
tracker.brandTitle=widget()
tracker.brandCaption=widget()
tracker.stepCount=widget()
tracker.stepTitle=widget()
tracker.next=widget()
tracker.objectiveCaption=widget()
tracker.objectiveText=widget()
tracker.location=widget()
tracker.pinButton=widget()
tracker.upcomingTitle=widget()
tracker.upcomingButtons={}
tracker.menuButtons={}
tracker.minimizeButton=widget()
tracker.pageButton=widget()
tracker.upcomingPage=1
tracker.upcomingPageCount=1
tracker.RefreshTabs=function() end
tracker.RefreshObjectives=function() end
tracker.ApplyOpacity=function() end
tracker.Layout=function() end
tracker:Refresh()

assert(tracker.objectiveCaption.text=="CURRENT STEP | PICK UP", "Expected step-reader mode, not HUB SWEEP")
assert(tracker.upcomingTitle.text=="NEXT GUIDE STEPS", "Show authored upcoming steps")
assert(#tracker.upcomingEntries==2, "Completed later steps are not presented as pending")
assert(tracker.upcomingEntries[1].index==2 and tracker.upcomingEntries[2].index==3,
    "Upcoming steps should remain in authored order")
assert(tracker.upcomingEntries[1].label:find("2. Finish the quest",1,true))
assert(tracker.stepCount.text=="Step 1 / 4  |  1/4 steps complete",
    "Saved cursor and completed count must be clearly distinguished")
assert(tracker.brandCaption.text=="STEP READER | 1.0b19", "Display the installed version visibly")
assert(saved.current==1 and saved.completed.last,"Rendering must never change saved progress")

-- A manual checkpoint stays visible when selected, with the proper action.
saved.current=4
tracker:Refresh()
assert(tracker.objectiveCaption.text=="CURRENT STEP | FOLLOW")
assert(tracker.next.text=="Done / Next")

print("WayForth Step Reader tracker displays authored guide steps without old hub UI")
