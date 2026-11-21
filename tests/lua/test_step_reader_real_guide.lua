-- Forever Step Reader QA: a real Skyborne quest hub and manual checkpoint.
-- This tests authored guide data with synthetic client events, not a live game client.
local ns = {
    Modules = {}, state = {},
    char = { activeGuide = "zephras-alliance", guideProgress = {}, turnedInQuests = {} },
    starterGuides = {},
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
local active, ready, turnedIn = {}, {}, {}
UnitFactionGroup = function() return "Alliance" end
UnitClass = function() return "Mage", "MAGE" end
UnitLevel = function() return 2 end
UnitRace = function() return "Skyborne", "SKYBORNE" end
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    GetLogIndexForQuestID = function(id) return active[id] and 1 or nil end,
    IsQuestFlaggedCompleted = function(id) return turnedIn[id] == true end,
    ReadyForTurnIn = function(id) return ready[id] == true end,
}
ns.Modules.Database = { Get = function(_, setting)
    if setting == "simpleStepReader" or setting == "autoAdvance" then return true end
    if setting == "guidePaused" then return false end
    return nil
end }
assert(loadfile("clients/forever/guides/StarterGuide.lua"))("WayForth",ns)
assert(loadfile("clients/forever/guides/ZephrasIsle.lua"))("WayForth",ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
local guides=ns.Modules.Guides
local saved=guides:GetProgress()
local function step()
    local s = guides:CurrentStep()
    return s and s.id
end
local function expect(id)
    assert(step()==id, "Expected "..id.."; got "..tostring(step()))
end
local function accept(id)
    active[id]=true
    guides:RecordQuestEvent("QUEST_ACCEPTED", 1, id)
    guides:Sync()
end
local function readyQuest(id)
    ready[id]=true
    guides:Sync()
end
local function handIn(id)
    active[id],ready[id],turnedIn[id]=nil,nil,true
    guides:RecordQuestEvent("QUEST_TURNED_IN",id)
    guides:Sync()
end

expect("start-accept")
accept(92460)
expect("start-report")
handIn(92460)
expect("harmony-accept")
accept(92461)
expect("flies-accept")

-- Complete a later objective early. The player must still collect the second quest.
readyQuest(92461)
expect("flies-accept")
accept(92462)
expect("flies-clear") -- Harmony was ready already; only consecutive verified steps advance.
readyQuest(92462)
expect("flies-return")
handIn(92462)
expect("harmony-return")
handIn(92461)
expect("class-mage")
assert(not saved.completed["class-mage"], "Class training must be a manual checkpoint")

-- A manual instruction can mention a quest ID; completing that quest does
-- not make the reader silently skip the trainer interaction.
turnedIn[92481]=true
guides:Sync()
expect("class-mage")
assert(not saved.completed["class-mage"])
guides:CompleteCurrent()
expect("glide-accept")
assert(saved.completed["class-mage"]==true, "Done / Next records a manual checkpoint")

-- Re-creating the guide module simulates /reload using existing character state.
local stored=saved.currentStepId
local before=ns.char.guideProgress
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
guides=ns.Modules.Guides
assert(ns.char.guideProgress==before, "SavedVariables must not be replaced")
expect("glide-accept")
assert(guides:GetProgress().currentStepId==stored, "Stable step IDs restore correctly")

print("WayForth Forever step reader: real Zephras hub, manual checkpoint and reload QA passed")
