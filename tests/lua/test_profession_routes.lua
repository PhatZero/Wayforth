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
        source="test fixture only",reagents={{itemId=1001,name="Hide",count=3},
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
print("profession route fixture: OK")
