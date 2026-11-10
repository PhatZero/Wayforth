-- Live objective reads, tracker rendering, event refresh and completion authority.
local ns={Modules={},state={initialized={}},char={guideProgress={},activeGuide="live",settings={}},starterGuides={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call(name,method,...)
    local module=self.Modules[name]
    if not module or not module[method] then return false end
    return true,module[method](module,...)
end
function ns:Print() end
local active,ready,turnedIn,failed,objectives={},{},{},{},{}
local reads=0
local api={
    IsOnQuest=function(id) return active[id]==true end,
    GetLogIndexForQuestID=function(id) return active[id] and 7 or 0 end,
    ReadyForTurnIn=function(id) return ready[id]==true end,
    IsComplete=function(id) return ready[id]==true end,
    IsFailed=function(id) return failed[id]==true end,
    IsQuestFlaggedCompleted=function(id) return turnedIn[id]==true end,
    GetQuestObjectives=function(id) reads=reads+1;return objectives[id] end,
}
C_QuestLog=api
assert(loadfile("shared/core/QuestProgress.lua"))("WayForth",ns)
local progress=ns.Modules.QuestProgress
active[10]=true
objectives[10]={
    {text="Wolves slain",type="monster",numFulfilled=3,numRequired=8,finished=false},
    {text="5/5 Apples",type="item",numFulfilled=5,numRequired=5,finished=true},
    {text="Scout rescued",type="event",finished=false},
}
local snapshot=progress:Get(10)
assert(snapshot.state=="active" and #snapshot.rows==3 and snapshot.completed==1)
assert(snapshot.rows[1].display=="Wolves slain (3/8)")
assert(snapshot.rows[2].display=="5/5 Apples", "Native counters must not be duplicated")
assert(snapshot.rows[3].display=="Scout rescued", "Boolean objectives must not invent 0/1 counters")
objectives[10][1].numFulfilled=4
assert(progress:Get(10).rows[1].current==4, "Counters must be fresh, not cached")
turnedIn[10]=true
assert(progress:Get(10).state=="active", "An active repeatable quest takes precedence over historical completion")
turnedIn[10]=nil
ready[10]=true
assert(progress:Get(10).state=="ready")
failed[10]=true
assert(progress:Get(10).state=="failed" and not progress:Get(10).ready)
failed[10],ready[10]=nil,nil
local priorReads=reads
active[10]=nil
snapshot=progress:Get(10)
assert(snapshot.state=="inactive" and #snapshot.rows==0 and reads==priorReads,
    "Cached objective data must not appear for a quest absent from the log")
ns.state.acceptedQuestIDs={[10]=true}
assert(progress:Get(10).state=="loading" and #progress:Get(10).rows==0)
ns.state.acceptedQuestIDs=nil
assert(progress:Get(nil)==nil and progress:Get(-1)==nil)

-- Fallback reads use the exact quest log index and never change selection.
C_QuestLog={GetQuestObjectives=function() error("unsupported") end}
GetQuestLogIndexByID=function(id) assert(id==10);return 9 end
GetNumQuestLeaderBoards=function(index) assert(index==9);return 1 end
GetQuestLogLeaderBoard=function(row,index) assert(row==1 and index==9);return "Wolves slain: 2/8","monster",false end
SelectQuestLogEntry=function() error("Quest selection must remain untouched") end
snapshot=progress:Get(10)
assert(snapshot.state=="active" and snapshot.rows[1].current==2 and snapshot.rows[1].required==8)
GetQuestLogIndexByID,GetNumQuestLeaderBoards,GetQuestLogLeaderBoard,SelectQuestLogEntry=nil,nil,nil,nil
C_QuestLog=api
active[10]=true
objectives[10]={}
snapshot=progress:Get(10)
assert(snapshot.state=="unavailable" and not snapshot.ready and #snapshot.rows==0,
    "An empty objective list is not quest completion")
objectives[10]={{text="Battle progress",type="progressbar",finished=false}}
GetQuestProgressBarPercent=function(id) assert(id==10);return 43.8 end
assert(progress:Get(10).rows[1].display=="Battle progress (43%)")
GetQuestProgressBarPercent=nil
local hidden=setmetatable({}, {__tostring=function() error("restricted") end})
issecretvalue=function(value) return value==hidden end
objectives[10]={{text=hidden,type="item",numFulfilled=2,numRequired=5,finished=false}}
assert(progress:Get(10).rows[1].display=="Objective 1 (2/5)", "Restricted text must not be parsed")
objectives[10]={{text="Public objective",numFulfilled=hidden,numRequired=5,finished=false}}
assert(progress:Get(10).rows[1].display=="Public objective", "Unreadable counters must not become zero")
issecretvalue=nil

-- A small strict widget harness runs the actual tracker and layout code.
local frames={}
local function widget(kind,parent)
    local w={kind=kind,parent=parent,width=380,height=448,shown=true,scripts={},points={},text="",fontSize=11,scroll=0}
    for _,name in ipairs({"SetAllPoints","SetColorTexture","SetTextColor","SetJustifyH","SetJustifyV",
        "SetShadowOffset","SetShadowColor","SetTexture","SetTexCoord","SetFrameStrata","SetToplevel",
        "SetClampedToScreen","SetMovable","SetResizable","EnableMouse","EnableMouseWheel","SetResizeBounds",
        "SetMinResize","RegisterForDrag","SetScale","SetHighlightTexture","StartMoving","StopMovingOrSizing","StartSizing","SetWordWrap"}) do
        w[name]=function() end
    end
    function w:SetScript(name,fn) self.scripts[name]=fn end
    function w:SetSize(width,height) self.width,self.height=width,height end
    function w:SetWidth(width) self.width=width end
    function w:SetHeight(height) self.height=height end
    function w:GetWidth() return self.width end
    function w:GetHeight() return self.height end
    function w:SetPoint(point,relative,relativePoint,x,y) self.points[point]={relative,relativePoint,x,y} end
    function w:ClearAllPoints() self.points={} end
    function w:SetText(value) self.text=value or "" end
    function w:SetFont(_,size) self.fontSize=size end
    function w:SetMaxLines(count) self.maxLines=count end
    function w:GetStringHeight()
        if self.text=="" then return 0 end
        local lines=0
        for line in (self.text.."\n"):gmatch("(.-)\n") do
            lines=lines+math.max(1,math.ceil(#line*self.fontSize*0.52/math.max(1,self.width)))
        end
        return math.min(lines,self.maxLines or lines)*self.fontSize*1.2
    end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:GetFrameLevel() return self.level or 1 end
    function w:SetFrameLevel(value) self.level=value end
    function w:CreateFontString() return widget("FontString",self) end
    function w:CreateTexture() return widget("Texture",self) end
    function w:SetScrollChild(child) assert(child.parent==self);self.child=child end
    function w:SetVerticalScroll(value) assert(value>=0);self.scroll=value end
    function w:GetVerticalScroll() return self.scroll end
    function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
    frames[#frames+1]=w
    return w
end
function CreateFrame(kind,_,parent) return widget(kind,parent) end
UIParent=widget("Frame")
local settings={autoAdvance=true,autoRecovery=true,smartRouting=false}
ns.Modules.Database={Get=function(_,key) return settings[key] end,Set=function(_,key,value) settings[key]=value end}
ns.Modules.Navigator={Refresh=function() end,Show=function() end,Hide=function() end}
ns.Modules.UI={RefreshFooter=function() end}
ns.Modules.Diagnostics={Error=function(_,where,message) error(where..": "..message) end}
ns.starterGuides={{id="live",title="Live test",zone="Elwynn Forest",steps={
    {id="accept",questId=10,action="accept",title="Pick up test",text="Accept the quest."},
    {id="work",questId=10,action="objective",title="Work on test",text="Complete the quest objectives."},
    {id="turnin",questId=10,action="turnin",title="Turn in test",text="Return to the quest giver."},
    {id="next",action="manual",title="Travel",text="Travel to the next camp."},
}}}
ns.starterGuides[2]={id="second",title="Second guide",steps={
    {id="second-accept",questId=20,action="accept",title="Pick up second",text="Accept the quest."},
    {id="second-work",questId=20,action="objective",title="Work on second",text="Complete the quest objectives."},
    {id="second-turnin",questId=20,action="turnin",title="Turn in second",text="Return to the quest giver."},
}}
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/ui/Theme.lua"))("WayForth",ns)
assert(loadfile("shared/tracker/Tracker.lua"))("WayForth",ns)
local tracker,guides=ns.Modules.Tracker,ns.Modules.Guides
objectives[10]={
    {text="Wolves slain",type="monster",numFulfilled=3,numRequired=8,finished=false},
    {text="Apples",type="item",numFulfilled=2,numRequired=5,finished=false},
}
tracker:Show()
assert(guides:CurrentStep().action=="objective")
assert(tracker.liveRows[1].text=="[ ] Wolves slain (3/8)")
local index=guides:GetProgress().current
objectives[10][1].numFulfilled=4
tracker:RequestObjectiveRefresh()
tracker:RequestObjectiveRefresh()
tracker.frame.scripts.OnUpdate(tracker.frame,0.05)
assert(tracker.liveRows[1].text:find("3/8",1,true), "Event bursts must coalesce")
tracker.frame.scripts.OnUpdate(tracker.frame,0.06)
assert(tracker.liveRows[1].text:find("4/8",1,true) and guides:GetProgress().current==index,
    "Counters must refresh even when the guide cursor does not advance")
tracker:RequestObjectiveRefresh(20)
assert(not tracker.objectiveDirty, "Another quest's data-load event must not refresh the current quest")

-- Completed rows alone cannot skip a quest's remaining server requirements.
for _,row in ipairs(objectives[10]) do row.finished=true;row.numFulfilled=row.numRequired end
tracker:RequestObjectiveRefresh()
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
assert(guides:CurrentStep().action=="objective" and tracker.liveSnapshot.completed==2)
ready[10]=true
tracker:RequestObjectiveRefresh()
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
assert(guides:CurrentStep().action=="turnin" and tracker.liveStatus.text=="Ready to turn in.",
    tostring(guides:CurrentStep().action).." / "..tostring(tracker.liveStatus.text))

-- Large/wrapped objective lists scroll without covering controls or upcoming rows.
ready[10]=nil
objectives[10]={}
for i=1,12 do objectives[10][i]={text="A long objective with room to wrap onto a second line "..i,
    numFulfilled=i,numRequired=20,finished=false} end
tracker:Refresh()
assert(tracker.liveScroll:IsShown() and tracker.liveStatus.text:find("scroll",1,true))
assert(tracker.liveContentHeight>tracker.liveScroll:GetHeight())
local cardBottom=149+tracker.objectiveCard:GetHeight()
assert(cardBottom<=tracker.frame:GetHeight()-56)
for _,button in ipairs(tracker.upcomingButtons) do
    if button:IsShown() then
        local top=-button.points.TOPLEFT[4]
        assert(top>cardBottom and top+button:GetHeight()<=tracker.frame:GetHeight()-56)
    end
end
tracker.liveScroll.scripts.OnMouseWheel(tracker.liveScroll,-3)
local previousScroll=tracker.liveScroll:GetVerticalScroll()
assert(previousScroll>0)
tracker:RequestObjectiveRefresh()
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
assert(tracker.liveScroll:GetVerticalScroll()==previousScroll, "Progress refresh must preserve scrolling")
tracker.frame:SetSize(620,700)
tracker:Layout()
assert(tracker.liveScroll:GetVerticalScroll()<=math.max(0,tracker.liveContentHeight-tracker.liveScroll:GetHeight()))
for _,size in ipairs({{370,440},{380,448},{620,700}}) do
    tracker.frame:SetSize(size[1],size[2])
    tracker:Layout()
    assert(149+tracker.objectiveCard:GetHeight()<=size[2]-56)
    for _,button in ipairs(tracker.upcomingButtons) do
        if button:IsShown() then
            local top=-button.points.TOPLEFT[4]
            assert(top>149+tracker.objectiveCard:GetHeight() and top+button:GetHeight()<=size[2]-56)
        end
    end
end

-- The ordinary event dispatcher must queue an in-place refresh, not depend on advancement.
ns.state.loaded=true
assert(loadfile("shared/core/Bootstrap.lua"))("WayForth",ns)
local events=frames[#frames]
assert(events.events.QUEST_WATCH_UPDATE and events.events.QUEST_DATA_LOAD_RESULT and events.events.BAG_UPDATE_DELAYED)
events.scripts.OnEvent(events,"QUEST_LOG_UPDATE")
assert(tracker.objectiveDirty)
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
active[10]=nil
guides:RecordQuestEvent("QUEST_REMOVED",10)
events.scripts.OnEvent(events,"QUEST_REMOVED",10)
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
assert(tracker.liveSnapshot.state=="inactive" and not tracker.liveRows[1]:IsShown(),
    "Abandoning a quest must clear old objective counters")
ns.state.acceptedQuestIDs=nil
local saved=guides:GetProgress()
saved.awaitingQuestMatch=true
tracker:Refresh()
assert(not tracker.liveSnapshot and not tracker.liveScroll:IsShown(), "Recovery warnings must not show stale objectives")
saved.awaitingQuestMatch=nil
tracker:Hide()
tracker:RequestObjectiveRefresh()
assert(not tracker.objectiveDirty)
active[10]=true
objectives[10]={{text="New progress",numFulfilled=1,numRequired=3,finished=false}}
tracker:Show()
assert(tracker.liveRows[1].text:find("1/3",1,true), "Reopening must read fresh progress")
ns.char.trackerMinimized=true
tracker:RequestObjectiveRefresh()
assert(not tracker.objectiveDirty)
ns.char.trackerMinimized=false
active[20]=true
objectives[20]={{text="Second quest items",numFulfilled=1,numRequired=7,finished=false}}
guides:SetActive("second")
tracker:Refresh()
assert(tracker.liveSnapshot.questID==20 and tracker.liveRows[1].text:find("1/7",1,true))
assert(not tracker.liveRows[2]:IsShown() and tracker.liveScroll:GetVerticalScroll()==0,
    "Guide switches must clear the previous quest's rows and scroll position")
settings.guidePaused=true
ready[20]=true
events.scripts.OnEvent(events,"QUEST_WATCH_UPDATE",20)
tracker.frame.scripts.OnUpdate(tracker.frame,0.11)
assert(guides:CurrentStep().action=="objective" and tracker.liveSnapshot.ready,
    "Paused guides still show fresh counters without advancing")
settings.guidePaused=false
events.scripts.OnEvent(events,"QUEST_WATCH_UPDATE",20)
assert(guides:CurrentStep().action=="turnin")
guides:Reset("second")
settings.autoAdvance=false
guides:SetCurrent(2)
tracker:Refresh()
assert(guides:CurrentStep().action=="objective" and tracker.liveSnapshot.ready,
    "Live tracking must respect the Auto Advance setting")
print("WayForth live objective counters, layout and event refresh passed")
