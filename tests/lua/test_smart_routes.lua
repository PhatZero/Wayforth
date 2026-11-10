-- Lua 5.1 regression tests for integrated Smart Routes (no WoW client required).
local ns = {
    Modules = {}, state = {}, char = { guideProgress = {}, activeGuide = "first-steps" },
    starterGuides = {
      {id="first-steps", title="Tutorial", steps={{id="first",title="Intro",action="manual"}}},
    },
}
function ns:RegisterModule(name, module) self.Modules[name] = module end
function ns:Call() return true end
local level, faction = 18, "Alliance"
local complete, accepted = {}, {}
UnitLevel = function() return level end
UnitFactionGroup = function() return faction end
UnitClass = function() return "Hunter", "HUNTER" end
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return complete[id] == true end,
    IsOnQuest = function(id) return accepted[id] == true end,
    GetLogIndexForQuestID = function(id) return accepted[id] and 1 or nil end,
    GetTitleForQuestID = function(id)
      if id == 783 then return "A Threat Within" end
      if id == 456 then return "Wrong Quest" end
      return nil
    end,
}
assert(loadfile("clients/forever/guides/AllianceStarters.lua"))("WayForth",ns)
assert(loadfile("clients/forever/guides/ForeverQuestCatalog.lua"))("WayForth",ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth",ns)
assert(loadfile("shared/core/QuestAudit.lua"))("WayForth",ns)
local g, routes, audit = ns.Modules.Guides, ns.Modules.SmartRoutes, ns.Modules.QuestAudit
assert(#routes:ListGuides() == 4, "Tutorial and three Alliance starter regions")
local all, idset = 0, {}
for _, ids in pairs(ns.foreverQuestCatalog) do
    all = all + #ids
    for _,id in ipairs(ids) do idset[id] = true end
end
assert(all == 439, "Source list has 439 candidate IDs, not verified quests")
for _, id in ipairs({783, 456, 457, 458, 459, 282, 420}) do
    assert(idset[id], "Essential quest missing from source catalog "..id)
end
local summary = audit:Scan()
assert(audit.counts.total == 439, "Audit scans all source candidates")
assert(audit.counts.matched >= 1, "Matching ID/title recognized")
assert(audit.counts.mismatch >= 1, "Wrong ID/title flagged")
assert(audit:IsMismatched(456), "Mismatch available to switch engine")
assert(summary:find("ID catalog"), "Readable audit summary")
local index, reason = routes:Preview("alliance-teldrassil", "recommended")
assert(index == nil and reason:find("Ashenvale"), "High-level player is not sent to gray starter quests")
assert(not routes:Switch("alliance-teldrassil", "recommended"), "Cannot force low XP quests")
assert(g:GetGuide().id == "first-steps", "Failed selection does not change active guide")
assert(routes:Switch("alliance-teldrassil", "beginning"), "Story mode allows low-level zone")
assert(g:GetGuide().id == "alliance-teldrassil", "Switches original guide engine")
local saved = g:GetProgress()
assert(saved.routeMode == "beginning" and saved.current == 1, "Mode and progress saved")
g:CompleteCurrent()
assert(saved.completed["quest-458"], "Manual completion recorded")
assert(routes:Switch("alliance-elwynn", "beginning"), "Switch to human lands")
assert(not g:GetProgress("alliance-elwynn").completed["quest-458"], "Region progress isolated")
assert(routes:Switch("alliance-teldrassil", "resume"), "Resume night-elf guide")
assert(g:GetProgress().completed["quest-458"], "Previous region history remains")
assert(g:GetProgress().current == 2, "Resume uses saved location")
level = 5
accepted[62] = true
local e, why = routes:Preview("alliance-elwynn", "recommended")
assert(e ~= nil, "Active and suitable quests can be recommended")
local step = g:GetSteps("alliance-elwynn")[e]
assert(step.questId == 62, "Active quest prioritized over inactive same-level quests")
-- End-to-end: recommendation never inserts fabricated completion flags.
assert(routes:Switch("alliance-elwynn", "recommended"))
assert(g:GetProgress().completed["quest-62"] ~= true, "Skipped/selected is not completed")
print("WayForth integrated smart routes + quest audit tests passed")
