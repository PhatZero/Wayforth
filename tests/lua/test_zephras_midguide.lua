-- Level-10 character entering the Zephras guide after questing independently.
-- Do not rely on inferred quest availability or falsely complete earlier steps.
local ns = {
    Modules = {}, state = {},
    char = { activeGuide = "zephras-alliance", guideProgress = {} },
    starterGuides = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
function ns:Call() return true end
local level, faction = 10, "Alliance"
local accepted, ready, turnedIn = { [999001] = true }, {}, {}
UnitLevel = function() return level end
UnitFactionGroup = function() return faction end
UnitClass = function() return "Mage", "MAGE" end
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return turnedIn[id] == true end,
    IsOnQuest = function(id) return accepted[id] == true end,
    GetLogIndexForQuestID = function(id) return accepted[id] and 1 or nil end,
    ReadyForTurnIn = function(id) return ready[id] == true end,
}
ns.Modules.Database = {
    Get = function(_, setting)
        if setting == "smartRouting" or setting == "autoRecovery" then return true end
        return false
    end,
}
assert(loadfile("clients/forever/guides/ZephrasIsle.lua"))("WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth", ns)
local guides, routes = ns.Modules.Guides, ns.Modules.SmartRoutes
local id = "zephras-alliance"
local state = guides:GetProgress(id)
guides:SetCurrent(43, id)
state.routeMode = "recommended"

-- An unrelated quest in the log is not evidence of availability in this route.
local stepIndex, message = routes:Preview(id, "recommended")
assert(stepIndex == nil and message:find("No actionable"), "No quest match must not pick a level-10 quest")
assert(routes:Recalculate() == true and state.awaitingQuestMatch == true,
    "Stale step must be marked unverified on login")
assert(state.current == 43 and next(state.completed) == nil,
    "Keep the cursor and completion flags intact")
assert(#routes:NearbyGroup() == 0, "No suggested or navigable grouped objectives when blocked")

-- Accepted quest with an objective step should take precedence.
accepted[92849] = true
stepIndex = routes:Preview(id, "recommended")
assert(stepIndex and guides:GetSteps(id)[stepIndex].id == "scholar-92849-objective",
    "Use active unfinished quest objective, not pickup or turn-in")
assert(routes:Recalculate() == true and state.awaitingQuestMatch == false,
    "Newly accepted guide quest clears mismatch warning")
assert(guides:CurrentStep().id == "scholar-92849-objective",
    "Route moves to the live quest's objective")
assert(next(state.completed) == nil, "Recommendation must not forge completions")

-- Once the in-progress quest is ready, point to its hand-in instead.
ready[92849] = true
stepIndex = routes:Preview(id, "recommended")
assert(stepIndex and guides:GetSteps(id)[stepIndex].id == "scholar-92849-turnin",
    "Ready-for-turn-in phase preferred over objective")
assert(routes:Recalculate() == true, "Tracker should advance to the ready turn-in")

-- Losing the quest must not continue to show the old arrow.
accepted[92849] = nil
ready[92849] = nil
assert(routes:Recalculate() == true and state.awaitingQuestMatch == true,
    "Removing quest blocks old destination instead of guessing")

-- The explicit story mode still permits earlier steps and preserves history.
assert(routes:Switch(id, "beginning"), "Manual story mode remains selectable")
assert(state.awaitingQuestMatch == false and state.routeMode == "beginning")
assert(guides:CurrentStep().id == "start-accept")
assert(next(state.completed) == nil, "No false completion across route switches")

-- A different faction uses the same safe behavior.
faction = "Horde"
ns.char.activeGuide = "zephras-horde"
local hordeState = guides:GetProgress("zephras-horde")
hordeState.routeMode = "recommended"
assert(routes:Preview("zephras-horde", "recommended") == nil,
    "Horde level-10 Zephras guide also needs live quest evidence")
assert(routes:Recalculate() == true and hordeState.awaitingQuestMatch == true,
    "Horde route protects against stale steps too")
print("WayForth Zephras mid-guide quest synchronization tests passed")
