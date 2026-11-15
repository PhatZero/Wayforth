-- Exercise actual imported ForeverDB build 1.60.1.70938 catalog, not fixtures.
local ns={Modules={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
assert(loadfile("clients/forever/guides/ForeverProfessionData.lua"))("WayForth",ns)
assert(loadfile("shared/core/ProfessionRoutes.lua"))("WayForth",ns)
local route=ns.Modules.ProfessionRoutes
local complete={alchemy=true,cooking=true,enchanting=true,leatherworking=true,tailoring=true}
local knownGaps={blacksmithing=20,engineering=30,["first-aid"]=30}
local total=0
for _,slug in ipairs({"alchemy","blacksmithing","cooking","enchanting",
    "engineering","first-aid","leatherworking","tailoring"}) do
    local catalog=assert(ns.professionRecipeCatalog[slug])
    assert(#catalog>0,slug)
    total=total+#catalog
    local plan=route:Plan(slug,1,300)
    if complete[slug] then
        assert(plan.complete and #plan.crafts>0 and #plan.materials>0,slug.." must have complete offline route")
        local sum=0
        for _,item in ipairs(plan.materials) do
            assert(type(item.itemId)=="number" and item.required>0)
            sum=sum+item.required
        end
        assert(sum>0)
    else
        assert(not plan.complete and plan.uncoveredSkill==knownGaps[slug],slug.." data gap must be explicit")
        assert(#plan.crafts>0 and #plan.materials>0,slug.." verified prefix must be preserved")
    end
end
for _,slug in ipairs({"fishing","herbalism","mining","skinning"}) do
    local catalog=assert(ns.professionGatheringCatalog[slug])
    assert(#catalog>0,"Missing gathering options for "..slug)
end
local leather=route:Plan("leatherworking",61,100)
assert(leather.complete and #leather.crafts>0 and #leather.materials>0)
print("Forever profession catalog: "..total.." client-verified recipes, all 12 profiles, 5 full 1-300 routes, 3 explicit source gaps, Leatherworking 61-100 OK")
