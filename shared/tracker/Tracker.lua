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

local MAX_OPEN_TABS = 8
local MAX_VISIBLE_TABS = 5
local MIN_TAB_WIDTH = 160

local function visibleTabCount(width)
    -- Never squeeze fixed-width labels and their close buttons on narrow trackers.
    local available = math.max(0, width - 18 - 36 - 46)
    return math.max(2, math.min(MAX_VISIBLE_TABS, math.floor(available / MIN_TAB_WIDTH)))
end

-- Open tabs are presentation state only. The guide's completed steps and
-- profession craft counters remain in their existing per-character stores.
function Tracker:EnsureOpenTabs(activeId)
    if not ns.char then return {} end
    local previous=type(ns.char.trackerOpenTabs)=="table" and ns.char.trackerOpenTabs or {}
    local tabs,seen={},{}
    for _,id in ipairs(previous) do
        local guide=type(id)=="string" and ns.Modules.Guides:GetGuide(id)
        if guide and guide.id==id and not seen[id] then
            tabs[#tabs+1]=id
            seen[id]=true
        end
    end
    if activeId and not seen[activeId] then tabs[#tabs+1]=activeId end
    while #tabs>MAX_OPEN_TABS do table.remove(tabs,1) end
    ns.char.trackerOpenTabs=tabs
    return tabs
end

function Tracker:ActivateGuideTab(id)
    local guide=ns.Modules.Guides:GetGuide(id)
    if not guide or guide.id~=id then return end
    ns.Modules.Guides:SetActive(id)
    ns:Call("Navigator","ResetTarget")
    self.upcomingSignature=nil
    self:Refresh()
end

function Tracker:CloseGuideTab(id)
    if not ns.char then return end
    local tabs=self:EnsureOpenTabs(nil)
    local index
    for i,value in ipairs(tabs) do
        if value==id then index=i;break end
    end
    if not index then return end
    table.remove(tabs,index)
    ns.char.trackerOpenTabs=tabs
    local active=ns.Modules.Guides:GetGuide()
    if active and active.id==id then
        if #tabs==0 then self:Hide();return end
        self:ActivateGuideTab(tabs[math.min(index,#tabs)])
    else
        self:RefreshTabs()
    end
end

function Tracker:RefreshTabs()
    if not self.tabStrip then return end
    local active=ns.Modules.Guides:GetGuide()
    local activeId=active and active.id
    local tabs=self:EnsureOpenTabs(activeId)
    local count=#tabs
    local frameWidth=self.frame:GetWidth()
    local capacity=visibleTabCount(frameWidth)
    local visible=math.min(count,capacity)
    local overflow=count>capacity
    local maximumStart=math.max(1,count-capacity+1)
    local start=math.max(1,math.min(self.tabStart or 1,maximumStart))
    local current=1
    for i,id in ipairs(tabs) do if id==activeId then current=i;break end end
    local resized=self.tabLayoutWidth~=frameWidth or self.tabVisibleCount~=capacity
    -- Resizing or changing guides must reveal the active tab. Explicit paging
    -- stays in place across the ordinary objective/inventory refresh events.
    if resized or self.tabActiveId~=activeId then
        if current<start then start=current end
        if current>=start+capacity then start=current-capacity+1 end
        start=math.max(1,math.min(start,maximumStart))
    end
    self.tabActiveId=activeId
    self.tabLayoutWidth=frameWidth
    self.tabVisibleCount=capacity
    self.tabStart=start
    -- The + button stays anchored at right. Paging controls only occupy
    -- the left gutter when more guides exist than fit at this width.
    local available=math.max(0,frameWidth-18-36-(overflow and 46 or 0))
    local tabWidth=math.floor(available/math.max(1,visible))
    local baseX=overflow and 45 or 1
    for i,tab in ipairs(self.guideTabs or {}) do
        local id=i<=capacity and tabs[start+i-1] or nil
        tab.id=id
        if id then
            local guide=ns.Modules.Guides:GetGuide(id)
            local textWidth=math.max(22,tabWidth-37)
            local maxLetters=math.max(3,math.floor(textWidth/6))
            local title=tostring(guide.title or id)
            if #title>maxLetters then title=title:sub(1,math.max(1,maxLetters-2))..".." end
            tab.button:SetWidth(tabWidth-3)
            tab.button.label:SetWidth(textWidth)
            tab.button:SetLabel(title)
            tab.button.surface:SetColorTexture(unpack(id==activeId and theme.elevated or theme.panel))
            tab.button.label:SetTextColor(unpack(id==activeId and theme.teal or theme.ivory))
            tab.button:ClearAllPoints()
            tab.button:SetPoint("TOPLEFT",self.tabStrip,"TOPLEFT",baseX+(i-1)*tabWidth,-2)
            tab.button:Show()
        else tab.button:Hide() end
    end
    if overflow and start>1 then self.tabPrevious:Show() else self.tabPrevious:Hide() end
    if overflow and start+capacity-1<count then self.tabNext:Show() else self.tabNext:Hide() end
end
function Tracker:MakeFrame()
    if self.frame then return end
    local panel = CreateFrame("Frame", "WayForthGuideTracker", UIParent)
    panel:SetSize(math.max(500,pref("trackerWidth",620)), math.max(560,pref("trackerHeight",680)))
    panel:SetFrameStrata("HIGH")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:EnableMouse(true)
    if panel.SetResizeBounds then panel:SetResizeBounds(500, 560, 1000, 1050)
    elseif panel.SetMinResize then panel:SetMinResize(500, 560) end
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

    -- Reopen and close several guides without resetting their individual progress.
    local strip=CreateFrame("Frame",nil,panel)
    strip:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-54)
    strip:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-9,-54)
    strip:SetHeight(30)
    self.tabStrip=strip
    self.tabStart=1
    self.guideTabs={}
    for i=1,MAX_VISIBLE_TABS do
        local tab={}
        tab.button=theme:Button(strip,98,26,"",function()
            if tab.id then Tracker:ActivateGuideTab(tab.id) end
        end,"quiet")
        tab.button.label:ClearAllPoints()
        tab.button.label:SetPoint("CENTER",tab.button,"CENTER",-9,0)
        if tab.button.label.SetWordWrap then tab.button.label:SetWordWrap(false) end
        tab.close=theme:Button(tab.button,20,20,"X",function()
            if tab.id then Tracker:CloseGuideTab(tab.id) end
        end,"quiet")
        tab.close:SetPoint("RIGHT",tab.button,"RIGHT",-3,0)
        tab.close.label:SetTextColor(unpack(theme.muted))
        self.guideTabs[i]=tab
    end
    self.tabPrevious=theme:Button(strip,21,25,"<",function()
        Tracker.tabStart=math.max(1,(Tracker.tabStart or 1)-1)
        Tracker:RefreshTabs()
    end,"quiet")
    self.tabPrevious:SetPoint("TOPLEFT",strip,"TOPLEFT",0,-2)
    self.tabNext=theme:Button(strip,21,25,">",function()
        local tabs=Tracker:EnsureOpenTabs(nil)
        Tracker.tabStart=math.min(math.max(1,#tabs-(Tracker.tabVisibleCount or 2)+1),(Tracker.tabStart or 1)+1)
        Tracker:RefreshTabs()
    end,"quiet")
    self.tabNext:SetPoint("TOPLEFT",strip,"TOPLEFT",23,-2)
    self.tabAdd=theme:Button(strip,30,25,"+",function() Tracker:ToggleGuidePicker() end,"quiet")
    self.tabAdd:SetPoint("TOPRIGHT",strip,"TOPRIGHT",-1,-2)

    local summary = CreateFrame("Frame",nil,panel)
    summary:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-89)
    summary:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-9,-89)
    summary:SetHeight(52)
    self.summaryBg = theme:Panel(summary,theme.panelLight)
    self.summary = summary

    local guideIcon = summary:CreateTexture(nil,"ARTWORK")
    guideIcon:SetTexture(theme.artAtlas)
    guideIcon:SetTexCoord(theme:ArtCoords(1))
    guideIcon:SetSize(34,34)
    guideIcon:SetPoint("TOPLEFT",summary,"TOPLEFT",9,-8)
    self.guideIcon = guideIcon
    self.guideTitle = label(summary,"No guide selected",12,theme.ivory,52,5,270)
    self.stepCount = label(summary,"",10,theme.teal,52,21,260)
    local progressBg = summary:CreateTexture(nil,"BACKGROUND")
    progressBg:SetColorTexture(.18,.26,.31,1)
    progressBg:SetPoint("BOTTOMLEFT",summary,"BOTTOMLEFT",52,7)
    progressBg:SetPoint("BOTTOMRIGHT",summary,"BOTTOMRIGHT",-13,7)
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
    objective:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-151)
    objective:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-9,-151)
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

    -- Dedicated profession workspace: materials and crafting in the same tracker.
    local professionPanel=CreateFrame("Frame",nil,panel)
    professionPanel:SetPoint("TOPLEFT",panel,"TOPLEFT",9,-151)
    professionPanel:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-9,55)
    theme:Panel(professionPanel,theme.panelLight,theme.gold)
    self.professionPanel=professionPanel
    -- One full-width scrollable page at a time. The old half-width columns
    -- wrapped even short recipe names into unreadable multi-line fragments.
    self.professionView=ns.char and ns.char.professionView=="crafts" and "crafts" or "materials"
    self.materialsTab=theme:Button(professionPanel,150,28,"MATERIALS",function()
        Tracker.professionView="materials"
        if ns.char then ns.char.professionView="materials" end
        Tracker:RenderProfession()
    end,"quiet")
    self.materialsTab:SetPoint("TOPLEFT",professionPanel,"TOPLEFT",9,-8)
    self.craftsTab=theme:Button(professionPanel,150,28,"CRAFTING PLAN",function()
        Tracker.professionView="crafts"
        if ns.char then ns.char.professionView="crafts" end
        Tracker:RenderProfession()
    end,"quiet")
    self.craftsTab:SetPoint("LEFT",self.materialsTab,"RIGHT",6,0)
    local materials=CreateFrame("ScrollFrame",nil,professionPanel)
    local materialContent=CreateFrame("Frame",nil,materials)
    materials:SetScrollChild(materialContent)
    materials:EnableMouseWheel(true)
    materials:SetScript("OnMouseWheel",function(frame,delta)
        frame:SetVerticalScroll(math.max(0,math.min(math.max(0,materialContent:GetHeight()-frame:GetHeight()),frame:GetVerticalScroll()-delta*26)))
    end)
    local crafting=CreateFrame("ScrollFrame",nil,professionPanel)
    local craftContent=CreateFrame("Frame",nil,crafting)
    crafting:SetScrollChild(craftContent)
    crafting:EnableMouseWheel(true)
    crafting:SetScript("OnMouseWheel",function(frame,delta)
        frame:SetVerticalScroll(math.max(0,math.min(math.max(0,craftContent:GetHeight()-frame:GetHeight()),frame:GetVerticalScroll()-delta*26)))
    end)
    self.professionMaterials=materials
    self.professionCrafting=crafting
    self.professionMaterialContent=materialContent
    self.professionCraftContent=craftContent
    self.professionMaterialRows={}
    self.professionCraftRows={}
    local professionNav=CreateFrame("Frame",nil,panel)
    professionNav:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",13,8)
    professionNav:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-13,8)
    professionNav:SetHeight(36)
    self.professionNav=professionNav
    self.professionPrevButton=theme:Button(professionNav,115,33,"PREPARATION",function()
        Tracker.professionView="materials"
        if ns.char then ns.char.professionView="materials" end
        Tracker:RenderProfession()
    end,"quiet")
    self.professionPrevButton:SetPoint("LEFT",professionNav,"LEFT",0,0)
    self.professionNextButton=theme:Button(professionNav,170,33,"VIEW CRAFTS >",function()
        Tracker.professionView=Tracker.professionView=="materials" and "crafts" or "materials"
        if ns.char then ns.char.professionView=Tracker.professionView end
        Tracker:RenderProfession()
    end,"primary")
    self.professionNextButton:SetPoint("CENTER",professionNav,"CENTER",0,0)
    self.professionSyncButton=theme:Button(professionNav,75,33,"REFRESH",function()
        local profession=ns.Modules.ProfessionGuides
        if profession then profession:CaptureOpenProfession() end
        Tracker:RenderProfession()
    end,"quiet")
    self.professionSyncButton:SetPoint("RIGHT",professionNav,"RIGHT",0,0)
    professionNav:Hide()
    professionPanel:Hide()

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
    for i=1,12 do
        local idx=i
        local button=theme:Button(panel,350,46,"",function()
            if Tracker.upcomingActions and Tracker.upcomingActions[idx] then
                Tracker.upcomingActions[idx]()
            elseif Tracker.upcomingIndices and Tracker.upcomingIndices[idx] then
                navigate(Tracker.upcomingIndices[idx],false)
            end
        end,"quiet")
        button:SetPoint("TOPLEFT",panel,"TOPLEFT",15,-(323+(i-1)*33))
        button.label:ClearAllPoints()
        button.label:SetPoint("TOPLEFT",button,"TOPLEFT",8,-5)
        button.label:SetJustifyH("LEFT")
        button.label:SetJustifyV("TOP")
        button.label:SetTextColor(unpack(theme.gold))
        button.detail=label(button,"",10,theme.ivory,8,20,320)
        button.number=theme:Text(button,"",10,theme.muted,"RIGHT")
        button.number:SetPoint("TOPRIGHT",button,"TOPRIGHT",-8,-5)
        button:EnableMouseWheel(true)
        button:SetScript("OnMouseWheel",function(_,delta)
            Tracker.upcomingPage=math.max(1,math.min(Tracker.upcomingPageCount or 1,(Tracker.upcomingPage or 1)-delta))
            Tracker:Layout()
        end)
        button:SetScript("OnEnter",function(self)
            if GameTooltip and self.entry then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:SetText(self.entry.label)
                if self.entry.detail and self.entry.detail~="" then GameTooltip:AddLine(self.entry.detail,1,1,1,true) end
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave",function(self) if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
        self.upcomingButtons[i]=button
    end

    local control = CreateFrame("Frame",nil,panel)
    control:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",10,9)
    control:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-30,9)
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
            if current and g.ConditionReason then
                local reason=g:ConditionReason(current)
                if reason then ns:Print(reason); Tracker:Refresh(); return end
            end
            if current and current.checkpoint and g.LevelCheckpoint then
                local evidence=g:LevelCheckpoint(current)
                if not evidence.finished then ns:Print(evidence.display); Tracker:Refresh(); return end
                g:SetCurrent(index)
                g:CompleteCurrent()
                ns:Call("Navigator","ResetTarget")
                Tracker:Refresh()
                return
            end
            if current and current.visit and g.VisitSnapshot then
                local visit=g:VisitSnapshot(index)
                if visit and visit.completed<#visit.rows then
                    ns:Print("Finish the remaining visit actions, or use Skip to explicitly skip an action.")
                    Tracker:Refresh()
                    return
                end
            end
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
    -- Reserve a dedicated header for the visible close control.
    -- The extra height preserves every existing utility row and its spacing.
    menu:SetSize(236,548)
    menu:SetClampedToScreen(true)
    menu:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-7,53)
    theme:Panel(menu,theme.panel,theme.gold)
    menu:Hide()
    self.menu=menu
    local menuHeading=theme:Text(menu,"OPTIONS",11,theme.gold)
    menuHeading:SetPoint("TOPLEFT",menu,"TOPLEFT",13,-13)
    self.menuClose=theme:Button(menu,30,28,"X",function() Tracker:CloseMenu() end,"quiet")
    self.menuClose:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-8,-6)
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
        item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-44-(i-1)*35)
        self.menuButtons[key]=item
    end
    local entries2={
        {"Search this guide",function() Tracker.menu:Hide();ns.Modules.UI:ShowTab("Guide Search");ns.Modules.UI:Show() end},
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
        {"Rebuild Guide Progress",function()
            local guides=ns.Modules.Guides
            local guide=guides:GetGuide()
            if not guide or guide.isProfession then
                ns:Print("Rebuild applies to quest guides only.")
                return
            end
            if Tracker.confirmRebuildGuideId~=guide.id then
                Tracker.confirmRebuildGuideId=guide.id
                if Tracker.rebuildProgressButton then
                    Tracker.rebuildProgressButton:SetLabel("CONFIRM REBUILD")
                end
                ns:Print("Rebuild will replace saved progress for "..guide.title..
                    " using WoW quest evidence. Your old progress will be backed up."..
                    " Click CONFIRM REBUILD again to proceed.")
                return
            end
            Tracker.confirmRebuildGuideId=nil
            local ok,report=guides:RebuildProgress(guide.id)
            ns:Print(report or "Rebuild could not run.")
            if ok then ns:Call("Navigator","ResetTarget") end
            Tracker:Refresh()
        end},
        {"Restore Previous Progress",function()
            Tracker.confirmRebuildGuideId=nil
            local ok,report=ns.Modules.Guides:RestorePreviousProgress()
            ns:Print(report or "No guide backup to restore.")
            if ok then ns:Call("Navigator","ResetTarget") end
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
        item:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-150-(i-1)*35)
        if entry[1]=="Rebuild Guide Progress" then
            self.rebuildProgressButton=item
        elseif entry[1]=="Restore Previous Progress" then
            self.restoreProgressButton=item
        end
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

    -- Original pixel-dot diagonal grip: no font glyph or extra texture asset.
    -- The larger hit area stays clear of the footer's overflow button.
    local grip=CreateFrame("Button",nil,panel)
    grip:SetSize(24,24)
    grip:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-3,3)
    grip:SetFrameLevel(panel:GetFrameLevel()+4)
    self.resizeGrip=grip
    local dots={}
    for row=0,2 do
        for col=0,row do
            local dot=grip:CreateTexture(nil,"ARTWORK")
            dot:SetSize(3,3)
            dot:SetPoint("BOTTOMRIGHT",grip,"BOTTOMRIGHT",-4-col*5,4+(2-row)*5)
            dots[#dots+1]=dot
        end
    end
    local function paintGrip(active)
        for _,dot in ipairs(dots) do
            dot:SetColorTexture(unpack(active and theme.teal or theme.gold))
        end
    end
    paintGrip(false)
    grip:SetScript("OnEnter",function(self)
        paintGrip(true)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_LEFT")
            GameTooltip:SetText("Resize WayForth")
            GameTooltip:AddLine("Drag to resize the guide tracker.",1,1,1,true)
            GameTooltip:Show()
        end
    end)
    grip:SetScript("OnLeave",function(self)
        if not self.sizing then paintGrip(false) end
        if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    local function finishResize(self)
        if not self.sizing then return end
        self.sizing=nil
        panel:StopMovingOrSizing()
        paintGrip(false)
        if not ns.char.trackerMinimized then
            db:Set("trackerWidth",math.floor(panel:GetWidth()+0.5))
            db:Set("trackerHeight",math.floor(panel:GetHeight()+0.5))
        end
        Tracker:Layout()
    end
    grip:SetScript("OnMouseDown",function(self,button)
        if button=="LeftButton" and not pref("trackerLocked",false) and not ns.char.trackerMinimized then
            self.sizing=true
            paintGrip(true)
            panel:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp",finishResize)
    grip:SetScript("OnHide",finishResize)

    panel:SetScript("OnSizeChanged",function() Tracker:Layout() end)
    panel:SetScript("OnHide",function() ns:Call("QuestItemButton","Refresh",Tracker) end)
    panel:SetScript("OnUpdate",function(_,elapsed)
        Tracker.professionElapsed=(Tracker.professionElapsed or 0)+elapsed
        if Tracker.professionElapsed>=1.5 then
            Tracker.professionElapsed=0
            local guide=ns.Modules.Guides:GetGuide()
            if guide and guide.isProfession and not ns.char.trackerMinimized then
                local profession=ns.Modules.ProfessionGuides
                if profession then profession:CaptureOpenProfession() end
                Tracker:RenderProfession()
            end
        end
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
    if self.logWarning then
        GameTooltip:AddLine(self.logWarning,1,0.74,0.37,true)
        GameTooltip:AddLine("Turn in ready quests before collecting more. WayForth never abandons quests.",1,0.74,0.37,true)
    end
    if self.liveSnapshot then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(self.liveSnapshot.status,theme.teal[1],theme.teal[2],theme.teal[3],true)
        for _,row in ipairs(self.liveSnapshot.rows) do
            local color=row.finished and theme.green or theme.ivory
            GameTooltip:AddLine((row.heading and "" or row.finished and "[x] " or "[ ] ")..row.display,color[1],color[2],color[3],true)
        end
    end
    GameTooltip:Show()
end

-- Counter-only events do not need to rebuild the guide library or reroute it.
-- The visible tracker coalesces event bursts, and reads fresh data on reopening.
function Tracker:RequestObjectiveRefresh(questID)
    if not self.frame or not self.frame:IsShown() or not self.displayStep
        or ns.char and ns.char.trackerMinimized then return end
    if questID and questID ~= self.displayStep.questId and not self.displayStep.visit then
        local tracked=false
        for _,id in ipairs(self.displayStep.concurrentQuestIds or {}) do if id==questID then tracked=true;break end end
        if not tracked then return end
    end
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
    local visit=step and step.visit and guides.VisitSnapshot and guides:VisitSnapshot(self.displayIndex)
    local snapshot=visit or (step and progress and progress:Get(step.questId) or nil)
    local checkpoint=step and step.checkpoint and guides.LevelCheckpoint and guides:LevelCheckpoint(step)
    if checkpoint then
        snapshot={questID="checkpoint:"..tostring(step.id),status=checkpoint.finished and "CHECKPOINT REACHED" or "LEVELING CHECKPOINT",state=checkpoint.finished and "ready" or "active",rows={checkpoint}}
    end
    if ns.Modules.Travel and ns.Modules.Travel:Current(step) then snapshot=nil end
    if snapshot and snapshot.state=="inactive" and step.action=="accept" then snapshot=nil end
    if snapshot and snapshot.ready and step.action=="objective" and not fromRefresh then
        local changed=guides:Sync()
        if changed then self:Refresh();return end
    end
    local concurrent=step and self.allowLiveInstructionText and not visit and guides.ConcurrentSnapshot and guides:ConcurrentSnapshot(self.displayIndex) or {}
    if #concurrent>0 then
        local combined={rows={},questID=step.questId or step.id,status="TRACK WHILE TRAVELING",state="active"}
        if snapshot then
            for k,v in pairs(snapshot) do if k~="rows" then combined[k]=v end end
            for _,row in ipairs(snapshot.rows or {}) do combined.rows[#combined.rows+1]=row end
            if #combined.rows>0 then combined.rows[#combined.rows+1]={heading=true,display="ALSO TRACK ALONG THE WAY"} end
        end
        for _,row in ipairs(concurrent) do combined.rows[#combined.rows+1]=row end
        snapshot=combined
    end
    if not snapshot or not self.liveSnapshot or snapshot.questID~=self.liveSnapshot.questID then
        self.liveScroll:SetVerticalScroll(0)
    end
    self.liveSnapshot=snapshot
    if visit and snapshot==visit and self.allowLiveInstructionText then
        self.stepTitle:SetText(visit.title or "Quest giver visit")
        self.objectiveText:SetText("Complete the listed quest actions at this stop.")
        self.objectiveCaption:SetText(visit.first.."–"..visit.last.." | CURRENT VISIT")
    end
    if step and step.useLiveInstructions and snapshot and snapshot.active and #snapshot.rows>0
        and self.allowLiveInstructionText then
        self.objectiveText:SetText("Complete the remaining requirements listed below. Follow the marked location where available.")
    end
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
        line:SetText((row.heading and "" or row.finished and "[x] " or "[ ] ")..row.display)
        line:SetTextColor(unpack(row.heading and theme.teal or row.finished and theme.green or theme.ivory))
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
    local cardH=math.min(math.max(118,desired),math.max(118,height-151-112))
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

-- Reused visual components are intentionally pooled. Re-reading bags and
-- successful casts repaints numbers; it never creates a fresh widget tree.
local function setProfessionText(font,parent,value,x,y,w,h,color)
    font:ClearAllPoints()
    font:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    font:SetWidth(math.max(15,w))
    font:SetHeight(h or 18)
    font:SetText(tostring(value or ""))
    font:SetTextColor(unpack(color or theme.ivory))
end
local function professionLine(tracker,group,key,parent,value,y,width,size,color)
    tracker[group]=tracker[group] or {}
    local font=tracker[group][key]
    if not font then
        font=theme:Text(parent,"",size or 11,color or theme.ivory)
        font:SetWordWrap(true)
        tracker[group][key]=font
    end
    setProfessionText(font,parent,value,0,y,width,400,color)
    local measured=font.GetStringHeight and font:GetStringHeight() or 16
    local height=math.max(16,math.min(160,(measured or 16)+4))
    font:SetHeight(height)
    font:Show()
    return y+height+4
end
local function professionIcon(itemId)
    if type(itemId)=="number" and type(GetItemIcon)=="function" then
        local ok,texture=pcall(GetItemIcon,itemId)
        if ok and texture then return texture end
    end
    if type(itemId)=="number" and C_Item and type(C_Item.GetItemIconByID)=="function" then
        local ok,texture=pcall(C_Item.GetItemIconByID,itemId)
        if ok and texture then return texture end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
local function newMaterialCard(content)
    local card=CreateFrame("Frame",nil,content)
    theme:Panel(card,theme.elevated,theme.border)
    card.icon=card:CreateTexture(nil,"ARTWORK")
    card.icon:SetPoint("TOPLEFT",card,"TOPLEFT",10,-12)
    card.icon:SetSize(36,36)
    card.title=theme:Text(card,"",12,theme.ivory)
    card.details=theme:Text(card,"",10,theme.muted)
    card.status=theme:Text(card,"",10,theme.gold,"RIGHT")
    card.track=card:CreateTexture(nil,"BACKGROUND")
    card.track:SetColorTexture(0.14,0.25,0.30,1)
    card.track:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",56,11)
    card.track:SetHeight(5)
    card.fill=card:CreateTexture(nil,"ARTWORK")
    card.fill:SetColorTexture(unpack(theme.teal))
    card.fill:SetPoint("LEFT",card.track,"LEFT")
    card.fill:SetHeight(5)
    return card
end
local function newCraftCard(content)
    local card=CreateFrame("Frame",nil,content)
    theme:Panel(card,theme.elevated,theme.border)
    card.range=theme:Text(card,"",10,theme.teal)
    card.title=theme:Text(card,"",12,theme.ivory)
    card.count=theme:Text(card,"",10,theme.muted,"RIGHT")
    card.source=theme:Text(card,"",10,theme.muted)
    card.track=card:CreateTexture(nil,"BACKGROUND")
    card.track:SetColorTexture(0.14,0.25,0.30,1)
    card.track:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",12,10)
    card.track:SetHeight(5)
    card.fill=card:CreateTexture(nil,"ARTWORK")
    card.fill:SetColorTexture(unpack(theme.teal))
    card.fill:SetPoint("LEFT",card.track,"LEFT")
    card.fill:SetHeight(5)
    return card
end
local function paintFill(card,amount,total,width)
    local fraction=total>0 and math.max(0,math.min(1,amount/total)) or 0
    card.track:SetWidth(math.max(2,width))
    card.fill:SetWidth(math.max(1,width*fraction))
    if fraction==0 then card.fill:Hide() else card.fill:Show() end
    card.fill:SetColorTexture(unpack(fraction>=1 and theme.green or theme.teal))
end

function Tracker:RenderProfessionChecklist(plan,width)
    local content=self.professionMaterialContent
    local prep=plan.preparation or {materials=plan.materials or {},intermediates={}}
    local list=prep.materials or {}
    local y=0
    y=professionLine(self,"professionPrepLabels","heading",content,
        "STEP 1  |  GATHER MATERIALS",y,width,13,theme.gold)
    y=professionLine(self,"professionPrepLabels","skill",content,
        "Skill "..plan.skill.." / "..plan.target.."  |  Bags + bank (when accessible)",y,width,10,theme.teal)
    local routeLabel=(plan.offline or plan.verifiedSegment) and "Source-verified route + yellow reserve"
        or plan.gathering and "Gathering guide" or plan.requiresVerification and "Live orange/yellow recipe only"
        or "Current orange/yellow craft only"
    y=professionLine(self,"professionPrepLabels","route",content,routeLabel,y,width,10,theme.muted)
    if plan.yellowBuffer and plan.yellowBuffer>0 then
        y=professionLine(self,"professionPrepLabels","buffer",content,
            "Yellow reserve: +"..plan.yellowBuffer.." planned crafts (10%); skill gains are not guaranteed.",y,width,10,theme.gold)
    elseif self.professionPrepLabels and self.professionPrepLabels.buffer then
        self.professionPrepLabels.buffer:Hide()
    end
    y=y+7
    y=professionLine(self,"professionPrepLabels","checklist",content,
        prep.expanded and "RAW MATERIAL CHECKLIST" or "MATERIAL CHECKLIST",y,width,12,theme.teal)
    y=professionLine(self,"professionPrepLabels","types",content,
        #list.." ingredient types  |  Counts update from your inventory",y,width,10,theme.muted)
    self.professionMaterialCards=self.professionMaterialCards or {}
    for i,item in ipairs(list) do
        local card=self.professionMaterialCards[i]
        if not card then
            card=newMaterialCard(content)
            self.professionMaterialCards[i]=card
        end
        card:SetSize(width,70)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT",content,"TOPLEFT",0,-y)
        card.icon:SetTexture(professionIcon(item.itemId))
        setProfessionText(card.title,card,item.name,55,8,width-160,19,theme.ivory)
        setProfessionText(card.details,card,
            "Have "..item.owned.."  /  "..item.required.."  |  Need "..item.missing,
            55,29,width-75,18,theme.muted)
        setProfessionText(card.status,card,item.missing==0 and "READY" or "MISSING",
            width-99,8,86,18,item.missing==0 and theme.green or theme.gold)
        paintFill(card,math.min(item.owned,item.required),item.required,width-69)
        card:Show()
        y=y+77
    end
    for i=#list+1,#self.professionMaterialCards do self.professionMaterialCards[i]:Hide() end
    if #list==0 then
        y=professionLine(self,"professionPrepLabels","empty",content,
            plan.instructions or "No remaining raw materials are required.",y,width,11,theme.ivory)
    elseif self.professionPrepLabels and self.professionPrepLabels.empty then
        self.professionPrepLabels.empty:Hide()
    end

    local collected,total=0,0
    for _,item in ipairs(list) do
        total=total+item.required
        collected=collected+math.min(item.owned,item.required)
    end
    if not self.professionSummary then
        local summary=CreateFrame("Frame",nil,content)
        theme:Panel(summary,theme.panel,theme.border)
        summary.caption=theme:Text(summary,"COLLECTED",10,theme.teal)
        summary.count=theme:Text(summary,"",12,theme.ivory,"RIGHT")
        summary.track=summary:CreateTexture(nil,"BACKGROUND")
        summary.track:SetColorTexture(0.14,0.25,0.30,1)
        summary.track:SetPoint("BOTTOMLEFT",summary,"BOTTOMLEFT",12,9)
        summary.track:SetHeight(5)
        summary.fill=summary:CreateTexture(nil,"ARTWORK")
        summary.fill:SetColorTexture(unpack(theme.teal))
        summary.fill:SetPoint("LEFT",summary.track,"LEFT")
        summary.fill:SetHeight(5)
        self.professionSummary=summary
    end
    local summary=self.professionSummary
    summary:SetSize(width,53)
    summary:ClearAllPoints()
    summary:SetPoint("TOPLEFT",content,"TOPLEFT",0,-y)
    setProfessionText(summary.caption,summary,"COLLECTED",12,9,width-120,19,theme.teal)
    setProfessionText(summary.count,summary,collected.." / "..total.." items",width-170,8,158,20,theme.ivory)
    paintFill(summary,collected,total,width-24)
    summary:Show()
    y=y+64

    -- Material conversion is distinct from skill-point progress. These are
    -- source-verified recipes, but the player must have learned each one.
    local conversions=prep.intermediates or {}
    if #conversions>0 then
        y=professionLine(self,"professionPrepLabels","convertHeading",content,
            "PREPARE CRAFTED INTERMEDIATES",y,width,11,theme.gold)
        y=professionLine(self,"professionPrepLabels","convertNote",content,
            "Optional conversion route. Learn the recipes first, or obtain the finished items directly.",y,width,10,theme.muted)
    else
        for _,key in ipairs({"convertHeading","convertNote"}) do
            if self.professionPrepLabels and self.professionPrepLabels[key] then self.professionPrepLabels[key]:Hide() end
        end
    end
    self.professionConversionLabels=self.professionConversionLabels or {}
    for i,entry in ipairs(conversions) do
        local field=self.professionConversionLabels[i]
        if not field then
            field=theme:Text(content,"",11,theme.ivory)
            field:SetWordWrap(true)
            self.professionConversionLabels[i]=field
        end
        local label=entry.crafts.."x "..entry.name..
            (entry.acquisition and ("  |  "..entry.acquisition) or "  |  Recipe must be learned")
        setProfessionText(field,content,label,7,y,width-16,400,theme.ivory)
        local h=math.max(19,math.min(70,(field:GetStringHeight() or 15)+6))
        field:SetHeight(h)
        field:Show()
        y=y+h+4
    end
    for i=#conversions+1,#self.professionConversionLabels do self.professionConversionLabels[i]:Hide() end
    y=y+7
    y=professionLine(self,"professionPrepLabels","nextHeading",content,
        plan.gathering and "THEN FOLLOW THE GATHERING ROUTE" or "THEN CRAFT IN THIS ORDER",y,width,12,theme.gold)
    if plan.gathering then
        for _,row in ipairs(self.professionPreviewLabels or {}) do row:Hide() end
        if self.professionPrepLabels and self.professionPrepLabels.nextHelp then self.professionPrepLabels.nextHelp:Hide() end
        y=professionLine(self,"professionPrepLabels","nextEmpty",content,
            plan.instructions or "Gather verified nodes to raise skill.",y,width,11,theme.ivory)
    else
        local current=1
        for i,craft in ipairs(plan.crafts or {}) do
            if not craft.toSkill or plan.skill<craft.toSkill then current=i;break end
            current=i+1
        end
        local previewCount=0
        self.professionPreviewLabels=self.professionPreviewLabels or {}
        for i=current,math.min(#(plan.crafts or {}),current+2) do
            local craft=plan.crafts[i]
            local row=self.professionPreviewLabels[previewCount+1]
            if not row then
                row=theme:Text(content,"",10,theme.ivory)
                self.professionPreviewLabels[previewCount+1]=row
            end
            local range=craft.fromSkill and (craft.fromSkill.."-"..craft.toSkill.."  ") or ""
            local progress=craft.progressType=="observed-cast" and
                (craft.completed.."/"..craft.required.." crafts") or "craft count unavailable"
            setProfessionText(row,content,range..craft.name.."  |  "..progress,7,y,width-12,38,
                craft.color=="yellow" and theme.gold or theme.ivory)
            local h=math.max(18,math.min(36,(row:GetStringHeight() or 14)+3))
            row:SetHeight(h)
            row:Show()
            y=y+h+4
            previewCount=previewCount+1
        end
        for i=previewCount+1,#(self.professionPreviewLabels or {}) do self.professionPreviewLabels[i]:Hide() end
        if previewCount==0 then
            y=professionLine(self,"professionPrepLabels","nextEmpty",content,
                plan.complete and "Profession skill cap reached." or
                (plan.instructions or "No verified crafting sequence is available."),y,width,11,theme.ivory)
        elseif self.professionPrepLabels and self.professionPrepLabels.nextEmpty then
            self.professionPrepLabels.nextEmpty:Hide()
        end
        y=professionLine(self,"professionPrepLabels","nextHelp",content,
            "Open CRAFTING PLAN for every recipe, acquisition method and live craft progress.",y,width,10,theme.teal)
    end
    content:SetSize(width,math.max(1,y+8))
end

function Tracker:RenderProfessionCrafts(plan,width)
    local content=self.professionCraftContent
    local y=0
    y=professionLine(self,"professionCraftLabels","heading",content,
        plan.gathering and "STEP 2  |  GATHERING ROUTE" or "STEP 2  |  CRAFTING PLAN",
        y,width,13,theme.gold)
    y=professionLine(self,"professionCraftLabels","source",content,
        (plan.offline or plan.verifiedSegment) and "Recipe data: ForeverDB.net (foreverdb.net)"
        or "Live recipe color and known Forever data only",y,width,10,theme.teal)
    if plan.needsTrainer then
        y=professionLine(self,"professionCraftLabels","trainer",content,
            "TRAIN NEXT RANK before crafting",y,width,11,theme.gold)
    elseif self.professionCraftLabels and self.professionCraftLabels.trainer then
        self.professionCraftLabels.trainer:Hide()
    end
    y=professionLine(self,"professionCraftLabels","warning",content,
        plan.gathering and (plan.instructions or "Find source-observed zones for gathering.")
        or "Orange first; yellow crafts have a +10% reserve. A yellow skill-up is not guaranteed.",
        y,width,10,theme.muted)
    y=y+8
    self.professionCraftCards=self.professionCraftCards or {}
    local cards=0
    if not plan.gathering then
        for _,craft in ipairs(plan.crafts or {}) do
            -- A returning character must not see unobserved old crafts as
            -- unfinished. Show the actionable skill bands only.
            if not craft.toSkill or craft.toSkill>plan.skill then
            cards=cards+1
            local card=self.professionCraftCards[cards]
            if not card then
                card=newCraftCard(content)
                self.professionCraftCards[cards]=card
            end
            card:SetSize(width,101)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT",content,"TOPLEFT",0,-y)
            local color=craft.color=="yellow" and theme.gold or {1,.63,.32,1}
            setProfessionText(card.range,card,
                craft.fromSkill and ("SKILL "..craft.fromSkill.." -> "..craft.toSkill) or
                    ("CURRENT SKILL "..plan.skill),12,10,145,17,theme.teal)
            setProfessionText(card.title,card,craft.name.." ("..(craft.color or "orange")..")",
                12,31,width-26,22,color)
            if craft.progressType=="observed-cast" then
                setProfessionText(card.count,card,"Crafted "..craft.completed.." / "..craft.required,
                    width-146,9,132,18,theme.ivory)
            else
                setProfessionText(card.count,card,"Craft count unavailable",
                    width-168,9,154,18,theme.gold)
            end
            local details=craft.acquisition or (craft.trainer and "Trainer recipe" or "Check learned recipes")
            if (craft.bufferExtra or 0)>0 then
                details=details.."  |  Yellow reserve: +"..craft.bufferExtra
            end
            if craft.learnAt then details=details.."  |  Learn at "..craft.learnAt end
            setProfessionText(card.source,card,details,12,59,width-24,20,theme.muted)
            local done=craft.progressType=="observed-cast" and craft.completed or 0
            paintFill(card,done,craft.required,width-25)
            card:Show()
            y=y+108
            end
        end
    end
    for i=cards+1,#self.professionCraftCards do self.professionCraftCards[i]:Hide() end
    if plan.gathering then
        if self.professionCraftLabels and self.professionCraftLabels.none then self.professionCraftLabels.none:Hide() end
        local shown=0
        for _,option in ipairs(plan.gatheringOptions or {}) do
            shown=shown+1
            y=professionLine(self,"professionCraftLabels","zone"..tostring(_),content,
                (option.verified and "[Observed] " or "[Candidate] ")..
                option.zone.." (map "..option.mapId..")",y,width,11,theme.ivory)
        end
        for i=shown+1,3 do
            local key="zone"..i
            if self.professionCraftLabels and self.professionCraftLabels[key] then self.professionCraftLabels[key]:Hide() end
        end
    elseif cards==0 then
        for _,key in ipairs({"zone1","zone2","zone3"}) do
            if self.professionCraftLabels and self.professionCraftLabels[key] then self.professionCraftLabels[key]:Hide() end
        end
        y=professionLine(self,"professionCraftLabels","none",content,
            plan.instructions or "Learn an orange/yellow recipe or visit a trainer.",y,width,11,theme.ivory)
    else
        if self.professionCraftLabels and self.professionCraftLabels.none then self.professionCraftLabels.none:Hide() end
        for _,key in ipairs({"zone1","zone2","zone3"}) do
            if self.professionCraftLabels and self.professionCraftLabels[key] then self.professionCraftLabels[key]:Hide() end
        end
    end
    if not plan.gathering and cards>0 then
        y=professionLine(self,"professionCraftLabels","footer",content,
            plan.instructions or "Craft counts update from successful player spellcast events. Recheck actual skill after each craft.",
            y,width,10,theme.muted)
    elseif self.professionCraftLabels and self.professionCraftLabels.footer then
        self.professionCraftLabels.footer:Hide()
    end
    content:SetSize(width,math.max(1,y+10))
end

function Tracker:RenderProfession()
    local guide=ns.Modules.Guides:GetGuide()
    if not guide or not guide.isProfession or not self.professionPanel then return end
    local profession=ns.Modules.ProfessionGuides
    local plan=profession and profession:GatherPlan(guide.professionId)
    if not plan then return end
    self.professionPlan=plan
    local width=math.max(230,self.professionPanel:GetWidth()-26)
    local left=self.professionMaterials
    local right=self.professionCrafting
    for _,scroll in ipairs({left,right}) do
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT",self.professionPanel,"TOPLEFT",12,-44)
        scroll:SetPoint("BOTTOMRIGHT",self.professionPanel,"BOTTOMRIGHT",-12,12)
    end
    local view=self.professionView or "materials"
    if view=="materials" then left:Show();right:Hide() else left:Hide();right:Show() end
    self.materialsTab.surface:SetColorTexture(unpack(view=="materials" and theme.elevated or theme.panel))
    self.craftsTab.surface:SetColorTexture(unpack(view=="crafts" and theme.elevated or theme.panel))
    self.materialsTab.label:SetTextColor(unpack(view=="materials" and theme.teal or theme.ivory))
    self.craftsTab.label:SetTextColor(unpack(view=="crafts" and theme.teal or theme.ivory))
    -- Only render the visible scroll page. A 1-to-300 route can contain
    -- many recipe cards; repainting the hidden page every inventory event
    -- wastes UI time and created the stuttering seen in earlier betas.
    if view=="materials" then self:RenderProfessionChecklist(plan,width)
    else self:RenderProfessionCrafts(plan,width) end
    if self.professionNextButton then
        self.professionNextButton:SetLabel(view=="materials" and "VIEW CRAFTS >" or "< BACK TO PREP")
    end
    for _,scroll in ipairs({left,right}) do
        local content=scroll==left and self.professionMaterialContent or self.professionCraftContent
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(),math.max(0,content:GetHeight()-scroll:GetHeight())))
    end
end

function Tracker:Layout()
    if not self.frame or not self.summary then return end
    local width,height=self.frame:GetWidth(),self.frame:GetHeight()
    if width <= 0 or height <= 0 then return end
    local contentW=math.max(240,width-45)
    local _,hasItem=ns:Call("QuestItemButton","Refresh",self)
    self.guideTitle:SetWidth(contentW-30)
    if self.guideTitle.SetMaxLines then self.guideTitle:SetMaxLines(1) end
    self.guideTitle:SetHeight(16)
    self.stepCount:SetWidth(contentW-30)
    if self.stepCount.SetMaxLines then self.stepCount:SetMaxLines(1) end
    self.stepCount:SetHeight(15)
    -- Keep the title/caption clear of the quest-item and PIN controls.
    self.stepTitle:SetWidth(math.max(170,contentW-(hasItem and 135 or 89)))
    self.objectiveCaption:SetWidth(math.max(170,contentW-(hasItem and 135 or 89)))
    self.objectiveText:SetWidth(contentW)
    self.location:SetWidth(contentW)
    self.progressBar:SetWidth(math.max(1,(width-83)*(self.progressFraction or 0)))
    local isProfession=ns.Modules.Guides:GetGuide() and ns.Modules.Guides:GetGuide().isProfession
    if self.tabStrip then
        if ns.char.trackerMinimized then self.tabStrip:Hide() else self.tabStrip:Show() end
        -- OnSizeChanged calls Layout: tab widths and pager counts must respond
        -- immediately while the player drags the resize grip.
        self:RefreshTabs()
    end
    if self.professionPanel then
        if isProfession and not ns.char.trackerMinimized then
            self.professionPanel:Show()
            self:RenderProfession()
        else self.professionPanel:Hide() end
    end
    local cardH=self:LayoutObjectives(width,height)
    local upcomingY=151+cardH+9
    self.upcomingTitle:ClearAllPoints()
    self.upcomingTitle:SetPoint("TOPLEFT",self.frame,"TOPLEFT",15,-upcomingY)
    local visible=math.max(0,math.min(12,math.floor((height-56-(upcomingY+23)+3)/49)))
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
            button.entry=entry
            local heading=entry.label
            if entry.index>0 then heading=heading:gsub("^%d+%.%s*",""):gsub("| %d+%.%s*","| ") end
            button:SetLabel(heading)
            button.label:SetSize(math.max(100,width-100),15)
            if button.label.SetMaxLines then button.label:SetMaxLines(1) end
            button.detail:SetWidth(math.max(100,width-48))
            button.detail:SetHeight(24)
            if button.detail.SetMaxLines then button.detail:SetMaxLines(2) end
            button.detail:SetText(entry.detail or "")
            button.detail:SetTextColor(unpack(theme.ivory))
            button.number:SetText(entry.index>0 and tostring(entry.index) or "")
        else
            button.entry=nil
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
        button:SetPoint("TOPLEFT",self.frame,"TOPLEFT",15,-(upcomingY+23+(i-1)*49))
        if self.upcomingIndices and self.upcomingIndices[i]
            and i <= visible
            and not (ns.char and ns.char.trackerMinimized) then
            button:Show()
        else button:Hide() end
    end
    if self.resizeGrip then
        if ns.char.trackerMinimized or pref("trackerLocked",false) then self.resizeGrip:Hide() else self.resizeGrip:Show() end
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
    if self.professionNav then
        if isProfession and not ns.char.trackerMinimized then self.professionNav:Show()
        else self.professionNav:Hide() end
    end
    if isProfession and not ns.char.trackerMinimized then
        self.objectiveCard:Hide()
        self.upcomingTitle:Hide()
        if self.pageButton then self.pageButton:Hide() end
        for _,button in ipairs(self.upcomingButtons) do button:Hide() end
        self.controls:Hide()
    end
    ns:Call("QuestItemButton","Position")
end

function Tracker:ToggleMinimize()
    if not self.frame then return end
    local minimized=not (ns.char and ns.char.trackerMinimized)
    if ns.char then ns.char.trackerMinimized=minimized end
    self.frame:SetHeight(minimized and 50 or math.max(560,pref("trackerHeight",680)))
    self.minimizeButton:SetLabel(minimized and "+" or "-")
    self:Refresh()
    self:Layout()
    if minimized then
        self.header:Show()
    end
end

-- The overflow X dismisses only the menu. Keep tracker visibility, the
-- navigation arrow, current guide, and per-character checkpoints untouched.
function Tracker:CloseMenu()
    self.confirmRebuildGuideId=nil
    if self.rebuildProgressButton then
        self.rebuildProgressButton:SetLabel("Rebuild Guide Progress")
    end
    if self.menu then self.menu:Hide() end
end

function Tracker:ToggleMenu()
    if not self.menu then return end
    if self.menu:IsShown() then self:CloseMenu()
    else
        if self.picker then self.picker:Hide() end
        self.menu:Show()
    end
end
function Tracker:ToggleGuidePicker()
    if not self.picker then return end
    if self.picker:IsShown() then self.picker:Hide();return end
    if self.menu then self:CloseMenu() end
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
    -- Match the guide engine exactly; a missing setting is not an enabled reader.
    local simpleReader=pref("simpleStepReader",false)==true
    self:RefreshTabs()
    local step,index,total=guides:CurrentStep()
    if not g or not step or not total or total==0 then
        self.displayStep,self.liveSnapshot=nil,nil
        self.upcomingIndices={}
        self.upcomingEntries={}
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
            self.brandCaption:SetText(simpleReader
                and ("STEP READER | " .. tostring(ns.version or "dev"))
                or "GUIDE TRACKER")
        end
    end
    -- Count completed steps separately from the saved cursor. Older characters
    -- can resume at step 1 with many later quests already completed.
    local progressText=count .. "/" .. total .. " steps complete"
    local dungeon=g.isDungeon and ns.Modules.DungeonGuides
    if dungeon then
        local overview=dungeon:Overview(g.id)
        if overview then
            self.stepCount:SetText("Dungeon quests "..overview.collected.."/"..overview.eligible..
                " collected  |  "..overview.completed.."/"..overview.eligible.." turned in")
        end
    else
        self.stepCount:SetText(focus and ("Viewing " .. index .. " | Route " .. routeIndex .. "/" .. total .. " | " .. progressText)
            or ("Step " .. index .. " / " .. total .. "  |  " .. progressText))
        if self.progressBar then
            local low,high=g.levelMin,g.levelMax
            local band=low and high and ("Lv "..low.."-"..high.."  |  ") or ""
            self.stepCount:SetText(band.."Step "..index.."/"..total.."  |  "..math.floor(self.progressFraction*100+0.5).."% complete")
            if focus then self.stepCount:SetText("Viewing "..index.." | Route "..routeIndex.."/"..total.." | "..math.floor(self.progressFraction*100+0.5).."% complete") end
        end
    end
    local space=ns.Modules.QuestLogSpace
    local logStatus=space and space:Status()
    self.logWarning=space and space:Message(logStatus)
    if self.logWarning then self.stepCount:SetText(self.logWarning) end
    self.stepCount:SetTextColor(unpack(self.logWarning and theme.gold or theme.teal))
    self.stepTitle:SetText(step.title or "Next objective")
    self.next:SetLabel(step.action=="manual" and "Done / Next" or "Next Step")
    -- In step-reader mode the tracker shows the authored guide, not a separate
    -- hub router. These advisory helpers must not replace or obscure its steps.
    local grouped=not simpleReader and ns.Modules.SmartRoutes
        and ns.Modules.SmartRoutes:NearbyGroup(focus) or {}
    local actions={accept="PICK UP",objective="DO",turnin="TURN IN",checkpoint="LEVEL UP"}
    local counts={accept=0,objective=0,turnin=0}
    for _,entry in ipairs(grouped) do
        if entry.index ~= index and counts[entry.step.action] then
            counts[entry.step.action]=counts[entry.step.action]+1
        end
    end
    if focus then
        self.objectiveCaption:SetText(simpleReader and "SELECTED GUIDE STEP"
            or (navigator.pinnedIndex and "PINNED SIDE OBJECTIVE" or "SELECTED SIDE OBJECTIVE"))
    elseif simpleReader and not g.isProfession then
        self.objectiveCaption:SetText("CURRENT STEP | "..(actions[step.action] or "FOLLOW"))
    elseif #grouped>1 then
        local statuses={}
        if counts.turnin>0 then statuses[#statuses+1]=counts.turnin.." TURN-INS" end
        if counts.accept>0 then statuses[#statuses+1]=counts.accept.." PICKUPS" end
        if counts.objective>0 then statuses[#statuses+1]=counts.objective.." OBJECTIVES" end
        self.objectiveCaption:SetText("HUB SWEEP | "..table.concat(statuses," | "))
    else
        self.objectiveCaption:SetText(g.isProfession and "PROFESSION SKILL-UP PLAN"
            or g.testingOnly and "TEST ROUTE - VERIFY QUEST" or "CURRENT OBJECTIVE")
    end
    self.objectiveCaption:SetTextColor(unpack(theme.teal))
    if simpleReader and not g.isProfession and self.progressBar and not focus then
        self.objectiveCaption:SetText(index.." | CURRENT STEP | "..(actions[step.action] or "FOLLOW"))
    end
    local objectiveText=step.text or ""
    if g.isProfession then
        local profession=ns.Modules.ProfessionGuides
        local plan=profession and profession:PlanText(g.professionId)
        if plan and plan~="" then objectiveText=plan.."\n\n"..objectiveText end
    end
    self.objectiveText:SetText(objectiveText)
    local place=step.hub or step.zone or g.zone or "Quest objective"
    local target
    if navigator and type(navigator.TargetForStep)=="function" then
        local ok,found=pcall(navigator.TargetForStep,navigator,step)
        if ok then target=found end
    end
    if g.isProfession then
        if step.trainer and target then
            self.location:SetText("Trainer: "..place)
        elseif step.trainer then
            self.location:SetText("Trainer visit | No verified trainer waypoint")
        else
            self.location:SetText("Profession window | No map waypoint for crafting")
        end
        if self.pinButton then
            if step.trainer and target then self.pinButton:Show() else self.pinButton:Hide() end
        end
    else
        self.location:SetText(step.x and step.y and (place .. string.format("  (%.1f, %.1f)",step.x,step.y))
            or (target and place or (place .. " | No waypoint verified")))
        if self.pinButton then self.pinButton:Show() end
    end
    -- Combine all hub pickups, genuinely active parallel objectives and
    -- upcoming route steps. Page through them in the same compact tracker.
    local entries,shown={},{}
    local visit=simpleReader and not focus and step.visit and guides.VisitSnapshot and guides:VisitSnapshot(index)
    if visit then for i=visit.first,visit.last do shown[i]=true end end
    local function append(candidate,label)
        if not candidate or not candidate.index or shown[candidate.index]
            or candidate.index==index or stepComplete(steps[candidate.index],candidate.index,saved) then return end
        if saved.skipped and saved.skipped[steps[candidate.index].id or candidate.index] then return end
        local source=steps[candidate.index]
        entries[#entries+1]={index=candidate.index,label=label,detail=source.text or ""}
        shown[candidate.index]=true
    end
    if not simpleReader and logStatus and logStatus.near then
        for _,item in ipairs(space:ReadyTurnIns(steps,saved)) do
            append(item,"FREE A SLOT | "..tostring(item.step.title or "Turn in quest"))
        end
    end
    for _,item in ipairs(grouped) do
        local name=tostring(item.step.title or "Quest"):gsub("^Pick up:%s*","")
        append(item,(actions[item.step.action] or "VISIT").." | "..name)
    end
    local work=not simpleReader and ns.Modules.SmartRoutes
        and ns.Modules.SmartRoutes:ConcurrentQuestSteps(30) or {}
    for _,item in ipairs(work) do
        append(item,item.action.." | "..tostring(item.step.title or "Quest"))
    end
    local fallback=0
    -- Keep the next actionable steps in guide order. If earlier steps were
    -- completed or skipped on this character, explain the numbering gap
    -- instead of appearing to lose guide instructions (e.g. 25 -> 46).
    local hiddenDone,hiddenSkipped=0,0
    for i=routeIndex+1,#steps do
        if not simpleReader and fallback>=12 then break end
        if not shown[i] then
            local key=steps[i].id or i
            if simpleReader and stepComplete(steps[i],i,saved) then
                hiddenDone=hiddenDone+1
            elseif simpleReader and saved.skipped and saved.skipped[key] then
                hiddenSkipped=hiddenSkipped+1
            elseif not stepComplete(steps[i],i,saved)
                and not (saved.skipped and saved.skipped[key]) then
                local label=tostring(i)..". "..tostring(steps[i].title or "Next step")
                if simpleReader and (hiddenDone>0 or hiddenSkipped>0) then
                    local hidden={}
                    if hiddenDone>0 then hidden[#hidden+1]=hiddenDone.." DONE" end
                    if hiddenSkipped>0 then hidden[#hidden+1]=hiddenSkipped.." SKIPPED" end
                    label=table.concat(hidden,", ").." | "..label
                end
                append({index=i},label)
                fallback=fallback+1
                hiddenDone,hiddenSkipped=0,0
            end
        end
    end
    local zones=ns.Modules.NextZone
    local options=not simpleReader and zones and zones:Options() or {}
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
    if simpleReader then
        self.upcomingTitle:SetText("NEXT GUIDE STEPS")
    elseif #options>0 then
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
        -- Keep independently validated next-zone recommendations accessible
        -- when the current zone has no recoverable quest. Hide quest targets.
        self.upcomingEntries={}
        for _,entry in ipairs(entries) do
            if entry.index==0 and entry.action then self.upcomingEntries[#self.upcomingEntries+1]=entry end
        end
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
    if not blocked and guides.ConditionReason then blocked=guides:ConditionReason(step,g.id) end
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
        local checkpoint=leg.kind=="flightPath" or leg.kind=="fly" or leg.kind=="bindHearth" or leg.kind=="hearth"
        if checkpoint and travel.CheckpointInstruction then
            self.objectiveText:SetText(leg.text.."\n"..travel:CheckpointInstruction(leg))
        else self.objectiveText:SetText(leg.text) end
        self.next:SetLabel("Next Travel")
    end
    for key,item in pairs(self.menuButtons) do
        local title=key=="guidePaused" and "Pause Guide" or key=="autoAdvance" and "Auto Advance" or "Show Arrow"
        item:SetLabel(title .. ": " .. (pref(key,false) and "ON" or "OFF"))
    end
    if self.confirmRebuildGuideId and self.confirmRebuildGuideId~=g.id then
        self.confirmRebuildGuideId=nil
    end
    if self.rebuildProgressButton then
        self.rebuildProgressButton:SetLabel(self.confirmRebuildGuideId==g.id
            and "CONFIRM REBUILD" or "Rebuild Guide Progress")
    end
    if self.minimizeButton then self.minimizeButton:SetLabel(ns.char and ns.char.trackerMinimized and "+" or "-") end
    self.displayStep=step
    self.allowLiveInstructionText=not blocked and not leg and not saved.awaitingQuestMatch
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
