-- Skill-aware profession guides; no fixed recipe or item-price assumptions.
local _, ns = ...
local Profession = {}
ns:RegisterModule("ProfessionGuides", Profession)

local profiles = {}
for _, row in ipairs(ns.professionProfiles or {}) do profiles[row.id]=row end
local bySkillLine = {}
local lastRecommendation = {}
local recipeSnapshots = {}
for _, row in ipairs(ns.professionProfiles or {}) do bySkillLine[row.skillLine]=row.id end
local function cleanName(value)
    return tostring(value or ""):lower():gsub("[^%a]", "")
end
local function number(value)
    return type(value)=="number" and value>=0 and value==value and value or nil
end
local function infoValues(...)
    local first={...}
    if type(first[1])=="table" then
        local row=first[1]
        return row.professionName or row.name,number(row.skillLevel or row.skillRank),
            number(row.maxSkillLevel or row.maxSkillRank),number(row.skillLineID or row.skillLine)
    end
    return first[1],number(first[3]),number(first[4]),number(first[7])
end

function Profession:Read()
    local result={}
    local function add(name,skill,maxSkill,skillLine)
        local id=bySkillLine[skillLine] or self:IdForName(name)
        skill,maxSkill=number(skill),number(maxSkill)
        if id and skill then
            result[id]={id=id,name=profiles[id].name,skill=skill,maxSkill=maxSkill or 0,skillLine=skillLine}
        end
    end
    -- Supported by the classic-style skill window and retained by many Forever builds.
    if type(GetProfessions)=="function" and type(GetProfessionInfo)=="function" then
        local ok,indexes,count=pcall(function()
            local function pack(...) return {n=select("#",...),...} end
            local values=pack(GetProfessions())
            return values,values.n
        end)
        if ok then
            for position=1,count do
                local index=indexes[position]
                if type(index)=="number" then
                    local values={pcall(GetProfessionInfo,index)}
                    if values[1] then
                        table.remove(values,1)
                        add(infoValues(unpack(values)))
                    end
                end
            end
        end
    end
    -- Newer trade-skill APIs can expose secondary skills by skill-line ID.
    local api=C_TradeSkillUI
    if type(api)=="table" and type(api.GetProfessionInfoBySkillLineID)=="function" then
        for skillLine,id in pairs(bySkillLine) do
            if not result[id] then
                local ok,a,b,c,d,e,f,g=pcall(api.GetProfessionInfoBySkillLineID,skillLine)
                if ok then
                    local name,skill,maxSkill,line=infoValues(a,b,c,d,e,f,g)
                    add(name,skill,maxSkill,line or skillLine)
                    if not result[id] and skill then add(profiles[id].name,skill,maxSkill,skillLine) end
                end
            end
        end
    end
    -- Last fallback for clients exposing only the Character Skills list.
    if type(GetNumSkillLines)=="function" and type(GetSkillLineInfo)=="function" then
        local ok,count=pcall(GetNumSkillLines)
        if ok and type(count)=="number" then
            for index=1,math.min(count,100) do
                local values={pcall(GetSkillLineInfo,index)}
                if values[1] then
                    local name,isHeader,_,skill,maxSkill=unpack(values,2)
                    if not isHeader then add(name,skill,maxSkill) end
                end
            end
        end
    end
    return result
end

function Profession:IdForName(name)
    local key=cleanName(name)
    for id,row in pairs(profiles) do if cleanName(row.name)==key then return id end end
end

function Profession:Selected(id)
    local all=self:Read()
    return id and all[id] or nil,all
end

function Profession:Suggested()
    local all=self:Read()
    for _,row in ipairs(ns.professionProfiles or {}) do if all[row.id] then return row.id end end
    return "alchemy"
end

-- Read the classic trade-skill list when it is open. It exposes the character's
-- learned recipes, live skill-up color, reagent quantities and bag counts, which
-- lets the guide recommend a recipe without bundling stale price/recipe tables.
function Profession:Recommendation(id)
    local profile=profiles[id]
    if not profile then return nil,"Choose a profession first." end
    if id=="fishing" or id=="herbalism" or id=="mining" or id=="skinning" then
        return nil,profile.method
    end
    if type(GetTradeSkillLine)~="function" or type(GetNumTradeSkills)~="function"
        or type(GetTradeSkillInfo)~="function" then
        return nil,"Recipe color cannot be verified while the profession window is closed. Reopen it before crafting."
    end
    local ok,line=pcall(GetTradeSkillLine)
    if not ok or self:IdForName(line)~=id then
        return nil,"Recipe color cannot be verified while the profession window is closed. Reopen it before crafting."
    end
    local countOk,count=pcall(GetNumTradeSkills)
    if not countOk or type(count)~="number" then
        return nil,"Recipe color cannot be verified while the profession window is closed. Reopen it before crafting."
    end

    local candidates={}
    for index=1,math.min(count,1000) do
        local rowOk,name,color=pcall(GetTradeSkillInfo,index)
        local colorName=type(color)=="string" and color:lower() or ""
        if rowOk and type(name)=="string" and (colorName=="optimal" or colorName=="medium") then
            local reagentCount=0
            if type(GetTradeSkillNumReagents)=="function" then
                local reagentsOk,value=pcall(GetTradeSkillNumReagents,index)
                if reagentsOk and type(value)=="number" then reagentCount=math.min(value,20) end
            end
            local reagents,total,missing={},0,0
            for reagentIndex=1,reagentCount do
                if type(GetTradeSkillReagentInfo)=="function" then
                    local reagentOk,reagentName,_,amount,owned=pcall(GetTradeSkillReagentInfo,index,reagentIndex)
                    if reagentOk and type(reagentName)=="string" and type(amount)=="number" then
                        owned=type(owned)=="number" and owned or 0
                        total=total+amount
                        missing=missing+math.max(0,amount-owned)
                        local itemId=nil
                        if type(GetTradeSkillReagentItemLink)=="function" then
                            local linkOk,link=pcall(GetTradeSkillReagentItemLink,index,reagentIndex)
                            if linkOk and type(link)=="string" then
                                itemId=tonumber(link:match("item:(%d+)"))
                            end
                        end
                        reagents[#reagents+1]={name=reagentName,itemId=itemId,count=amount,owned=owned}
                    end
                end
            end
            if #reagents>0 then
                -- Orange is preferred; medium (yellow) is an eligible fallback.
                -- Yellow has no guaranteed skill gain, so reserve materials.
                local spellId=nil
                if type(GetTradeSkillRecipeLink)=="function" then
                    local linkOk,link=pcall(GetTradeSkillRecipeLink,index)
                    if linkOk and type(link)=="string" then
                        spellId=tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
                    end
                end
                local color=colorName=="optimal" and "orange" or "yellow"
                candidates[#candidates+1]={name=name,spellId=spellId,color=color,reagents=reagents,
                    total=total,missing=missing,colorRank=color=="orange" and 1 or 2}
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.colorRank~=b.colorRank then return a.colorRank<b.colorRank end
        if a.missing~=b.missing then return a.missing<b.missing end
        if a.total~=b.total then return a.total<b.total end
        return a.name<b.name
    end)
    if #candidates==0 then
        lastRecommendation[id]=nil
        recipeSnapshots[id]=nil
        if ns.char and ns.char.professionRecipeCache then ns.char.professionRecipeCache[id]=nil end
        return nil,"No orange or yellow recipe is visible. Train a suitable recipe or refresh the profession window."
    end
    lastRecommendation[id]=candidates[1]
    recipeSnapshots[id]=candidates
    if ns.char then
        ns.char.professionRecipeCache=ns.char.professionRecipeCache or {}
        ns.char.professionRecipeCache[id]=candidates
    end
    return lastRecommendation[id]
end

-- Track observed successful spellcasts separately from skill gains.
-- This is a per-character record and never assumes a skill point equals a craft.
function Profession:RecordCraft(spellId)
    if type(spellId)~="number" or not ns.char then return false end
    local professionId,recipeName
    for id,candidates in pairs(recipeSnapshots) do
        for _,candidate in ipairs(candidates) do
            if candidate.spellId==spellId then
                professionId,recipeName=id,candidate.name
                break
            end
        end
        if professionId then break end
    end
    -- The offline catalog also supplies spell IDs before the trade-skill
    -- window has ever been opened. Never infer success from a skill gain.
    if not professionId then
        for id,recipes in pairs(ns.professionRecipeCatalog or {}) do
            for _,recipe in ipairs(recipes) do
                if recipe.spellId==spellId and recipe.provenance
                    and recipe.provenance.client=="forever"
                    and recipe.provenance.verified==true then
                    professionId,recipeName=id,recipe.name
                    break
                end
            end
            if professionId then break end
        end
    end
    if not professionId then return false end
    ns.char.professionSuccessfulCrafts=ns.char.professionSuccessfulCrafts or {}
    local counts=ns.char.professionSuccessfulCrafts
    counts[professionId]=counts[professionId] or {}
    counts[professionId][spellId]=(counts[professionId][spellId] or 0)+1
    return true,professionId,recipeName
end

function Profession:RecordCraftEvent(unit,...)
    if unit~="player" then return false end
    -- Signature differs between WoW client families. Only match numeric spell
    -- IDs already read from actual profession links; never count unrelated casts.
    for i=1,select("#",...) do
        local value=select(i,...)
        if type(value)=="number" then
            local recorded,id,name=self:RecordCraft(value)
            if recorded then return true,id,name end
        end
    end
    return false
end

function Profession:PlanText(id)
    local profile=profiles[id]
    if not profile then return nil end
    if id=="fishing" or id=="herbalism" or id=="mining" or id=="skinning" then
        return "Next action: "..profile.method
    end
    local recipe,message=self:Recommendation(id)
    if not recipe then return "Next craft: "..tostring(message or "Open this profession's recipe list to calculate the next skill-up.") end
    local materials={}
    for _,reagent in ipairs(recipe.reagents or {}) do
        materials[#materials+1]=reagent.count.."x "..reagent.name.." (have "..reagent.owned..")"
    end
    return "MAKE: "..recipe.name.." ("..recipe.color..")\nNeed: "..table.concat(materials,", ")
end

function Profession:RouteTarget(skill,maxSkill)
    maxSkill=number(maxSkill) or 0
    if maxSkill>=300 then return 300,"Artisan" end
    if maxSkill>=225 then return maxSkill-25,"Artisan" end
    if maxSkill>=150 then return maxSkill-25,"Expert" end
    if maxSkill>=75 then return maxSkill-25,"Journeyman" end
    return maxSkill>0 and maxSkill or 300,"next rank"
end

function Profession:Sync(id)
    local guideId=id or (ns.char and ns.char.activeGuide)
    local guide=ns.Modules.Guides:GetGuide(guideId)
    if not guide or not guide.isProfession then return false end
    local snapshot=self:Read()[guide.professionId]
    if not snapshot then return false,"Open the profession or skills window once so WayForth can read its current skill." end
    ns.char.professions=type(ns.char.professions)=="table" and ns.char.professions or {}
    ns.char.professions[guide.professionId]={skill=snapshot.skill,maxSkill=snapshot.maxSkill}
    local saved=ns.Modules.Guides:GetProgress(guide.id)
    local steps=ns.Modules.Guides:GetSteps(guide.id)
    local changed=false
    for index,step in ipairs(steps) do
        local complete=step.skillComplete and snapshot.skill>=step.skillComplete
            or step.rankCap and snapshot.maxSkill>step.rankCap
        local key=step.id or index
        if complete and not saved.completed[key] then saved.completed[key]=true;changed=true end
    end
    local settings=ns.Modules.Database
    local advance=not settings or settings:Get("autoAdvance")~=false
    local paused=settings and settings:Get("guidePaused")==true
    if advance and not paused then
        while saved.current<#steps and saved.completed[steps[saved.current].id or saved.current] do
            ns.Modules.Guides:SetCurrent(saved.current+1,guide.id)
            changed=true
        end
    end
    return changed,snapshot
end

function Profession:Start(id)
    local guideId="profession-"..tostring(id)
    local guide=ns.Modules.Guides:GetGuide(guideId)
    if not guide or not guide.isProfession then return false,"Choose a profession guide first." end
    ns.Modules.Guides:SetActive(guideId)
    local _,message=self:Sync(guideId)
    ns:Call("Tracker","Show")
    if ns.Modules.UI then ns:Call("UI","Hide") end
    return true,message
end


-- Profession planning is offline first. Only verified Forever recipe data
-- can establish a full shopping list. Live scans are limited to the next craft.
local gathering={fishing=true,herbalism=true,mining=true,skinning=true}
local allianceOnly={["Elwynn Forest"]=true,["Dun Morogh"]=true,
    ["Teldrassil"]=true,["Loch Modan"]=true,["Westfall"]=true,
    ["Redridge Mountains"]=true,["Darkshore"]=true,["Darnassus"]=true,
    ["Ironforge"]=true,["Stormwind City"]=true}
local hordeOnly={["Durotar"]=true,["Mulgore"]=true,["Tirisfal Glades"]=true,
    ["The Barrens"]=true,["Silverpine Forest"]=true,
    ["Orgrimmar"]=true,["Undercity"]=true,["Thunder Bluff"]=true}
local function availableZone(zone)
    if type(UnitFactionGroup)~="function" then return true end
    local ok,faction=pcall(UnitFactionGroup,"player")
    if not ok then return true end
    return not (faction=="Alliance" and hordeOnly[zone]
        or faction=="Horde" and allianceOnly[zone])
end
local function inventoryCount(id,name,fallback)
    if type(GetItemCount)=="function" then
        local lookup=id or name
        if lookup then
            local ok,amount=pcall(GetItemCount,lookup,true)
            if ok and type(amount)=="number" and amount>=0 then return amount end
        end
    end
    if type(C_Item)=="table" and type(C_Item.GetItemCount)=="function" then
        local ok,amount=pcall(C_Item.GetItemCount,id or name,true)
        if ok and type(amount)=="number" and amount>=0 then return amount end
    end
    return fallback or 0
end

function Profession:GatherPlan(id)
    local profile=profiles[id]
    if not profile then return nil end
    local snapshot=self:Read()[id]
    local skill=snapshot and snapshot.skill or 0
    local cap=snapshot and snapshot.maxSkill or 0
    -- Show full 1-to-300 material and craft requirements up front when
    -- the entire route has source-verified orange coverage.
    local target=gathering[id] and math.min(300,math.max(50,math.ceil(math.max(skill,1)/50)*50)) or 300
    local plan={id=id,name=profile.name,skill=skill,target=target,cap=cap,
        materials={},crafts={},gathering=gathering[id],ready=false}
    if skill>=300 then
        plan.instructions="Maximum profession skill reached."
        plan.complete=true
        return plan
    end
    if cap>0 and skill>=cap then
        plan.needsTrainer=true
    end
    if plan.gathering then
        local catalog=ns.professionGatheringCatalog and ns.professionGatheringCatalog[id] or {}
        local options={}
        for _,entry in ipairs(catalog) do
            if entry.client=="forever" and type(entry.skillFrom)=="number"
                and type(entry.skillUntil)=="number"
                and entry.skillFrom<=math.max(1,skill) and skill<entry.skillUntil
                and availableZone(entry.zone) then
                options[#options+1]=entry
            end
        end
        table.sort(options,function(a,b)
            if a.verified~=b.verified then return a.verified==true end
            if a.skillFrom~=b.skillFrom then return a.skillFrom>b.skillFrom end
            return tostring(a.zone)<tostring(b.zone)
        end)
        plan.gatheringOptions={}
        for i=1,math.min(3,#options) do
            plan.gatheringOptions[i]=options[i]
        end
        plan.gatheringTarget=options[1]
        plan.instructions=plan.gatheringTarget and
            (plan.gatheringTarget.zone..": "..plan.gatheringTarget.instructions..
             " Verify gathering skill gains in the live client.")
            or (profile.method.." No zone route is verified for your current skill.")
        return plan
    end

    local routes=ns.Modules.ProfessionRoutes
    local options={allowYellow=true,yellowPadding=0.10}
    plan.yellowPadding=options.yellowPadding
    if routes and ns.char and skill>0 and target>skill then
        ns.char.professionRouteProgress=ns.char.professionRouteProgress or {}
        local saved=ns.char.professionRouteProgress[id]
        if not saved or saved.target~=target or (saved.startSkill or skill)>skill then
            saved={startSkill=skill,target=target,baseline={}}
            ns.char.professionRouteProgress[id]=saved
        end
        local all=routes:Plan(id,saved.startSkill,target,options)
        local remaining=routes:Plan(id,skill,target,options)
        plan.yellowCrafts=remaining.yellowCrafts or 0
        plan.yellowBuffer=remaining.yellowBuffer or 0
        if all.complete and remaining.complete then
            plan.verified=true
            plan.offline=true
            plan.instructions=plan.needsTrainer
                and "Train your next profession rank before crafting. Full 1-to-300 materials are shown below."
                or "Source-verified orange-first route; yellow crafts include a 10% reserve. Yellow skill-ups are not guaranteed. Recalculate after each skill change."
            local counts=ns.char.professionSuccessfulCrafts and ns.char.professionSuccessfulCrafts[id] or {}
            local accounted={}
            for _,craft in ipairs(all.crafts) do
                local observed=counts[craft.spellId] or 0
                if saved.baseline[craft.spellId]==nil then saved.baseline[craft.spellId]=observed end
                local available=math.max(0,observed-saved.baseline[craft.spellId]-(accounted[craft.spellId] or 0))
                local finished=math.min(craft.count,available)
                accounted[craft.spellId]=(accounted[craft.spellId] or 0)+finished
                plan.crafts[#plan.crafts+1]={name=craft.name,spellId=craft.spellId,
                    color=craft.color or "orange",required=craft.count,completed=finished,
                    skillPoints=craft.skillPoints,bufferExtra=craft.bufferExtra or 0,
                    fromSkill=craft.fromSkill,toSkill=craft.toSkill,
                    progressType="observed-cast",acquisition=craft.acquisition,
                    learnAt=craft.learnAt,trainer=craft.trainer}
            end
            plan.ready=true
            for _,item in ipairs(remaining.materials) do
                local owned=inventoryCount(item.itemId,item.name,0)
                local entry={itemId=item.itemId,name=item.name,required=item.required,
                    owned=owned,missing=math.max(0,item.required-owned)}
                plan.materials[#plan.materials+1]=entry
                if entry.missing>0 then plan.ready=false end
            end
            return plan
        end
        plan.coverageGap=remaining.uncoveredSkill or all.uncoveredSkill
        plan.partial=true
        -- A gap later in the skill line must not discard a verified, playable
        -- orange sequence that reaches that gap. Display only its exact
        -- materials and mark the remaining range unavailable.
        if not remaining.complete and #remaining.crafts>0 then
            plan.verifiedSegment=true
            plan.segmentEnd=remaining.uncoveredSkill
            plan.instructions="Verified orange/yellow sequence until skill "..tostring(plan.segmentEnd)..
                ". Yellow steps include a 10% reserve; their skill gains are not guaranteed. No verified color route exists beyond this boundary."
            local counts=ns.char.professionSuccessfulCrafts and ns.char.professionSuccessfulCrafts[id] or {}
            for _,craft in ipairs(remaining.crafts) do
                local observed=counts[craft.spellId] or 0
                if saved.baseline[craft.spellId]==nil then saved.baseline[craft.spellId]=observed end
                plan.crafts[#plan.crafts+1]={name=craft.name,spellId=craft.spellId,
                    color=craft.color or "orange",required=craft.count,
                    skillPoints=craft.skillPoints,bufferExtra=craft.bufferExtra or 0,
                    completed=math.min(craft.count,math.max(0,observed-saved.baseline[craft.spellId])),
                    fromSkill=craft.fromSkill,toSkill=craft.toSkill,progressType="observed-cast",
                    acquisition=craft.acquisition,learnAt=craft.learnAt}
            end
            plan.ready=true
            for _,item in ipairs(remaining.materials) do
                local owned=inventoryCount(item.itemId,item.name,0)
                plan.materials[#plan.materials+1]={itemId=item.itemId,name=item.name,
                    required=item.required,owned=owned,missing=math.max(0,item.required-owned)}
                if owned<item.required then plan.ready=false end
            end
            return plan
        end
    end

    -- If no fully verified offline route exists, offer only the next
    -- LIVE orange/yellow recipe instead of assuming a future color boundary.
    local recipe,message=self:Recommendation(id)
    if not recipe then
        plan.requiresScan=true
        plan.instructions=(plan.coverageGap and ("Offline data gap at skill "..plan.coverageGap..". ") or "")
            ..(message or "Open the profession window to verify a current orange recipe.")
        return plan
    end
    local candidates=recipeSnapshots[id]
    local selected
    for _,candidate in ipairs(candidates or {}) do
        if candidate.color=="orange" or candidate.color=="yellow" then selected=candidate;break end
    end
    if not selected then
        plan.instructions="No currently orange/yellow recipe. Train a recipe or rescan."
        return plan
    end
    plan.cached=true
    plan.partial=true
    plan.requiresVerification=true
    local completed=0
    if selected.spellId and ns.char and ns.char.professionSuccessfulCrafts then
        completed=(ns.char.professionSuccessfulCrafts[id] or {})[selected.spellId] or 0
    end
    local isYellow=selected.color=="yellow"
    local craftNeeded=isYellow and math.ceil(1*1.10) or 1
    local done=0
    if ns.char and selected.spellId then
        ns.char.professionLiveCraftProgress=ns.char.professionLiveCraftProgress or {}
        local previous=ns.char.professionLiveCraftProgress[id]
        if not previous or previous.spellId~=selected.spellId or previous.skill~=skill then
            previous={spellId=selected.spellId,skill=skill,baseline=completed}
            ns.char.professionLiveCraftProgress[id]=previous
        end
        done=math.min(craftNeeded,math.max(0,completed-previous.baseline))
    end
    plan.crafts[1]={name=selected.name,color=selected.color,spellId=selected.spellId,
        required=craftNeeded,completed=done,observedTotal=completed,
        skillPoints=1,bufferExtra=craftNeeded-1,
        progressType=selected.spellId and "observed-cast" or "unverified"}
    for _,item in ipairs(selected.reagents or {}) do
        local amount=item.count*craftNeeded
        local owned=inventoryCount(item.itemId,item.name,item.owned)
        plan.materials[#plan.materials+1]={itemId=item.itemId,name=item.name,required=amount,
            owned=owned,missing=math.max(0,amount-owned)}
    end
    plan.yellowCrafts=isYellow and craftNeeded or 0
    plan.yellowBuffer=isYellow and craftNeeded-1 or 0
    plan.instructions="Current learned "..selected.color.." recipe only. Yellow crafts have a rounded-up 10% reserve, not guaranteed skill points. Recalculate after every skill gain; missing color ranges remain unverified."
    return plan
end

-- Triggered by tracker refreshes while the player has the trade-skill panel open.
-- This captures recipes before the profession window is closed.
function Profession:CaptureOpenProfession()
    if type(GetTradeSkillLine)~="function" then return end
    local ok,name=pcall(GetTradeSkillLine)
    if not ok then return end
    local id=self:IdForName(name)
    if id and not gathering[id] then self:Recommendation(id) end
end

function Profession:Initialize()
    if ns.char and type(ns.char.professionRecipeCache)=="table" then
        for id,candidates in pairs(ns.char.professionRecipeCache) do
            if profiles[id] and type(candidates)=="table" and #candidates>0 then
                recipeSnapshots[id]=candidates
                lastRecommendation[id]=candidates[1]
            end
        end
    end
    self:Sync()
end
