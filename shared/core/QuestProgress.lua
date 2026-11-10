-- Read the current character's quest log. Objective counters are never saved.
local _, ns = ...
local Progress = {}
ns:RegisterModule("QuestProgress", Progress)

local function public(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return nil end
    end
    return value
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return public(a), public(b), public(c) end
end

local function number(value)
    value = public(value)
    if type(value) == "number" and value == value and value > -math.huge and value < math.huge then
        return value
    end
end

local function text(value)
    value = public(value)
    if type(value) == "string" and value ~= "" then return value end
end

local function normalize(raw, index, questID)
    raw = public(raw)
    if type(raw) ~= "table" then return nil end
    local caption = text(raw.text)
    local current, required = number(raw.numFulfilled), number(raw.numRequired)
    local finished = public(raw.finished)
    local kind = text(raw.type)
    if not caption and not current and finished == nil then return nil end
    local row = {
        index = index, kind = kind,
        finished = finished == true or finished == 1,
        current = current and math.max(0, current), required = required,
        text = caption or ("Objective " .. index),
    }
    if kind == "progressbar" then
        local percent = number(call(GetQuestProgressBarPercent, questID))
        if percent then row.percent = math.max(0, math.min(100, percent)) end
    end
    row.display = row.text
    if row.percent then
        if not row.text:find("%%") then
            row.display = row.text .. " (" .. math.floor(row.percent) .. "%)"
        end
    elseif row.current and row.required and row.required > 0 then
        if not row.text:find("%d+%s*/%s*%d+") then
            row.display = row.text .. string.format(" (%d/%d)", row.current, row.required)
        end
    end
    return row
end

local function modernRows(api, questID)
    local raw = call(api.GetQuestObjectives, questID)
    if type(raw) ~= "table" then return nil end
    local rows = {}
    for index = 1, math.min(#raw, 100) do
        local ok, row = pcall(normalize, raw[index], index, questID)
        if ok and row then rows[#rows + 1] = row end
    end
    return rows
end

local function legacyRows(logIndex, questID)
    if not logIndex then return nil end
    local count = number(call(GetNumQuestLeaderBoards, logIndex))
    if not count then return nil end
    local rows = {}
    for index = 1, math.min(math.max(0, math.floor(count)), 100) do
        local caption, kind, finished = call(GetQuestLogLeaderBoard, index, logIndex)
        caption = text(caption)
        if caption then
            local current, required = caption:match("(%d+)%s*/%s*(%d+)")
            local row = normalize({text = caption, type = kind, finished = finished,
                numFulfilled = tonumber(current), numRequired = tonumber(required)}, index, questID)
            if row then rows[#rows + 1] = row end
        end
    end
    return rows
end

function Progress:Get(questID)
    questID = number(questID)
    if not questID or questID < 1 or questID ~= math.floor(questID) then return nil end
    local api = type(C_QuestLog) == "table" and C_QuestLog or {}
    local index = number(call(api.GetLogIndexForQuestID, questID))
    if not index or index <= 0 then index = number(call(GetQuestLogIndexByID, questID)) end
    if index and index <= 0 then index = nil end
    local active = call(api.IsOnQuest, questID) == true or index ~= nil
    local result = {questID = questID, active = active, rows = {}, completed = 0}
    if not active then
        local pending = ns.state and ns.state.acceptedQuestIDs and ns.state.acceptedQuestIDs[questID]
        local turnedIn = call(api.IsQuestFlaggedCompleted, questID) == true
            or call(IsQuestFlaggedCompleted, questID) == true
            or ns.char and ns.char.turnedInQuests and ns.char.turnedInQuests[questID] == true
        if pending then
            result.state, result.status = "loading", "Waiting for your quest log to update."
        elseif turnedIn then
            result.state, result.status = "turnedIn", "Quest turned in."
        else
            result.state, result.status = "inactive", "Quest not in your log. Use Sync to find its pickup."
        end
        return result
    end

    result.ready = call(api.ReadyForTurnIn, questID) == true or call(api.IsComplete, questID) == true
    result.failed = call(api.IsFailed, questID) == true
    if result.failed then result.ready = false end
    -- Guard the entire read as well as each row: older builds can reject the
    -- call, and restricted values must not be parsed or compared by the addon.
    local ok, rows = pcall(modernRows, api, questID)
    if not ok or not rows or #rows == 0 then
        local legacyOK, fallback = pcall(legacyRows, index, questID)
        if legacyOK and fallback and #fallback > 0 then rows = fallback end
    end
    result.rows = type(rows) == "table" and rows or {}
    for _, row in ipairs(result.rows) do
        if row.finished then result.completed = result.completed + 1 end
    end
    if result.failed then
        result.state, result.status = "failed", "Quest failed. Check your quest log."
    elseif result.ready then
        result.state, result.status = "ready", "Ready to turn in."
    elseif #result.rows > 0 then
        result.state = "active"
        result.status = "LIVE PROGRESS  |  " .. result.completed .. "/" .. #result.rows .. " complete"
    else
        result.state, result.status = "unavailable", "Waiting for objective details. Check your quest log."
    end
    -- Counts/finished rows are display information. Only the client's actual
    -- ready/completed flags may advance the existing guide engine.
    return result
end
