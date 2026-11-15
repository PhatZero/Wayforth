-- End-to-end synthetic engine fixture: offline planning, bag/bank counts,
-- live orange recipe fallback, observed successful casts and saved progress.
local ns={Modules={},char={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
ns.professionProfiles={{id="tailoring",name="Tailoring",skillLine=197,method="Gather cloth."}}
function GetProfessions() return 1 end
function GetProfessionInfo(index)
    assert(index==1)
    return "Tailoring","icon",1,75,0,0,197
end
function GetTradeSkillLine() return "Tailoring" end
function GetNumTradeSkills() return 1 end
function GetTradeSkillInfo(index) return "Fixture Bolt","optimal" end
function GetTradeSkillNumReagents(index) return 1 end
function GetTradeSkillReagentInfo(index,reagent) return "Cloth","icon",1,5 end
function GetTradeSkillReagentItemLink() return "|Hitem:2100:0|h[Cloth]|h" end
function GetTradeSkillRecipeLink() return "|Henchant:9001:0|h[Fixture Bolt]|h" end
local items={[2100]=5,[2101]=0,[2103]=0}
function GetItemCount(id,includeBank)
    assert(includeBank==true)
    return items[id] or 0
end
local stamp={client="forever",verified=true,checkedBuild="synthetic",url="https://www.wowhead.com/forever/spell=9001"}
ns.professionRecipeCatalog={tailoring={
    {name="Fixture Bolt",spellId=9001,orangeFrom=1,orangeUntil=20,
        outputItemId=2101,yield=1,source="synthetic",provenance=stamp,
        reagents={{itemId=2100,name="Cloth",count=1}}},
    {name="Fixture Garment",spellId=9002,orangeFrom=20,orangeUntil=50,
        outputItemId=2110,yield=1,source="synthetic",provenance=stamp,
        reagents={{itemId=2101,name="Bolt",count=1},{itemId=2103,name="Thread",count=2}}},
    {name="Fixture Tabard",spellId=9003,orangeFrom=50,orangeUntil=301,
        outputItemId=2111,yield=1,source="synthetic",provenance=stamp,
        reagents={{itemId=2103,name="Thread",count=1}}},
}}
assert(loadfile("shared/core/ProfessionRoutes.lua"))("WayForth",ns)
assert(loadfile("shared/core/ProfessionGuides.lua"))("WayForth",ns)
local guides=ns.Modules.ProfessionGuides
local plan=guides:GatherPlan("tailoring")
assert(plan and plan.offline and plan.verified and not plan.ready)
assert(plan.target==300 and #plan.crafts==3 and plan.crafts[1].required==19
    and plan.crafts[2].required==30 and plan.crafts[3].required==250)
assert(#plan.materials==3)
assert(plan.materials[1].itemId==2100 and plan.materials[1].required==19)
assert(plan.materials[1].owned==5 and plan.materials[1].missing==14)
assert(plan.materials[2].itemId==2101 and plan.materials[2].required==11)
assert(plan.materials[3].itemId==2103 and plan.materials[3].required==310)
assert(ns.char.professionRouteProgress.tailoring.startSkill==1)
local selected=guides:Recommendation("tailoring")
assert(selected and selected.spellId==9001 and selected.reagents[1].itemId==2100)
local ok,id=guides:RecordCraftEvent("player","CAST-1",9001)
assert(ok and id=="tailoring")
assert(not guides:RecordCraftEvent("target","CAST-2",9001))
assert(not guides:RecordCraftEvent("player","CAST-3",99999))
local ok2,id2=guides:RecordCraftEvent("player","CAST-4",9003)
assert(ok2 and id2=="tailoring")
assert(ns.char.professionSuccessfulCrafts.tailoring[9001]==1)
local progressed=guides:GatherPlan("tailoring")
assert(progressed.crafts[1].completed==1)
assert(progressed.crafts[3].completed==1)
assert(ns.char.professionRouteProgress.tailoring.baseline[9001]==0)
-- A missing Forever-verified range cannot masquerade as a complete route.
ns.professionRecipeCatalog.tailoring[2].provenance={client="forever",verified=false,
    checkedBuild="synthetic",url="https://www.wowhead.com/forever/spell=9002"}
local gap=guides:GatherPlan("tailoring")
assert(not gap.offline and gap.verifiedSegment and gap.segmentEnd==20)
assert(#gap.crafts==1 and gap.crafts[1].required==19)
assert(gap.materials[1].itemId==2100 and gap.materials[1].required==19)
-- Once all client-verified coverage disappears and the window closes,
-- a cached scan cannot claim current orange status.
ns.professionRecipeCatalog.tailoring[1].provenance={client="forever",verified=false,
    checkedBuild="synthetic",url="https://www.wowhead.com/forever/spell=9001"}
GetTradeSkillLine=function() return "Other" end
local stale=guides:GatherPlan("tailoring")
assert(not stale.offline and stale.requiresScan and #stale.materials==0)
print("profession runtime fixture: OK")
