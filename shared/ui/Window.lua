local _, ns = ...
local UI = { currentTab = "Dashboard", tabs = { "Dashboard", "Guides", "Map", "Character", "Professions", "Progress", "Settings", "Diagnostics" } }
ns:RegisterModule("UI", UI)

local theme = ns.Modules.Theme
local function setting(key, fallback)
    local value = ns.Modules.Database:Get(key)
    if value == nil then return fallback end
    return value
end

local function safeAction(action)
    if not action then return end
    local ok, err = pcall(action)
    if not ok then ns.Modules.Diagnostics:Error("UI action", err) end
end

function UI:MakeWindow()
    if self.frame then return end
    local window = CreateFrame("Frame", "WayForthWindow", UIParent)
    window:SetSize(790, 530)
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(frame)
        if not setting("lockWindow", false) then frame:StartMoving() end
    end)
    window:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local x, y = frame:GetCenter()
        if cx and cy and x and y then
            ns.Modules.Database:Set("windowX", x - cx)
            ns.Modules.Database:Set("windowY", y - cy)
        end
    end)
    window:SetPoint("CENTER", UIParent, "CENTER", setting("windowX", 0), setting("windowY", 0))
    window:SetScale(setting("uiScale", 1))
    theme:Panel(window, theme.navy)
    window:Hide()
    self.frame = window

    local logo = theme:Text(window, "WAYFORTH", 25, theme.gold)
    logo:SetPoint("TOPLEFT", window, "TOPLEFT", 22, -16)
    local tag = theme:Text(window, "ADDON   /   FREE CORE", 10, theme.teal)
    tag:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 2, -2)
    local status = theme:Text(window, "Offline-first  •  v" .. ns.version, 11, theme.muted)
    status:SetPoint("TOPRIGHT", window, "TOPRIGHT", -70, -26)
    local close = theme:Button(window, 32, 28, "X", function() UI:Hide() end)
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -18, -17)

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -88)
    sidebar:SetSize(176, 414)
    theme:Panel(sidebar, theme.panel)

    self.navigation = {}
    for index, title in ipairs(self.tabs) do
        local button = theme:Button(sidebar, 158, 37, title, function() UI:ShowTab(title) end)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 9, -11 - (index - 1) * 46)
        self.navigation[title] = button
    end

    local main = CreateFrame("Frame", nil, window)
    main:SetPoint("TOPLEFT", window, "TOPLEFT", 200, -88)
    main:SetSize(575, 414)
    theme:Panel(main, theme.panel)
    self.main = main

    local heading = theme:Text(main, "Dashboard", 22, theme.gold)
    heading:SetPoint("TOPLEFT", main, "TOPLEFT", 20, -18)
    self.heading = heading

    local subtitle = theme:Text(main, "", 12, theme.teal)
    subtitle:SetPoint("TOPLEFT", main, "TOPLEFT", 20, -50)
    subtitle:SetWidth(520)
    self.subtitle = subtitle

    local inner = CreateFrame("Frame", nil, main)
    inner:SetPoint("TOPLEFT", main, "TOPLEFT", 18, -82)
    inner:SetSize(539, 254)
    theme:Panel(inner, theme.panelLight)
    self.inner = inner

    local content = theme:Text(inner, "", 13, theme.ivory)
    content:SetPoint("TOPLEFT", inner, "TOPLEFT", 17, -16)
    content:SetWidth(505)
    content:SetHeight(232)
    content:SetWordWrap(true)
    self.content = content

    -- Six zone cards per page, within the EXISTING minimap dashboard.
    self.guideCards = {}
    for i = 1, 6 do
        local index = i
        local card = theme:Button(inner, 158, 30, "", function()
            local entries = UI:GuideEntries()
            local page = UI.guidePage or 1
            local entry = entries[(page - 1) * 6 + index]
            if entry then UI.selectedGuideId = entry.id; UI:Refresh() end
        end)
        local column = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        card:SetPoint("TOPLEFT", inner, "TOPLEFT", 17 + column * 169, -14 - row * 34)
        card:Hide()
        self.guideCards[i] = card
    end

    self.actions = {}
    for i = 1, 6 do
        local button = theme:Button(main, 160, 27, "", function() safeAction(UI.actionHandlers and UI.actionHandlers[i]) end)
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        button:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 18 + col * 179, 12 + row * 33)
        self.actions[i] = button
    end
    local footer = theme:Text(window, "WayForth   •   All core functionality works without a login or paid membership", 10, theme.muted)
    footer:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 12)

    window:SetScript("OnShow", function() UI:Refresh() end)
end

function UI:ShowTab(tab)
    if not self.navigation[tab] then tab = "Dashboard" end
    self.currentTab = tab
    if setting("rememberTab", true) then ns.Modules.Database:Set("lastTab", tab) end
    self:Refresh()
end

function UI:SetActions(actions)
    self.actionHandlers = {}
    for i, button in ipairs(self.actions) do
        local action = actions and actions[i]
        if action then
            button:SetLabel(action.label)
            self.actionHandlers[i] = action.run
            button:Show()
        else
            self.actionHandlers[i] = nil
            button:Hide()
        end
    end
end

-- Display recommended-level zones by default. The user can show all zones,
-- including low-level story quests, without race-locking the Alliance guides.
function UI:GuideEntries()
    local all = ns.Modules.SmartRoutes:ListGuides()
    local view = self.guideView or "near"
    if view == "all" then return all end
    local entries = {}
    local level = type(UnitLevel) == "function" and UnitLevel("player") or 1
    for _, entry in ipairs(all) do
        if view == "kalimdor" then
            if entry.continent == "Kalimdor" or entry.id == "alliance-teldrassil" then
                entries[#entries + 1] = entry
            end
        else
            local low, high = entry.levelMin, entry.levelMax
            if entry.id == "zephras-alliance" then low, high = 1, 12 end
            if low and high and not entry.isOptional
                and level >= low - 2 and level <= high + 2 then
                entries[#entries + 1] = entry
            end
        end
    end
    if #entries == 0 and view == "near" then return all end
    return entries
end

function UI:Refresh()
    if not self.frame then return end
    local tab = self.currentTab
    local text, subtitle, actions = "", "", {}
    local guide = ns.Modules.Guides
    local character = ns.Modules.Character
    local database = ns.Modules.Database
    local diagnostics = ns.Modules.Diagnostics

    for _, card in ipairs(self.guideCards) do card:Hide() end
    self.content:ClearAllPoints()
    self.content:SetPoint("TOPLEFT", self.inner, "TOPLEFT", 17, -16)
    self.content:SetHeight(232)

    if tab == "Dashboard" then
        local snap = character:Get()
        local visible = ns.Modules.Tracker.frame and ns.Modules.Tracker.frame:IsShown()
        subtitle = "Manage guides and settings here; follow quests with the compact tracker"
        text = table.concat({
            "CHARACTER",
            tostring(snap.name or "Your character") .. "  |  Level " .. tostring(snap.level or "?") .. " " .. tostring(snap.class or ""),
            "Current zone: " .. tostring(snap.zone or "Unknown"),
            "",
            "ACTIVE LEVELING GUIDE",
            guide:Summary(),
            "",
            "TRACKER",
            visible and "Running on screen" or "Hidden - open it to follow your route",
            "The guide tracker stays visible while you play.",
            "Use the minimap icon to return to this dashboard.",
            "",
            "Client: " .. (ns.client and ns.client.label or "Unknown"),
        }, "\n")
        actions = {
            { label = "Select Guide", run = function() UI.selectedGuideId = guide:GetGuide().id; UI:ShowTab("Guides") end },
            { label = "Show Tracker", run = function() ns.Modules.Tracker:Show(); UI:Hide() end },
            { label = "Settings", run = function() UI:ShowTab("Settings") end },
            { label = "Character", run = function() UI:ShowTab("Character") end },
        }
    elseif tab == "Guides" then
        subtitle = "Switch zones at any level. Choose XP-aware, story, or saved progress."
        local routes = ns.Modules.SmartRoutes
        local entries = UI:GuideEntries()
        local pages = math.max(1, math.ceil(#entries / 6))
        UI.guidePage = math.max(1, math.min(UI.guidePage or 1, pages))
        local known = false
        for _, entry in ipairs(entries) do if entry.id == UI.selectedGuideId then known = true; break end end
        if not known then
            local first = entries[(UI.guidePage - 1)*6 + 1] or entries[1]
            if first then UI.selectedGuideId = first.id end
        end
        for i, card in ipairs(self.guideCards) do
            local entry = entries[(UI.guidePage - 1) * 6 + i]
            if entry then
                local label = entry.zone or entry.title
                if label == "Moonglade" or label == "The Barrens" then label = label .. " *" end
                card:SetLabel(label)
                card:Show()
                if UI.selectedGuideId == entry.id then card:LockHighlight() else card:UnlockHighlight() end
            end
        end
        self.content:ClearAllPoints()
        self.content:SetPoint("TOPLEFT", self.inner, "TOPLEFT", 17, -91)
        self.content:SetHeight(153)
        local selected = guide:GetGuide(UI.selectedGuideId)
        local steps = guide:GetSteps(selected.id)
        local saved = guide:GetProgress(selected.id)
        local proposed, reason = routes:Preview(selected.id, "recommended")
        local preview = proposed and steps[proposed] and steps[proposed].title
            or "No suitable quest at this level; choose another zone or Story mode"
        local viewName = ({near = "Near My Level", kalimdor = "Kalimdor", all = "All Zones"})[UI.guideView or "near"] or "Near My Level"
        text = table.concat({
            selected.title .. "   [" .. viewName .. ", " .. UI.guidePage .. "/" .. pages .. "]",
            (selected.levelMin and ("Levels " .. selected.levelMin .. "-" .. selected.levelMax .. " | ") or "")
                .. #steps .. " steps | saved at " .. (saved and saved.current or 1),
            "Recommended: " .. preview,
            reason or "",
            selected.travelHint or (selected.description or ""),
            selected.contentStatus and "Source-indexed; confirm objectives in game." or "",
            "Switching preserves completed quests and never invents completion.",
        }, "\n")
        local function begin(mode)
            local ok, message = routes:Switch(UI.selectedGuideId, mode)
            if ok then
                ns.Modules.Tracker:Show()
                UI:Hide()
            else
                ns:Print(message or "Cannot switch guide")
                UI:Refresh()
            end
        end
        actions = {
            { label = "Start Guide", run = function() begin("recommended") end },
            { label = "From Beginning", run = function() begin("beginning") end },
            { label = "Resume Saved", run = function() begin("resume") end },
            { label = "< Prev Zones", run = function()
                UI.guidePage = ((UI.guidePage - 2) % pages) + 1
                local first = entries[(UI.guidePage - 1) * 6 + 1]
                if first then UI.selectedGuideId = first.id end
                UI:Refresh()
            end },
            { label = "More Zones >", run = function()
                UI.guidePage = (UI.guidePage % pages) + 1
                local first = entries[(UI.guidePage - 1) * 6 + 1]
                if first then UI.selectedGuideId = first.id end
                UI:Refresh()
            end },
            { label = (UI.guideView == "near" or UI.guideView == nil) and "Show Kalimdor"
                or UI.guideView == "kalimdor" and "Show All Zones" or "Near My Level",
              run = function()
                UI.guideView = (UI.guideView == "near" or UI.guideView == nil)
                    and "kalimdor" or UI.guideView == "kalimdor" and "all" or "near"
                UI.guidePage = 1
                UI.selectedGuideId = nil
                UI:Refresh()
              end },
        }
    elseif tab == "Map" then
        subtitle = "In-zone map pins, live quest waypoints, and safe coordinate fallback"
        local step = guide:CurrentStep()
        local where = step and step.hub or "No current objective"
        local coords = step and step.x and step.y and (step.x .. ", " .. step.y) or "Not verified for this objective"
        text = "CURRENT ROUTE DESTINATION\n\n" .. where .. "\nCoordinates: " .. coords
            .. "\n\nIn Kalimdor, authored pickup points work only after you arrive in that zone. Live quest objectives are preferred when available."
            .. "\n\nCross-zone automatic pathfinding is not implemented; check the guide travel hint."
        actions = {
            { label = "Set Map Pin", run = function() local ok, message = guide:PinCurrent(); ns:Print(message); UI:Refresh() end },
            { label = "Open Guide", run = function() UI:ShowTab("Guides") end },
        }
    elseif tab == "Character" then
        subtitle = "Character snapshot saved on this character only"
        text = character:Summary()
        actions = {
            { label = "Refresh Data", run = function() character:Capture(); UI:Refresh() end },
            { label = "See Progress", run = function() UI:ShowTab("Progress") end },
        }
    elseif tab == "Professions" then
        subtitle = "Profession skill, rank checkpoints and tailored guidance"
        local profession=ns.Modules.ProfessionGuides
        local selected=UI.selectedProfession or (profession and profession:Suggested()) or "alchemy"
        local profile
        for _,row in ipairs(ns.professionProfiles or {}) do if row.id==selected then profile=row;break end end
        local snapshot=profession and profession:Read()[selected]
        text=profile and (profile.name.."\n\n"..(snapshot and ("Skill "..snapshot.skill.." / cap "..snapshot.maxSkill) or "Open your profession window to read skill progress.").."\n\n"..profile.focus.."\n\n"..profile.method) or "Choose a profession guide from the modern dashboard."
        actions = { { label = "View Progress", run = function() UI:ShowTab("Progress") end } }
    elseif tab == "Progress" then
        local snap = character:Get()
        subtitle = "Your saved guide steps and current level"
        text = table.concat({
            "GUIDE PROGRESSION",
            guide:Summary(),
            "",
            "CHARACTER PROGRESSION",
            "Level: " .. tostring(snap.level or "?"),
            "Experience: " .. tostring(snap.xp or 0) .. " / " .. tostring(snap.xpMax or 0),
            "Zone: " .. tostring(snap.zone or "Unknown"),
            "",
            "Later: quest completion, exploration, achievements and session goals.",
        }, "\n")
        actions = {
            { label = "Current Guide", run = function() UI:ShowTab("Guides") end },
            { label = "Refresh", run = function() character:Capture(); UI:Refresh() end },
        }
    elseif tab == "Settings" then
        local page = UI.settingsPage or 1
        subtitle = page == 1 and "Dashboard and minimap preferences" or "In-game tracker and navigation pointer preferences"
        if page == 1 then
            text = table.concat({
                "GENERAL SETTINGS",
                "Minimap button: " .. (setting("showMinimap", true) and "Visible" or "Hidden"),
                "Dashboard locked: " .. (setting("lockWindow", false) and "Yes" or "No"),
                "Remember last tab: " .. (setting("rememberTab", true) and "Yes" or "No"),
                "Dashboard scale: " .. math.floor(setting("uiScale", 1) * 100 + 0.5) .. "%",
                "",
                "Left-click the minimap icon for this dashboard.",
                "Right-click it to open Settings.",
                "",
                "Tracker and arrow settings are on the next page.",
            }, "\n")
            actions = {
                { label = setting("showMinimap", true) and "Hide Map Icon" or "Show Map Icon", run = function()
                    database:Set("showMinimap", not setting("showMinimap", true)); ns:Call("Minimap", "UpdateVisibility"); UI:Refresh()
                end },
                { label = setting("lockWindow", false) and "Unlock Dashboard" or "Lock Dashboard", run = function()
                    database:Set("lockWindow", not setting("lockWindow", false)); UI:Refresh()
                end },
                { label = "Dashboard Scale +", run = function()
                    local value = setting("uiScale", 1) + 0.1
                    if value > 1.25 then value = 0.75 end
                    database:Set("uiScale", math.floor(value * 100 + 0.5) / 100)
                    UI.frame:SetScale(setting("uiScale", 1)); UI:Refresh()
                end },
                { label = setting("rememberTab", true) and "Forget Last Tab" or "Remember Tab", run = function()
                    database:Set("rememberTab", not setting("rememberTab", true)); UI:Refresh()
                end },
                { label = "Reset Dashboard", run = function()
                    database:Set("windowX", 0); database:Set("windowY", 0)
                    UI.frame:ClearAllPoints(); UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    UI:Refresh()
                end },
                { label = "Tracker Settings >", run = function() UI.settingsPage = 2; UI:Refresh() end },
            }
        else
            local open = ns.Modules.Tracker.frame and ns.Modules.Tracker.frame:IsShown()
            text = table.concat({
                "TRACKER & WAYPOINT ARROW",
                "Tracker: " .. (open and "Visible" or "Hidden"),
                "Position locked: " .. (setting("trackerLocked", false) and "Yes" or "No"),
                "Tracker scale: " .. math.floor(setting("trackerScale", 1) * 100 + 0.5) .. "%",
                "",
                "Drag the tracker and compass independently when unlocked.",
                "The arrow uses game quest waypoints or verified guide locations.",
                "When no supported waypoint exists, direction is hidden.",
                "",
                "Visibility of the guide tracker is saved per character.",
            }, "\n")
            actions = {
                { label = open and "Hide Tracker" or "Show Tracker", run = function()
                    if open then ns.Modules.Tracker:Hide() else ns.Modules.Tracker:Show() end; UI:Refresh()
                end },
                { label = setting("trackerLocked", false) and "Unlock Position" or "Lock Position", run = function()
                    database:Set("trackerLocked", not setting("trackerLocked", false)); UI:Refresh()
                end },
                { label = "Tracker Scale +", run = function()
                    local value = setting("trackerScale", 1) + 0.1
                    if value > 1.3 then value = 0.8 end
                    database:Set("trackerScale", math.floor(value * 100 + 0.5) / 100)
                    if ns.Modules.Tracker.frame then ns.Modules.Tracker.frame:SetScale(setting("trackerScale", 1)) end
                    UI:Refresh()
                end },
                { label = "Reset Positions", run = function()
                    database:Set("trackerX", -30); database:Set("trackerY", -235)
                    database:Set("navX", 0); database:Set("navY", -110)
                    local tracker = ns.Modules.Tracker.frame
                    local nav = ns.Modules.Navigator.frame
                    if tracker then tracker:ClearAllPoints(); tracker:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -235) end
                    if nav then nav:ClearAllPoints(); nav:SetPoint("TOP", UIParent, "TOP", 0, -110) end
                    UI:Refresh()
                end },
                { label = "Reset All Settings", run = function()
                    database:ResetSettings(); UI.frame:SetScale(1)
                    UI.frame:ClearAllPoints(); UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    if ns.Modules.Tracker.frame then ns.Modules.Tracker.frame:SetScale(1) end
                    ns:Call("Minimap", "UpdateVisibility"); ns:Call("Minimap", "Position")
                    UI:Refresh()
                end },
                { label = "< General", run = function() UI.settingsPage = 1; UI:Refresh() end },
            }
        end
    elseif tab == "Diagnostics" then
        subtitle = "Compatibility, safe-loading, and Forever quest ID source audit"
        local audit = ns.Modules.QuestAudit
        text = diagnostics:Summary() .. "\n\nQUEST ID AUDIT\n"
            .. (audit.summary or "Not scanned") .. "\n"
            .. "Client title matches are not proof of in-game quest availability."
            .. "\n\nRECENT EVENTS\n" .. diagnostics:Recent()
        actions = {
            { label = "Validate Quest IDs", run = function()
                ns:Print(audit:Scan()); UI:Refresh()
            end },
            { label = "Copy ID Report", run = function() audit:ShowReport() end },
            { label = "Refresh", run = function() ns:Call("Compatibility", "Detect"); UI:Refresh() end },
            { label = "Settings", run = function() UI:ShowTab("Settings") end },
        }
    end

    self.heading:SetText(tab)
    self.subtitle:SetText(subtitle)
    self.content:SetText(text)
    self:SetActions(actions)
    for key, button in pairs(self.navigation) do
        if key == tab then button:LockHighlight() else button:UnlockHighlight() end
    end
end

function UI:Show()
    self:MakeWindow()
    self.frame:Show()
end

function UI:Hide()
    if self.frame then self.frame:Hide() end
end

function UI:Toggle()
    self:MakeWindow()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
        self:ShowTab("Dashboard")
    end
end

function UI:Initialize()
    self:MakeWindow()
    local remembered = setting("rememberTab", true) and setting("lastTab", "Dashboard") or "Dashboard"
    self:ShowTab(remembered)
end
