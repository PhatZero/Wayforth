-- Issue #65: first source-observed dungeon quest manifest and live checklist.
local ns={Modules={},state={acceptedQuestIDs={}},char={guideProgress={},turnedInQuests={}}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call() return true end
local faction="Alliance"
UnitFactionGroup=function() return faction end
UnitClass=function() return "Hunter","HUNTER" end
UnitLevel=function() return 16 end
local questStates={}
ns.Modules.QuestProgress={Get=function(_,id)
    return {state=questStates[id] or "inactive"}
end}
ns.Modules.Database={Get=function() return false end}
assert(loadfile("clients/forever/guides/DungeonGuides.lua"))("WayForth",ns)
local manifest=assert(ns.dungeonManifests["dungeon-hall-of-thanes"])
assert(manifest.coverage=="Partial" and #manifest.quests==4)
local unique={}
for _,quest in ipairs(manifest.quests) do
    assert(type(quest.id)=="number" and quest.url:find("foreverdb.net/quest/",1,true))
    assert(not unique[quest.id]);unique[quest.id]=true
    assert(type(quest.objective)=="string" and #quest.objective>12)
    if quest.pickup then
        assert(quest.pickup.mapId and quest.pickup.x and quest.pickup.y)
        assert(quest.turnin and quest.turnin.mapId and quest.turnin.x and quest.turnin.y)
    else
        assert(quest.pickupUnverified and quest.turninUnverified)
    end
end
local hall=assert(ns.starterGuides[1])
assert(hall.isDungeon and hall.testingOnly and hall.limitedData)
assert(hall.contentStatus:find("verification",1,true))
local work,pre,post,manual=0,0,0,0
for _,step in ipairs(hall.steps) do
    if step.id:find("%-pickup$") then pre=pre+1 end
    if step.id:find("%-work$") then
        work=work+1
        assert(not step.mapId and not step.x and not step.y,
            "No guessed instance waypoints")
    end
    if step.id:find("%-finish$") then post=post+1 end
    if step.action=="manual" then manual=manual+1 end
end
assert(pre==4 and work==4 and post==4 and manual==1)
assert(loadfile("shared/core/DungeonGuides.lua"))("WayForth",ns)
local d=ns.Modules.DungeonGuides
local initial=d:Overview(hall.id)
assert(initial.known==4 and initial.eligible==4)
assert(initial.collected==0 and initial.completed==0 and initial.unknown==4)
assert(initial.missingPickup==1 and initial.rows[4].status=="Unknown")
questStates[96403]="active"
questStates[96394]="ready"
ns.char.turnedInQuests[96393]=true
local synced=d:Overview(hall.id)
assert(synced.collected==3 and synced.completed==1 and synced.unknown==1)
assert(d:QuestStatus(manifest.quests[2])=="Ready to turn in")
assert(d:Summary(hall.id):find("Quests collected 3/4",1,true))
faction="Horde"
local horde=d:Overview(hall.id)
assert(horde.eligible==2 and horde.collected==1)
assert(horde.rows[1].status=="Not eligible" and horde.rows[2].status=="Not eligible")
faction="Alliance"
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
local guides=ns.Modules.Guides
assert(guides:SetActive(hall.id))
local visible=guides:GetSteps(hall.id)
local a,h=0,0
for _,step in ipairs(visible) do
    if step.questId==96394 then a=a+1 end
    if step.questId==96395 then h=h+1 end
end
assert(a==3 and h==3)
local saved=guides:GetProgress(hall.id)
guides:SetCurrent(3,hall.id)
guides:SkipCurrent(hall.id)
assert(saved.skipped[visible[3].id] and #guides:GetSteps(hall.id)==#visible)
assert(not ns.char.turnedInQuests[96395],"Skipping must not fake completed quests")
print("Forever dungeon manifest, faction-safe checklist and saved progress passed")
