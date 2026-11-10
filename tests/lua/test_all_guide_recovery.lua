-- Cross-guide regression tests: test actual shared recovery behavior in every
-- installed Forever leveling guide, without pretending to verify NPCs in game.
local ns = {
    Modules = {}, state = { acceptedQuestIDs = {} },
    char = { guideProgress = {}, turnedInQuests = {}, activeGuide = "first-steps" },
    starterGuides = {}, foreverQuestCatalog = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
function ns:Call() return true end
local level, faction, race, klass = 10, "Alliance", "HUMAN", "HUNTER"
local active, completed, ready = {}, {}, {}
UnitLevel = function() return level end
UnitFactionGroup = function() return faction end
UnitRace = function() return race, race end
UnitClass = function() return klass, klass end
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return completed[id] == true end,
    IsOnQuest = function(id) return active[id] == true end,
    GetLogIndexForQuestID = function(id) return active[id] and 1 or nil end,
    ReadyForTurnIn = function(id) return ready[id] == true end,
}
ns.Modules.Database = {
    Get = function(_, k)
        if k == "smartRouting" or k == "autoRecovery" or k == "autoAdvance" then return true end
        return false
    end,
}
for _, path in ipairs({
    "clients/forever/guides/StarterGuide.lua",
    "clients/forever/guides/ZephrasLocations.lua",
    "clients/forever/guides/ZephrasIsle.lua",
    "clients/forever/guides/AllianceStarters.lua",
    "clients/forever/guides/ForeverQuestCatalog.lua",
    "clients/forever/guides/KalimdorAlliance.lua",
    "clients/forever/guides/HordeKalimdor.lua",
    "clients/forever/guides/EasternEarly.lua",
    "clients/forever/guides/EasternHigh.lua",
    "clients/forever/guides/HordeRaceStarterExtras.lua",
}) do
    assert(loadfile(path))( "WayForth", ns)
end
assert(loadfile("clients/forever/guides/ForeverQuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/QuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth", ns)
local guides, routes = ns.Modules.Guides, ns.Modules.SmartRoutes

-- Alliance starter routes previously had no 'accept' step at all. Existing
-- turn-in step keys must remain identical for SavedVariables compatibility.
local starter = guides:GetSteps("alliance-teldrassil")
assert(starter[1].id == "quest-458-accept" and starter[1].action == "accept")
assert(starter[2].id == "quest-458" and starter[2].action == "turnin")
level = 3
guides:SetActive("alliance-teldrassil")
local progress = guides:GetProgress()
local first, reason = routes:Preview("alliance-teldrassil", "recommended")
assert(first and starter[first].x and starter[first].mapId,
    "Alliance starter pickups need a bundled source location")
local _, syncReport = guides:Sync(nil, true)
assert(syncReport:find("pickup", 1, true), "Explicit Sync provides pickup instructions")
assert(next(progress.completed) == nil, "Synchronizing alone cannot complete quests")

local checked, prereqExamples, withPickup, unmatched = 0, 0, 0, 0
for _, guide in ipairs(guides:List()) do
    checked = checked + 1
    faction = guide.faction or "Alliance"
    race = faction == "Horde" and "ORC" or "HUMAN"
    level = math.max(guide.levelMin or 1, 5)
    if guide.levelMax then level = math.min(level + 2, guide.levelMax) end
    ns.char.activeGuide = guide.id
    local steps = guides:GetSteps(guide.id)
    assert(#steps > 0, "No visible steps for " .. guide.id)
    local saved = guides:GetProgress(guide.id)
    local seen = {}
    for index, step in ipairs(steps) do
        local key = step.id or index
        assert(not seen[key], "Duplicate visible step ID: " .. guide.id .. "/" .. tostring(key))
        seen[key] = true
    end
    if guide.id ~= "first-steps" then
        assert(routes:NeedsLiveQuest(guide.id) or level < 5,
            "Quest recovery is disabled for guide " .. guide.id)
        assert(routes:Preview(guide.id, "beginning") ~= nil,
            "From Beginning must remain available: " .. guide.id)
        assert(routes:Preview(guide.id, "resume") == saved.current,
            "Resume must retain the saved cursor: " .. guide.id)

        -- A new guide with no live quests should not invent completion flags.
        saved.routeMode = "recommended"
        routes:Recalculate()
        assert(next(saved.completed) == nil,
            "Automatic recovery forged a completion: " .. guide.id)
        assert(saved.current >= 1 and saved.current <= #steps)

        local candidate, candidateId
        for index, step in ipairs(steps) do
            if step.action == "accept" and type(step.questId) == "number" then
                candidate = index
                candidateId = step.questId
                if step.x then break end
            end
        end
        if candidate then
            withPickup = withPickup + 1
            -- A real active quest always wins over arbitrary level matches.
            active[candidateId] = true
            local match = routes:Preview(guide.id, "recommended")
            assert(match and steps[match].questId == candidateId,
                "Live quest not prioritized: " .. guide.id)
            active[candidateId] = nil
            assert(next(saved.completed) == nil,
                "Preview may not modify completion flags")
        end

        -- For an unstarted downstream quest with an internal prerequisite,
        -- navigate to the missing prerequisite or state exactly why it cannot
        -- be resolved. NEVER direct to the unavailable downstream objective.
        local links = {}
        for _, step in ipairs(steps) do
            if step.action == "accept" and step.questId then
                links[step.questId] = true
            end
        end
        local downstream
        for index, step in ipairs(steps) do
            if step.action == "accept" and type(step.requires) == "table" then
                for _, requirement in ipairs(step.requires) do
                    if links[requirement] and requirement ~= step.questId then
                        downstream = index
                        break
                    end
                end
            end
            if downstream then break end
        end
        if downstream then
            prereqExamples = prereqExamples + 1
            guides:SetCurrent(downstream, guide.id)
            local selected, explanation = routes:Preview(guide.id, "recommended")
            assert(not selected or steps[selected].questId ~= steps[downstream].questId,
                "Unavailable downstream quest selected before its prerequisite: " .. guide.id)
            assert(selected or type(explanation) == "string",
                "Unresolvable prerequisite must return a reason: " .. guide.id)
        else
            unmatched = unmatched + 1
        end
    end
end
assert(checked >= 65, "The complete 1-60 guide library was not loaded")
assert(withPickup >= 55, "Most guide zones must have quest pickup steps")
assert(prereqExamples >= 25, "Not enough prerequisite graph examples checked")
print(string.format(
    "WayForth all-guides recovery passed: %d guides, %d with pickup steps, %d chain backtracks, %d no internal chain example",
    checked, withPickup, prereqExamples, unmatched))
