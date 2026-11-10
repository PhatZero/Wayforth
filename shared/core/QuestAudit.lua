-- Audit publicly sourced Forever quest IDs against title data exposed by this game client.
-- Source catalog presence is NOT live validation. Uncached titles remain unresolved.
local _, ns = ...
local Audit = { results = {}, summary = "Not scanned in this game session." }
ns:RegisterModule("QuestAudit", Audit)

local function normalize(title)
    if type(title) ~= "string" then return "" end
    return title:lower():gsub("%s*%(%d+/%d+%)", ""):gsub("%[[^%]]+%]", ""):gsub("[^%w]", "")
end
local function clientTitle(id)
    if type(C_QuestLog) == "table" and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local ok, result = pcall(C_QuestLog.GetTitleForQuestID, id)
        if ok and type(result) == "string" and result ~= "" then return result end
    end
    if type(QuestUtils_GetQuestName) == "function" then
        local ok, result = pcall(QuestUtils_GetQuestName, id)
        if ok and type(result) == "string" and result ~= "" then return result end
    end
end
function Audit:Scan()
    local expected = {}
    for _, guide in ipairs(ns.Modules.Guides:List()) do
        for _, step in ipairs(guide.steps or {}) do
            if type(step.questId) == "number" and step.sourceStatus == "public-catalog-match" then
                expected[step.questId] = step.title
            end
        end
    end
    local results, counts = {}, { total = 0, matched = 0, mismatch = 0, loaded = 0, unresolved = 0 }
    for zone, ids in pairs(ns.foreverQuestCatalog or {}) do
        for _, id in ipairs(ids) do
            counts.total = counts.total + 1
            local title = clientTitle(id)
            local status
            if not title then
                status = "unresolved"
                counts.unresolved = counts.unresolved + 1
            elseif expected[id] and normalize(expected[id]) ~= normalize(title) then
                status = "mismatch"
                counts.mismatch = counts.mismatch + 1
            elseif expected[id] then
                status = "matched"
                counts.matched = counts.matched + 1
            else
                status = "title-loaded"
                counts.loaded = counts.loaded + 1
            end
            results[#results + 1] = { id = id, zone = zone, title = title, expected = expected[id], status = status }
        end
    end
    table.sort(results, function(a,b)
        if a.zone == b.zone then return a.id < b.id end
        return a.zone < b.zone
    end)
    self.mismatchById = {}
    for _, row in ipairs(results) do
        if row.status == "mismatch" then self.mismatchById[row.id] = true end
    end
    self.results, self.counts = results, counts
    self.summary = string.format("ID catalog: %d entries | %d exact title matches | %d title only | %d mismatches | %d unavailable",
        counts.total, counts.matched, counts.loaded, counts.mismatch, counts.unresolved)
    return self.summary
end
function Audit:IsMismatched(id)
    return self.mismatchById and self.mismatchById[id] == true or false
end
function Audit:Report()
    if not self.counts then self:Scan() end
    local lines = {
        "WayForth Forever client quest ID audit",
        self.summary,
        "Loaded title is NOT proof of quest availability or location.",
        "Status,Zone,ID,Expected Title,Client Title",
    }
    for _, item in ipairs(self.results) do
        local function csv(s) return '"' .. tostring(s or ""):gsub('"', '""') .. '"' end
        lines[#lines + 1] = table.concat({
            csv(item.status), csv(item.zone), tostring(item.id), csv(item.expected), csv(item.title)
        }, ",")
    end
    return table.concat(lines, "\n")
end
function Audit:ShowReport()
    if not self.window then
        local frame = CreateFrame("Frame", "WayForthQuestAuditReport", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(710, 480)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:Hide()
        if frame.TitleText then frame.TitleText:SetText("WayForth: Quest ID Audit") end
        local note = frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
        note:SetPoint("TOPLEFT",frame,"TOPLEFT",15,-36)
        note:SetText("Select text (Ctrl+A), copy (Ctrl+C), then share the client report for validation.")
        local scroll = CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-64)
        scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-31,18)
        local editor = CreateFrame("EditBox",nil,scroll)
        editor:SetMultiLine(true)
        editor:SetAutoFocus(false)
        editor:SetFontObject(ChatFontNormal)
        editor:SetWidth(646)
        editor:SetScript("OnEscapePressed",function() frame:Hide() end)
        editor:SetScript("OnTextChanged",function(e)
            if e.SetHeight then e:SetHeight(math.max(400,e:GetNumLetters()*0.5)) end
        end)
        scroll:SetScrollChild(editor)
        self.window, self.editor = frame, editor
    end
    self.editor:SetText(self:Report())
    self.editor:HighlightText(0, 0)
    self.window:Show()
    self.editor:SetFocus()
end
