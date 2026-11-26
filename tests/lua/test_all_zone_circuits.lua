-- All leveling-zone pickup circuits should be reproducible from the exact
-- offline quest evidence shipped to the Forever client, with no new cursor engine.
local loaded=dofile("scripts/audit_quest_locations.lua")
local ns,guides=loaded.ns,loaded.guides
local stats=assert(ns.zoneRouteBuildStats,"All-zone circuit data was not loaded")
assert(stats.converted>=45,
    "Expected most generated leveling zones to use the source circuit pass; got "..stats.converted)
assert(stats.quests>750, "A large portion of the Forever source catalog was omitted")
assert(stats.circuits>0)

local converted,questCount,groupedPairs=0,0,0
local function key(step,i) return step.id or i end
for _,guide in ipairs(guides:List()) do
    if guide.routeStyle=="source-circuits" and not guide.generatedChapter then
        converted=converted+1
        assert(not guide.isProfession and not guide.isDungeon)
        assert(guide.testingOnly and guide.contentStatus:find("verification pending",1,true),
            "Generated source circuits must never claim live-client verification")
        assert(type(guide.legacySteps)=="table" and #guide.legacySteps>0)
        local oldKeys,oldQuests,actualKeys,positions,sourceCount={},{},{},{},0
        for i,step in ipairs(guide.legacySteps) do
            assert(step.id and not oldKeys[step.id],guide.id.." duplicate legacy ID")
            oldKeys[step.id]=true
            oldQuests[step.questId]=true
            sourceCount=sourceCount+1
        end
        assert(sourceCount%2==0,guide.id.." lost source step pair")
        local inOptional=false
        local phaseCounts={accept=0,turnin=0,objective=0}
        local chapterFirstTurnin={}
        local chapterAccepts={}
        for i,step in ipairs(guide.steps) do
            assert(step.id and not actualKeys[step.id],guide.id.." duplicated authored ID "..tostring(step.id))
            actualKeys[step.id]=true
            assert(step.questId and oldQuests[step.questId],
                guide.id.." invented or dropped source quest")
            assert(step.action=="accept" or step.action=="objective" or step.action=="turnin")
            phaseCounts[step.action]=phaseCounts[step.action]+1
            positions[step.questId]=positions[step.questId] or {}
            positions[step.questId][step.action]=i
            if step.optional then inOptional=true
            elseif inOptional then
                error(guide.id.." put core steps behind optional source candidates")
            end
            assert(step.routeChapter and #step.routeChapter>0,
                guide.id.." has missing circuit label")
            local chapter=step.routeChapter
            if step.action=="accept" then
                chapterAccepts[chapter]=(chapterAccepts[chapter] or 0)+1
            elseif step.action=="turnin" then
                chapterFirstTurnin[chapter]=chapterFirstTurnin[chapter] or i
            end
            if step.action=="objective" then
                assert(step.id:find("%-objective$"),"Objective ID incompatible with saved progress")
                assert(step.x==nil and step.y==nil,
                    "An objective must not inherit the quest giver's map coordinates")
            end
        end
        assert(phaseCounts.accept==sourceCount/2
            and phaseCounts.turnin==sourceCount/2,
            guide.id.." changed the number of original accept/turnin phases")
        questCount=questCount+sourceCount/2
        for id in pairs(oldQuests) do
            local phases=assert(positions[id],guide.id.." missed "..id)
            assert(phases.accept and phases.turnin and phases.accept<phases.turnin)
            local oldTurnin
            for _,step in ipairs(guide.legacySteps) do
                if step.questId==id and step.action=="turnin" then
                    oldTurnin=step
                    break
                end
            end
            local record=(ns.foreverQuestLocations or {})[id]
            if record and record.hasObjective then
                assert(phases.objective
                    and actualKeys[oldTurnin.id.."-objective"],
                    guide.id.." missing source-backed objective "..id)
                assert(phases.accept<phases.objective
                    and phases.objective<phases.turnin,
                    guide.id.." invalid pickup/objective/turn-in ordering "..id)
            end
        end
        for id in pairs(oldKeys) do
            assert(actualKeys[id],guide.id.." lost original ID "..id)
        end
        for chapter,n in pairs(chapterAccepts) do
            if n>1 then
                groupedPairs=groupedPairs+n-1
                assert(chapterFirstTurnin[chapter],
                    guide.id.." emitted pickup circuit with no turn-ins")
            end
        end
        -- Every class/race restriction from the source must survive; no core
        -- route may infer eligibility from the source having a quest ID.
        local lookup={}
        for _,step in ipairs(guide.steps) do lookup[step.id]=step end
        for _,step in ipairs(guide.legacySteps) do
            local current=assert(lookup[step.id])
            assert(current.class==step.class and current.races==step.races,
                guide.id.." dropped class/race restrictions")
        end
        -- Stable source IDs prevent migration from reinterpreting the numeric
        -- cursor after adding grouped quest phases.
        local saved=guides:GetProgress(guide.id)
        local visible=guides:GetSteps(guide.id)
        local visibleKeys={}
        for _,step in ipairs(visible) do visibleKeys[step.id]=true end
        local marker
        for _,old in ipairs(guide.legacySteps) do
            if visibleKeys[old.id] then marker=old; break end
        end
        assert(marker,guide.id.." has no visible saved-step candidate")
        saved.currentStepId=marker.id
        saved.current=1
        saved.completed[marker.id]=true
        local restored=guides:GetProgress(guide.id)
        assert(restored.currentStepId==marker.id
            and visible[restored.current].id==marker.id
            and restored.completed[marker.id],
            guide.id.." did not restore a visible saved step key")
    end
end
assert(converted==stats.converted)
assert(questCount==stats.quests)
assert(groupedPairs>25,"No meaningful multi-pickup circuits were generated")
assert(guides:GetGuide("alliance-westfall").routeStyle=="authored-circuits",
    "Hand-authored Westfall must not be rebuilt from the source catalog")
assert(guides:GetGuide("zephras-alliance").routeStyle==nil
    and guides:GetGuide("zephras-horde").routeStyle==nil
    and guides:GetGuide("first-steps").routeStyle==nil,
    "Already-authored Skyborne/tutorial guides must remain untouched")
assert(guides:GetGuide("dungeon-hall-of-thanes").routeStyle==nil,
    "Dungeon route and pre-run checklist must remain intact")

local function position(guideId,questId,action)
    for i,step in ipairs(guides:GetSteps(guideId)) do
        if step.questId==questId and step.action==action then return i,step end
    end
    error("Missing "..guideId.." quest "..questId.." "..action)
end
-- Known chain links must not be grouped into the same pickup lap.
local p1=position("alliance-elwynn",783,"turnin")
local p2=position("alliance-elwynn",7,"accept")
assert(p1<p2,"Kobold Camp Cleanup must not appear before A Threat Within turn-in")
local b1=position("alliance-darkshore",954,"turnin")
local b2=position("alliance-darkshore",955,"accept")
assert(b1<b2,"Bashal'Aran follow-up must wait for its prerequisite")

-- At least one known hub can pick up multiple independent quests at once.
local x1=position("alliance-elwynn",47,"accept")
local x2=position("alliance-elwynn",60,"accept")
local y1=position("alliance-elwynn",47,"turnin")
local y2=position("alliance-elwynn",60,"turnin")
assert(math.max(x1,x2)<math.min(y1,y2),
    "Goldshire quests should be accepted together before fieldwork")

print(string.format("All-zone source circuits: %d guides, %d quests, %d multi-pickup pairings, %d blocked source dependencies",
    converted,questCount,groupedPairs,stats.deferred))
