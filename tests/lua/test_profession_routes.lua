-- Synthetic fixture validates the planner without inventing Forever recipes.
local ns={Modules={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
assert(loadfile("shared/core/ProfessionRoutes.lua"))("WayForth",ns)
local routes=ns.Modules.ProfessionRoutes
local missing=routes:Plan("leatherworking",61,100)
assert(not missing.complete and missing.uncoveredSkill==61)
ns.professionRecipeCatalog.leatherworking={
    {name="Fixture A",spellId=900001,orangeFrom=1,orangeUntil=75,
        source="test fixture only",provenance={client="forever",verified=true,url="https://www.wowhead.com/forever/spell=900001",checkedBuild="synthetic-test-only"},reagents={{itemId=1001,name="Hide",count=2}}},
    {name="Fixture B",spellId=900002,orangeFrom=75,orangeUntil=100,
        source="test fixture only",provenance={client="forever",verified=true,url="https://www.wowhead.com/forever/spell=900002",checkedBuild="synthetic-test-only"},reagents={{itemId=1001,name="Hide",count=3},
            {itemId=1002,name="Thread",count=1}}},
    {name="Fixture Yellow",spellId=900003,orangeFrom=1,orangeUntil=61,
        source="test fixture only",reagents={{itemId=1003,name="Wrong",count=1}}},
}
local plan=routes:Plan("leatherworking",61,100)
assert(plan.complete and #plan.crafts==2)
assert(plan.crafts[1].count==14 and plan.crafts[2].count==25)
assert(plan.materials[1].itemId==1001 and plan.materials[1].required==103)
assert(plan.materials[2].itemId==1002 and plan.materials[2].required==25)
ns.professionRecipeCatalog.leatherworking[2].provenance.client="classic"
local rejected=routes:Plan("leatherworking",61,100)
assert(not rejected.complete and rejected.uncoveredSkill==75)
ns.professionRecipeCatalog.leatherworking[2].provenance.client="forever"
ns.professionRecipeCatalog.leatherworking[2].orangeFrom=76
local gap=routes:Plan("leatherworking",61,100)
assert(not gap.complete and gap.uncoveredSkill==75)
-- Intermediate output must not be purchased twice.
ns.professionRecipeCatalog.tailoring={
    {name="Bolt",spellId=910001,outputItemId=2101,yield=1,orangeFrom=1,orangeUntil=2,
        source="fixture",provenance={client="forever",verified=true,url="https://www.wowhead.com/forever/spell=910001",checkedBuild="synthetic"},
        reagents={{itemId=2100,name="Cloth",count=3}}},
    {name="Robe",spellId=910002,outputItemId=2102,yield=1,orangeFrom=2,orangeUntil=3,
        source="fixture",provenance={client="forever",verified=true,url="https://www.wowhead.com/forever/spell=910002",checkedBuild="synthetic"},
        reagents={{itemId=2101,name="Bolt",count=1},{itemId=2103,name="Thread",count=2}}},
}
local net=routes:Plan("tailoring",1,3)
assert(net.complete and #net.materials==2)
assert(net.materials[1].itemId==2100 and net.materials[1].required==3)
assert(net.materials[2].itemId==2103 and net.materials[2].required==2)
-- Client-verified yellow is allowed only below its GREEN threshold.
-- A 10-skill yellow segment plans 11 crafts, rounded up (10% reserve).
local proof={client="forever",verified=true,
    url="https://www.wowhead.com/forever/spell=990001",checkedBuild="synthetic"}
ns.professionRecipeCatalog.yellowtest={
    {name="Yellow Wax",spellId=990001,orangeFrom=1,orangeUntil=3,yellowUntil=13,
        learnAt=1,source="fixture",provenance=proof,
        reagents={{itemId=9991,name="Wax",count=2}}},
}
local orangeOnly=routes:Plan("yellowtest",3,13)
assert(not orangeOnly.complete and orangeOnly.uncoveredSkill==3)
local yellowPlan=routes:Plan("yellowtest",3,13,{allowYellow=true,yellowPadding=0.10})
assert(yellowPlan.complete and #yellowPlan.crafts==1)
assert(yellowPlan.crafts[1].color=="yellow")
assert(yellowPlan.crafts[1].skillPoints==10)
assert(yellowPlan.crafts[1].count==11 and yellowPlan.crafts[1].bufferExtra==1)
assert(yellowPlan.yellowBuffer==1 and yellowPlan.yellowCrafts==11)
assert(yellowPlan.materials[1].itemId==9991 and yellowPlan.materials[1].required==22)
local turnsGreen=routes:Plan("yellowtest",13,14,{allowYellow=true})
assert(not turnsGreen.complete and turnsGreen.uncoveredSkill==13)
-- Orange must take precedence over an inexpensive eligible yellow recipe.
ns.professionRecipeCatalog.yellowtest[2]={
    name="Orange Oil",spellId=990002,orangeFrom=3,orangeUntil=5,
    source="fixture",provenance=proof,reagents={{itemId=9992,name="Oil",count=4}}}
local preferred=routes:Plan("yellowtest",3,6,{allowYellow=true,yellowPadding=0.10})
assert(preferred.complete and #preferred.crafts==2)
assert(preferred.crafts[1].color=="orange" and preferred.crafts[1].count==2)
assert(preferred.crafts[2].color=="yellow" and preferred.crafts[2].count==2)
assert(preferred.crafts[2].bufferExtra==1 and preferred.crafts[2].skillPoints==1)
-- A Forever-client YELLOW band with Classic-derived orange boundaries
-- may be used as yellow only; it is NEVER promoted to guaranteed orange.
ns.professionRecipeCatalog.yellowtest[3]={
    name="Forever yellow only",spellId=990003,
    orangeFrom=13,orangeUntil=13,yellowUntil=23,yellowOnly=true,
    learnAt=13,source="https://foreverdb.net/spell/990003",
    provenance={client="forever",verified=true,
        checkedBuild="synthetic",orangeSource="classic",yellowSource="forever-client",
        url="https://foreverdb.net/spell/990003"},
    reagents={{itemId=9994,name="Copper",count=3}}
}
local notOrange=routes:Plan("yellowtest",13,23)
assert(not notOrange.complete and notOrange.uncoveredSkill==13)
local recovered=routes:Plan("yellowtest",13,23,{allowYellow=true,yellowPadding=0.10})
assert(recovered.complete and #recovered.crafts==1)
assert(recovered.crafts[1].color=="yellow")
assert(recovered.crafts[1].count==11 and recovered.crafts[1].bufferExtra==1)
assert(recovered.materials[1].itemId==9994 and recovered.materials[1].required==33)
local beyond=routes:Plan("yellowtest",23,24,{allowYellow=true})
assert(not beyond.complete and beyond.uncoveredSkill==23)
print("profession route fixture: OK")
