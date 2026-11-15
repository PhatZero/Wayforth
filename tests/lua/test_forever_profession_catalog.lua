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
-- All eligible yellow intervals come from the imported Forever client bands.
local options={allowYellow=true,yellowPadding=0.10}
for _,slug in ipairs({"alchemy","blacksmithing","cooking","enchanting",
    "leatherworking","tailoring"}) do
    local planned=route:Plan(slug,1,300,options)
    assert(planned.complete,slug.." must have a verified orange/yellow route")
end
local steel=route:Plan("blacksmithing",20,30,options)
assert(steel.complete and (steel.yellowCrafts or 0)>0)
assert((steel.yellowBuffer or 0)>0,"yellow reserve missing")
local engineering=route:Plan("engineering",1,300,options)
assert(not engineering.complete and engineering.uncoveredSkill==52)
-- Classic-derived orange thresholds are not guaranteed. These same
-- records contain client-reported yellow-to-green bands, which we may use
-- as YELLOW ONLY with the 10% craft reserve.
for _,slug in ipairs({"engineering","first-aid"}) do
    local recovered=0
    for _,recipe in ipairs(ns.professionRecipeCatalog[slug]) do
        if recipe.yellowOnly==true and recipe.provenance
            and recipe.provenance.orangeSource=="classic"
            and recipe.provenance.yellowSource=="forever-client" then
            assert(recipe.orangeFrom==recipe.orangeUntil)
            assert(recipe.yellowUntil>recipe.orangeUntil)
            recovered=recovered+1
        end
    end
    assert(recovered>0,slug.." must recover Forever-client yellow-only records")
end
local copper=route:Plan("engineering",45,52,options)
assert(copper.complete and (copper.yellowCrafts or 0)>0)
assert(not route:Plan("engineering",45,52).complete)
local linen=route:Plan("first-aid",50,75,options)
assert(linen.complete and (linen.yellowCrafts or 0)>0)
local firstAid=route:Plan("first-aid",1,300,options)
assert(not firstAid.complete and firstAid.uncoveredSkill==45)
for _,slug in ipairs({"fishing","herbalism","mining","skinning"}) do
    local catalog=assert(ns.professionGatheringCatalog[slug])
    assert(#catalog>0,"Missing gathering options for "..slug)
end
local leather=route:Plan("leatherworking",61,100)
assert(leather.complete and #leather.crafts>0 and #leather.materials>0)
print("Forever profession catalog: "..total.." client-verified recipes, all 12 profiles, 6 orange/yellow 1-300 routes, 2 explicit source gaps, Leatherworking 61-100 OK")
