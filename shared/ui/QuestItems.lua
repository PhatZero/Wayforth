-- Optional quest-item discovery for the Forever tracker.
-- Reads Blizzard quest-log special-item metadata; never guesses bag contents.
local _, ns = ...
local QuestItems = {}
ns:RegisterModule("QuestItems", QuestItems)

local function questIndex(questID)
    if type(questID) ~= "number" then return nil end
    local newer = C_QuestLog and C_QuestLog.GetLogIndexForQuestID
    if type(newer) == "function" then
        local ok, index = pcall(newer, questID)
        if ok and type(index) == "number" and index > 0 then return index end
    end
    if type(GetQuestLogIndexByID) == "function" then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then return index end
    end
end

function QuestItems:Find(questID)
    if type(GetQuestLogSpecialItemInfo) ~= "function" then return nil end
    local index = questIndex(questID)
    if not index then return nil end
    local ok, link, icon, charges, showWhenComplete = pcall(GetQuestLogSpecialItemInfo, index)
    if not ok or type(link) ~= "string" or link == "" then return nil end
    local ready = C_QuestLog and (C_QuestLog.ReadyForTurnIn or C_QuestLog.IsComplete)
    if type(ready) == "function" and showWhenComplete == false then
        local statusOK, isReady = pcall(ready, questID)
        if statusOK and isReady == true then return nil end
    end
    return { link = link, icon = icon, charges = charges }
end
