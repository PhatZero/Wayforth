-- Lua 5.1: backtrack to an actual quest pickup when joining Zephras mid-route.
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
local function stepIndex(identifier, guideId)
    for index, step in ipairs(guides:GetSteps(guideId or id)) do
        if step.id == identifier then return index end
    end
    error("Missing guide step: " .. identifier)
end
local state = guides:GetProgress(id)
guides:SetCurrent(stepIndex("turncoat"), id)
state.routeMode = "recommended"
local turncoatOld = state.current

-- Never send a non-questing character straight to a downstream objective.
local stepIndex1, reason = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("supreme-92699-accept"),
    "Backtrack through the known chain to the earliest incomplete pickup")
assert(reason:find("Quest pickup needed"), "Explain that a pickup is required")
assert(routes:Recalculate() == true, "Recover from stale legacy saved cursor")
assert(state.current == stepIndex1 and state.awaitingQuestMatch == false)
assert(not next(state.completed), "Quest recovery must not forge completion history")

-- Advance known prerequisites in the *game*, not by altering guide flags.
for _, questID in ipairs({
    92699, 92727, 92849, 92850, 99260, 92840,
    92860, 93320, 92642, 92645, 92880,
}) do
    turnedIn[questID] = true
end
guides:SetCurrent(stepIndex("turncoat"), id)
stepIndex1 = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("elder-92881-accept"),
    "The Turncoat must backtrack to High Elder's Request, not the cultist's location")
assert(routes:Recalculate() == true and state.current == stepIndex1)

-- Accepting a simple report quest (without a separate objective step) should
-- route to its hand-in, not to a locked downstream pickup.
accepted[92881] = true
stepIndex1 = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("elder-92881-turnin"),
    "In-progress report quest directs to its hand-in NPC")
assert(routes:Recalculate() == true and state.current == stepIndex1)

-- After turning in the prerequisite, the correct quest giver is next.
accepted[92881] = nil
turnedIn[92881] = true
stepIndex1 = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("turncoat-92643-accept"),
    "After prerequisite turn-in, show the Turncoat pickup")
assert(routes:Recalculate() == true and state.current == stepIndex1)
assert(not state.completed["turncoat"], "Did not falsely complete the Turncoat")

-- Once The Turncoat is accepted, guide objective comes before hand-in.
accepted[92643] = true
stepIndex1 = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("turncoat-92643-objective"))
assert(routes:Recalculate() == true and state.current == stepIndex1)
ready[92643] = true
stepIndex1 = routes:Preview(id, "recommended")
assert(stepIndex1 == stepIndex("turncoat"))
assert(routes:Recalculate() == true and state.current == stepIndex1)

-- Explicit Sync in Story mode must recover too, while keeping the selected mode.
accepted[92643] = nil
ready[92643] = nil
turnedIn[92881] = nil
state.routeMode = "beginning"
guides:SetCurrent(stepIndex("turncoat"), id)
local changed, report = guides:Sync(nil, true)
assert(changed == true and state.current == stepIndex("elder-92881-accept"),
    "Explicit Sync resolves missing prerequisites even in Story mode")
assert(state.routeMode == "beginning", "Sync retains user-selected route mode")
assert(report:find("Quest pickup needed"), "Sync describes recovered pickup")
assert(turnedIn[92881] == nil, "No game quest completion forged")

-- Explicit story beginning still works, and stable step keys remain valid.
assert(routes:Switch(id, "beginning"), "Beginning mode remains available")
assert(guides:CurrentStep().id == "start-accept", "Story mode starts at first unfinished step")

-- Horde recovery fails safely where prerequisite metadata/pins are incomplete.
faction = "Horde"
ns.char.activeGuide = "zephras-horde"
local h = guides:GetProgress("zephras-horde")
h.routeMode = "recommended"
guides:SetCurrent(stepIndex("turncoat", "zephras-horde"), "zephras-horde")
local hIndex, hReason = routes:Preview("zephras-horde", "recommended")
assert(hIndex == nil and hReason:find("pickup location"),
    "Unknown Horde precursor pin must not generate speculative route")
assert(routes:Recalculate() == true and h.awaitingQuestMatch == true)
print("WayForth Zephras prerequisite backtracking and Sync tests passed")
