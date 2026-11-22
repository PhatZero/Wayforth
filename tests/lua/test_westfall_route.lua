-- Issue #77: Westfall must be an authored circuit, not the level-sorted
-- ATT catalog displayed as a pickup/turn-in pair for every individual quest.
-- This tests the real manifest and source-resolved guide under Lua 5.1.
local coverage = dofile("scripts/audit_quest_locations.lua")
local ns,guides = coverage.ns,coverage.guides
UnitFactionGroup=function() return "Alliance" end
UnitRace=function() return "Human","HUMAN" end
UnitClass=function() return "Hunter","HUNTER" end
local manifest=assert(io.open("clients/forever/manifest/WayForth.toc")):read("*a")
assert(manifest:find("Data/ForeverQuestLocations.lua",1,true)
        < manifest:find("Data/WestfallRoute.lua",1,true)
    and manifest:find("Data/ForeverDBQuestData.lua",1,true)
        < manifest:find("Data/WestfallRoute.lua",1,true)
    and manifest:find("Data/WestfallRoute.lua",1,true)
        < manifest:find("Core/QuestLocations.lua",1,true),
    "Westfall route authoring must run after complete Forever quest records")

local guide = guides:GetGuide("alliance-westfall")
assert(guide and guide.id=="alliance-westfall")
assert(guide.routeStyle=="authored-circuits",
    "Westfall must use the curated route rather than the level-sort generator")
assert(guide.testingOnly and guide.contentStatus:find("in%-game"),
    "An authored order is not proof of actual NPC availability in the live client")
local steps = guides:GetSteps("alliance-westfall")
local originals = guide.legacySteps
assert(originals and #originals==88,"All 44 source quests must retain legacy pairs")

local seen,actions,positions={},{},{}
local function note(step,index)
    assert(type(step.id)=="string" and not seen[step.id],
        "Duplicate/absent stable step ID: "..tostring(step.id))
    seen[step.id]=true
    local id = step.questId
    if type(id)=="number" then
        positions[id]=positions[id] or {}
        assert(not positions[id][step.action], "Repeated "..step.action.." for quest "..id)
        positions[id][step.action]=index
        actions[id]=true
    end
end
for i,step in ipairs(steps) do note(step,i) end
local count=0
for id in pairs(actions) do count=count+1 end
assert(count==44, "The authored guide must retain all 44 source catalog quests")
for _,legacy in ipairs(originals) do
    local place=positions[legacy.questId]
    assert(place and place[legacy.action], "Former quest step lost: "..legacy.id)
    assert(seen[legacy.id], "Existing SavedVariables step ID must survive: "..legacy.id)
end
for id,phases in pairs(positions) do
    assert(phases.accept and phases.turnin and phases.accept<phases.turnin,
        "Quest must be accepted before its hand-in: "..id)
    if phases.objective then
        assert(phases.accept<phases.objective and phases.objective<phases.turnin,
            "Work objective must be between pickup and hand-in: "..id)
        assert(steps[phases.objective].id==
            steps[phases.turnin].id.."-objective",
            "Keep the existing auto-inserted objective key: "..id)
    end
end

local function before(a,phaseA,b,phaseB)
    assert(positions[a][phaseA]<positions[b][phaseB],
        a.." "..phaseA.." must precede "..b.." "..phaseB)
end
-- Prerequisite chains cannot be turned in after their follow-up pickup.
for _,chain in ipairs({
    {12,13,14},{36,38},{92742,92744,92745,92747,92748},
    {65,132,135,141,142,155},{136,138,139,140},
    {92910,92911},{92109,92110},{48,49,50,51,53},
}) do
    for index=2,#chain do
        before(chain[index-1],"turnin",chain[index],"accept")
    end
end
for _,step in ipairs(steps) do
    if step.action=="accept" then
        for _,needed in ipairs(step.requires or {}) do
            if positions[needed] then
                before(needed,"turnin",step.questId,"accept")
            end
        end
        for _,needed in ipairs(step.requiresAny or {}) do
            if positions[needed] then
                before(needed,"turnin",step.questId,"accept")
            end
        end
    end
end
-- Quest pickups are grouped before objective/turn-in circuits. Do not make
-- a player pick one quest, go back, and then pick the next from the same hub.
assert(positions[151].accept<positions[36].accept
    and positions[36].accept<positions[151].turnin,
    "Jansen Stead pickups should be collected before Blanchy's turn-in")
assert(positions[9].accept<positions[22].accept
    and positions[22].accept<positions[9].turnin,
    "Saldean Farm errands must share the opening pickup sweep")
assert(positions[102].accept<positions[12].accept
    and positions[12].accept<positions[102].turnin,
    "Sentinel Hill pickup loop must collect both quests before fieldwork")
assert(positions[13].turnin<positions[14].accept,
    "Third People's Militia stage must wait until second is handed in")
-- Real quest-location data must already exist when the route is authored.
-- All field objectives for a circuit come before its first return trip.
assert(positions[9].objective and positions[22].objective
    and positions[151].objective and positions[102].objective,
    "Quest objective phases must be authored using the full source catalog")
assert(positions[22].objective<positions[9].turnin
    and positions[102].objective<positions[151].turnin,
    "A hub circuit must do nearby field objectives before grouped hand-ins")

-- Optional/specialization and level-40 quests do not interrupt core quests.
for _,id in ipairs({184,109,93928,92910,92911,92109,92110,79008,1076,48,49,50,51,53}) do
    assert(positions[155].turnin<positions[id].accept,
        "Optional quest "..id.." interrupted the main Westfall route")
end
assert(steps[positions[48].accept].optional and steps[positions[53].turnin].optional)
assert(steps[positions[48].accept].level>=40,
    "The late Sweet Amber chain must not masquerade as a level-12 requirement")

-- Two different quest phases must use their separate source-backed endpoints.
local defiasPickup=steps[positions[65].accept]
local defiasTurnin=steps[positions[65].turnin]
assert(defiasPickup.mapId==1436 and defiasTurnin.mapId==1433,
    "Defias Brotherhood goes from Westfall to the Redridge quest finisher")
local wells=steps[positions[92742].accept]
assert(wells.mapId==1436 and wells.x and wells.y)

-- Simulate a player resuming their previously active militia step after the
-- authored order changes. The stable ID should restore the exact quest phase.
local oldIndex = 24
local saved=guides:GetProgress("alliance-westfall")
saved.current=oldIndex
saved.currentStepId=steps[positions[14].objective or positions[14].turnin].id
saved.completed[steps[positions[12].turnin].id]=true
local relocated=guides:GetProgress("alliance-westfall")
assert(relocated.currentStepId==saved.currentStepId
    and relocated.current==(positions[14].objective or positions[14].turnin),
    "Returning characters must keep their actual quest phase after reordering")
assert(relocated.completed[steps[positions[12].turnin].id])

print("Westfall authored route passed: 44 quests, grouped pickups, chain ordering, pins and saved step IDs")
