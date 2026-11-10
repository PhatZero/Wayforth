-- Render Guide Details in a small Lua 5.1 UI harness to catch runtime
-- regressions without starting the Forever client.
local selected="zone-one"
local ns={Modules={}, char={activeGuide="another-zone",favorites={},recentGuides={}}}
local steps={
    {id="one",title="Quest One",level=10},
    {id="two",title="Quest Two",level=11},
    {id="three",title="Quest Three",level=12},
}
local saved={current=2,completed={one=true},skipped={}}
local guide={
    id=selected,title="Example Alliance Leveling",zone="Darkshore",
    continent="Kalimdor",levelMin=10,levelMax=20,
    description="Complete the next quests in this region.",
}
local calls={preview={},switch={}}
local Guides={}
function Guides:GetGuide(id) if id==nil or id==selected then return guide end return nil end
function Guides:GetSteps(id) return steps end
function Guides:GetProgress(id) return saved end
function Guides:Status(id) return "In Progress" end
function Guides:IsFavorite(id) return ns.char.favorites[id] == true end
function Guides:ToggleFavorite(id) ns.char.favorites[id]=not self:IsFavorite(id) end
ns.Modules.Guides=Guides
ns.Modules.Character={Get=function() return {name="Phat Sparkles"} end}
ns.Modules.Tracker={Show=function(self) self.shown=true end}
ns.Modules.Database={Get=function() return nil end}
ns.Modules.SmartRoutes={
    Preview=function(self,id,mode)
        calls.preview[#calls.preview+1]=mode
        if mode=="recommended" then return 3,"Level-suitable option." end
        if mode=="beginning" then return 1,"Earliest unfinished." end
        if mode=="resume" then return saved.current,"Saved position." end
    end,
    Switch=function(self,id,mode)
        calls.switch[#calls.switch+1]={id=id,mode=mode}
        ns.char.activeGuide=id
        return true,"Selected"
    end,
}
ns.Modules.Theme={
    gold={1,0.7,0.2,1},teal={0.2,0.8,0.9,1},
    muted={0.5,0.6,0.7,1},ivory={1,1,1,1},
    green={0.3,0.8,0.4,1},
}
UnitLevel=function() return 12 end
UnitFactionGroup=function() return "Alliance" end
function ns:Print(x) self.lastMessage=x end
ns.Modules.UI={}
assert(loadfile("shared/ui/Modern.lua"))("WayForth",ns)
local ui=ns.Modules.UI
ui.currentTab="Guide Details"
ui.selectedGuideId=selected
ui.frame={}
ui.body={GetWidth=function() return 700 end}
ui.page={GetHeight=function() return 525 end}
ui.navigation={}
ui.widgets={}
ui.handlers={}
local actions,texts
function ui:ClearPage() actions={};texts={} end
function ui:Button(id,text,x,y,w,h,callback,primary)
    actions[id]=callback
    texts[id]=text
end
function ui:Hit(id,x,y,w,h,callback) actions[id]=callback end
function ui:Label(id,text) texts[id]=text end
function ui:Art() end
function ui:Surface(id)
    return {SetColorTexture=function() end}
end
function ui:Title(name,sub) texts.title=name;texts.subtitle=sub end
function ui:Hide() self.hidden=true end

ui:Refresh()
assert(ui.detailMode=="recommended", "New selection defaults to smart start")
assert(texts.detailsPreviewStep:find("Step 3:"), "Preview did not show smart starting step")
assert(#calls.switch==0, "Preview should not mutate the active guide")
assert(#calls.preview==1 and calls.preview[1]=="recommended")
assert(saved.current==2 and not saved.completed.three, "Saved progress changed during preview")
assert(type(actions.detailChoose2)=="function")
actions.detailChoose2()
assert(ui.detailMode=="beginning", "From Beginning selection was not captured")
assert(texts.detailsPreviewStep:find("Step 1:"), "Beginning preview was not updated")
assert(#calls.switch==0, "Selecting a card must not change guides")
actions.detailChoose3()
assert(ui.detailMode=="resume" and texts.detailsPreviewStep:find("Step 2:"),
    "Resume preview did not use existing guide position")
assert(#calls.switch==0 and saved.current==2, "Resume preview changed saved progress")
assert(type(actions.detailLaunch)=="function", "Launch action was not offered")
actions.detailLaunch()
assert(#calls.switch==1 and calls.switch[1].mode=="resume" and
    calls.switch[1].id==selected, "Launch selected the wrong mode")
assert(ns.Modules.Tracker.shown and ui.hidden, "Start must open tracker and close dashboard")
assert(saved.current==2 and saved.completed.one, "Switch must preserve saved quest state")
print("Guide Details interaction and preview behavior passed")
