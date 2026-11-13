-- WayForth premium dashboard. Replaces the presentation methods of UI/Window.lua.
-- Keeps the same UI module, minimap button and guide engine; adds no extra window.
local _, ns = ...
local UI = ns.Modules.UI
local theme = ns.Modules.Theme
local db = ns.Modules.Database

local NAV = { "Dashboard", "Guide Library", "Favorites", "Recently Used",
    "Professions", "Legacy", "Map", "Settings" }
local NAV_ICONS = {
    Dashboard = "Interface\\Icons\\INV_Misc_EngGizmos_32",
    ["Guide Library"] = "Interface\\Icons\\INV_Misc_Book_09",
    Favorites = "Interface\\Icons\\INV_Misc_Gem_01",
    ["Recently Used"] = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    Map = "Interface\\Icons\\INV_Misc_Spyglass_02",
    Professions = "Interface\\Icons\\Trade_BlackSmithing",
    Legacy = "Interface\\Icons\\INV_Misc_TreasureChest_01",
    Settings = "Interface\\Icons\\INV_Gizmo_02",
}
local CATEGORIES = {
    { title="Leveling", icon="Interface\\Icons\\Achievement_Level_10", art=2, tab="Guide Library" },
    { title="Professions", icon="Interface\\Icons\\Trade_BlackSmithing", art=3, tab="Professions" },
    { title="Legacy", icon="Interface\\Icons\\INV_Misc_TreasureChest_01", art=4, tab="Legacy" },
    { title="Gold Making", icon="Interface\\Icons\\INV_Misc_Coin_02", art=5, tab="Gold Making" },
    { title="Exploration", icon="Interface\\Icons\\INV_Misc_Map_01", art=1, tab="Exploration" },
}
local function run(fn)
    if not fn then return end
    local ok, err = pcall(fn)
    if not ok and ns.Modules.Diagnostics then ns.Modules.Diagnostics:Error("Dashboard action", err) end
end
local function value(k, default)
    local v = db:Get(k)
    if v == nil then return default end
    return v
end
local function safeGuide(id)
    local guide = ns.Modules.Guides:GetGuide(id)
    if guide and (not id or guide.id == id) then return guide end
end

function UI:MakeWindow()
    if self.frame then return end
    self.currentTab = "Dashboard"
    self.widgets = {}
    self.handlers = {}
    local window = CreateFrame("Frame", "WayForthWindow", UIParent)
    window:SetSize(value("dashboardWidth", 900), value("dashboardHeight", 660))
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetMovable(true)
    window:SetResizable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    if window.SetResizeBounds then window:SetResizeBounds(720, 600, 1400, 950)
    elseif window.SetMinResize then window:SetMinResize(720, 600) end
    window:SetPoint("CENTER", UIParent, "CENTER", value("windowX", 0), value("windowY", 0))
    window:SetScale(value("uiScale", 1))
    theme:Panel(window, theme.navy, theme.gold)
    self.frame = window

    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", window, "TOPLEFT", 2, -2)
    header:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
    header:SetHeight(69)
    theme:Panel(header, theme.panel)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() if not value("lockWindow", false) then window:StartMoving() end end)
    header:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local x, y = window:GetCenter()
        if cx and x then db:Set("windowX", x - cx) end
        if cy and y then db:Set("windowY", y - cy) end
    end)
    local emblem = theme:Compass(header, 43)
    emblem:SetPoint("LEFT", header, "LEFT", 16, 0)
    local brand = theme:Text(header, "WAYFORTH", 26, theme.gold)
    brand:SetPoint("TOPLEFT", header, "TOPLEFT", 69, -10)
    local tag = theme:Text(header, "YOUR ADVENTURE, YOUR WAY", 10, theme.teal)
    tag:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 2, -1)
    local version = theme:Text(header, "FOREVER  |  v" .. (ns.version or "1.0"), 10, theme.muted)
    version:SetPoint("RIGHT", header, "RIGHT", -111, 0)
    local settings = theme:Button(header, 36, 30, "", function() UI:ShowTab("Settings") end, "quiet")
    settings:SetPoint("RIGHT", header, "RIGHT", -58, 0)
    local gear = theme:Gear(settings, 19)
    gear:SetPoint("CENTER", settings, "CENTER")
    local close = theme:Button(header, 34, 30, "X", function() UI:Hide() end, "quiet")
    close:SetPoint("RIGHT", header, "RIGHT", -14, 0)

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -82)
    sidebar:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 12, 36)
    sidebar:SetWidth(172)
    theme:Panel(sidebar, theme.panel)
    self.navigation = {}
    for i, title in ipairs(NAV) do
        local idx, page = i, title
        local button = theme:Button(sidebar, 156, 38, title, function() UI:ShowTab(page) end, "quiet")
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -12 - (idx - 1) * 49)
        local icon = button:CreateTexture(nil, "ARTWORK")
        if title == "Settings" then
            icon:SetTexture(theme.artAtlas)
            icon:SetTexCoord(theme:ArtCoords(6))
        else
            icon:SetTexture(NAV_ICONS[title] or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", button, "LEFT", 13, 0)
        local font = button.label
        font:ClearAllPoints()
        font:SetPoint("LEFT", button, "LEFT", 42, 0)
        font:SetWidth(108)
        font:SetJustifyH("LEFT")
        self.navigation[title] = button
    end

    local body = CreateFrame("Frame", nil, window)
    body:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 12, 0)
    body:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -12, 36)
    theme:Panel(body, theme.panel)
    self.body = body
    self.page = CreateFrame("Frame", nil, body)
    self.page:SetPoint("TOPLEFT", body, "TOPLEFT", 15, -10)
    self.page:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -15, 10)

    local search = CreateFrame("EditBox", nil, self.page)
    search:SetSize(300, 30)
    search:SetAutoFocus(false)
    search:SetFontObject(GameFontNormal)
    if search.SetTextInsets then search:SetTextInsets(9, 9, 0, 0) end
    theme:Panel(search, theme.panelLight)
    search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    search:SetScript("OnTextChanged", function(box, userTyped)
        if userTyped and UI.currentTab == "Guide Library" then
            UI.guideQuery = box:GetText()
            UI.guidePage = 1
            UI:Refresh()
        elseif userTyped and UI.currentTab=="Guide Search" then
            UI.stepSearchQuery=box:GetText()
            UI.stepSearchPage=1
            UI:Refresh()
            box:SetFocus()
        end
    end)
    search:Hide()
    self.searchBox = search
    self.sliders = {}

    self.footer = theme:Text(window, "", 11, theme.muted)
    self.footer:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 17, 13)

    local grip = theme:Button(window, 22, 22, "/", nil, "quiet")
    grip:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -4, 4)
    grip:SetScript("OnMouseDown", function()
        if not value("lockWindow", false) then window:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        window:StopMovingOrSizing()
        db:Set("dashboardWidth", math.floor(window:GetWidth() + 0.5))
        db:Set("dashboardHeight", math.floor(window:GetHeight() + 0.5))
        UI:Refresh()
    end)
    window:SetScript("OnSizeChanged", function()
        if UI.frame and UI.frame:IsShown() then UI:Refresh() end
    end)
    window:SetScript("OnShow", function() UI:Refresh() end)
    window:Hide()
end

function UI:ClearPage()
    for _, widget in pairs(self.widgets) do widget:Hide() end
end
function UI:Label(id, str, x, y, w, size, color)
    local widget = self.widgets[id]
    if not widget then
        widget = theme:Text(self.page, "", size or 12, color or theme.ivory)
        self.widgets[id] = widget
    end
    widget:SetText(str or "")
    widget:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
    widget:SetTextColor(unpack(color or theme.ivory))
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetWidth(math.max(w or 100, 30))
    widget:Show()
    return widget
end
function UI:Button(id, str, x, y, w, h, action, primary)
    local widget = self.widgets[id]
    if not widget then
        widget = theme:Button(self.page, w, h, str, function() run(UI.handlers[id]) end, primary and "primary" or "quiet")
        self.widgets[id] = widget
    end
    self.handlers[id] = action
    widget:SetLabel(str)
    widget:SetSize(w, h)
    widget.label:SetSize(math.max(20, w - 12), math.max(16, h - 6))
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:Show()
    return widget
end
-- Dashboard cards MUST be textures in the page's BACKGROUND layer, not child
-- Frames. WoW renders child frames above parent FontStrings regardless of creation
-- order; the old frame-based cards obscured text and artwork on the live client.
function UI:Surface(id, x, y, w, h, accent)
    local widget = self.widgets[id]
    if not widget then
        widget = self.page:CreateTexture(nil, "BACKGROUND", nil, 1)
        self.widgets[id] = widget
        for i = 1, 4 do
            self.widgets[id .. "_edge_" .. i] = self.page:CreateTexture(nil, "BORDER", nil, 1)
        end
    end
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetSize(math.max(1,w), math.max(1,h))
    local tone = accent and theme.elevated or theme.panelLight
    widget:SetColorTexture(unpack(tone))
    widget:Show()
    local color = accent and theme.gold or theme.border
    for i = 1, 4 do
        local edge = self.widgets[id .. "_edge_" .. i]
        edge:ClearAllPoints()
        edge:SetColorTexture(unpack(color))
        if i == 1 then
            edge:SetPoint("TOPLEFT", widget, "TOPLEFT")
            edge:SetSize(w, 1)
        elseif i == 2 then
            edge:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT")
            edge:SetSize(w, 1)
        elseif i == 3 then
            edge:SetPoint("TOPLEFT", widget, "TOPLEFT")
            edge:SetSize(1, h)
        else
            edge:SetPoint("TOPRIGHT", widget, "TOPRIGHT")
            edge:SetSize(1, h)
        end
        edge:Show()
    end
    return widget
end
-- Invisible click target over a category card; highlights without obscuring art.
function UI:Hit(id, x, y, w, h, callback)
    local widget = self.widgets[id]
    if not widget then
        widget = CreateFrame("Button", nil, self.page)
        local glow = widget:CreateTexture(nil, "HIGHLIGHT")
        glow:SetAllPoints(widget)
        glow:SetColorTexture(0.22, 0.72, 0.85, 0.10)
        widget:SetHighlightTexture(glow)
        widget:SetScript("OnClick", function() run(UI.handlers[id]) end)
        self.widgets[id] = widget
    end
    self.handlers[id] = callback
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetSize(w,h)
    widget:Show()
end
function UI:Portrait(id, x, y, size)
    local portrait = self.widgets[id]
    if not portrait then
        portrait = self.page:CreateTexture(nil, "ARTWORK")
        self.widgets[id] = portrait
    end
    portrait:ClearAllPoints()
    portrait:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    portrait:SetSize(size,size)
    if type(SetPortraitTexture) == "function" then
        local ok = pcall(SetPortraitTexture, portrait, "player")
        if not ok then portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
    else
        portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    portrait:Show()
end
function UI:Icon(id, texture, x, y, w, h)
    local widget = self.widgets[id]
    if not widget then
        widget = self.page:CreateTexture(nil, "ARTWORK")
        self.widgets[id] = widget
    end
    widget:SetTexture(texture)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetSize(w, h)
    widget:Show()
    return widget
end
-- Atlas artwork is a BORDER-level texture so it sits above card surfaces
-- but below legible OVERLAY text and custom clickable controls.
function UI:Art(id, index, x, y, w, h)
    local widget = self.widgets[id]
    if not widget then
        widget = self.page:CreateTexture(nil, "BORDER", nil, 0)
        self.widgets[id] = widget
    end
    widget:SetTexture(theme.artAtlas)
    widget:SetTexCoord(theme:ArtCoords(index))
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetSize(w,h)
    widget:Show()
    return widget
end

function UI:ArtShade(id, x, y, w, h)
    local widget = self.widgets[id]
    if not widget then
        widget = self.page:CreateTexture(nil, "ARTWORK", nil, -1)
        self.widgets[id] = widget
    end
    widget:SetColorTexture(0.027, 0.055, 0.08, 0.91)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, -y)
    widget:SetSize(w,h)
    widget:Show()
end

function UI:Title(title, subtitle, width)
    self:Label("pageTitle", title, 7, 3, width - 14, 21, theme.gold)
    self:Label("pageSubtitle", subtitle or "", 7, 33, width - 14, 11, theme.muted)
end
function UI:GuideRow(prefix, id, x, y, width)
    local guide = safeGuide(id)
    if not guide then return end
    local status = ns.Modules.Guides:Status(id)
    local favorite = ns.Modules.Guides:IsFavorite(id)
    self:Button(prefix .. "open", (guide.zone or guide.title):sub(1, 37), x, y, width - 90, 28,
        function() UI.selectedGuideId = id; UI:ShowTab("Guide Details") end)
    self:Button(prefix .. "star", favorite and "* Saved" or "+ Fav", x + width - 85, y, 80, 28,
        function() ns.Modules.Guides:ToggleFavorite(id); UI:Refresh() end)
    local compactStatus = status == "In Progress" and "Active"
        or status == "Not Started" and "New" or status
    -- Dashboard rows have limited width; keep their metadata on one line so
    -- it cannot run into the next guide when the window is resized.
    local meta = guide.levelMin and ("Levels "..guide.levelMin.."-"..(guide.levelMax or "?"))
        or guide.isProfession and "Profession" or (guide.faction or "Shared")
    local details = self:Label(prefix .. "status", meta .. "  |  " .. compactStatus,
        x + 8, y + 29, width - 16, 10, theme.muted)
    if details.SetWordWrap then details:SetWordWrap(false) end
end
-- Rich Guide Library row, deliberately separate from the compact dashboard lists.
function UI:LibraryCard(prefix, id, x, y, width)
    local guide = safeGuide(id)
    if not guide then return end
    local guides = ns.Modules.Guides
    local state = guides:GetProgress(id)
    local status = guides:Status(id)
    local active = ns.char and ns.char.activeGuide == id
    local favorite = guides:IsFavorite(id)
    local steps = guides:GetSteps(id)
    local done = 0
    if state and state.completed then
        for index, step in ipairs(steps) do
            if state.completed[step.id or index] then done=done+1 end
        end
    end
    self:Surface(prefix.."card", x, y, width, 53, active)
    local zephras = (guide.zone or guide.title or ""):find("Zephras",1,true)
    self:Art(prefix.."art", zephras and 1 or 2, x+5, y+5, 45, 43)
    self:Label(prefix.."title", guide.title or guide.zone or "Guide",
        x+61, y+7, width-253, 13, theme.ivory)
    local meta = tostring(guide.continent or "Starter Zones")
    if guide.levelMin then
        meta = meta .. (guide.levelRangeEstimate and "  |  Est. levels " or "  |  Levels ") .. guide.levelMin .. "-" .. (guide.levelMax or "?")
    end
    if guide.testingOnly then meta = meta .. (guide.limitedData and "  |  LIMITED DATA" or "  |  SOURCE TEST") end
    self:Label(prefix.."meta", meta, x+61, y+29, width-250, 10, theme.muted)
    self:Label(prefix.."status", active and "ACTIVE" or status,
        x+width-184, y+8, 113, 10, active and theme.teal
        or (status == "Completed" and theme.green or theme.muted))
    if done > 0 and #steps > 0 then
        local base = self:Surface(prefix.."progressBg", x+width-182, y+37, 105, 4)
        base:SetColorTexture(0.14,0.22,0.28,1)
        local fill=self:Surface(prefix.."progress",x+width-182,y+37,
            math.max(2,105*done/#steps),4)
        fill:SetColorTexture(unpack(theme.teal))
    end
    -- Whole card opens details; Favorites remains an independent action.
    self:Hit(prefix.."open",x+1,y+1,width-79,51,function()
        UI.selectedGuideId=id
        UI:ShowTab("Guide Details")
    end)
    self:Button(prefix.."fav",favorite and "Saved" or "+ Fav",
        x+width-70,y+12,63,30,function()
            guides:ToggleFavorite(id)
            UI:Refresh()
        end)
end

function UI:RecentIds()
    local result = {}
    for _, id in ipairs(ns.char and ns.char.recentGuides or {}) do
        if safeGuide(id) then result[#result + 1] = id end
    end
    return result
end
function UI:FavoriteIds()
    local result = {}
    for id, yes in pairs(ns.char and ns.char.favorites or {}) do
        if yes and safeGuide(id) then result[#result + 1] = id end
    end
    table.sort(result)
    return result
end
function UI:FilterGuides()
    local result, view = {}, self.guideView or "near"
	local list = ns.Modules.SmartRoutes:ListGuides(view == "professions" and "professions" or view == "all" and "all" or nil)
    local level = UnitLevel and UnitLevel("player") or 1
    local search = (self.guideQuery or ""):lower()
    for _, guide in ipairs(list) do
        local region = guide.continent or ""
        local name = ((guide.title or "") .. " " .. (guide.zone or "") .. " " .. region):lower()
        local accept = view == "all"
            or view == "near" and not guide.isProfession and guide.levelMin and guide.levelMax and level >= guide.levelMin - 2 and level <= guide.levelMax + 2
            or view == "professions" and guide.isProfession
            or view == "starters" and (region == "Starter Zones"
                or ((guide.levelMin or 1) <= 5 and (guide.levelMax or 999) <= 15))
            or view == "kalimdor" and region == "Kalimdor"
            or view == "eastern" and region == "Eastern Kingdoms"
        if (accept or (view == "near" and not guide.levelMin and not guide.isProfession)) and (search == "" or name:find(search, 1, true)) then
            result[#result + 1] = guide
        end
    end
    if view == "near" and #result == 0 and search == "" then
        self.guideView = "all"
        return self:FilterGuides()
    end
    table.sort(result, function(a,b)
        local active = ns.char and ns.char.activeGuide
        if a.id == active then return true end
        if b.id == active then return false end
        local amin, bmin = a.levelMin or 1, b.levelMin or 1
        local amax, bmax = a.levelMax or amin, b.levelMax or bmin
        if view == "near" then
            local ad = level < amin and amin-level or level > amax and level-amax or 0
            local bd = level < bmin and bmin-level or level > bmax and level-bmax or 0
            if ad ~= bd then return ad < bd end
        end
        if amin ~= bmin then return amin < bmin end
        local left = (a.continent or "") .. (a.zone or a.title or "")
        local right = (b.continent or "") .. (b.zone or b.title or "")
        return left < right
    end)
    return result
end
function UI:ShowTab(tab)
    self.currentTab = tab or "Dashboard"
    if value("rememberTab", true) then db:Set("lastTab", self.currentTab) end
    self:Refresh()
end
function UI:SettingsToggle(id, label, key, x, y, w, onChange)
    self:Label(id .. "lbl", label, x, y + 7, w - 104, 12, theme.ivory)
    self:Button(id, value(key, false) and "ON" or "OFF", x + w - 90, y, 85, 30, function()
        db:Set(key, not value(key, false))
        if onChange then onChange() end
        UI:Refresh()
    end)
end
function UI:SettingsSlider(id, label, key, x, y, width, low, high, step, after)
    local number = value(key, low)
    self:Label(id .. "label", label .. "    " .. math.floor(number * 100 + 0.5) .. "%", x, y, width, 12, theme.ivory)
    local slider = self.sliders[id]
    if not slider then
        slider = CreateFrame("Slider", nil, self.page)
        slider:SetOrientation("HORIZONTAL")
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints(slider)
        track:SetColorTexture(0.14, 0.25, 0.31, 1)
        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        thumb:SetSize(22, 22)
        slider:SetThumbTexture(thumb)
        self.sliders[id] = slider
    end
    slider:Hide()
    slider:ClearAllPoints()
    slider:SetPoint("TOPLEFT", self.page, "TOPLEFT", x + 51, -(y + 34))
    slider:SetSize(width - 146, 7)
    slider:SetMinMaxValues(low, high)
    if slider.SetValueStep then slider:SetValueStep(step) end
    slider._loading = true
    slider:SetValue(number)
    slider._loading = false
    slider:SetScript("OnValueChanged", function(control, n)
        if control._loading then return end
        n = math.floor(math.min(high, math.max(low, n)) * 100 + 0.5) / 100
        db:Set(key, n)
        local caption = UI.widgets[id .. "label"]
        if caption then caption:SetText(label .. "    " .. math.floor(n*100+0.5) .. "%") end
        if after then after(n) end
    end)
    slider:Show()
    local function nudge(delta)
        slider:SetValue(math.min(high, math.max(low, value(key,low) + delta)))
    end
    self:Button(id .. "minus", "-", x, y + 23, 42, 28, function() nudge(-step) end)
    self:Button(id .. "plus", "+", x + width - 85, y + 23, 42, 28, function() nudge(step) end)
end

function UI:RefreshFooter()
    if not self.footer then return end
    local guides = ns.Modules.Guides
    local guide = guides:GetGuide()
    local sync = guides.syncStatus
    local status
    if not guide then
        status = "Select a guide to sync quests"
    elseif not sync or sync.guideId ~= guide.id then
        status = "Waiting for a quest check"
    elseif sync.matched == 0 then
        status = "No matching quests"
    else
        status = sync.matched .. (sync.matched == 1 and " quest matched" or " quests matched")
        if sync.completed > 0 then
            status = status .. "  |  " .. sync.completed ..
                (sync.completed == 1 and " step completed" or " steps completed")
        end
    end
    local prefix = value("guidePaused", false) and "Guide paused  |  " or ""
    self.footer:SetText(prefix .. "Quest sync: " .. status)
end

function UI:StepPreview(instructions,width)
    if not self.stepPreviewScroll then
        local scroll=CreateFrame("ScrollFrame",nil,self.page)
        local content=CreateFrame("Frame",nil,scroll)
        local text=theme:Text(content,"",13,theme.ivory)
        text:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
        text:SetWordWrap(true)
        scroll:SetScrollChild(content)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel",function(frame,delta)
            local maximum=math.max(0,content:GetHeight()-frame:GetHeight())
            frame:SetVerticalScroll(math.max(0,math.min(maximum,frame:GetVerticalScroll()-delta*26)))
        end)
        self.stepPreviewScroll,self.stepPreviewContent,self.stepPreviewText=scroll,content,text
    end
    local scroll,content,text=self.stepPreviewScroll,self.stepPreviewContent,self.stepPreviewText
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",self.page,"TOPLEFT",10,-148)
    scroll:SetSize(width-20,208)
    text:SetWidth(width-28)
    text:SetText(instructions)
    content:SetSize(width-20,math.max(1,text:GetStringHeight()+8))
    scroll:SetVerticalScroll(0)
    scroll:Show()
end

function UI:Refresh()
    if not self.frame then return end
    self:RefreshFooter()
    self:ClearPage()
    if self.searchBox then self.searchBox:Hide() end
    if self.stepPreviewScroll then self.stepPreviewScroll:Hide() end
    for _, control in pairs(self.sliders or {}) do control:Hide() end
    local width = math.max(500, (self.body:GetWidth() or 700) - 30)
    local tab = self.currentTab or "Dashboard"
    local guides = ns.Modules.Guides
    local active = guides:GetGuide()
    local saved = guides:GetProgress()
    local snap = ns.Modules.Character:Get() or {}
    local fave = self:FavoriteIds()
    local recent = self:RecentIds()
    local activeTitle = active and active.title or "Select a guide"

    for _, label in ipairs(NAV) do
        local button = self.navigation[label]
        if button then
            if label == tab then button:LockHighlight() else button:UnlockHighlight() end
        end
    end

    if tab == "Dashboard" then
        local col = (width - 20) / 2
        local charX = width - 288
        self:Label("dashHeading", "Dashboard", 6, 6, width - 296, 23, theme.gold)
        self:Label("dashSubtitle", "Manage your guides, progress, and adventure.", 7, 42, width - 296, 11, theme.muted)

        -- Compact real character portrait instead of the placeholder map icon.
        self:Surface("characterCard", charX, 3, 284, 78)
        self:Portrait("characterPortrait", charX + 12, 16, 52)
        self:Label("charName", tostring(snap.displayName or snap.name or UnitName("player") or "Adventurer"),
            charX + 76, 12, 199, 15, theme.ivory)
        self:Label("charLevel", "Level " .. tostring(snap.level or "?") .. " " ..
            tostring(snap.class or ""), charX + 76, 36, 199, 11, theme.teal)
        self:Label("charZone", tostring(snap.zone or "Unknown zone"), charX + 76, 55, 199, 10, theme.muted)
        self:Hit("openCharacter", charX, 3, 284, 78, function() UI:ShowTab("Character") end)

        self:Surface("currentCard", 4, 96, width - 8, 146, true)
        local heroIndex = active and ((active.id == "zephras-alliance" or active.id == "zephras-horde") and 1 or 2) or 1
        self:Art("guideArt", heroIndex, 18, 114, 103, 102)
        self:Surface("artAccent", 17, 217, 105, 2, true)
        self:Label("currentHeader", active and active.testingOnly and "CURRENT GUIDE  |  TEST ROUTE" or "CURRENT GUIDE", 137, 110, width - 342, 10, theme.teal)
        self:Label("currentTitle", activeTitle, 137, 133, width - 346, 16, theme.ivory)
        local steps = guides:GetSteps()
        local done = 0
        for index, step in ipairs(steps) do
            if saved and saved.completed and saved.completed[step.id or index] then
                done = done + 1
            end
        end
        local percent = #steps > 0 and math.floor(100*done/#steps+0.5) or 0
        self:Label("currentStatus", "Step " .. tostring(saved and saved.current or 1) .. "/" ..
            tostring(#steps) .. "   |   " .. percent .. "% complete", 137, 167, width - 330, 11, theme.muted)
        local progressWidth = math.max(30, width - 358)
        self:Surface("currentProgressBg", 137, 201, progressWidth, 7)
        if done > 0 then
            self:Surface("currentProgressFill", 138, 202, math.max(1,(progressWidth-2)*done/#steps), 5)
            self.widgets["currentProgressFill"]:SetColorTexture(unpack(theme.teal))
        end
        self:Button("continue", "Continue Guide", width - 188, 137, 175, 38, function()
            ns.Modules.Tracker:Show()
            UI:Hide()
        end, true)
        self:Button("browse", "Guide Details", width - 188, 186, 175, 32,
            function() UI.selectedGuideId=active and active.id; UI:ShowTab("Guide Details") end)

        self:Label("catHeading", "Guide Categories", 6, 255, width - 160, 16, theme.gold)
        self:Button("browseAll", "Browse all guides  >", width - 175, 248, 166, 29,
            function() UI.guideView="all"; UI:ShowTab("Guide Library") end)
        local tileGap = 7
        local tileW = (width - tileGap * #CATEGORIES) / #CATEGORIES
        local texts = {
            "Zone & leveling guides", "Skills, recipes & routes",
            "Plan your Legacy perks", "Farming & efficient gold",
            "Discover the world",
        }
        for i, entry in ipairs(CATEGORIES) do
            local x = 4 + (i - 1) * (tileW + tileGap)
            self:Surface("catSurface" .. i, x, 287, tileW, 111)
            self:Art("catArt" .. i, entry.art, x + 1, 288, tileW - 2, 109)
            self:ArtShade("catShade" .. i, x + 1, 343, tileW - 2, 54)
            self:Label("catTitle" .. i, entry.title, x + 10, 349, tileW - 20, 14, theme.ivory)
            self:Label("catDesc" .. i, texts[i], x + 10, 374, tileW - 20, 10, theme.muted)
            self:Hit("category" .. i, x, 287, tileW, 111, function() UI:ShowTab(entry.tab) end)
        end

        local pageHeight=self.page:GetHeight() or 520
        local visibleRows=pageHeight<510 and 1 or 2
        local lowerY=visibleRows==1 and math.min(413,pageHeight-67) or 413
        local rightX = col + 16
        self:Label("faveTitle", "FAVORITES", 6, lowerY, col - 2, 14, theme.gold)
        self:Label("recentTitle", "RECENTLY USED", rightX, lowerY, col - 2, 14, theme.gold)
        local guideRowGap = 40
        for i = 1, visibleRows do
            local id = fave[i]
            if id then self:GuideRow("dashFave" .. i, id, 6, lowerY + 28 + (i-1)*guideRowGap, col - 6) end
            id = recent[i]
            if id then self:GuideRow("dashRecent" .. i, id, rightX, lowerY + 28 + (i-1)*guideRowGap, col - 6) end
        end
        if #fave == 0 then
            self:Label("emptyFave", "Star a guide to keep it here.", 10, lowerY + 33, col - 12, 11, theme.muted)
        end
        if #recent == 0 then
            self:Label("emptyRecent", "Your visited guides appear here.", rightX + 4, lowerY + 33, col - 12, 11, theme.muted)
        end

    elseif tab == "Guide Library" or tab == "Favorites" or tab == "Recently Used" then
        local faction = type(UnitFactionGroup)=="function" and UnitFactionGroup("player") or "your"
        local subtitle = tab=="Guide Library"
            and ("Routes for "..tostring(faction).." characters  |  Choose a guide to select your starting point")
            or tab=="Favorites" and "Saved routes for this character."
            or "Your recently opened routes, newest first."
        self:Title(tab,subtitle,width)
        local filters={
            {"Near My Level","near"},{"Starter Zones","starters"},
            {"Kalimdor","kalimdor"},{"Eastern Kingdoms","eastern"},{"All Zones","all"},{"Professions","professions"}
        }
        if tab=="Guide Library" then
            local filterW=math.floor((width-32)/6)
            for i,option in ipairs(filters) do
                local x=6+(i-1)*(filterW+5)
                self:Button("filter"..i,option[1],x,62,filterW,31,function()
                    UI.guideView=option[2];UI.guidePage=1;UI:Refresh()
                end)
                if (self.guideView or "near")==option[2] then
                    local accent=self:Surface("activeFilter"..i,x+2,62,filterW-4,2)
                    accent:SetColorTexture(unpack(theme.teal))
                end
            end
            if self.searchBox then
                self:Label("searchLabel","Search guides",8,110,100,11,theme.muted)
                self.searchBox:ClearAllPoints()
                self.searchBox:SetPoint("TOPLEFT",self.page,"TOPLEFT",116,-102)
                self.searchBox:SetWidth(width-125)
                self.searchBox:Show()
            end
        end
        local ids={}
        if tab=="Favorites" then
            for _,id in ipairs(fave) do ids[#ids+1]=id end
        elseif tab=="Recently Used" then
            for _,id in ipairs(recent) do ids[#ids+1]=id end
        else
            for _,guide in ipairs(self:FilterGuides()) do ids[#ids+1]=guide.id end
        end
        local firstY=tab=="Guide Library" and 164 or 94
        local pageHeight=math.max(430,self.page:GetHeight() or 520)
        local pagerY=pageHeight-39
        local perPage=math.max(3,math.min(8,math.floor((pagerY-firstY-53)/58)+1))
        local pages=math.max(1,math.ceil(#ids/perPage))
        self.guidePage=math.max(1,math.min(self.guidePage or 1,pages))
        self:Label("guideCount",tostring(#ids).." guides  |  Page "..self.guidePage.." of "..pages,
            7,tab=="Guide Library" and 142 or 69,width-14,11,theme.muted)
        for i=1,perPage do
            local id=ids[(self.guidePage-1)*perPage+i]
            if id then self:LibraryCard("library"..i,id,7,firstY+(i-1)*58,width-14) end
        end
        if #ids==0 then
            self:Surface("emptyGuidesCard",7,firstY,width-14,96)
            self:Label("emptyGuides",
                tab=="Favorites" and "No favorites yet. Select + Fav beside a guide."
                or tab=="Recently Used" and "Your selected guides will appear here."
                or "No matches. Try All Zones or another search.",
                24,firstY+30,width-44,12,theme.muted)
        end
        if self.guidePage>1 then
            self:Button("guidePrev","< Previous",7,pagerY,138,30,function()
                UI.guidePage=math.max(1,(UI.guidePage or 1)-1);UI:Refresh()
            end)
        end
        if self.guidePage<pages then
            self:Button("guideNext","Next >",width-151,pagerY,142,30,function()
                UI.guidePage=math.min(pages,(UI.guidePage or 1)+1);UI:Refresh()
            end)
        end

    elseif tab == "Professions" then
        local module=ns.Modules.ProfessionGuides
        local all=module and module:Read() or {}
        local profiles=ns.professionProfiles or {}
        local selectedId=self.selectedProfession or module and module:Suggested() or "alchemy"
        local selected
        for _,profile in ipairs(profiles) do if profile.id==selectedId then selected=profile;break end end
        selected=selected or profiles[1]
        self.selectedProfession=selected and selected.id
        if selected and ns.char and ns.char.activeGuide==("profession-"..selected.id) and module then
            module:Sync("profession-"..selected.id)
            all=module:Read()
        end
        self:Title("Profession guides", "12 skill-aware guides for WoW: Forever. Skill progress updates from your profession window.", width)
        local cols=4
        local gap=5
        local cardW=(width-20-gap*(cols-1))/cols
        for i,profile in ipairs(profiles) do
            local col=(i-1)%cols
            local row=math.floor((i-1)/cols)
            local x=6+col*(cardW+gap)
            local y=62+row*39
            local skill=all[profile.id]
            local label=profile.name
            if skill then label=label.."  "..skill.skill.."/"..skill.maxSkill end
            self:Button("professionChoice"..i,label,x,y,cardW,32,function()
                UI.selectedProfession=profile.id;UI:Refresh()
            end,profile.id==selected.id)
            if profile.id==selected.id then
                local accent=self:Surface("professionChoiceAccent"..i,x+3,y+29,cardW-6,2)
                accent:SetColorTexture(unpack(theme.teal))
            end
        end
        local current=all[selected.id]
        local guideId="profession-"..selected.id
        local saved=guides:GetProgress(guideId)
        local steps=guides:GetSteps(guideId)
        local position=saved and saved.current or 1
        local nextStep=steps[position]
        local recommendation,recommendationMessage
        if module then recommendation,recommendationMessage=module:Recommendation(selected.id) end
        local target,targetRank=50,"Journeyman"
        if current then target,targetRank=module:RouteTarget(current.skill,current.maxSkill) end
        self:Surface("professionOverview",6,190,width-12,184,true)
        self:Label("professionFocus",selected.focus,17,202,width-34,12,theme.ivory)
        self:Label("professionStatus",current and
            ("Current skill: "..current.skill.." / 300  |  Cap: "..current.maxSkill)
            or "Skill not detected yet. Open the Professions window (K) or Character Skills list once, then return here.",
            17,229,width-34,11,current and theme.teal or theme.gold)
        self:Label("professionNext",nextStep and ("Guide step "..position.."/"..#steps..": "..nextStep.title)
            or "Guide complete: skill 300 recorded.",17,257,width-34,11,theme.gold)
        local rankAction="continue Artisan"
        if current and current.maxSkill<300 then
            if current.skill>=current.maxSkill then rankAction="train "..targetRank.." now"
            elseif current.skill>=target then rankAction="check for "..targetRank.."; if unavailable, continue to cap"
            else rankAction="check for "..targetRank.." at skill "..target end
        end
        self:Label("professionTarget",current and (current.skill>=300 and "Leveling route: Complete at skill 300"
            or ("Leveling route: skill "..current.skill.." → "..target.."; "..rankAction..
                ". Make one craft per check."))
            or "Leveling route: detect skill, then set the next rank target.",17,280,width-34,11,theme.ivory)
        local gathering=selected.id=="fishing" or selected.id=="herbalism"
            or selected.id=="mining" or selected.id=="skinning"
        local routeText=recommendation and ("Next craft: "..recommendation.name.." ("..recommendation.color..")")
            or ((gathering and "Next action: " or "Next skill-up: ")..
                (recommendationMessage or "Open this profession's recipe list to calculate its next skill-up."))
        self:Label("professionRecommendation",routeText,17,303,width-34,11,recommendation and theme.teal or theme.muted)
        local reagentText=""
        if recommendation then
            local parts={}
            for _,reagent in ipairs(recommendation.reagents) do
                parts[#parts+1]=reagent.count.."x "..reagent.name.." (have "..reagent.owned..")"
            end
            reagentText="Materials for one craft: "..table.concat(parts,", ")
        end
        self:Label("professionReagents",reagentText,17,326,width-34,10,theme.ivory)
        self:Label("professionMaterials",selected.materials,17,352,width-34,10,theme.muted)
        self:Surface("professionCampCard",6,382,width-12,48)
        self:Label("professionCamp",selected.camp,17,393,width-34,10,theme.teal)
        self:Label("professionPairing","Common pairing: "..selected.pairing.."  |  Recheck after each skill-up to avoid extra crafts.",
            17,411,width-34,9,theme.muted)
        local actionY=math.max(420,(self.page:GetHeight() or 466)-43)
        local buttonW=(width-25)/2
        self:Button("startProfessionGuide",saved and "Continue "..selected.name or "Start "..selected.name.." Guide",
            7,actionY,buttonW,35,function()
                local ok,message=module:Start(selected.id)
                if not ok then ns:Print(message) elseif type(message)=="string" then ns:Print(message) end
                UI:Refresh()
            end,true)
        self:Button("browseProfessionGuides","Browse Profession Guides",14+buttonW,actionY,buttonW,35,function()
            UI.guideView="professions";UI.guidePage=1;UI:ShowTab("Guide Library")
        end)
        self:Label("professionDataNote","Recipe colors, exact materials, rank access and trainer requirements vary by character and learned recipes. Confirm each in the live profession window.",
            9,actionY-28,width-18,10,theme.muted)
    elseif tab == "Legacy" then
        local planner=ns.Modules.LegacyPlanner
        local perkData=ns.legacyProfessionPerks
        if not planner or not perkData then
            self:Title("Legacy planner", "Legacy planning data is unavailable.", width)
            return
        end
        local ranks,total,limit=planner:Read()
        self:Title("Legacy Professions planner", "Plan your character's Professions tree with the Forever Fortune perk rules.", width)
        self:Surface("legacySummary",6,49,width-12,49,true)
        self:Label("legacyPointCount",total.." / "..limit.." points allocated",18,61,220,13,theme.gold)
        self:Label("legacySaveNote","Saved to this character. Planner only; this does not spend or reset in-game Legacy points.",250,61,width-270,11,theme.muted)
        self:Button("legacyGatherPreset", "Gathering 5-point plan", 7,108,174,30,function()
            local ok,message=planner:ApplyPreset("gathering")
            if not ok then ns:Print(message) end
            UI:Refresh()
        end)
        self:Button("legacyFortunePreset", "Fortune 16-point plan", 188,108,174,30,function()
            local ok,message=planner:ApplyPreset("fortune")
            if not ok then ns:Print(message) end
            UI:Refresh()
        end,true)
        self:Button("legacyResetPlan", "Reset plan", width-113,108,106,30,function()
            planner:Reset();UI:Refresh()
        end)
        for i,perk in ipairs(planner:Perks()) do
            local y=149+(i-1)*43
            self:Surface("legacyPerkRow"..perk.id,7,y,width-14,39)
            local rank=ranks[perk.id] or 0
            self:Label("legacyPerkName"..perk.id,perk.name.."  "..rank.."/"..perk.maxRank,
                16,y+5,width-210,12,rank>0 and theme.gold or theme.ivory)
            self:Label("legacyPerkEffect"..perk.id,perk.effect,16,y+22,width-210,9,theme.muted)
            local minus=self:Button("legacyMinus"..perk.id,"-",width-92,y+6,34,27,function()
                local ok,message=planner:SetRank(perk.id,rank-1)
                if not ok then ns:Print(message) end
                UI:Refresh()
            end)
            if rank <= 0 then minus:Disable() else minus:Enable() end
            local plus=self:Button("legacyPlus"..perk.id,"+",width-50,y+6,34,27,function()
                local ok,message=planner:SetRank(perk.id,rank+1)
                if not ok then ns:Print(message) end
                UI:Refresh()
            end)
            if rank >= perk.maxRank or total >= limit then plus:Disable() else plus:Enable() end
        end
        local noteY=149+#planner:Perks()*43+8
        self:Label("legacyRulesNote","Unlocks and prerequisites match the existing Forever Fortune planner. Legacy effects and thresholds are pre-launch observations; verify them in game before making permanent choices.",
            9,noteY,width-18,10,theme.muted)
    elseif tab == "Guide Details" then
        local selected = safeGuide(self.selectedGuideId) or active
        if not selected then self:ShowTab("Guide Library"); return end
        local routing = ns.Modules.SmartRoutes
        local steps = guides:GetSteps(selected.id)
        local saved = guides:GetProgress(selected.id)
        local status = guides:Status(selected.id)
        local isCurrent = ns.char and ns.char.activeGuide == selected.id
        -- Selection is local UI state; preview never changes guide progress.
        if self.detailGuideId ~= selected.id then
            self.detailGuideId = selected.id
            self.detailMode = isCurrent and "resume" or "recommended"
        end
        local selectedMode = self.detailMode or "recommended"
        local index, explanation = routing:Preview(selected.id, selectedMode)
        local completed, skipped = 0, 0
        for i, step in ipairs(steps) do
            local key = step.id or i
            if saved and saved.completed and saved.completed[key] then completed = completed + 1 end
            if saved and saved.skipped and saved.skipped[key] then skipped = skipped + 1 end
        end
        local progress = #steps > 0 and math.floor(100 * completed / #steps + 0.5) or 0
        local location = tostring(selected.continent or "Starter Zones")
        local band = selected.levelMin and
            ((selected.levelRangeEstimate and "Estimated Levels " or "Levels ") .. tostring(selected.levelMin) .. "-" .. tostring(selected.levelMax or "?")) or "All Levels"
        local playerLevel = type(UnitLevel)=="function" and UnitLevel("player") or 1
        self:Title(selected.title or selected.zone or "Guide Details",
            location .. "  |  " .. band .. "  |  Your level " .. tostring(playerLevel), width)

        -- Featured guide overview uses the existing illustrated WayForth atlas.
        self:Surface("detailsHero", 6, 66, width-12, 133, true)
        local zoneName = tostring(selected.zone or selected.title or "")
        self:Art("detailsArt", zoneName:find("Zephras", 1, true) and 1 or 2,
            16, 76, 111, 111)
        self:Label("detailsState", selected.testingOnly and
            (selected.limitedData and "LIMITED GUIDE DATA  |  VALIDATE BEFORE USING"
                or "TEST GUIDE  |  SOURCE DATA / IN-GAME VERIFICATION REQUIRED")
            or (isCurrent and "ACTIVE GUIDE  |  " or "") .. status,
            140, 77, width-158, 11, selected.testingOnly and theme.gold
                or (isCurrent and theme.teal or theme.gold))
        local overview = selected.description or selected.travelHint
            or "Follow this route at your pace. Guide steps update from your quest progress."
        if #overview > 165 then overview = overview:sub(1,162) .. "..." end
        self:Label("detailsDescription", overview, 140, 102, width-155, 11, theme.ivory)
        self:Label("detailsProgress", "Saved step " .. tostring(saved and saved.current or 1)
            .. " of " .. tostring(#steps) .. "     |     " .. progress
            .. "% confirmed" .. (skipped > 0 and ("     |     " .. skipped .. " skipped") or ""),
            140, 157, width-155, 10, theme.muted)
        local fillWidth=math.max(30,width-161)
        local bg=self:Surface("detailsBarBg",140,181,fillWidth,6)
        bg:SetColorTexture(0.13,0.22,0.29,1)
        if completed > 0 and #steps > 0 then
            local bar=self:Surface("detailsBarFill",141,182,
                math.max(2,(fillWidth-2)*completed/#steps),4)
            bar:SetColorTexture(unpack(theme.teal))
        end

        self:Label("detailsSelectTitle", "HOW WOULD YOU LIKE TO START?", 8, 206, width-16, 13, theme.gold)
        local choices = {
            {key="recommended", title="SMART START", subtitle="Start with relevant quests for your level."},
            {key="beginning", title="FROM BEGINNING", subtitle="Follow the earliest unfinished quest step."},
            {key="resume", title="RESUME SAVED", subtitle="Return to the last saved guide position."},
        }
        local cardW=(width-32)/3
        for i,choice in ipairs(choices) do
            local x=6+(i-1)*(cardW+7)
            local modeKey=choice.key -- close over a distinct option for Lua 5.1 callbacks
            local chosen=selectedMode==modeKey
            self:Surface("detailChoiceSurface"..i,x,229,cardW,118,chosen)
            self:Label("detailChoiceIndex"..i,chosen and "SELECTED" or "OPTION "..i,
                x+12,240,cardW-24,10,chosen and theme.teal or theme.muted)
            self:Label("detailChoiceTitle"..i,choice.title,x+12,260,cardW-24,12,
                chosen and theme.gold or theme.ivory)
            self:Label("detailChoiceDesc"..i,choice.subtitle,x+12,287,cardW-24,11,theme.muted)
            self:Hit("detailChoose"..i,x+1,230,cardW-2,116,function()
                UI.detailMode=modeKey
                UI:Refresh()
            end)
        end

        -- Show exactly what the selected mode would do before starting.
        local previewName = index and steps[index] and tostring(steps[index].title or "Next quest step")
        local previewLine = index and ("Step " .. index .. ": " .. previewName)
            or (explanation or "There are no suitable available steps for this mode.")
        if #previewLine > 95 then previewLine=previewLine:sub(1,92).. "..." end
        self:Surface("detailsPreviewCard",6,358,width-12,55)
        self:Label("detailsPreviewHeading",
            index and "STARTING POINT PREVIEW" or "NO MATCHING START POINT",
            17,365,width-34,10,index and theme.teal or theme.gold)
        self:Label("detailsPreviewStep",previewLine,17,383,width-34,11,theme.ivory)
        local pageHeight=self.page:GetHeight() or 466
        local actionY=math.max(420,pageHeight-43)
        local actionW=math.max(142,math.floor((width-32)/3))
        self:Button("detailBack","Back to Library",7,actionY,actionW,35,function()
            UI:ShowTab("Guide Library")
        end)
        self:Button("detailFavorite",guides:IsFavorite(selected.id) and "Remove Favorite" or "Add Favorite",
            14+actionW,actionY,actionW,35,function()
                guides:ToggleFavorite(selected.id)
                UI:Refresh()
            end)
        local buttonX=21+2*actionW
        if index then
            local actionLabel = selectedMode=="resume" and isCurrent
                and "Continue Guide" or "Start Guide"
            self:Button("detailLaunch",actionLabel,buttonX,actionY,
                width-buttonX-7,35,function()
                    -- Re-evaluate at click time; no progress is changed by previews.
                    local ok,message=routing:Switch(selected.id,selectedMode)
                    if ok then
                        ns.Modules.Tracker:Show()
                        UI:Hide()
                    else
                        ns:Print(message or "Could not select guide.")
                        UI:Refresh()
                    end
                end,true)
        else
            self:Button("detailUnavailable","Choose Another Option",buttonX,actionY,
                width-buttonX-7,35,function() ns:Print(explanation or "No matching quest steps.") end)
        end
        -- Smart Start uses an estimated five-level threshold rather than exact XP.
        -- It never grants quest completion or clears previously saved progress.

    elseif tab == "Guide Search" then
        self:Title("Search this guide",activeTitle,width)
        if self.stepSearchGuide~=active.id then
            self.stepSearchGuide=active.id;self.stepSearchPage=1;self.stepSearchQuery=""
        end
        if self.searchBox then
            self.searchBox:ClearAllPoints()
            self.searchBox:SetPoint("TOPLEFT",self.page,"TOPLEFT",10,-80)
            self.searchBox:SetWidth(width-20)
            if self.searchBox:GetText()~=(self.stepSearchQuery or "") then self.searchBox:SetText(self.stepSearchQuery or "") end
            self.searchBox:Show()
        end
        local results=ns.Modules.GuideSearch:Find(self.stepSearchQuery)
        local pages=math.max(1,math.ceil(#results/4))
        self.stepSearchPage=math.max(1,math.min(self.stepSearchPage or 1,pages))
        self:Label("stepSearchHint",#results.." results | Quest, NPC, hub, ID or step text",10,120,width-20,11,theme.teal)
        for slot=1,4 do
            local item=results[(self.stepSearchPage-1)*4+slot]
            if item then
                local result=item
                self:Button("stepResult"..slot,result.index..". "..tostring(result.title or "Guide step"):sub(1,68),10,153+(slot-1)*58,width-20,32,function()
                    UI.stepSearchSelection=result;UI:ShowTab("Guide Step")
                end)
                self:Label("stepResultMeta"..slot,result.status.." | "..tostring(result.action or "manual").." | Quest "..tostring(result.questId or "-"),14,188+(slot-1)*58,width-28,10,theme.muted)
            end
        end
        if #results==0 then self:Label("stepNoMatches","No matching steps in this guide. Try fewer words or a quest ID.",10,170,width-20,13,theme.ivory) end
        self:Button("stepSearchPrev","Previous",10,408,110,32,function() UI.stepSearchPage=math.max(1,UI.stepSearchPage-1);UI:Refresh() end)
        self:Label("stepSearchPage",self.stepSearchPage.." / "..pages,140,416,90,12,theme.ivory)
        self:Button("stepSearchNext","Next",240,408,110,32,function() UI.stepSearchPage=math.min(pages,UI.stepSearchPage+1);UI:Refresh() end)
    elseif tab == "Guide Step" then
        local result=self.stepSearchSelection
        local step,reason=ns.Modules.GuideSearch:Resolve(result)
        self:Title("Guide step",step and step.title or "Search result unavailable",width)
        if step then
            self:Label("stepPreviewMeta","Step "..result.index.." | "..tostring(step.action or "manual").." | Quest "..tostring(step.questId or "-"),10,82,width-20,12,theme.teal)
            self:Label("stepPreviewLocation",tostring(step.hub or step.zone or active.zone or ""),10,111,width-20,12,theme.ivory)
            self:StepPreview(step.text or "No additional instructions for this step.",width)
        else self:Label("stepPreviewError",reason,10,90,width-20,13,theme.ivory) end
        self:Button("stepBackSearch","Back to Results",10,408,170,34,function() UI:ShowTab("Guide Search") end)
        self:Label("stepReadOnly","Viewing instructions only. Route and completion history are unchanged.",10,370,width-20,11,theme.muted)
    elseif tab == "Quest Recovery" then
        self:Title("Quest not offered", "Find a prerequisite or continue another active quest", width)
        local help=ns.Modules.QuestAssistance
        local proposal=help:Recovery()
        self:Label("recoveryReason",proposal.message,10,84,width-20,13,theme.ivory)
        for i,option in ipairs(proposal.options) do
            local choice=option
            self:Button("recoveryOption"..i,choice.title or "Continue quest",10,224+(i-1)*56,width-20,32,function()
                local ok,message=help:Choose(proposal,choice)
                if ok then ns.Modules.Tracker:Show();UI:Hide()
                else ns:Print(message);UI:Refresh() end
            end,true)
            self:Label("recoveryOptionReason"..i,choice.reason,14,259+(i-1)*56,width-28,10,theme.teal)
        end
        self:Button("recoveryRetry","Sync Guide Now",10,408,170,34,function()
            local _,message=guides:Sync(nil,true)
            ns:Print(message or "Guide refreshed")
            ns:Call("Tracker","Refresh");UI:Refresh()
        end)
        self:Button("recoveryReport","Report a Bug",190,408,160,34,function() ns.Modules.Diagnostics:ShowBugReport() end)
    elseif tab == "Travel Directions" then
        self:Title("Travel directions", "Authored travel steps for your selected objective", width)
        local travel=ns.Modules.Travel
        local plan=travel:Plan()
        local leg=travel:Current()
        self:Label("travelMessage",plan.message,10,84,width-20,12,theme.ivory)
        local lines={}
        for i,entry in ipairs(plan.legs) do
            local prefix=leg and travel.route.index==i and "> " or ""
            lines[#lines+1]=prefix..i..". "..string.upper(entry.kind or "travel")..": "..entry.text
        end
        self:Label("travelLegs",table.concat(lines,"\n\n"),10,145,width-20,13,theme.ivory)
        self:Button("travelStart",leg and "Next Travel Leg" or "Follow Directions",10,370,180,34,function()
            local ok,message
            if travel:Current() then ok,message=travel:Next() else ok,message=travel:Start() end
            ns:Print(message);ns:Call("Tracker","Refresh");UI:Refresh()
        end,true)
        self:Button("travelStop","Stop Travel Route",200,370,180,34,function()
            travel:Stop();ns:Call("Tracker","Refresh");UI:Refresh()
        end)
        self:Label("travelCaution","Transport and unlocated legs show instructions without an arrow. Advancing a travel leg never completes a quest.",10,420,width-20,11,theme.muted)
    elseif tab == "Settings" then
        self:Title("Settings", "Character-specific settings. Changes are saved immediately.", width)
        local sections={ "Display", "Navigation", "Guides & Routing", "Progress & Recovery", "Quest Actions" }
        self.settingsSection = self.settingsSection or "Display"
        local buttonW = (width - 22) / 5
        for i, section in ipairs(sections) do
            self:Button("settingsTab" .. i, section, 6+(i-1)*(buttonW+3), 70, buttonW, 34,
                function() UI.settingsSection=section; UI:Refresh() end)
        end
        local sec = self.settingsSection
        self:Label("settingsTitle", sec, 9, 130, width-20, 17, theme.gold)
        if sec == "Display" then
            self:SettingsSlider("guideAlpha", "Guide Window Opacity", "guideOpacity", 10, 175, width-28, 0.2, 1, 0.05,
                function() ns:Call("Tracker", "ApplyOpacity") end)
            self:SettingsToggle("lockTracker", "Lock Guide Window", "trackerLocked", 10, 258, width-28)
            self:SettingsToggle("lockDash", "Lock Dashboard", "lockWindow", 10, 304, width-28)
            self:Button("resetDisplay", "Reset Window Positions", 10, 385, 210, 34, function()
                db:Set("windowX",0);db:Set("windowY",0);db:Set("trackerX",-30);db:Set("trackerY",-235)
                UI.frame:ClearAllPoints();UI.frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
                ns:Call("Tracker","ResetPosition");UI:Refresh()
            end)
        elseif sec == "Navigation" then
            self:SettingsSlider("arrowAlpha", "Navigation Arrow Opacity", "arrowOpacity", 10, 175, width-28, 0.2, 1, 0.05,
                function() ns:Call("Navigator","UpdateDirection") end)
            self:SettingsSlider("arrowSize", "Navigation Arrow Size", "arrowScale", 10, 259, width-28, 0.6, 2, 0.1,
                function() ns:Call("Navigator","UpdateDirection") end)
            self:SettingsToggle("arrowShow", "Show Navigation Arrow", "showArrow", 10, 352, width-28,
                function() ns:Call("Navigator","UpdateDirection") end)
            self:Button("resetNav", "Reset Arrow Position", 10, 410, 210, 34, function()
                db:Set("navX",0);db:Set("navY",-110)
                local nav=ns.Modules.Navigator.frame
                if nav then nav:ClearAllPoints();nav:SetPoint("TOP",UIParent,"TOP",0,-110) end
            end)
        elseif sec == "Guides & Routing" then
            self:SettingsToggle("smartRoute", "Smart Routing", "smartRouting", 10, 178, width-28)
            self:SettingsToggle("advance", "Automatic Step Advancement", "autoAdvance", 10, 230, width-28)
            self:SettingsToggle("pause", "Pause Guide", "guidePaused", 10, 282, width-28)
            self:SettingsToggle("zones", "Smart Zone Recommendations", "zoneSuggestions", 10, 334, width-28)
            self:SettingsToggle("extras", "Show Additional Available Quests", "showAdditionalQuests", 10, 386, width-28)
            self:SettingsToggle("cleanupSideQuests", "Offer side-quest cleanup on new area", "cleanupSideQuestsOnZoneChange", 10, 438, width-28)
            self:Label("cleanupSideQuestsNote", "WayForth asks before abandoning. Story, campaign, important and non-abandonable quests are excluded.", 12, 479, width-24, 10, theme.muted)
        elseif sec == "Quest Actions" then
            self:SettingsToggle("autoAccept","Accept Active Guide Quests","autoAcceptQuests",10,178,width-28)
            self:SettingsToggle("autoTurnIn","Turn In Active Guide Quests","autoTurnInQuests",10,230,width-28)
            self:Label("questActionsHelp","Both options start OFF. Only quests in your selected guide are handled. Multiple reward choices stay manual. Hold Shift, pause the guide, or turn these options off to read and handle dialogs yourself. Combat blocks automatic interactions.",10,300,width-28,13,theme.ivory)
        else
            self:SettingsToggle("recovery", "Automatic Guide Recovery", "autoRecovery", 10, 178, width-28)
            self:SettingsToggle("recoveryNote", "Recovery Notifications", "recoveryNotifications", 10, 230, width-28)
            self:Button("syncNow", "Sync Guide Now", 10, 310, 182, 38, function()
                local _, message=guides:Sync(nil,true)
                local saved=guides:GetProgress()
                if saved and saved.awaitingQuestMatch then
                    message="A missing prerequisite has no verified pickup yet: " .. tostring(saved.recoveryReason or "Unknown")
                end
                ns:Print(message or "Sync attempted")
                ns:Call("Tracker","Refresh")
            end, true)
            self:Label("noFalseQuest", "Manual Next and Skip never mark quests completed.", 10, 379, width-24, 12, theme.muted)
            self:Button("diagnostics", "Diagnostics & Quest Audit", 10, 426, 213, 34, function()
                UI:ShowTab("Diagnostics")
            end)
        end
    elseif tab == "Map" then
        local step = guides:CurrentStep()
        self:Title("Map & Waypoints", "Current guide navigation, not a separate window.", width)
        self:Surface("mapCard", 6, 74, width-12, 190)
        self:Label("mapName", step and step.title or "No objective selected", 20, 95, width-40, 16, theme.gold)
        self:Label("mapHub", step and (step.hub or step.zone or "Quest objective") or "", 20, 133, width-40, 13, theme.ivory)
        self:Label("mapCoord", step and step.x and ("Location: " .. step.x .. ", " .. step.y) or "Waypoint may depend on in-game quest data.", 20, 175, width-40, 12, theme.muted)
        self:Button("mapReset", "Reset Navigation Target", 10, 288, 210, 34, function() ns:Call("Navigator","ResetTarget") end)
    elseif tab == "Character" then
        self:Title("Character", "Local character snapshot and route progress", width)
        self:Label("charSummary", ns.Modules.Character:Summary(), 10, 86, width-20, 13, theme.ivory)
        self:Button("refreshChar", "Refresh Character", 10, 360, 185, 34, function()
            ns.Modules.Character:Capture();UI:Refresh()
        end)
    elseif tab == "Diagnostics" then
        self:Title("Diagnostics", "Quest mapping and client compatibility", width)
        self:Label("diagInfo", (ns.Modules.Compatibility:Report() or "") .. "\n\n" ..
            (ns.Modules.Diagnostics:Recent() or ""), 10, 84, width-20, 12, theme.ivory)
        self:Button("bugReport", "Report a Bug", 210, 367, 186, 36, function()
            ns.Modules.Diagnostics:ShowBugReport()
        end)
        self:Button("audit", "Validate Quest IDs", 10, 367, 186, 36, function()
            ns:Print(ns.Modules.QuestAudit:Scan())
        end)
    else
        self:Title(tab, "Guide content is added as validated routes become available.", width)
        self:Surface("futureCard", 6, 78, width-12, 150)
        self:Label("futureText", "This category is part of the WayForth library. Verified " ..
            tab:lower() .. " routes will appear here when they are bundled with the addon.",
            22, 107, width-42, 14, theme.ivory)
        self:Button("futureBack", "Guide Library", 10, 252, 150, 36, function() UI:ShowTab("Guide Library") end)
    end
end

function UI:Show()
    self:MakeWindow()
    self.frame:Show()
    self:Refresh()
end
function UI:Hide() if self.frame then self.frame:Hide() end end
function UI:Toggle()
    self:MakeWindow()
    if self.frame:IsShown() then self:Hide()
    else self:ShowTab("Dashboard"); self:Show() end
end
function UI:Initialize()
    self:MakeWindow()
    local last = value("rememberTab", true) and value("lastTab", "Dashboard") or "Dashboard"
    self.currentTab = last
end
