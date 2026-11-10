-- Inventory the same guide data and resolution path loaded by the addon.
-- Run at the repository root. An optional argument writes the full Markdown audit.
local ns = {Modules = {}, char = {guideProgress = {}}, state = {}}
function ns:RegisterModule(name, module) self.Modules[name] = module end
local race, class = "HUMAN", "HUNTER"
UnitRace = function() return race, race end
UnitClass = function() return class, class end
local toc = assert(io.open("clients/forever/manifest/WayForth.toc"))
for line in toc:lines() do
    local data = line:match("^Data/(.+%.lua)$")
    if data then assert(loadfile("clients/forever/guides/" .. data))("WayForth", ns) end
end
toc:close()
assert(loadfile("shared/core/QuestLocations.lua"))("WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth", ns)
local guides = ns.Modules.Guides
local totals, report, gaps, ids = {}, {}, {}, {}
local function hasPoint(step)
    return type(step.mapId) == "number" and type(step.x) == "number" and type(step.y) == "number"
        and step.x > 0 and step.x < 100 and step.y > 0 and step.y < 100
end
local function questName(step)
    local record = (ns.foreverQuestLocations or {})[step.questId]
    if record and record.name and record.name ~= "" then return record.name end
    local name = tostring(step.title)
    for _, prefix in ipairs({"^Work on: ", "^Pick up: ", "^Complete: ", "^Accept: "}) do
        name = name:gsub(prefix, "")
    end
    return name:gsub(" %(%d+/%d+%)", "")
end
for _, guide in ipairs(guides:List()) do
    local races, classes = {HUMAN = true, ORC = true}, {HUNTER = true}
    for _, step in ipairs(guide.steps) do
        for _, token in ipairs(step.races or {}) do races[token] = true end
        if step.class then classes[step.class] = true end
    end
    local seen, count, missing = {}, 0, 0
    for raceToken in pairs(races) do
        for classToken in pairs(classes) do
            race, class = raceToken, classToken
            for index, step in ipairs(guides:GetSteps(guide.id)) do
                local key = step.id or index
                if not seen[key] then
                    seen[key] = true
                    local action = step.action
                    if action == "accept" or action == "objective" or action == "turnin" then
                        assert(type(step.questId) == "number" and step.questId > 0,
                            "Missing quest ID: " .. guide.id .. "/" .. tostring(key))
                        ids[step.questId] = true
                        local total = totals[action] or {steps = 0, located = 0, requirements = 0}
                        totals[action] = total
                        total.steps = total.steps + 1
                        count = count + 1
                        if hasPoint(step) then
                            total.located = total.located + 1
                        else
                            missing = missing + 1
                            local guidance = ""
                            if step.objectiveSource then
                                total.requirements = total.requirements + 1
                                guidance = step.objectiveSource .. " (" .. step.objectiveKind .. "): " .. step.text
                            end
                            gaps[#gaps + 1] = {guide.id, tostring(step.questId), questName(step), action, guidance}
                        end
                    end
                end
            end
        end
    end
    if count > 0 then report[#report + 1] = {guide.id, count, count - missing, missing} end
end
local lines = {
    "# Forever quest location coverage", "",
    "Generated from the bundled manifest by `scripts/audit_quest_locations.lua`.", "",
    "Sources are corrected Forever facts from QuestieDB, the compiled AllTheThings Forever catalog, Wowhead Forever and Classic quest maps, AHledger, WoWDB, and reviewed quest/item pages found through web searches. Exact revisions and the refresh command are in `docs/QUEST_LOCATION_SOURCES.md`.", "",
    "Counts include the union of faction, race and class variants within each guide. Shared quests can appear in multiple guides.", "",
    "| Phase | Quest IDs present | Static destinations | Missing static destinations |",
    "| --- | ---: | ---: | ---: |",
}
for _, action in ipairs({"accept", "objective", "turnin"}) do
    local total = totals[action]
    local row = string.format("| %s | %d | %d | %d |", action, total.steps, total.located, total.steps - total.located)
    lines[#lines + 1] = row
    print(row)
end
lines[#lines + 1] = ""
lines[#lines + 1] = "Static coverage describes source availability. It does not verify quest eligibility or live-client accuracy. Some requirements involve crafting, reputation or player-held items and have no single world destination. Unresolved phases use an active quest's live marker when available."
lines[#lines + 1] = ""
lines[#lines + 1] = string.format("Of the %d missing objective destinations, %d have specific source-backed requirements in the tracker. They remain counted as missing static destinations.",
    totals.objective.steps - totals.objective.located, totals.objective.requirements)
lines[#lines + 1] = ""
lines[#lines + 1] = "| Guide | Quest steps | Static destinations | Missing |"
lines[#lines + 1] = "| --- | ---: | ---: | ---: |"
for _, row in ipairs(report) do lines[#lines + 1] = string.format("| %s | %d | %d | %d |", unpack(row)) end
lines[#lines + 1] = ""
lines[#lines + 1] = "## Unresolved static destinations"
lines[#lines + 1] = ""
lines[#lines + 1] = "Quest names below omit WayForth's Work on, Pick up and Complete labels, chain numbering and faction annotations. Use the clean name and quest ID when searching. The complete 101-quest web search receipt is in `scripts/data/quest_web_search_review.json`."
lines[#lines + 1] = ""
lines[#lines + 1] = "| Guide | Quest ID | Quest name | Phase | Known requirements |"
lines[#lines + 1] = "| --- | ---: | --- | --- | --- |"
table.sort(gaps, function(a, b) return table.concat(a, "/") < table.concat(b, "/") end)
for _, row in ipairs(gaps) do
    for index, value in ipairs(row) do row[index] = value:gsub("|", "/"):gsub("\n", " ") end
    lines[#lines + 1] = "| " .. table.concat(row, " | ") .. " |"
end
if arg[1] then
    local file = assert(io.open(arg[1], "w"))
    file:write(table.concat(lines, "\n") .. "\n")
    file:close()
end
return {totals = totals, gaps = gaps, guides = guides, ns = ns}
