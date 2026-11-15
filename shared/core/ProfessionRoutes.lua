-- Offline profession route engine. Catalog entries must be verified against
-- WoW Forever before inclusion. Never fill missing ranges with guesses.
local _, ns = ...
local Route = {}
ns:RegisterModule("ProfessionRoutes", Route)

-- A catalog entry: {name, spellId, outputItemId, yield, orangeFrom,
-- orangeUntil, reagents={{itemId,name,count}}, source}.
-- orangeUntil is exclusive. Every planned skill must have an orange recipe.
-- provenance = {client="forever", verified=true, url="https://www.wowhead.com/forever/...", checkedBuild="..."}.
-- Only verified Forever records are eligible for planning.
ns.professionRecipeCatalog = ns.professionRecipeCatalog or {}

local function valid(recipe)
    local provenance=recipe and recipe.provenance
    if type(provenance)~="table" or provenance.client~="forever"
        or provenance.verified~=true or type(provenance.url)~="string"
        or not (provenance.url:match("^https://www%.wowhead%.com/forever/")
            or provenance.url:match("^https://foreverdb%.net/"))
        or type(provenance.checkedBuild)~="string" or provenance.checkedBuild=="" then return false end
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
    local totals,stock,skill={},{},fromSkill
    local function materialize()
        result.materials={}
        for _,entry in pairs(totals) do result.materials[#result.materials+1]=entry end
        table.sort(result.materials,function(a,b) return a.itemId<b.itemId end)
    end
    -- Evaluate every craft in actual route order. An intermediate made by a
    -- *later* recipe cannot satisfy an earlier craft. Count missing external
    -- materials only when needed and consume available intermediate stock.
    while skill<toSkill do
        local chosen
        local chosenCost,chosenPriority
        for _,recipe in ipairs(catalog) do
            if valid(recipe) and recipe.orangeFrom<=skill and skill<recipe.orangeUntil
                and (type(recipe.learnAt)~="number" or recipe.learnAt<=skill) then
                local cost=0
                for _,reagent in ipairs(recipe.reagents) do cost=cost+reagent.count end
                local priority=type(recipe.sourcePriority)=="number" and recipe.sourcePriority or 0
                if not chosen or priority<chosenPriority
                    or (priority==chosenPriority and cost<chosenCost)
                    or (priority==chosenPriority and cost==chosenCost and recipe.spellId<chosen.spellId) then
                    chosen,chosenCost,chosenPriority=recipe,cost,priority
                end
            end
        end
        if not chosen then
            result.uncoveredSkill=skill
            result.error="No source-verified orange recipe at skill "..skill
            materialize()
            return result
        end
        local count=math.min(toSkill,chosen.orangeUntil)-skill
        local previous=result.crafts[#result.crafts]
        if previous and previous.spellId==chosen.spellId then
            previous.count=previous.count+count
            previous.toSkill=skill+count
        else
            result.crafts[#result.crafts+1]={name=chosen.name,spellId=chosen.spellId,
                count=count,fromSkill=skill,toSkill=skill+count,source=chosen.source,
                outputItemId=chosen.outputItemId,outputCount=chosen.yield or 1,
                learnAt=chosen.learnAt,trainer=chosen.trainer,acquisition=chosen.acquisition}
        end
        for _,reagent in ipairs(chosen.reagents) do
            local required=reagent.count*count
            local used=math.min(stock[reagent.itemId] or 0,required)
            stock[reagent.itemId]=(stock[reagent.itemId] or 0)-used
            local external=required-used
            if external>0 then
                local entry=totals[reagent.itemId]
                if not entry then
                    entry={itemId=reagent.itemId,name=reagent.name,required=0}
                    totals[reagent.itemId]=entry
                end
                entry.required=entry.required+external
            end
        end
        if type(chosen.outputItemId)=="number" then
            local yield=type(chosen.yield)=="number" and chosen.yield>0 and chosen.yield or 1
            stock[chosen.outputItemId]=(stock[chosen.outputItemId] or 0)+count*yield
        end
        skill=skill+count
    end
    materialize()
    result.complete=true
    return result
end
