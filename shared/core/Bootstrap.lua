local addonName, ns = ...

local frame = CreateFrame("Frame")
local diagnostics = ns.Modules.Diagnostics
local function allowLegacyRerouting()
    local db = ns.Modules.Database
    return not db or db:Get("simpleStepReader") ~= true
end
local function invoke(name, method, ...)
    local ok = ns:Call(name, method, ...)
    if ok then ns.state.initialized[name] = true end
end

local function dispatch(event, ...)
    if ns.Modules.NextZone and event~="PLAYER_MONEY" and event~="PLAYER_XP_UPDATE" then ns.Modules.NextZone.cache=nil end
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= addonName or ns.state.loaded then return end
        invoke("Database", "Initialize")
        invoke("Compatibility", "Detect")
        ns.state.loaded = true
        diagnostics:Info("Bootstrap", "Addon loaded; SavedVariables initialized")
        return
    end

    if not ns.state.loaded then return end
    if event == "PLAYER_LOGIN" then
        if ns.state.loggedIn then return end
        ns.state.loggedIn = true
        invoke("Character", "Capture")
        invoke("Guides", "GetProgress")
        invoke("ProfessionGuides", "Initialize")
        invoke("QuestCleanup", "Initialize")
        ns:Call("Guides", "Sync")
        -- One-time recovery from a stale first-step cursor using a real active
        -- quest. Never run this during ordinary quest/zone updates.
        ns:Call("Guides", "ResumeOnLogin")
        if allowLegacyRerouting() then ns:Call("SmartRoutes", "Recalculate") end
        ns:Call("NextZone", "OnZoneChanged") -- Login starts a fresh settling window.
        invoke("UI", "Initialize")
        invoke("Tracker", "Initialize")
        invoke("Minimap", "Initialize")
        invoke("QuestInteractions", "Initialize")
        ns:Call("QuestLogSpace", "Notify")
        if ns.client and not ns.client.supported then
            diagnostics:Warn("Compatibility", ns.Modules.Compatibility:Report())
        end
        diagnostics:Info("Bootstrap", "Player login complete")
    elseif event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN"
        or event == "QUEST_REMOVED" or event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_UPDATE" then
        if event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" then
            ns:Call("Guides", "RecordQuestEvent", event, ...)
        end
        ns:Call("QuestLogSpace", "Notify")
        local ok, advanced = ns:Call("Guides", "Sync")
        local routeOK, rerouted
        if allowLegacyRerouting() then
            routeOK, rerouted = ns:Call("SmartRoutes", "Recalculate")
        end
        ns:Call("Navigator", "Refresh")
        local changed = (ok and advanced) or (routeOK and rerouted)
        local tracker = ns.Modules.Tracker
        local visible = tracker and tracker.frame and tracker.frame:IsShown()
        -- Repaint the hub list when quests are accepted/removed even if the
        -- route cursor stays put. Throttle repetitive log-update bursts.
        local update = changed or (visible and event ~= "QUEST_LOG_UPDATE")
        if visible and event == "QUEST_LOG_UPDATE" and type(GetTime) == "function" then
            local now = GetTime()
            if now - (ns.state.lastQuestTrackerRefresh or -10) >= 0.5 then
                update = true
                ns.state.lastQuestTrackerRefresh = now
            end
        end
        if update then
            if visible then ns:Call("Tracker", "Refresh") end
            if ns.Modules.UI.frame and ns.Modules.UI.frame:IsShown() then
                ns:Call("UI", "Refresh")
            end
        else
            ns:Call("Tracker", "RequestObjectiveRefresh")
        end
    elseif event == "QUEST_DATA_LOAD_RESULT" or event == "BAG_UPDATE_DELAYED"
        or event == "PLAYERBANKSLOTS_CHANGED" or event == "BANKFRAME_OPENED"
        or event == "BANKFRAME_CLOSED" then
        ns:Call("Tracker", "RequestObjectiveRefresh", event == "QUEST_DATA_LOAD_RESULT" and (...) or nil)
        if event ~= "QUEST_DATA_LOAD_RESULT" then
            local guide=ns.Modules.Guides:GetGuide()
            local tracker=ns.Modules.Tracker
            if guide and guide.isProfession and tracker and tracker.frame and tracker.frame:IsShown() then
                ns:Call("Tracker","RenderProfession")
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local ok,recorded=ns:Call("ProfessionGuides","RecordCraftEvent",...)
        if ok and recorded then
            ns:Call("Tracker","Refresh")
            if ns.Modules.UI and ns.Modules.UI.frame and ns.Modules.UI.frame:IsShown() then
                ns:Call("UI","Refresh")
            end
        end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
        or event == "TRADE_SKILL_LIST_UPDATE" or event == "SKILL_LINES_CHANGED" then
        ns:Call("ProfessionGuides", "Sync")
        ns:Call("ProfessionGuides", "CaptureOpenProfession")
        if ns.Modules.UI and ns.Modules.UI.frame and ns.Modules.UI.frame:IsShown() then ns:Call("UI", "Refresh") end
        local guide=ns.Modules.Guides:GetGuide()
        if guide and guide.isProfession then ns:Call("Tracker", "Refresh") end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEVEL_UP"
        or event == "PLAYER_XP_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "PLAYER_MONEY" then
        if event == "ZONE_CHANGED_NEW_AREA" then
            ns:Call("QuestCleanup", "OnZoneChanged")
            ns.state.lastAcceptedQuestID = nil -- never follow an old hub to another zone
            ns.state.lastTurnedInQuestID = nil
            ns.state.lastHubEventAt = nil
        end
        ns:Call("Character", "Capture")
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            ns:Call("NextZone", "OnZoneChanged")
        end
        local routeOK, rerouted
        if allowLegacyRerouting() and (event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA") then
            routeOK, rerouted = ns:Call("SmartRoutes", "Recalculate")
        end
        ns:Call("Navigator", "Refresh")
        if (routeOK and rerouted) or event=="PLAYER_LEVEL_UP" or event=="ZONE_CHANGED_NEW_AREA" then ns:Call("Tracker", "Refresh") end
        if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
            local step=ns.Modules.Guides:CurrentStep()
            if step and step.checkpoint then
                ns:Call("Guides","Sync")
                ns:Call("Tracker","Refresh")
            end
        end
        if event == "PLAYER_MONEY" then ns:Call("Tracker", "RequestObjectiveRefresh") end
        if ns.Modules.UI.frame and ns.Modules.UI.frame:IsShown() then ns:Call("UI", "Refresh") end
    elseif event == "PLAYER_LOGOUT" then
        ns:Call("Character", "Capture")
    end
end

-- Coalesce noisy log/watch bursts without delaying accepted/removed/turned-in events.
local pendingQuestUpdate, elapsedQuestUpdate=false,0
local elapsedZoneCheck=0
local function safelyDispatch(event, ...)
    local ok, err = pcall(dispatch, event, ...)
    if not ok then diagnostics:Error("Event " .. event, err) end
end
frame:SetScript("OnEvent", function(_, event, ...)
    if (event=="QUEST_LOG_UPDATE" or event=="QUEST_WATCH_UPDATE") and ns.state.loaded then
        pendingQuestUpdate=true
        return
    end
    if event=="QUEST_ACCEPTED" or event=="QUEST_TURNED_IN" or event=="QUEST_REMOVED" then
        pendingQuestUpdate=false;elapsedQuestUpdate=0
    end
    safelyDispatch(event, ...)
end)
frame:SetScript("OnUpdate", function(_, elapsed)
    -- One inexpensive state check per second lets a landed player see a
    -- suggestion after 30 seconds without requiring a new quest event.
    elapsedZoneCheck=elapsedZoneCheck+elapsed
    if elapsedZoneCheck>=1 then
        elapsedZoneCheck=elapsedZoneCheck%1
        if ns.state.loggedIn and ns.Modules.NextZone then
            local ok,changed=ns:Call("NextZone","Tick")
            if ok and changed then
                local tracker=ns.Modules.Tracker
                if tracker and tracker.frame and tracker.frame:IsShown() then
                    ns:Call("Tracker","Refresh")
                end
            end
        end
    end
    if not pendingQuestUpdate then return end
    elapsedQuestUpdate=elapsedQuestUpdate+elapsed
    if elapsedQuestUpdate<0.15 then return end
    pendingQuestUpdate=false;elapsedQuestUpdate=0
    safelyDispatch("QUEST_LOG_UPDATE")
end)
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
    "PLAYER_XP_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_MONEY", "PLAYER_LOGOUT",
    "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
}) do frame:RegisterEvent(event) end
-- Forever does not expose every trade-skill event found in other WoW clients.
-- Treat these as optional so an unsupported event cannot abort addon loading.
-- TRADE_SKILL_SHOW provides a compatible refresh when a profession is opened.
for _, event in ipairs({"TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE",
    "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED",
    "QUEST_WATCH_UPDATE", "QUEST_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "UNIT_SPELLCAST_SUCCEEDED"}) do
    pcall(frame.RegisterEvent, frame, event)
end
