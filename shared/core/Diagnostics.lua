local _, ns = ...
local Diagnostics = { entries = {}, maxEntries = 20 }
ns:RegisterModule("Diagnostics", Diagnostics)

local function add(self, level, source, message)
    local timeText = type(date) == "function" and date("%H:%M:%S") or "--:--:--"
    table.insert(self.entries, 1, {
        time = timeText,
        level = level,
        source = tostring(source),
        message = tostring(message):sub(1, 220),
    })
    if #self.entries > self.maxEntries then table.remove(self.entries) end
end

function Diagnostics:Info(source, message)
    add(self, "INFO", source, message)
end

function Diagnostics:Warn(source, message)
    ns.state.warning = tostring(message)
    add(self, "WARN", source, message)
end

function Diagnostics:Error(source, message)
    ns.state.errors = ns.state.errors + 1
    ns.state.warning = tostring(source) .. ": " .. tostring(message)
    add(self, "ERROR", source, message)
end

function Diagnostics:Summary()
    local client = ns.client or {}
    local health = ns:Call("Database", "Health")
    local databaseHealthy = health and ns.Modules.Database:Health() or false
    local lines = {
        "Addon version: " .. ns.version,
        "Target interface: " .. ns.interfaceTarget,
        "Client: " .. (client.label or "Unknown") .. " " .. (client.version or ""),
        "Client interface: " .. tostring(client.interface or "Unknown"),
        "Client build: " .. tostring(client.build or "Unknown"),
        "API: " .. (client.modern and "Modern detected" or "Modern API not verified"),
        "Compatibility: " .. ns.Modules.Compatibility:Report(),
        "SavedVariables: " .. (databaseHealthy and "Healthy" or "Unavailable"),
        "Lua errors caught: " .. tostring(ns.state.errors),
        "Loaded modules: " .. tostring(self:ModuleCount()),
    }
    if ns.state.warning then table.insert(lines, "Last warning: " .. ns.state.warning:sub(1, 85)) end
    return table.concat(lines, "\n")
end

function Diagnostics:ModuleCount()
    local count = 0
    for _ in pairs(ns.Modules) do count = count + 1 end
    return count
end

function Diagnostics:Recent()
    local lines = {}
    for i = 1, math.min(5, #self.entries) do
        local entry = self.entries[i]
        table.insert(lines, entry.time .. "  " .. entry.level .. "  " .. entry.source .. "  " .. entry.message)
    end
    return #lines > 0 and table.concat(lines, "\n") or "No diagnostic events yet."
end

local function read(fn, ...)
    if type(fn)~="function" then return nil end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
local function plain(value)
    -- Reports are plain copyable text, not executable chat links or markup.
    return tostring(value or "unknown"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|", "/")
end
function Diagnostics:BugReport()
    local guides=ns.Modules.Guides
    local guide=guides and guides:GetGuide()
    local step,index
    if guides then step,index=guides:CurrentStep() end
    local saved=guides and guides:GetProgress()
    local nav=ns.Modules.Navigator
    if nav and nav.overrideIndex and guides then
        index=nav.overrideIndex
        step=guides:GetSteps()[index]
    end
    local mapAPI=type(C_Map)=="table" and C_Map or {}
    local map=read(mapAPI.GetBestMapForUnit,"player")
    local position=map and read(mapAPI.GetPlayerMapPosition,map,"player")
    local x,y
    if position then
        if type(position.GetXY)=="function" then x,y=read(position.GetXY,position)
        else x,y=position.x,position.y end
    end
    local coordinates=type(x)=="number" and type(y)=="number" and string.format("%.2f, %.2f",x*100,y*100) or "unavailable"
    local client=ns.client or {}
    local lines={
        "WayForth bug report", "Version: "..plain(ns.version),
        "Client: "..plain(client.label).." | build "..plain(client.build).." | interface "..plain(client.interface),
        "Guide: "..plain(guide and guide.title).." ["..plain(guide and guide.id).."]",
        "Step: "..plain(index).." ["..plain(step and step.id).."] | "..plain(step and step.action),
        "Objective: "..plain(step and step.title), "Quest ID: "..plain(step and step.questId),
        "Player map: "..plain(map).." | coordinates: "..coordinates,
        "Target: "..plain(step and step.mapId).." | "..plain(step and step.x)..", "..plain(step and step.y),
        "Route mode: "..plain(saved and saved.routeMode),
        "Recovery: "..plain(saved and saved.recoveryReason),
    }
    local progress=ns.Modules.QuestProgress
    local snapshot=step and progress and progress:Get(step.questId)
    if snapshot then
        lines[#lines+1]="Quest status: "..plain(snapshot.status)
        for _,row in ipairs(snapshot.rows or {}) do lines[#lines+1]="- "..plain(row.display) end
    end
    if nav and nav.NavigationFeedback then lines[#lines+1]="Navigation: "..plain(nav:NavigationFeedback(step)) end
    lines[#lines+1]="\nWhat happened:\n\nWhat I expected:\n\nSteps to reproduce:\n"
    return table.concat(lines,"\n")
end

function Diagnostics:ShowBugReport()
    if not self.reportFrame then
        local theme=ns.Modules.Theme
        local frame=CreateFrame("Frame","WayForthBugReport",UIParent)
        frame:SetSize(580,440)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)
        theme:Panel(frame,theme.navy,theme.gold)
        local title=theme:Text(frame,"REPORT A BUG",16,theme.gold)
        title:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-14)
        local hint=theme:Text(frame,"Ctrl+C to copy. Paste into a GitHub issue or this chat.",11,theme.ivory)
        hint:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-43)
        local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-69)
        scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-38,55)
        local edit=CreateFrame("EditBox",nil,scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(GameFontHighlightSmall)
        edit:SetWidth(520)
        edit:SetHeight(300)
        edit:SetScript("OnEscapePressed",function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        local close=theme:Button(frame,90,30,"Close",function() frame:Hide() end,"quiet")
        close:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-16,12)
        local select=theme:Button(frame,120,30,"Select All",function() edit:SetFocus();edit:HighlightText() end)
        select:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,12)
        frame:SetScript("OnHide",function() edit:ClearFocus() end)
        self.reportFrame,self.reportEdit,self.reportScroll=frame,edit,scroll
    end
    self.reportEdit:SetText(self:BugReport())
    self.reportFrame:Show()
    self.reportScroll:SetVerticalScroll(0)
    self.reportEdit:SetFocus()
    self.reportEdit:HighlightText()
end
