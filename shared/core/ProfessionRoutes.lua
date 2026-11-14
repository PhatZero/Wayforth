-- Offline profession route engine. Catalog entries must be verified against
-- WoW Forever before inclusion. Never fill missing ranges with guesses.
local _, ns = ...
local Route = {}
ns:RegisterModule("ProfessionRoutes", Route)

-- A catalog entry: {name, spellId, outputItemId, yield, orangeFrom,
-- orangeUntil, reagents={{itemId,name,count}}, source}.
-- orangeUntil is exclusive. Every planned skill must have an orange recipe.
ns.professionRecipeCatalog = ns.professionRecipeCatalog or {}

local function valid(recipe)
    if type(recipe)~="table" or type(recipe.name)~="string"
        or type(recipe.spellId)~="number" or type(recipe.orangeFrom)~="number"
        or type(recipe.orangeUntil)~="number"
        or recipe.orangeUntil<=recipe.orangeFrom
        or type(recipe.source)~="string" or recipe.source=="" then return false end
    if type(recipe.reagents)~="table" or #recipe.reagents==0 then return false end
    for _,reagent in ipairs(recipe.reagents) do
        if type(reagent.itemId)~="number" or type(reagent.count)~="number"
            or reagent.count<=0 or type(reagent.name)~="string" then return false end
    end
    return true
end

function Route:Plan(profession, fromSkill, toSkill)
    local result={profession=profession,fromSkill=fromSkill,toSkill=toSkill,
        crafts={},materials={},complete=false}
    if type(fromSkill)~="number" or type(toSkill)~="number"
        or fromSkill<1 or toSkill<fromSkill then
        result.error="Invalid profession skill range"
        return result
    end
    local catalog=ns.professionRecipeCatalog[profession] or {}
    local totals,skill={},fromSkill
    while skill<toSkill do
        local chosen
        for _,recipe in ipairs(catalog) do
            if valid(recipe) and recipe.orangeFrom<=skill and skill<recipe.orangeUntil then
                if not chosen or #recipe.reagents<#chosen.reagents
                    or (#recipe.reagents==#chosen.reagents and recipe.spellId<chosen.spellId) then
                    chosen=recipe
                end
            end
        end
        if not chosen then
            result.uncoveredSkill=skill
            result.error="No source-verified orange recipe at skill "..skill
            return result
        end
        local count=math.min(toSkill,chosen.orangeUntil)-skill
        local previous=result.crafts[#result.crafts]
        if previous and previous.spellId==chosen.spellId then
            previous.count=previous.count+count
            previous.toSkill=skill+count
        else
            result.crafts[#result.crafts+1]={name=chosen.name,spellId=chosen.spellId,
                count=count,fromSkill=skill,toSkill=skill+count,source=chosen.source}
        end
        for _,reagent in ipairs(chosen.reagents) do
            local entry=totals[reagent.itemId]
            if not entry then
                entry={itemId=reagent.itemId,name=reagent.name,required=0}
                totals[reagent.itemId]=entry
            end
            entry.required=entry.required+reagent.count*count
        end
        skill=skill+count
    end
    for _,entry in pairs(totals) do
        result.materials[#result.materials+1]=entry
    end
    table.sort(result.materials,function(a,b) return a.itemId<b.itemId end)
    result.complete=true
    return result
end
