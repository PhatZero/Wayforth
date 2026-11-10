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

local supplies = assert(find("alliance-silithus", 8856, "turnin"))
assert(supplies.hub == "Calandrath" and supplies.mapId == 1451,
    "The matching WoWDB finisher must use the NPC's Forever map position")
assert(supplies.locationSource:find("WoWDB", 1, true), "Retain the finisher reference's provenance")

for _, guideId in ipairs({"alliance-azshara", "horde-azshara"}) do
    local meeting = assert(find(guideId, 3381, "turnin"))
    assert(meeting.hub == "Sanath Lim-yo" and meeting.mapId == 1447)
    assert(meeting.locationSource:find("WoWDB", 1, true))
end
local pledge = assert(find("alliance-tanaris", 3638, "objective"))
assert(pledge.mapId == 1446 and pledge.hub == "Nixx Sprocketspring")
assert(pledge.text:find("Use the provided Pledge", 1, true),
    "The pledge interaction must retain the item-use instruction at its waypoint")
local armor = assert(find("alliance-tanaris", 2771, "objective"))
assert(armor.x == nil and armor.text:find("2 Mithril Coifs", 1, true),
    "Crafting requirements must not borrow the quest finisher's position")
local hunt = assert(find("alliance-winterspring", 5306, "objective"))
assert(hunt.x == nil and hunt.text:find("Blackrock Spire", 1, true),
    "A documented instance objective must not fabricate an outdoor coordinate")
local reputation = assert(find("alliance-desolace", 1382, "objective"))
assert(reputation.mapId == 1443 and reputation.locationKind == "target")
assert(reputation.text:find("Defeat Magram", 1, true))
local flight = ns.foreverQuestLocations[5931].objective[1]
assert(flight.id == 11800 and flight.mapId == 1450,
    "Forever's flight objective must route to Silva, before the Darnassus finisher")

local notes = assert(find("alliance-stranglethorn-vale", 95384, "accept"))
assert(notes.locationKind == "loot" and notes.hub == "Skullsplitter Mystic")
assert(notes.text:find("Use the item to accept", 1, true),
    "An item-started quest must explain how to accept it after looting the item")
local goliath = assert(find("horde-arathi-highlands", 92707, "turnin"))
assert(goliath.hub == "Drum Fel" and goliath.mapId == 1417)
local doll = assert(find("alliance-eastern-plaguelands", 5149, "objective"))
assert(doll.mapId == 1423 and doll.hub == "Pamela's Doll's Head")
assert(doll.text:find("Combine the three pieces", 1, true))
local delivery = assert(find("alliance-riverglades", 95147, "objective"))
assert(delivery.hub == "Cedric Dalton" and delivery.mapId == 2548)
local crate = assert(find("alliance-riverglades", 95943, "objective"))
assert(crate.x == 51.9 and crate.y == 57.3 and crate.locationSource == "Wowhead Forever comment",
    "A community point must retain its distinct provenance")
local boots = assert(find("alliance-tanaris", 7654, "objective"))
assert(boots.x == nil and not boots.text:find("20", 1, true),
    "Retail material quantities must not overwrite an unresolved Forever quantity")
assert(ns.foreverQuestLocations[98447].name == "The Valor Family")
for _, row in ipairs(coverage.gaps) do
    assert(not row[3]:find("^Work on: ") and not row[3]:find("^Pick up: ") and not row[3]:find("^Complete: "),
        "The audit's quest-name column must be suitable for external searches")
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
