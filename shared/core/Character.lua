local _, ns = ...
local Character = {}
ns:RegisterModule("Character", Character)

local function safely(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok and type(result) ~= "function" then return result end
    return nil
end

local function number(value, fallback)
    return type(value) == "number" and value == value and value or (fallback or 0)
end

local function trim(value)
    if type(value) ~= "string" then return nil end
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
end

local function normalizeRealm(value)
    return (trim(value) or ""):lower():gsub("[%s%-_']", "")
end

-- WoW Forever switched UnitFullName("player") from name/realm to
-- first name/surname in later 1.60.1 builds. Some early builds placed
-- "First Last" in UnitName instead. Never interpret a standard realm as
-- the surname, and never use a display-name CVar to infer identity.
function Character:ReadNames()
    local normalName, normalSecond, fullName, fullSecond
    if type(UnitName) == "function" then
        local ok, first, second = pcall(UnitName, "player")
        if ok then normalName, normalSecond = trim(first), trim(second) end
    end
    if type(UnitFullName) == "function" then
        local ok, first, second = pcall(UnitFullName, "player")
        if ok then fullName, fullSecond = trim(first), trim(second) end
    end
    local raw = normalName or fullName or "Unknown"
    local given, embeddedSurname = raw:match("^(%S+)%s+(.+)$")
    local first = given or raw
    local surname = embeddedSurname
    local forever = ns.client and ns.client.forever
    if forever and not surname then
        local realm = normalizeRealm(safely(GetRealmName))
        local normalizedRealm = normalizeRealm(safely(GetNormalizedRealmName))
        local function valid(second)
            if not second or second:find("%s") then return false end
            local lowered = normalizeRealm(second)
            return lowered ~= "" and lowered ~= normalizeRealm(first)
                and lowered ~= realm and lowered ~= normalizedRealm
        end
        -- UnitFullName is authoritative on later builds; UnitName is
        -- fallback for builds where only it returned a surname.
        if valid(fullSecond) then surname = fullSecond
        elseif valid(normalSecond) then surname = normalSecond end
    end
    local display = surname and (first .. " " .. surname) or raw
    return first, surname, display
end

function Character:Capture()
    if not ns.char then return end
    local snapshot = ns.char.snapshot
    local first, surname, display = self:ReadNames()
    local class = safely(UnitClass, "player")
    local race = safely(UnitRace, "player")
    -- Keep the legacy first-name field for save compatibility.
    snapshot.name = first
    snapshot.firstName = first
    snapshot.lastName = surname
    snapshot.displayName = display
    snapshot.realm = safely(GetRealmName) or snapshot.realm or "Unknown"
    snapshot.class = type(class) == "string" and class or snapshot.class or "Unknown"
    snapshot.race = type(race) == "string" and race or snapshot.race or "Unknown"
    snapshot.level = number(safely(UnitLevel, "player"), snapshot.level or 0)
    snapshot.xp = number(safely(UnitXP, "player"), snapshot.xp or 0)
    snapshot.xpMax = number(safely(UnitXPMax, "player"), snapshot.xpMax or 0)
    snapshot.money = number(safely(GetMoney), snapshot.money or 0)
    snapshot.zone = safely(GetZoneText) or snapshot.zone or "Unknown"
    snapshot.updatedAt = safely(time) or 0
end

function Character:Get()
    return (ns.char and ns.char.snapshot) or {}
end

function Character:FormattedMoney(money)
    money = math.max(0, math.floor(number(money)))
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

function Character:Summary()
    local s = self:Get()
    local xp = number(s.xp)
    local total = number(s.xpMax)
    local pct = total > 0 and math.min(100, math.floor(xp * 100 / total)) or 0
    return table.concat({
        tostring(s.displayName or s.name or "Unknown") .. " - Level " .. tostring(s.level or "?") .. " " .. tostring(s.race or "") .. " " .. tostring(s.class or ""),
        "Realm: " .. tostring(s.realm or "Unknown"),
        "Zone: " .. tostring(s.zone or "Unknown"),
        "XP: " .. xp .. " / " .. total .. " (" .. pct .. "%)",
        "Gold: " .. self:FormattedMoney(s.money),
        "",
        "The first release captures basic character information locally.",
        "Profession skill guides are available from the Professions tab. Inventory tracking and website export remain future work.",
    }, "\n")
end
