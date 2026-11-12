local _, ns = ...
local Cleanup = {}
ns:RegisterModule("QuestCleanup", Cleanup)

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local values = { pcall(fn, ...) }
    if values[1] then return unpack(values, 2) end
end

local function protectedQuest(info, tag)
    if not info then return true end
    if info.isHeader or info.isCampaign == true or info.isStory == true
        or info.isImportant == true or info.isLegendary == true
        or info.isCalling == true or info.isBounty == true or info.isTask == true then
        return true
    end
    if (tonumber(info.campaignID) or 0) > 0 or (tonumber(info.questLineID) or 0) > 0 then
        return true
    end
    if tonumber(info.frequency) and tonumber(info.frequency) > 0 then return true end
    if tag then
        local name = tostring(tag.tagName or tag.name or tag.tag or ""):lower()
        if tonumber(tag.tagID) == 292 or name:find("important", 1, true)
            or name:find("campaign", 1, true) or name:find("story", 1, true) then
            return true
        end
    end
    return false
end

local function questInfoAt(api, index)
    local info = call(api.GetInfo, index) or call(api.GetQuestLogInfo, index)
    if type(info) == "table" then return info end
    if type(GetQuestLogTitle) == "function" then
        local title, level, tag, isHeader, isCollapsed, isComplete, frequency,
            questID, startEvent, isTask, isBounty, isStory, isHidden, campaignID, isImportant =
            call(GetQuestLogTitle, index)
        if title then
            return { title=title, questID=questID, isHeader=isHeader, frequency=frequency,
                isTask=isTask, isBounty=isBounty, isStory=isStory, isHidden=isHidden,
                campaignID=campaignID, isImportant=isImportant, tagName=tag }
        end
    end
end

function Cleanup:Candidates()
    local api = type(C_QuestLog) == "table" and C_QuestLog or {}
    local countFn = api.GetNumQuestLogEntries or GetNumQuestLogEntries
    if type(countFn) ~= "function" then return {}, false end
    local shown, total = call(countFn)
    local limit = tonumber(shown) or tonumber(total) or 0
    if limit < 1 then return {}, true end
    local result = {}
    for index = 1, limit do
        local info = questInfoAt(api, index)
        local id = info and tonumber(info.questID)
        if id and id > 0 and not protectedQuest(info, info.tagInfo) then
            local tag = call(api.GetQuestTagInfo, id)
            if not protectedQuest(info, tag) then
                local canAbandon = call(api.CanAbandonQuest, id)
                if canAbandon == true then
                    result[#result + 1] = { id=id, index=index, title=tostring(info.title or info.questName or ("Quest " .. id)) }
                end
            end
        end
    end
    table.sort(result, function(a,b) return a.index > b.index end)
    return result, true
end

local function dialogs()
    if type(StaticPopupDialogs) ~= "table" then return false end
    if StaticPopupDialogs.WAYFORTH_SIDEQUEST_CLEANUP then return true end
    StaticPopupDialogs.WAYFORTH_SIDEQUEST_CLEANUP = {
        text = "%s",
        button1 = "Abandon Side Quests",
        button2 = "Keep Quests",
        OnAccept = function()
            ns:Call("QuestCleanup", "AbandonPending")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    return true
end

function Cleanup:Initialize()
    self.lastZone = type(GetZoneText) == "function" and GetZoneText() or nil
end

function Cleanup:OnZoneChanged()
    local zone = type(GetZoneText) == "function" and GetZoneText() or nil
    if not zone or zone == "" then return end
    local previous = self.lastZone
    self.lastZone = zone
    if not previous or previous == zone then return end
    local db = ns.Modules.Database
    if not db or db:Get("cleanupSideQuestsOnZoneChange") ~= true then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return
    end
    local inInstance = call(IsInInstance)
    if inInstance then return end
    local candidates, available = self:Candidates()
    if not available or #candidates == 0 then return end
    self.pending = candidates
    self.pendingZone = zone
    if not dialogs() or type(StaticPopup_Show) ~= "function" then
        ns:Print("Side-quest cleanup is ready for " .. zone .. ". Open the quest log to review it.")
        return
    end
    local names = {}
    for i=1,math.min(#candidates, 4) do names[#names+1]=candidates[i].title end
    if #candidates > #names then names[#names+1]="and "..(#candidates-#names).." more" end
    local summary = "You entered " .. zone .. ". WayForth found " .. #candidates ..
        " abandonable side quest(s): " .. table.concat(names, "; ") ..
        ". Chapter, campaign, important and non-abandonable quests are protected. Quest progress will be lost. Abandon these quests?"
    StaticPopup_Show("WAYFORTH_SIDEQUEST_CLEANUP", summary)
end

function Cleanup:AbandonPending()
    local pending = self.pending
    self.pending = nil
    if type(pending) ~= "table" or #pending == 0 then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        ns:Print("Quest cleanup paused during combat. Change areas again after combat to review quests.")
        return false
    end
    local api = type(C_QuestLog) == "table" and C_QuestLog or {}
    local setSelected = api.SetSelectedQuest or SetSelectedQuest
    local setAbandon = api.SetAbandonQuest or SetAbandonQuest
    local abandon = api.AbandonQuest or AbandonQuest
    local canAbandon = api.CanAbandonQuest
    if type(setSelected) ~= "function" or type(setAbandon) ~= "function"
        or type(abandon) ~= "function" or type(canAbandon) ~= "function" then
        ns:Print("This Forever client does not expose the safe quest-abandon APIs WayForth needs.")
        return false
    end
    local byId = {}
    for _, item in ipairs(self:Candidates()) do byId[item.id] = item end
    local dropped = 0
    for _, item in ipairs(pending) do
        local current = byId[item.id]
        if current and call(canAbandon, item.id) == true then
            local selected = pcall(setSelected, item.id)
            if selected then
                local prepared = pcall(setAbandon)
                if prepared then
                    local ok = pcall(abandon)
                    if ok then dropped = dropped + 1 end
                end
            end
        end
    end
    ns:Print("Abandoned " .. dropped .. " reviewed side quest(s) in " .. tostring(self.pendingZone or "the new area") .. ".")
    return dropped > 0
end
