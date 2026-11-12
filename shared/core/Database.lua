local _, ns = ...
local Database = {}
ns:RegisterModule("Database", Database)

local DEFAULTS = {
    showMinimap = true,
    minimapAngle = 220,
    uiScale = 1,
    lockWindow = false,
    rememberTab = true,
    lastTab = "Dashboard",
    windowX = 0,
    windowY = 0,
    trackerX = -30,
    trackerY = -235,
    navX = 0,
    navY = -110,
    trackerScale = 1,
    trackerLocked = false,
    dashboardWidth = 900, dashboardHeight = 660,
    trackerWidth = 380, trackerHeight = 448,
    guideOpacity = 0.98, arrowOpacity = 1,
    arrowScale = 1, showArrow = true,
    autoAdvance = true, guidePaused = false,
    autoRecovery = true, recoveryNotifications = true,
    smartRouting = true, zoneSuggestions = true,
    showAdditionalQuests = false,
    autoAcceptQuests = false, autoTurnInQuests = false,
    cleanupSideQuestsOnZoneChange = false,
}

-- Appearance, guide controls and positions are per character, never shared between alts.
local PERSONAL = {
    uiScale=true, lockWindow=true, rememberTab=true, lastTab=true,
    windowX=true, windowY=true, trackerX=true, trackerY=true,
    navX=true, navY=true, trackerScale=true, trackerLocked=true,
    dashboardWidth=true, dashboardHeight=true, trackerWidth=true, trackerHeight=true,
    guideOpacity=true, arrowOpacity=true, arrowScale=true, showArrow=true,
    autoAdvance=true, guidePaused=true, autoRecovery=true,
    recoveryNotifications=true, smartRouting=true, zoneSuggestions=true,
    showAdditionalQuests=true,
    autoAcceptQuests=true, autoTurnInQuests=true, cleanupSideQuestsOnZoneChange=true,
}

local function safeNumber(value, default, low, high)
    if type(value) ~= "number" or value ~= value or value < low or value > high then return default end
    return value
end

function Database:Initialize()
    if type(WoWForeverDB) ~= "table" then WoWForeverDB = {} end
    if type(WoWForeverCharDB) ~= "table" then WoWForeverCharDB = {} end
    local account = WoWForeverDB
    local character = WoWForeverCharDB
    if type(account.settings) ~= "table" then account.settings = {} end
    if type(character.guideProgress) ~= "table" then character.guideProgress = {} end
    if type(character.snapshot) ~= "table" then character.snapshot = {} end
    if type(character.settings) ~= "table" then
        character.settings = {}
        -- Keep existing players' layouts on their first upgraded login.
        for key in pairs(PERSONAL) do
            if account.settings[key] ~= nil then
                character.settings[key] = account.settings[key]
            end
        end
    end
    if type(character.favorites) ~= "table" then character.favorites = {} end
    if type(character.recentGuides) ~= "table" then character.recentGuides = {} end

    -- Migration gate is deliberately conservative: unknown future data is not destroyed.
    if type(account.schemaVersion) ~= "number" then account.schemaVersion = 0 end
    if type(character.schemaVersion) ~= "number" then character.schemaVersion = 0 end
    if account.schemaVersion < ns.schemaVersion then account.schemaVersion = ns.schemaVersion end
    if character.schemaVersion < ns.schemaVersion then character.schemaVersion = ns.schemaVersion end

    for key, value in pairs(DEFAULTS) do
        if account.settings[key] == nil then account.settings[key] = value end
    end
    for key, value in pairs(DEFAULTS) do
        if PERSONAL[key] and character.settings[key] == nil then character.settings[key] = value end
    end
    local settings = account.settings
    settings.showMinimap = settings.showMinimap ~= false
    settings.lockWindow = settings.lockWindow == true
    settings.trackerLocked = settings.trackerLocked == true
    settings.rememberTab = settings.rememberTab ~= false
    settings.minimapAngle = safeNumber(settings.minimapAngle, 220, 0, 360)
    settings.uiScale = safeNumber(settings.uiScale, 1, 0.75, 1.25)
    settings.windowX = safeNumber(settings.windowX, 0, -5000, 5000)
    settings.windowY = safeNumber(settings.windowY, 0, -5000, 5000)
    settings.trackerX = safeNumber(settings.trackerX, -30, -5000, 5000)
    settings.trackerY = safeNumber(settings.trackerY, -235, -5000, 5000)
    settings.navX = safeNumber(settings.navX, 0, -5000, 5000)
    settings.navY = safeNumber(settings.navY, -110, -5000, 5000)
    settings.trackerScale = safeNumber(settings.trackerScale, 1, 0.8, 1.3)
    if type(settings.lastTab) ~= "string" then settings.lastTab = "Dashboard" end
    local personal = character.settings
    -- Correct the old beta's too-transparent, oversized default tracker.
    -- Only migrate untouched old defaults, retaining customized values.
    if personal._visualDefaultsUpdated ~= true then
        if personal.guideOpacity == 0.85 then personal.guideOpacity = 0.98 end
        if personal.trackerHeight == 480 then personal.trackerHeight = 448 end
        personal._visualDefaultsUpdated = true
    end
    personal.dashboardWidth = safeNumber(personal.dashboardWidth, 900, 720, 1400)
    personal.dashboardHeight = safeNumber(personal.dashboardHeight, 660, 600, 950)
    personal.trackerWidth = safeNumber(personal.trackerWidth, 380, 370, 700)
    personal.trackerHeight = safeNumber(personal.trackerHeight, 448, 440, 850)
    personal.guideOpacity = safeNumber(personal.guideOpacity, 0.98, 0.2, 1)
    personal.arrowOpacity = safeNumber(personal.arrowOpacity, 1, 0.2, 1)
    personal.arrowScale = safeNumber(personal.arrowScale, 1, 0.6, 2)
    ns.db, ns.char = account, character
    return true
end

function Database:Get(key)
    if PERSONAL[key] and ns.char and ns.char.settings then
        return ns.char.settings[key]
    end
    return ns.db and ns.db.settings and ns.db.settings[key]
end

function Database:Set(key, value)
    if DEFAULTS[key] == nil then return end
    if PERSONAL[key] then
        if ns.char and ns.char.settings then ns.char.settings[key] = value end
    elseif ns.db and ns.db.settings then
        ns.db.settings[key] = value
    end
end

function Database:ResetSettings()
    if not ns.db then return end
    ns.db.settings = {}
    for key, value in pairs(DEFAULTS) do ns.db.settings[key] = value end
    if ns.char and ns.char.settings then
        for key in pairs(PERSONAL) do ns.char.settings[key] = DEFAULTS[key] end
    end
end

function Database:Health()
    return type(ns.db) == "table" and type(ns.char) == "table"
        and type(ns.db.settings) == "table" and type(ns.char.guideProgress) == "table"
end
