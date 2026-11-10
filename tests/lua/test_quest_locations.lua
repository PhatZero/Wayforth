-- Exercise the normal manifest, phase navigation and pre-upgrade saved cursors.
local coverage = assert(loadfile("scripts/audit_quest_locations.lua"))()
local guides, ns = coverage.guides, coverage.ns
local nav
ns.Modules.Theme = {}
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth", ns)
nav = ns.Modules.Navigator
local function find(guideId, questId, action)
    for index, step in ipairs(guides:GetSteps(guideId)) do
        if step.questId == questId and step.action == action then return step, index end
    end
end
local pickup = assert(find("alliance-elwynn", 783, "accept"))
local turnin = assert(find("alliance-elwynn", 783, "turnin"))
assert(pickup.mapId == 1429 and turnin.mapId == 1429)
assert(pickup.hub == "Deputy Willem" and turnin.hub == "Marshal McBride",
    "A delivery must route to the distinct quest finisher")
assert(pickup.x ~= turnin.x or pickup.y ~= turnin.y,
    "Turn-ins must not silently inherit pickup coordinates")
local apple = assert(find("alliance-elwynn", 91738, "objective"))
assert(apple.text:find("91736", 1, true), "Reward items need their source quest, not the current quest's finisher")
local objective, index = find("alliance-elwynn", 7, "objective")
assert(objective and objective.mapId == 1429 and objective.questId == 7)
local target = nav:TargetForStep(objective)
assert(target and target.mapId == 1429 and target.source:find("objective", 1, true))
local questActive, questReady = true, false
C_QuestLog = {
    IsOnQuest = function(id) return id == 7 and questActive end,
    ReadyForTurnIn = function(id) return id == 7 and questReady end,
    IsQuestFlaggedCompleted = function() return false end,
}
ns.Modules.Database = {Get = function(_, key) return key ~= "guidePaused" end}
ns.char.activeGuide = "alliance-elwynn"
ns.char.guideProgress["alliance-elwynn"] = {currentStepId = objective.id, current = index, completed = {}}
guides:Sync()
assert(guides:CurrentStep().action == "objective", "An accepted quest still has work to do")
questReady = true
guides:Sync()
assert(guides:CurrentStep().action == "turnin", "Ready quests advance to the finisher")

-- Old releases stored only a filtered numeric cursor. Inserting an objective
-- must preserve the prior turn-in, including a Horde race-filtered guide.
for _, guideId in ipairs({"alliance-elwynn", "horde-tirisfal-glades"}) do
    local legacy = guides:GetSteps(guideId, true)
    local oldIndex = #legacy
    ns.char.guideProgress[guideId] = {current = oldIndex, completed = {}}
    local saved = guides:GetProgress(guideId)
    assert(saved.currentStepId == legacy[oldIndex].id, "Legacy numeric cursor changed its quest step")
    local current = guides:GetSteps(guideId)[saved.current]
    assert(current.id == legacy[oldIndex].id)
end

-- A kill/loot target's allegiance must not restrict the quest's player faction.
local claw = assert(find("horde-ashenvale", 2, "accept"))
assert(claw.x and claw.y and claw.locationKind == "loot",
    "Horde players need the Sharptalon loot waypoint even though the target is friendly to Alliance")

for _, guide in ipairs(guides:List()) do
    for _, step in ipairs(guides:GetSteps(guide.id)) do
        assert(step.questId ~= 55296 and step.questId ~= 98294,
            "Internal completion flags must not become quest pickups or turn-ins")
    end
end

-- Corrected faction data removes Horde-only quests from Alliance catalogs.
local checkedFaction = false
for _, guide in ipairs(guides:List()) do
    if guide.faction == "Alliance" and guide.legacySteps then
        for oldIndex, oldStep in ipairs(guides:GetSteps(guide.id, true)) do
            if oldStep.questId == 6365 then
                for _, step in ipairs(guides:GetSteps(guide.id)) do
                    assert(step.questId ~= 6365, "Horde-only Crossroads deliveries must be filtered")
                end
                ns.char.guideProgress[guide.id] = {current = oldIndex, completed = {retained = true}}
                local saved = guides:GetProgress(guide.id)
                local current = guides:GetSteps(guide.id)[saved.current]
                assert(current.questId ~= 6365 and saved.completed.retained,
                    "An old cursor on an excluded faction quest must resume on a surviving step")
                checkedFaction = true
                break
            end
        end
    end
end
assert(checkedFaction, "Missing cross-faction source regression example")

-- Unknown endpoint data must not borrow a different quest phase.
local unknown = {questId = 999999999, action = "turnin"}
ns.Modules.QuestLocations:Apply(unknown, {id = "fixture", faction = "Alliance", zone = "Elwynn Forest"})
assert(unknown.x == nil and unknown.mapId == nil)
ns.foreverQuestLocations[999999999] = {
    pickup = {{mapId = 1429, x = 40, y = 50, kind = "npc", name = "Starter"}},
}
ns.Modules.QuestLocations:Apply(unknown, {id = "fixture", faction = "Alliance"})
assert(unknown.x == nil, "A pickup is not evidence of a turn-in destination")
ns.foreverQuestLocations[999999999] = nil
assert(coverage.totals.accept.located >= 2754, "Bundled pickup coverage regressed")
assert(coverage.totals.turnin.located >= 2734, "Bundled turn-in coverage regressed")
assert(coverage.totals.objective.located >= 1649, "Bundled objective coverage regressed")
print("WayForth quest locations preserve phase routing and existing saved progress")
