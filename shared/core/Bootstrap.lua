local addonName, ns = ...

local frame = CreateFrame("Frame")
local diagnostics = ns.Modules.Diagnostics
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
        ns:Call("Guides", "Sync")
        ns:Call("SmartRoutes", "Recalculate")
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
        local routeOK, rerouted = ns:Call("SmartRoutes", "Recalculate")
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
    elseif event == "QUEST_DATA_LOAD_RESULT" or event == "BAG_UPDATE_DELAYED" then
        ns:Call("Tracker", "RequestObjectiveRefresh", event == "QUEST_DATA_LOAD_RESULT" and (...) or nil)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEVEL_UP"
        or event == "PLAYER_XP_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "PLAYER_MONEY" then
        if event == "ZONE_CHANGED_NEW_AREA" then
            ns.state.lastAcceptedQuestID = nil -- never follow an old hub to another zone
            ns.state.lastTurnedInQuestID = nil
            ns.state.lastHubEventAt = nil
        end
        ns:Call("Character", "Capture")
        local routeOK, rerouted
        if event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA" then
            routeOK, rerouted = ns:Call("SmartRoutes", "Recalculate")
        end
        ns:Call("Navigator", "Refresh")
        if (routeOK and rerouted) or event=="PLAYER_LEVEL_UP" or event=="ZONE_CHANGED_NEW_AREA" then ns:Call("Tracker", "Refresh") end
        if event == "PLAYER_MONEY" then ns:Call("Tracker", "RequestObjectiveRefresh") end
        if ns.Modules.UI.frame and ns.Modules.UI.frame:IsShown() then ns:Call("UI", "Refresh") end
    elseif event == "PLAYER_LOGOUT" then
        ns:Call("Character", "Capture")
    end
end

-- Coalesce noisy log/watch bursts without delaying accepted/removed/turned-in events.
local pendingQuestUpdate, elapsedQuestUpdate=false,0
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
for _, event in ipairs({"QUEST_WATCH_UPDATE", "QUEST_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED"}) do
    pcall(frame.RegisterEvent, frame, event)
end
