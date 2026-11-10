-- Run the real tracker and item module against strict secure-frame rules.
local inCombat = false
local secureCreated = 0
InCombatLockdown = function() return inCombat end
UseItemByName = function() error("Item use requires the native secure click") end
UseQuestLogSpecialItem = UseItemByName
SelectQuestLogEntry = function() error("Quest selection must remain unchanged") end
local frames = {}
local function widget(kind, parent, secure)
    local w = {kind=kind,parent=parent,secure=secure,shown=true,width=380,height=448,scale=1,
        scripts={},points={},attributes={},text="",fontSize=11,scroll=0}
    local function permitted(self)
        assert(not (self.secure and inCombat), "Protected frame mutation during combat")
    end
    for _,name in ipairs({"SetColorTexture","SetTextColor","SetJustifyH","SetJustifyV","SetShadowOffset",
        "SetShadowColor","SetTexCoord","SetFrameStrata","SetToplevel","SetClampedToScreen","SetMovable",
        "SetResizable","EnableMouse","EnableMouseWheel","SetResizeBounds","SetMinResize","RegisterForDrag",
        "SetHighlightTexture","StartMoving","StopMovingOrSizing","StartSizing","SetWordWrap"}) do
        w[name]=function() end
    end
    function w:SetAttribute(key,value) permitted(self);self.attributes[key]=value end
    function w:RegisterForClicks(...) permitted(self);self.clicks={...} end
    function w:SetScript(name,fn) self.scripts[name]=fn end
    function w:SetAllPoints() permitted(self) end
    function w:SetSize(width,height) permitted(self);self.width,self.height=width,height end
    function w:SetWidth(value) permitted(self);self.width=value end
    function w:SetHeight(value) permitted(self);self.height=value end
    function w:GetWidth() return self.width end
    function w:GetHeight() return self.height end
    function w:SetScale(value) permitted(self);self.scale=value end
    function w:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
    function w:GetRight() return self.right or (self.parent and self.parent:GetRight()) or 1000 end
    function w:GetTop() return self.top or (self.parent and self.parent:GetTop()) or 800 end
    function w:SetPoint(point,relative,relativePoint,x,y)
        permitted(self)
        if self.secure then assert(relative==UIParent, "Secure items must not anchor to the tracker") end
        self.points[point]={relative,relativePoint,x,y}
    end
    function w:ClearAllPoints() permitted(self);self.points={} end
    function w:SetText(value) self.text=value or "" end
    function w:SetTexture(value) self.texture=value end
    function w:SetFont(_,size) self.fontSize=size end
    function w:SetMaxLines(count) self.maxLines=count end
    function w:GetStringHeight()
        if self.text=="" then return 0 end
        return math.min(math.max(1,math.ceil(#self.text*self.fontSize*.52/math.max(1,self.width))),
            self.maxLines or 100)*self.fontSize*1.2
    end
    function w:Show()
        permitted(self)
        local changed=not self.shown;self.shown=true
        if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function w:Hide()
        permitted(self)
        local changed=self.shown;self.shown=false
        if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function w:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
    function w:GetFrameLevel() return self.level or 1 end
    function w:SetFrameLevel(value) permitted(self);self.level=value end
    function w:CreateFontString() return widget("FontString",self) end
    function w:CreateTexture() return widget("Texture",self) end
    function w:SetScrollChild(child) self.child=child end
    function w:SetVerticalScroll(value) self.scroll=value end
    function w:GetVerticalScroll() return self.scroll end
    function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
    function w:SetCooldown(start,duration) self.start,self.duration=start,duration end
    frames[#frames+1]=w
    return w
end
function CreateFrame(kind,name,parent,template)
    local secure=template=="SecureActionButtonTemplate"
    if secure then
        assert(not inCombat and parent==UIParent, "Secure creation must wait until after combat")
        secureCreated=secureCreated+1
    end
    return widget(kind,parent,secure)
end
UIParent=widget("Frame")
GameTooltip={}
function GameTooltip:SetOwner(owner) self.owner=owner;self.lines={} end
function GameTooltip:IsOwned(owner) return self.owner==owner end
function GameTooltip:SetText(value) self.text=value end
function GameTooltip:SetHyperlink(value) self.link=value end
function GameTooltip:AddLine(value) self.lines[#self.lines+1]=value end
function GameTooltip:Show() self.shown=true end
function GameTooltip:Hide() self.shown=false;self.owner=nil end

local ns={Modules={},state={},char={settings={}}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call(name,method,...)
    local module=self.Modules[name]
    if not module or not module[method] then return false end
    return true,module[method](module,...)
end
function ns:Print() end
local indexByID={[10]=7,[20]=9}
local infoByID={
    [10]={"|Hitem:100:0|h[Test Wand]|h",1000,3,false},
    [20]={"|Hitem:200:0|h[Second Wand]|h",2000,1,false},
}
local inventory={[100]=1,[200]=1}
local ready,failed={},{}
local cooldownStart,cooldownDuration=100,30
local function idAt(index)
    for id,value in pairs(indexByID) do if value==index then return id end end
end
C_QuestLog={
    GetLogIndexForQuestID=function(id) return indexByID[id] or 0 end,
    GetQuestIDForLogIndex=idAt,
    IsFailed=function(id) return failed[id] or false end,
    ReadyForTurnIn=function(id) return ready[id] or false end,
}
C_Item={GetItemCount=function(id,includeBank,includeUses)
    assert(includeBank==false and includeUses==false)
    return inventory[id] or 0
end}
GetQuestLogSpecialItemInfo=function(index)
    local info=infoByID[idAt(index)]
    if info then return unpack(info) end
end
GetQuestLogSpecialItemCooldown=function(index)
    assert(idAt(index), "Cooldowns must resolve the current exact quest index")
    return cooldownStart,cooldownDuration,1
end
assert(loadfile("shared/ui/Theme.lua"))("WayForth",ns)
assert(loadfile("shared/tracker/QuestItemButton.lua"))("WayForth",ns)
local item=ns.Modules.QuestItemButton
local step={id="work",action="objective",questId=10,title="Use the test wand",text="Use the wand on a target."}
local snapshot=item:Read(step)
assert(snapshot.itemID==100 and snapshot.count==3)
assert(item:Read({questId=10,action="accept"})==nil)
assert(item:Read({questId=-1,action="objective"})==nil)
inventory[100]=0
assert(item:Read(step)==nil, "Bank-only and consumed items must be hidden")
inventory[100]=1
ready[10]=true
assert(item:Read(step)==nil, "Honor the client's hide-on-completion flag")
infoByID[10][4]=true
assert(item:Read(step).itemID==100, "Some items remain usable on completed quests")
failed[10]=true
assert(item:Read(step)==nil)
failed[10],ready[10],infoByID[10][4]=nil,nil,false
local originalIndexAPI=C_QuestLog.GetLogIndexForQuestID
C_QuestLog.GetLogIndexForQuestID=function() return 0 end
GetQuestLogIndexByID=function(id) return indexByID[id] end
assert(item:Read(step).index==7, "Support the legacy exact-index fallback")
C_QuestLog.GetLogIndexForQuestID=originalIndexAPI
GetQuestLogIndexByID=nil
local realIdentity=C_QuestLog.GetQuestIDForLogIndex
C_QuestLog.GetQuestIDForLogIndex=function() return 20 end
assert(item:Read(step)==nil, "A mismatched log index must never expose another quest's item")
C_QuestLog.GetQuestIDForLogIndex=realIdentity
local hidden={}
issecretvalue=function(value) return value==hidden end
local originalLink=infoByID[10][1]
infoByID[10][1]=hidden
assert(item:Read(step)==nil, "Restricted links must not be parsed")
infoByID[10][1]=originalLink
infoByID[10][2]=hidden
assert(item:Read(step).texture=="Interface\\Icons\\INV_Misc_QuestionMark")
infoByID[10][2]=1000
issecretvalue=nil

local settings={}
ns.Modules.Database={Get=function(_,key) return settings[key] end,Set=function(_,key,value) settings[key]=value end}
ns.Modules.Navigator={Refresh=function() end,Show=function() end,Hide=function() end}
local saved={current=1,completed={},skipped={}}
local guide={id="test",title="Quest item test",steps={step},zone="Elwynn Forest"}
ns.Modules.Guides={Sync=function() return false end,GetGuide=function() return guide end,
    CurrentStep=function() return step,1,1 end,GetProgress=function() return saved end,
    GetSteps=function() return guide.steps end}
assert(loadfile("shared/tracker/Tracker.lua"))("WayForth",ns)
local tracker=ns.Modules.Tracker
inCombat=true
tracker:Show()
assert(not item.button and item.blocker:IsShown() and secureCreated==0,
    "Logging in during combat must defer protected-button creation")
inCombat=false
item.events.scripts.OnEvent(item.events,"PLAYER_REGEN_ENABLED")
assert(item.button:IsShown() and secureCreated==1 and not item.blocker:IsShown())
assert(item.button.attributes.type1=="item" and item.button.attributes.item1=="item:100")
assert(item.button.scripts.OnClick==nil, "Never replace the template's secure click handler")
assert(item.button.clicks[1]=="AnyUp" and item.button.clicks[2]=="AnyDown")
assert(item.button.attributes.useOnKeyDown==false, "Both click phases must still execute once, on release")
assert(item.count.text==3 and item.cooldown.start==100 and item.cooldown.duration==30)
assert(tracker.stepTitle:GetWidth()==tracker.frame:GetWidth()-145, "Reserve title space for the item icon")
item.button.scripts.OnEnter(item.button)
assert(GameTooltip.link==originalLink and GameTooltip.lines[1]=="Left-click to use.")
item.button.scripts.OnLeave(item.button)
assert(not GameTooltip.shown)

-- Reordering the quest log must not change the bound item or read the old slot.
indexByID[10]=12
cooldownStart,cooldownDuration=150,15
item.events.scripts.OnEvent(item.events,"BAG_UPDATE_COOLDOWN")
assert(item.cooldown.start==150 and item.cooldown.duration==15 and item.button.attributes.item1=="item:100")
cooldownDuration=0
item.events.scripts.OnEvent(item.events,"BAG_UPDATE_COOLDOWN")
assert(item.cooldown.duration==0, "A finished cooldown must clear its swipe")

inCombat=true
item:Refresh()
assert(not item.blocker:IsShown(), "The unchanged item remains usable during combat")
local realRight=tracker.objectiveCard.GetRight
tracker.objectiveCard.GetRight=function() return nil end
tracker:Hide()
assert(item.blocker:IsShown(), "Hidden-frame geometry must not prevent blocking the old action")
tracker:Show()
tracker.objectiveCard.GetRight=realRight
item:Position()
assert(not item.blocker:IsShown())
infoByID[10][3]=2
item.events.scripts.OnEvent(item.events,"BAG_UPDATE_DELAYED")
assert(item.count.text==2)
step.questId=20
tracker:Refresh()
assert(item.button.attributes.item1=="item:100" and item.blocker:IsShown(),
    "Switching quests in combat must block the old action without rebinding it")
item.blocker.scripts.OnEnter(item.blocker)
item.events.scripts.OnUpdate(item.events,.1)
assert(GameTooltip.shown and GameTooltip.owner==item.blocker, "The wait tooltip must survive position updates")
inCombat=false
item.events.scripts.OnEvent(item.events,"PLAYER_REGEN_ENABLED")
assert(item.button.attributes.item1=="item:200" and not item.blocker:IsShown())

-- Moving/scaling/hiding the tracker must not mutate its secure sibling in combat.
inCombat=true
local oldX=item.x
tracker.objectiveCard.right=1200
tracker.frame:SetScale(.8)
tracker:Layout()
item.events.scripts.OnUpdate(item.events,.1)
assert(item.x==oldX and item.blocker:IsShown())
tracker:ToggleMinimize()
assert(item.blocker:IsShown() and item.button:IsShown())
tracker:Hide()
assert(not tracker.frame:IsShown() and item.blocker:IsShown())
inCombat=false
item.events.scripts.OnEvent(item.events,"PLAYER_REGEN_ENABLED")
assert(not item.button:IsShown() and not item.blocker:IsShown() and not item.button.attributes.item1)
tracker:Show()
assert(not item.button:IsShown(), "A minimized tracker must keep its item hidden")
tracker:ToggleMinimize()
assert(item.button:IsShown() and item.scale==.8)

-- Consuming/abandoning a quest clears its action, including after combat.
inventory[200]=0
item.events.scripts.OnEvent(item.events,"BAG_UPDATE_DELAYED")
assert(not item.button:IsShown() and not item.button.attributes.type1)
assert(tracker.stepTitle:GetWidth()==tracker.frame:GetWidth()-99, "Restore title width when the item disappears")
inventory[200]=1
item.events.scripts.OnEvent(item.events,"GET_ITEM_INFO_RECEIVED")
assert(item.button:IsShown())
inCombat=true
indexByID[20]=nil
item.events.scripts.OnEvent(item.events,"QUEST_REMOVED")
assert(item.blocker:IsShown() and item.button.attributes.item1=="item:200")
inCombat=false
item.events.scripts.OnEvent(item.events,"PLAYER_REGEN_ENABLED")
assert(not item.button:IsShown() and not item.bound and not item.button.attributes.item1)
saved.awaitingQuestMatch=true
indexByID[20]=9
tracker:Refresh()
assert(not item.button:IsShown(), "Quest-chain recovery warnings must never show a stale item")
print("Quest item discovery, secure actions, combat deferral, tracker layout, tooltip and cooldown checks passed")
