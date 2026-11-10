-- Standalone Lua 5.1 guide-sync regression test. No WoW installation required.
local ns = {
    Modules = {},
    state = {},
    char = { guideProgress = {}, activeGuide = "quest-test" },
    starterGuides = {
        {
            id = "quest-test",
            title = "Test route",
            steps = {
                { id = "first-accept", action = "accept", questId = 10 },
                { id = "first-turnin", action = "turnin", questId = 10 },
                { id = "manual", action = "manual" },
                { id = "later-accept", action = "accept", questId = 20 },
                { id = "later-objective", action = "objective", questId = 20 },
                { id = "later-turnin", action = "turnin", questId = 20 },
                { id = "finish", action = "manual" },
            },
        },
    },
}
function ns:RegisterModule(name, module) self.Modules[name] = module end

local active, completed, ready = {}, {}, {}
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return completed[id] == true end,
    IsOnQuest = function(id) return active[id] == true end,
    GetLogIndexForQuestID = function(id) return active[id] and 1 or nil end,
    IsComplete = function(id) return ready[id] == true end,
}
local module = assert(loadfile("shared/core/Guides.lua"))
module("WayForth", ns)
local guides = ns.Modules.Guides

local state = guides:GetProgress()
assert(state and state.current == 1, "starts at initial quest")

local changed, report = guides:Sync(nil, true)
assert(changed == false and report:find("No matching"), "empty quest log is not a success")
assert(state.current == 1)

active[10] = true
changed = guides:Sync()
assert(changed == true and state.current == 2, "acceptance advances to turnin")
assert(state.completed["first-accept"] == true)
assert(not state.completed["first-turnin"])

active[10] = nil
completed[10] = true
changed = guides:Sync()
assert(changed == true and state.current == 3, "completed quest advances to manual checkpoint")
assert(state.completed["first-turnin"] == true)

active[20] = true
changed = guides:Sync()
assert(changed == true and state.current == 3, "automatic sync tracks later quests but leaves manual step current")
assert(state.completed["later-accept"] == true)
assert(not state.completed["manual"], "manual steps are not falsely completed")

changed, report = guides:Sync(nil, true)
assert(changed == true and state.current == 5, "explicit sync catches up past earlier manual step")
assert(report:find("Earlier manual steps"), "catch-up explains unverified steps")
assert(not state.completed["manual"], "catch-up does not invent prior completion")

ready[20] = true
changed = guides:Sync()
assert(changed == true and state.current == 6, "objective completion advances to turnin")
assert(state.completed["later-objective"] == true)

-- QUEST_TURNED_IN is an authoritative signal even before completion flags update.
guides:RecordQuestEvent("QUEST_TURNED_IN", 20)
changed = guides:Sync()
assert(changed == true and state.current == 7, "turn-in event advances immediately")
assert(state.completed["later-turnin"] == true)
assert(ns.char.turnedInQuests[20] == true, "turn-in evidence persists per character")
changed = guides:Sync(nil, true)
assert(changed == false and state.current == 7, "repeated sync stays stable")
assert(not state.completed["finish"], "the final manual step stays unverified")

guides:Reset()
state = guides:GetProgress()
assert(state.current == 1, "reset restores guide cursor")
changed = guides:Sync()
assert(changed == true and state.current == 3, "saved completed quests restore progress after reset")

-- Older WoW clients and an API being unavailable do not crash or invent progress.
C_QuestLog = nil
IsQuestFlaggedCompleted = nil
GetQuestLogIndexByID = nil
ns.state.acceptedQuestIDs = nil
ns.char.turnedInQuests = nil
guides:Reset()
state = guides:GetProgress()
changed, report = guides:Sync(nil, true)
assert(changed == false and state.current == 1, "no API cannot invent quest completion")
assert(report:find("unavailable"), "no API condition is reported")

print("WayForth quest sync regression tests passed")
