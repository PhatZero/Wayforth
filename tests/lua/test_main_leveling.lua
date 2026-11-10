-- WayForth main leveling library smoke tests; no live client required.
-- Builds the same data catalog in the same order as the addon TOC.
local ns={Modules={},char={activeGuide="first-steps",guideProgress={},turnedInQuests={}},state={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
function ns:Call() return true end
UnitLevel=function() return 12 end
local faction="Alliance"
UnitFactionGroup=function() return faction end
UnitClass=function() return "Hunter","HUNTER" end
for _,file in ipairs({
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
    local load=assert(loadfile(file),file)
    load("WayForth",ns)
end
assert(loadfile("clients/forever/guides/ForeverQuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/QuestLocations.lua"))( "WayForth", ns)
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth",ns)
local guides,route=ns.Modules.Guides,ns.Modules.SmartRoutes
local total,listed=0,{}
local eligibleQuestIDs=0
local candidates=0
for _,guide in ipairs(guides:List()) do
    total=total+1
    assert(not listed[guide.id],"Duplicate guide ID: "..guide.id)
    listed[guide.id]=guide
    local keys={}
    assert(type(guide.steps)=="table" and #guide.steps>=1,"Empty guide: "..guide.id)
    if guide.testingOnly then
        candidates=candidates+1
        assert(guide.contentStatus and guide.contentStatus:find("verification"),
            "Tester route must disclose validation status: "..guide.id)
        assert(guide.faction=="Alliance" or guide.faction=="Horde")
        assert(guide.levelMin>=1 and guide.levelMax<=60)
        for _,step in ipairs(guide.steps) do
            assert(type(step.id)=="string" and not keys[step.id], "Duplicate step ID in "..guide.id)
            keys[step.id]=true
            assert(type(step.questId)=="number", "Quest ID missing in "..guide.id)
            assert(step.action=="accept" or step.action=="objective" or step.action=="turnin","Unexpected step kind")
            if step.x or step.y then
                assert(type(step.x)=="number" and step.x>=0 and step.x<=100)
                assert(type(step.y)=="number" and step.y>=0 and step.y<=100)
            end
            eligibleQuestIDs=eligibleQuestIDs+1
        end
    end
end
assert(total>=65,"Unexpectedly small route library: "..total)
assert(candidates>=48,"Missing faction zone test guides: "..candidates)
assert(eligibleQuestIDs>3000,"Main-route quest coverage unexpectedly small")
for _,id in ipairs({
    "horde-durotar","horde-mulgore","horde-tirisfal-glades",
    "horde-silverpine-forest","horde-the-barrens","horde-ashenvale",
    "alliance-westfall","alliance-loch-modan","alliance-duskwood",
    "alliance-wetlands","alliance-riverglades","horde-riverglades",
    "alliance-eastern-plaguelands","horde-eastern-plaguelands",
    "alliance-darkshore","alliance-elwynn","zephras-alliance","zephras-horde",
}) do assert(listed[id],"Missing main leveling guide: "..id) end
faction="Horde"
for _,guide in ipairs(route:ListGuides()) do
    assert(guide.faction==nil or guide.faction=="Horde","Horde sees Alliance-only guide")
end
-- Undead characters must see their first quest, but Orcs must not
-- inherit Undead-only story records.
local raceToken = "SCOURGE"
UnitRace=function() return raceToken == "SCOURGE" and "Undead" or "Orc", raceToken end
local foundIntro=false
for _,step in ipairs(guides:GetSteps("horde-tirisfal-glades")) do
    if step.questId == 363 then foundIntro=true end
end
assert(foundIntro,"Undead Rude Awakening intro missing")
raceToken="ORC"
for _,step in ipairs(guides:GetSteps("horde-tirisfal-glades")) do
    assert(step.questId ~= 363,"Undead-only quest leaked to Orc character")
end
raceToken="TAUREN"
local foundTauren=false
for _,step in ipairs(guides:GetSteps("horde-mulgore")) do
    if step.questId == 748 then foundTauren=true end
end
assert(foundTauren,"Tauren-only starter quest missing")
raceToken="ORC"
for _,step in ipairs(guides:GetSteps("horde-mulgore")) do
    assert(step.questId ~= 748,"Tauren-only starter quest leaked to Orc")
end
assert(guides:SetActive("horde-durotar"),"Cannot select Horde starting zone")
local progress=guides:GetProgress("horde-durotar")
local count=#guides:GetSteps("horde-durotar")
assert(count>=20,"Durotar route incomplete")
local step,index,amount=guides:CurrentStep("horde-durotar")
assert(step and index==1 and amount==count)
assert(progress.completed[step.id]~=true,"Unverified quest falsely marked completed")
faction="Alliance"
for _,guide in ipairs(route:ListGuides()) do
    assert(guide.faction==nil or guide.faction=="Alliance","Alliance sees Horde-only guide")
end
assert(guides:SetActive("alliance-westfall"),"Cannot select Alliance Westfall")
assert(ns.char.guideProgress["horde-durotar"]~=nil,
    "Switching factions/guides erased other saved progress")
print("WayForth main leveling routes passed: "..total.." guides, "..
      candidates.." test guides, "..eligibleQuestIDs.." candidate steps")
