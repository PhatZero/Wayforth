-- WayForth tracker: one movable/resizable in-game step window, no extra dialogs.
local _, ns = ...
local Tracker = ns.Modules.Tracker or {}
ns:RegisterModule("Tracker", Tracker)
local theme = ns.Modules.Theme
local db = ns.Modules.Database
local function pref(key, fallback)
    local v = db:Get(key)
    if v == nil then return fallback end
    return v
end
local function label(parent, text, size, color, x, y, width)
    local l = theme:Text(parent, text, size, color)
    l:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    l:SetWidth(width)
    l:SetWordWrap(true)
    return l
end
local function navigate(index, pinned)
    local ok, message = ns.Modules.Navigator:SetOverride(index, pinned)
    if not ok or (message and message:find("No verified waypoint", 1, true)) then
        ns:Print(message or "No navigation target available")
    end
    Tracker:Refresh()
end
local function stepComplete(step, index, saved)
    return saved and saved.completed and saved.completed[step.id or index]
end
local function textHeight(font, minimum)
    local height = font.GetStringHeight and font:GetStringHeight() or minimum
    return math.max(minimum, height or minimum)
end

function Tracker:MakeFrame()
    if self.frame then return end
    local panel = CreateFrame("Frame", "WayForthGuideTracker", UIParent)
    panel:SetSize(pref("trackerWidth", 380), pref("trackerHeight", 448))
    panel:SetFrameStrata("HIGH")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:EnableMouse(true)
    if panel.SetResizeBounds then panel:SetResizeBounds(370, 440, 700, 850)
    elseif panel.SetMinResize then panel:SetMinResize(370, 440) end
    panel:SetScale(pref("trackerScale", 1))
    panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", pref("trackerX",-30), pref("trackerY",-235))
    self.bg = theme:Panel(panel, theme.navy, theme.gold)
    self.frame = panel

    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
    header:SetHeight(48)
    theme:Panel(header, theme.panel)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not pref("trackerLocked", false) then panel:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local right, top = UIParent:GetRight(), UIParent:GetTop()
        local x, y = panel:GetRight(), panel:GetTop()
        if right and x then db:Set("trackerX", x-right) end
        if top and y then db:Set("trackerY", y-top) end
    end)
    self.header = header

    local compass = theme:Compass(header, 31)
    compass:SetPoint("LEFT",header,"LEFT",10,0)
    local title = theme:Text(header, "WAYFORTH", 18, theme.gold)
    title:SetPoint("TOPLEFT",header,"TOPLEFT",49,-7)
    local caption = theme:Text(header, "GUIDE TRACKER", 9, theme.teal)
    caption:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-1)
    self.brandTitle = title
    self.brandCaption = caption
    title:SetWidth(190)

    local settings = theme:Button(header,34,25,"",function()
        ns.Modules.UI:Show()
        ns.Modules.UI.settingsSection="Display"
        ns.Modules.UI:ShowTab("Settings")
    end,"quiet")
    settings:SetPoint("TOPRIGHT",header,"TOPRIGHT",-70,-11)
    local gear = theme:Gear(settings,19)
    gear:SetPoint("CENTER",settings,"CENTER")
    local minimize = theme:Button(header,25,25,"-",function() Tracker:ToggleMinimize() end,"quiet")
    minimize:SetPoint("TOPRIGHT",header,"TOPRIGHT",-39,-11)
    self.minimizeButton = minimize
    local close = theme:Button(header,25,25,"X",function() Tracker:Hide() end,"quiet")
    close:SetPoint("TOPRIGHT",header,"TOPRIGHT",-8,-11)

    local summary = CreateFrame("Frame",nil,panel)
    summary:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-55)
    summary:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-9,-55)
    summary:SetHeight(84)
    self.summaryBg = theme:Panel(summary,theme.panelLight)
    self.summary = summary

    local guideIcon = summary:CreateTexture(nil,"ARTWORK")
    guideIcon:SetTexture(theme.artAtlas)
    guideIcon:SetTexCoord(theme:ArtCoords(1))
    guideIcon:SetSize(53,53)
    guideIcon:SetPoint("TOPLEFT",summary,"TOPLEFT",9,-12)
    self.guideIcon = guideIcon
    self.guideTitle = label(summary,"No guide selected",12,theme.ivory,72,10,270)
    self.stepCount = label(summary,"",10,theme.teal,72,35,260)
    local progressBg = summary:CreateTexture(nil,"BACKGROUND")
    progressBg:SetColorTexture(.18,.26,.31,1)
    progressBg:SetPoint("BOTTOMLEFT",summary,"BOTTOMLEFT",72,11)
    progressBg:SetPoint("BOTTOMRIGHT",summary,"BOTTOMRIGHT",-13,11)
    progressBg:SetHeight(5)
    self.progressBg = progressBg
    local progress = summary:CreateTexture(nil,"ARTWORK")
    progress:SetColorTexture(unpack(theme.teal))
    progress:SetPoint("LEFT",progressBg,"LEFT")
    progress:SetWidth(1)
    progress:SetHeight(5)
    self.progressBar=progress
    local selectButton = CreateFrame("Button",nil,summary)
    selectButton:SetAllPoints(summary)
    selectButton:SetScript("OnClick",function() Tracker:ToggleGuidePicker() end)

    local objective = CreateFrame("Frame",nil,panel)
    objective:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-149)
    objective:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-9,-149)
    objective:SetHeight(138)
    self.objectiveBg=theme:Panel(objective,theme.panelLight,theme.gold)
    -- Narrow cyan accent makes the active objective unmistakable without
    -- another window, texture asset, or distracting animation.
    local accent = objective:CreateTexture(nil,"ARTWORK")
    accent:SetColorTexture(unpack(theme.teal))
    accent:SetPoint("TOPLEFT",objective,"TOPLEFT",2,-2)
    accent:SetPoint("BOTTOMLEFT",objective,"BOTTOMLEFT",2,2)
    accent:SetWidth(3)
    self.objectiveCard=objective
    self.objectiveCaption=label(objective,"CURRENT OBJECTIVE",9,theme.teal,12,10,290)
    self.stepTitle=label(objective,"",14,theme.gold,12,29,320)
    self.objectiveText=label(objective,"",11,theme.ivory,12,60,330)
    self.location=label(objective,"",10,theme.teal,12,112,335)
    self.liveStatus=label(objective,"",9,theme.teal,12,96,330)
    self.liveScroll=CreateFrame("ScrollFrame",nil,objective)
    self.liveContent=CreateFrame("Frame",nil,self.liveScroll)
    self.liveContent:SetSize(330,1)
    self.liveScroll:SetScrollChild(self.liveContent)
    self.liveScroll:EnableMouseWheel(true)
    self.liveScroll:EnableMouse(true)
    self.liveScroll:SetScript("OnMouseWheel",function(scroll,delta)
        local maximum=math.max(0,(Tracker.liveContentHeight or 0)-scroll:GetHeight())
        scroll:SetVerticalScroll(math.max(0,math.min(maximum,scroll:GetVerticalScroll()-delta*24)))
    end)
    self.liveRows={}
    self.liveStatus:Hide()
    self.liveScroll:Hide()
    objective:EnableMouse(true)
    local function tooltip() Tracker:ShowObjectiveTooltip() end
    local function hideTooltip()
        if GameTooltip and GameTooltip:IsOwned(objective) then GameTooltip:Hide() end
    end
    objective:SetScript("OnEnter",tooltip)
    objective:SetScript("OnLeave",hideTooltip)
    self.liveScroll:SetScript("OnEnter",tooltip)
    self.liveScroll:SetScript("OnLeave",hideTooltip)
    self.pinButton=theme:Button(objective,75,24,"MAP PIN",function()
        local nav=ns.Modules.Navigator
        local selected=nav and nav.overrideIndex
        local ok,message=ns.Modules.Guides:PinCurrent(selected)
        if message then ns:Print(message) end
        if ok then
            local shown, reason=nav:ShowMapPin()
            if not shown and reason then ns:Print(reason) end
        end
        Tracker:Refresh()
    end,"quiet")
    self.pinButton:SetPoint("TOPRIGHT",objective,"TOPRIGHT",-9,-6)

    self.upcomingTitle=label(panel,"UPCOMING STEPS",11,theme.teal,15,300,200)
    self.upcomingPage=1
    self.pageButton=theme:Button(panel,94,24,"MORE  >",function()
        Tracker.upcomingPage=(Tracker.upcomingPage or 1)+1
        if Tracker.upcomingPage>(Tracker.upcomingPageCount or 1) then
            Tracker.upcomingPage=1
        end
        Tracker:Refresh()
    end,"quiet")
    self.pageButton:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-15,-294)
    self.upcomingButtons={}
    for i=1,6 do
        local idx=i
        local button=theme:Button(panel,350,29,"",function()
            if Tracker.upcomingActions and Tracker.upcomingActions[idx] then
                Tracker.upcomingActions[idx]()
            elseif Tracker.upcomingIndices and Tracker.upcomingIndices[idx] then
                navigate(Tracker.upcomingIndices[idx],false)
            end
        end,"quiet")
        button:SetPoint("TOPLEFT",panel,"TOPLEFT",15,-(323+(i-1)*33))
        self.upcomingButtons[i]=button
    end

    local control = CreateFrame("Frame",nil,panel)
    control:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",10,9)
    control:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-10,9)
    control:SetHeight(37)
    self.controls=control
    self.prev=theme:Button(control,97,34,"Previous",function()
        local g=ns.Modules.Guides
        local p=g:GetProgress()
        if p then
            local nav=ns.Modules.Navigator
            g:SetCurrent(((nav and nav.overrideIndex) or p.current)-1)
        end
        ns:Call("Navigator","ResetTarget")
        Tracker:Refresh()
    end)
    self.prev:SetPoint("LEFT",control,"LEFT",0,0)
    self.next=theme:Button(control,97,34,"Next Step",function()
        local travel=ns.Modules.Travel
        if travel and travel:Current(Tracker.displayStep) then
            local _,message=travel:Next()
            if message then ns:Print(message) end
            Tracker:Refresh()
            return
        end
        local g=ns.Modules.Guides
        local p=g:GetProgress()
        if p then
            local nav=ns.Modules.Navigator
            local index=(nav and nav.overrideIndex) or p.current
            local current=g:GetSteps()[index]
            if current and current.action=="manual" then
                g:SetCurrent(index)
                g:CompleteCurrent()
            else g:SetCurrent(index+1) end
        end
        ns:Call("Navigator","ResetTarget")
        Tracker:Refresh()
    end,"primary")
    self.next:SetPoint("CENTER",control,"CENTER",-7,0)
    self.skip=theme:Button(control,83,34,"Skip",function()
        local guides = ns.Modules.Guides
        local navigator = ns.Modules.Navigator
        -- A clicked nearby step is the visible objective. Never silently
        -- skip the hidden underlying route step instead.
        if navigator and navigator.overrideIndex then
            guides:SetCurrent(navigator.overrideIndex)
        end
        guides:SkipCurrent()
        ns:Call("Navigator","ResetTarget")
        Tracker:Refresh()
    end)
    self.skip:SetPoint("RIGHT",control,"RIGHT",-42,0)
    self.moreButton=theme:Button(control,34,34,"...",function() Tracker:ToggleMenu() end,"quiet")
    self.moreButton:SetPoint("RIGHT",control,"RIGHT",0,0)

    local menu=CreateFrame("Frame",nil,panel)
    menu:SetFrameLevel(panel:GetFrameLevel()+12)
    menu:SetSize(236,421)
    menu:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-7,53)
    theme:Panel(menu,theme.panel,theme.gold)
    menu:Hide()
    self.menu=menu
    self.menuButtons={}
    local entries={
        {"Pause Guide","guidePaused"},
        {"Auto Advance","autoAdvance"},
        {"Show Arrow","showArrow"},
    }
    for i,entry in ipairs(entries) do
        local key=entry[2]
        local item=theme:Button(menu,216,29,"",function()
            db:Set(key,not pref(key,false))
            if key=="guidePaused" then ns:Call("UI","RefreshFooter") end
            if key=="showArrow" then ns:Call("Navigator","UpdateDirection") end
            Tracker:Refresh()
        end,"quiet")
        item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-10-(i-1)*35)
        self.menuButtons[key]=item
    end
    local entries2={
        {"Quest not offered",function() Tracker.menu:Hide();ns.Modules.UI:ShowTab("Quest Recovery");ns.Modules.UI:Show() end},
        {"Travel directions",function() Tracker.menu:Hide();ns.Modules.UI:ShowTab("Travel Directions");ns.Modules.UI:Show() end},
        {"Report a Bug",function() ns.Modules.Diagnostics:ShowBugReport() end},
        {"Sync Guide Now",function()
            local _,report=ns.Modules.Guides:Sync(nil,true)
            local saved=ns.Modules.Guides:GetProgress()
            if saved and saved.awaitingQuestMatch then
                report="A quest prerequisite cannot be routed safely: " .. tostring(saved.recoveryReason or "Unknown pickup.")
            end
            ns:Print(report or "Sync attempted")
            Tracker:Refresh()
        end},
        {"Reset Target",function() ns:Call("Navigator","ResetTarget");Tracker:Refresh() end},
        {"Undo Skip",function() ns.Modules.Guides:UndoSkip();Tracker:Refresh() end},
        {"Guide Library",function()
            Tracker.menu:Hide()
            ns.Modules.UI:Show()
            ns.Modules.UI:ShowTab("Guide Library")
        end},
        {"All Settings",function()
            Tracker.menu:Hide()
            ns.Modules.UI:Show()
            ns.Modules.UI:ShowTab("Settings")
        end},
    }
    for i,entry in ipairs(entries2) do
        local item=theme:Button(menu,216,29,entry[1],function()
            local action=entry[2]
            local ok,err=pcall(action)
            if not ok and ns.Modules.Diagnostics then ns.Modules.Diagnostics:Error("Tracker utility",err) end
        end,"quiet")
        item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-116-(i-1)*35)
    end

    local picker=CreateFrame("Frame",nil,panel)
    picker:SetFrameLevel(panel:GetFrameLevel()+14)
    picker:SetPoint("TOPLEFT",summary,"BOTTOMLEFT",0,3)
    picker:SetPoint("TOPRIGHT",summary,"BOTTOMRIGHT",0,3)
    picker:SetHeight(160)
    theme:Panel(picker,theme.panel,theme.gold)
    picker:Hide()
    self.picker=picker
    self.pickerButtons={}
    for i=1,4 do
        local idx=i
        local button=theme:Button(picker,300,32,"",function()
            local id=Tracker.pickerIds[idx]
            if id then
                local UI=ns.Modules.UI
                UI.selectedGuideId=id
                UI:Show()
                UI:ShowTab("Guide Details")
                picker:Hide()
            else
                ns.Modules.UI:Show()
                ns.Modules.UI:ShowTab("Guide Library")
                picker:Hide()
            end
        end,"quiet")
        button:SetPoint("TOPLEFT",picker,"TOPLEFT",9,-8-(i-1)*37)
        self.pickerButtons[i]=button
    end

    local grip=theme:Button(panel,13,12,"/",nil,"quiet")
    grip:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-1,1)
    grip:SetScript("OnMouseDown",function()
        if not pref("trackerLocked",false) and not ns.char.trackerMinimized then
            panel:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp",function()
        panel:StopMovingOrSizing()
        if not ns.char.trackerMinimized then
            db:Set("trackerWidth",math.floor(panel:GetWidth()+0.5))
            db:Set("trackerHeight",math.floor(panel:GetHeight()+0.5))
        end
        Tracker:Layout()
    end)

    panel:SetScript("OnSizeChanged",function() Tracker:Layout() end)
    panel:SetScript("OnHide",function() ns:Call("QuestItemButton","Refresh",Tracker) end)
    panel:SetScript("OnUpdate",function(_,elapsed)
        if not Tracker.objectiveDirty then return end
        Tracker.objectiveElapsed=(Tracker.objectiveElapsed or 0)+elapsed
        if Tracker.objectiveElapsed >= 0.1 then Tracker:RefreshObjectives() end
    end)
    panel:Hide()
    self:ApplyOpacity()
    self:Layout()
end

function Tracker:ShowObjectiveTooltip()
    if not GameTooltip or not self.displayStep then return end
    GameTooltip:SetOwner(self.objectiveCard,"ANCHOR_LEFT")
    GameTooltip:SetText(self.displayStep.title or "Quest objective",unpack(theme.gold))
    GameTooltip:AddLine(self.displayStep.text or "",theme.ivory[1],theme.ivory[2],theme.ivory[3],true)
    local routes=ns.Modules.SmartRoutes
    local blocked=routes and routes.BlockedReason and routes:BlockedReason(self.displayStep,ns.Modules.Guides:GetSteps())
    if blocked then GameTooltip:AddLine(blocked,1,0.74,0.37,true) end
    if self.liveSnapshot then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(self.liveSnapshot.status,theme.teal[1],theme.teal[2],theme.teal[3],true)
        for _,row in ipairs(self.liveSnapshot.rows) do
            local color=row.finished and theme.green or theme.ivory
            GameTooltip:AddLine((row.finished and "[x] " or "[ ] ")..row.display,color[1],color[2],color[3],true)
        end
    end
    GameTooltip:Show()
end

-- Counter-only events do not need to rebuild the guide library or reroute it.
-- The visible tracker coalesces event bursts, and reads fresh data on reopening.
function Tracker:RequestObjectiveRefresh(questID)
    if not self.frame or not self.frame:IsShown() or not self.displayStep
        or ns.char and ns.char.trackerMinimized then return end
    if questID and questID ~= self.displayStep.questId then return end
    if not self.objectiveDirty then self.objectiveElapsed=0 end
    self.objectiveDirty=true
end

function Tracker:RefreshObjectives(fromRefresh)
    self.objectiveDirty,self.objectiveElapsed=false,0
    local guides=ns.Modules.Guides
    local step=self.displayStep
    if not fromRefresh then
        local current,index=guides:CurrentStep()
        local nav=ns.Modules.Navigator
        if nav and nav.overrideIndex then
            index=nav.overrideIndex
            current=guides:GetSteps()[index]
        end
        if not step or not current or index~=self.displayIndex or current.questId~=step.questId
            or current.id~=step.id or current.action~=step.action then
            self:Refresh()
            return
        end
    end
    local progress=ns.Modules.QuestProgress
    local snapshot=step and progress and progress:Get(step.questId) or nil
    if ns.Modules.Travel and ns.Modules.Travel:Current(step) then snapshot=nil end
    if snapshot and snapshot.state=="inactive" and step.action=="accept" then snapshot=nil end
    if snapshot and snapshot.ready and step.action=="objective" and not fromRefresh then
        local changed=guides:Sync()
        if changed then self:Refresh();return end
    end
    if not snapshot or not self.liveSnapshot or snapshot.questID~=self.liveSnapshot.questID then
        self.liveScroll:SetVerticalScroll(0)
    end
    self.liveSnapshot=snapshot
    if not fromRefresh then self:Layout() end
end

function Tracker:LayoutObjectives(width,height)
    local contentW=math.max(240,width-45)
    local snapshot=self.liveSnapshot
    if self.stepTitle.SetMaxLines then self.stepTitle:SetMaxLines(2) end
    self.stepTitle:SetHeight(0)
    local titleH=textHeight(self.stepTitle,18)
    self.stepTitle:SetHeight(titleH)
    local descriptionY=29+titleH+8
    self.objectiveText:ClearAllPoints()
    self.objectiveText:SetPoint("TOPLEFT",self.objectiveCard,"TOPLEFT",12,-descriptionY)
    if self.objectiveText.SetMaxLines then self.objectiveText:SetMaxLines(snapshot and 2 or 4) end
    self.objectiveText:SetHeight(0)
    local descriptionH=math.min(textHeight(self.objectiveText,0),snapshot and 32 or 52)
    self.objectiveText:SetHeight(descriptionH)
    self.location:SetHeight(0)
    local locationH=textHeight(self.location,14)
    self.location:SetHeight(locationH)
    self.location:ClearAllPoints()
    self.location:SetPoint("BOTTOMLEFT",self.objectiveCard,"BOTTOMLEFT",12,10)

    local statusY=descriptionY+descriptionH+9
    local rowsY=statusY+17
    local rowsH=0
    for i,row in ipairs(snapshot and snapshot.rows or {}) do
        local line=self.liveRows[i]
        if not line then
            line=label(self.liveContent,"",11,theme.ivory,0,0,contentW)
            self.liveRows[i]=line
        end
        line:SetWidth(contentW)
        line:SetHeight(0)
        line:SetText((row.finished and "[x] " or "[ ] ")..row.display)
        line:SetTextColor(unpack(row.finished and theme.green or theme.ivory))
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT",self.liveContent,"TOPLEFT",0,-rowsH)
        local lineH=textHeight(line,15)
        line:SetHeight(lineH)
        line:Show()
        rowsH=rowsH+lineH+4
    end
    for i=(snapshot and #snapshot.rows or 0)+1,#self.liveRows do self.liveRows[i]:Hide() end
    rowsH=math.max(0,rowsH-4)
    self.liveContentHeight=rowsH
    local viewport=math.min(rowsH,math.max(52,math.min(120,height-360)))
    local desired=snapshot and rowsY+viewport+locationH+20 or descriptionY+descriptionH+locationH+20
    local cardH=math.min(math.max(138,desired),math.max(138,height-149-112))
    self.objectiveCard:SetHeight(cardH)
    viewport=math.max(0,math.min(viewport,cardH-rowsY-locationH-20))
    if snapshot then
        self.liveStatus:ClearAllPoints()
        self.liveStatus:SetPoint("TOPLEFT",self.objectiveCard,"TOPLEFT",12,-statusY)
        self.liveStatus:SetWidth(contentW)
        if self.liveStatus.SetMaxLines then self.liveStatus:SetMaxLines(1) end
        self.liveStatus:SetText(snapshot.status..(rowsH>viewport+1 and "  (scroll)" or ""))
        local color=(snapshot.state=="ready" or snapshot.state=="turnedIn") and theme.green or theme.teal
        self.liveStatus:SetTextColor(unpack(color))
        self.liveStatus:Show()
    else self.liveStatus:Hide() end
    if rowsH>0 and viewport>0 then
        self.liveScroll:ClearAllPoints()
        self.liveScroll:SetPoint("TOPLEFT",self.objectiveCard,"TOPLEFT",12,-rowsY)
        self.liveScroll:SetSize(contentW,viewport)
        self.liveContent:SetSize(contentW,math.max(1,rowsH))
        self.liveScroll:SetVerticalScroll(math.min(self.liveScroll:GetVerticalScroll(),math.max(0,rowsH-viewport)))
        self.liveScroll:Show()
    else self.liveScroll:Hide() end
    return cardH
end

function Tracker:ApplyOpacity()
    if not self.frame then return end
    local alpha=pref("guideOpacity",0.98)
    self.bg:SetColorTexture(theme.navy[1],theme.navy[2],theme.navy[3],alpha)
    if self.objectiveBg then
        self.objectiveBg:SetColorTexture(theme.panelLight[1],theme.panelLight[2],theme.panelLight[3],alpha)
    end
    if self.summaryBg then
        self.summaryBg:SetColorTexture(theme.panelLight[1],theme.panelLight[2],theme.panelLight[3],alpha)
    end
end

function Tracker:Layout()
    if not self.frame or not self.summary then return end
    local width,height=self.frame:GetWidth(),self.frame:GetHeight()
    if width <= 0 or height <= 0 then return end
    local contentW=math.max(240,width-45)
    local _,hasItem=ns:Call("QuestItemButton","Refresh",self)
    self.guideTitle:SetWidth(contentW-46)
    self.stepCount:SetWidth(contentW-40)
    -- Keep the title/caption clear of the quest-item and PIN controls.
    self.stepTitle:SetWidth(math.max(170,contentW-(hasItem and 135 or 89)))
    self.objectiveCaption:SetWidth(math.max(170,contentW-(hasItem and 135 or 89)))
    self.objectiveText:SetWidth(contentW)
    self.location:SetWidth(contentW)
    self.progressBar:SetWidth(math.max(1,(width-111)*(self.progressFraction or 0)))
    local cardH=self:LayoutObjectives(width,height)
    local upcomingY=149+cardH+12
    self.upcomingTitle:ClearAllPoints()
    self.upcomingTitle:SetPoint("TOPLEFT",self.frame,"TOPLEFT",15,-upcomingY)
    local visible=math.max(0,math.min(6,math.floor((height-56-(upcomingY+23)+4)/33)))
    local entries=self.upcomingEntries or {}
    self.upcomingPageCount=math.max(1,math.ceil(#entries/math.max(1,visible)))
    self.upcomingPage=math.max(1,math.min(self.upcomingPage or 1,self.upcomingPageCount))
    self.upcomingIndices={}
    self.upcomingActions={}
    for i,button in ipairs(self.upcomingButtons or {}) do
        local entry=i<=visible and entries[(self.upcomingPage-1)*visible+i]
        if entry then
            self.upcomingIndices[i]=entry.index
            self.upcomingActions[i]=entry.action
            button:SetLabel(tostring(entry.label):sub(1,51))
        end
    end
    if self.pageButton then
        self.pageButton:ClearAllPoints()
        self.pageButton:SetPoint("TOPRIGHT",self.frame,"TOPRIGHT",-15,-upcomingY+6)
        self.pageButton:SetLabel(self.upcomingPage.."/"..self.upcomingPageCount.."  >")
        if visible>0 and self.upcomingPageCount>1 then self.pageButton:Show() else self.pageButton:Hide() end
    end
    for i,button in ipairs(self.upcomingButtons or {}) do
        button:SetWidth(width-30)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT",self.frame,"TOPLEFT",15,-(upcomingY+23+(i-1)*33))
        if self.upcomingIndices and self.upcomingIndices[i]
            and i <= visible
            and not (ns.char and ns.char.trackerMinimized) then
            button:Show()
        else button:Hide() end
    end
    if ns.char.trackerMinimized then
        self.summary:Hide()
        self.objectiveCard:Hide()
        self.upcomingTitle:Hide()
        if self.pageButton then self.pageButton:Hide() end
        self.controls:Hide()
        if self.menu then self.menu:Hide() end
        if self.picker then self.picker:Hide() end
    else
        self.summary:Show()
        self.objectiveCard:Show()
        if visible>0 and self.upcomingIndices and self.upcomingIndices[1] then self.upcomingTitle:Show()
        else self.upcomingTitle:Hide() end
        self.controls:Show()
    end
    ns:Call("QuestItemButton","Position")
end

function Tracker:ToggleMinimize()
    if not self.frame then return end
    local minimized=not (ns.char and ns.char.trackerMinimized)
    if ns.char then ns.char.trackerMinimized=minimized end
    self.frame:SetHeight(minimized and 50 or pref("trackerHeight",448))
    self.minimizeButton:SetLabel(minimized and "+" or "-")
    self:Refresh()
    self:Layout()
    if minimized then
        self.header:Show()
    end
end

function Tracker:ToggleMenu()
    if not self.menu then return end
    if self.menu:IsShown() then self.menu:Hide()
    else
        if self.picker then self.picker:Hide() end
        self.menu:Show()
    end
end
function Tracker:ToggleGuidePicker()
    if not self.picker then return end
    if self.picker:IsShown() then self.picker:Hide();return end
    if self.menu then self.menu:Hide() end
    self.pickerIds={}
    local all=ns.char and ns.char.recentGuides or {}
    for i=1,3 do
        local id=all[i]
        if id and ns.Modules.Guides:GetGuide(id).id==id then
            self.pickerIds[i]=id
            self.pickerButtons[i]:SetLabel(ns.Modules.Guides:GetGuide(id).title:sub(1,40))
        else
            self.pickerIds[i]=nil
            self.pickerButtons[i]:SetLabel("Choose another guide")
        end
        self.pickerButtons[i]:SetWidth(self.frame:GetWidth()-40)
    end
    self.pickerButtons[4]:SetLabel("Browse All Guides")
    self.pickerButtons[4]:SetWidth(self.frame:GetWidth()-40)
    self.picker:Show()
end

function Tracker:Refresh()
    if not self.frame then return end
    local guides=ns.Modules.Guides
    guides:Sync()
    local g=guides:GetGuide()
    local step,index,total=guides:CurrentStep()
    if not g or not step or not total or total==0 then
        self.displayStep,self.liveSnapshot=nil,nil
        self.upcomingIndices={}
        self.stepTitle:SetText("No guide selected")
        self.objectiveText:SetText("Choose a guide from the Guide Library.")
        self.location:SetText("")
        self:Layout()
        return
    end
    local saved=guides:GetProgress()
    local routeIndex=index
    local count=0
    local steps=guides:GetSteps()
    local navigator=ns.Modules.Navigator
    local focus=navigator and navigator.overrideIndex
    if focus and steps[focus] and not stepComplete(steps[focus],focus,saved) then
        step,index=steps[focus],focus
    else
        focus=nil
    end
    for i,s in ipairs(steps) do if stepComplete(s,i,saved) then count=count+1 end end
    self.progressFraction=count/total
    self.guideTitle:SetText(g.title or "Active guide")
    if self.guideIcon then
        local illustration = (g.id == "zephras-alliance" or g.id == "zephras-horde") and 1 or 2
        self.guideIcon:SetTexture(theme.artAtlas)
        self.guideIcon:SetTexCoord(theme:ArtCoords(illustration))
    end
    if self.brandTitle and self.brandCaption then
        if ns.char and ns.char.trackerMinimized then
            self.brandTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
            self.brandTitle:SetText("WayForth: " .. tostring(g.zone or g.title or "Guide"):sub(1,18))
            self.brandCaption:SetText("Step " .. index .. " / " .. total)
        else
            self.brandTitle:SetFont("Fonts\\FRIZQT__.TTF", 18, "")
            self.brandTitle:SetText("WAYFORTH")
            self.brandCaption:SetText("GUIDE TRACKER")
        end
    end
    local progressText=math.floor(100*count/total) .. "% complete"
    self.stepCount:SetText(focus and ("Viewing " .. index .. " | Route " .. routeIndex .. "/" .. total .. " | " .. progressText)
        or ("Step " .. index .. " / " .. total .. "  |  " .. progressText))
    self.stepTitle:SetText(step.title or "Next objective")
    self.next:SetLabel(step.action=="manual" and "Done / Next" or "Next Step")
    local grouped=ns.Modules.SmartRoutes and ns.Modules.SmartRoutes:NearbyGroup(focus) or {}
    local actions={accept="PICK UP",objective="DO",turnin="TURN IN"}
    local counts={accept=0,objective=0,turnin=0}
    for _,entry in ipairs(grouped) do
        if entry.index ~= index and counts[entry.step.action] then
            counts[entry.step.action]=counts[entry.step.action]+1
        end
    end
    if focus then
        self.objectiveCaption:SetText(navigator.pinnedIndex and "PINNED SIDE OBJECTIVE" or "SELECTED SIDE OBJECTIVE")
    elseif #grouped>1 then
        local statuses={}
        if counts.turnin>0 then statuses[#statuses+1]=counts.turnin.." TURN-INS" end
        if counts.accept>0 then statuses[#statuses+1]=counts.accept.." PICKUPS" end
        if counts.objective>0 then statuses[#statuses+1]=counts.objective.." OBJECTIVES" end
        self.objectiveCaption:SetText("HUB SWEEP | "..table.concat(statuses," | "))
    else
        self.objectiveCaption:SetText(g.testingOnly and "TEST ROUTE - VERIFY QUEST" or "CURRENT OBJECTIVE")
    end
    self.objectiveCaption:SetTextColor(unpack(theme.teal))
    self.objectiveText:SetText(step.text or "")
    local place=step.hub or step.zone or g.zone or "Quest objective"
    local target
    if navigator and type(navigator.TargetForStep)=="function" then
        local ok,found=pcall(navigator.TargetForStep,navigator,step)
        if ok then target=found end
    end
    self.location:SetText(step.x and step.y and (place .. string.format("  (%.1f, %.1f)",step.x,step.y))
        or (target and place or (place .. " | No waypoint verified")))
    -- Combine all hub pickups, genuinely active parallel objectives and
    -- upcoming route steps. Page through them in the same compact tracker.
    local entries,shown={},{}
    local function append(candidate,label)
        if not candidate or not candidate.index or shown[candidate.index]
            or candidate.index==index or stepComplete(steps[candidate.index],candidate.index,saved) then return end
        if saved.skipped and saved.skipped[steps[candidate.index].id or candidate.index] then return end
        entries[#entries+1]={index=candidate.index,label=label}
        shown[candidate.index]=true
    end
    for _,item in ipairs(grouped) do
        local name=tostring(item.step.title or "Quest"):gsub("^Pick up:%s*","")
        append(item,(actions[item.step.action] or "VISIT").." | "..name)
    end
    local work=ns.Modules.SmartRoutes and ns.Modules.SmartRoutes:ConcurrentQuestSteps(30) or {}
    for _,item in ipairs(work) do
        append(item,item.action.." | "..tostring(item.step.title or "Quest"))
    end
    local fallback=0
    for i=routeIndex+1,#steps do
        if fallback>=12 then break end
        if not shown[i] and not stepComplete(steps[i],i,saved)
            and not (saved.skipped and saved.skipped[steps[i].id or i]) then
            append({index=i},tostring(i) .. ". "..tostring(steps[i].title or "Next step"))
            fallback=fallback+1
        end
    end
    local zones=ns.Modules.NextZone
    local options=zones and zones:Options() or {}
    for pos=#options,1,-1 do
        local option=options[pos]
        table.insert(entries,1,{index=0,label="NEXT ZONE | "..option.title,action=function()
            local ok,message=zones:Switch(option.id)
            if not ok then ns:Print(message) end
            Tracker:Refresh()
        end})
    end
    local signature={g.id,tostring(routeIndex),tostring(focus or 0)}
    for _,entry in ipairs(entries) do signature[#signature+1]=tostring(entry.index)..entry.label end
    local key=table.concat(signature,":")
    if self.upcomingSignature~=key then
        self.upcomingSignature=key
        self.upcomingPage=1
    end
    self.upcomingEntries=entries
    if #options>0 then
        self.upcomingTitle:SetText("SUGGESTED NEXT ZONES")
    elseif #entries>0 then
        self.upcomingTitle:SetText(#grouped>1 and "HUB & ACTIVE QUESTS"
            or (#work>0 and "ACTIVE QUESTS" or "UPCOMING STEPS"))
    else
        self.upcomingTitle:SetText("UPCOMING STEPS")
    end
    if self.pageButton then
        if self.upcomingPageCount>1 then
            self.pageButton:SetLabel(self.upcomingPage.."/"..self.upcomingPageCount.."  >")
            self.pageButton:Show()
        else self.pageButton:Hide() end
    end
    if saved.awaitingQuestMatch then
        -- The cached step remains saved, but is not presented as an available
        -- quest or navigable destination. This also prevents misleading pins
        -- in the upcoming list until the live quest log contains a match.
        self.objectiveCaption:SetText("QUEST CHAIN NEEDS REVIEW")
        self.objectiveCaption:SetTextColor(1,0.74,0.37,1)
        self.stepTitle:SetText("Prerequisite unavailable")
        self.objectiveText:SetText(saved.recoveryReason or "The next prerequisite needs additional quest data. Follow your quest log and retry Sync.")
        self.location:SetText("Use Sync after resolving this prerequisite | Progress preserved")
        self.upcomingEntries={}
        self.upcomingIndices={}
        for _,button in ipairs(self.upcomingButtons) do button:Hide() end
        if self.pageButton then self.pageButton:Hide() end
    end
    if not focus and not saved.awaitingQuestMatch and step.action == "accept"
        and saved.recoveryReason and saved.recoveryReason:find("Quest pickup needed", 1, true) then
        self.objectiveCaption:SetText("QUEST PICKUP REQUIRED")
    end
    local routes=ns.Modules.SmartRoutes
    local blocked=routes and routes.BlockedReason and routes:BlockedReason(step,steps)
    if blocked and not saved.awaitingQuestMatch then
        self.objectiveCaption:SetText("QUEST BLOCKED")
        self.objectiveCaption:SetTextColor(1,0.74,0.37,1)
        self.objectiveText:SetText(blocked)
    end
    if navigator and navigator.NavigationFeedback and not saved.awaitingQuestMatch then
        self.location:SetText(navigator:NavigationFeedback(step))
    end
    local travel=ns.Modules.Travel
    local leg=travel and travel:Current(step)
    if leg and not saved.awaitingQuestMatch then
        self.objectiveCaption:SetText("TRAVEL LEG "..travel.route.index.." / "..#travel.route.legs)
        self.objectiveText:SetText(leg.text)
        self.next:SetLabel("Next Travel")
    end
    for key,item in pairs(self.menuButtons) do
        local title=key=="guidePaused" and "Pause Guide" or key=="autoAdvance" and "Auto Advance" or "Show Arrow"
        item:SetLabel(title .. ": " .. (pref(key,false) and "ON" or "OFF"))
    end
    if self.minimizeButton then self.minimizeButton:SetLabel(ns.char and ns.char.trackerMinimized and "+" or "-") end
    self.displayStep=step
    if saved.awaitingQuestMatch then self.displayStep=nil end
    self.displayIndex=index
    self:RefreshObjectives(true)
    self:ApplyOpacity()
    self:Layout()
    ns:Call("Navigator","Refresh")
end

function Tracker:ResetPosition()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-30,-235)
    ns:Call("QuestItemButton","Position")
end
function Tracker:Show()
    self:MakeFrame()
    if ns.char then ns.char.trackerVisible=true end
    self.frame:Show()
    if ns.char and ns.char.trackerMinimized then
        self.frame:SetHeight(50)
    end
    self:Refresh()
    ns:Call("Navigator","Show")
end
function Tracker:Hide()
    if ns.char then ns.char.trackerVisible=false end
    if self.frame then self.frame:Hide() end
    ns:Call("QuestItemButton","Refresh",self)
    ns:Call("Navigator","Hide")
end
function Tracker:Initialize()
    self:MakeFrame()
    if ns.char and ns.char.trackerVisible==true then self:Show() end
end
