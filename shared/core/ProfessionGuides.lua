-- Skill-aware profession guides; no fixed recipe or item-price assumptions.
local _, ns = ...
local Profession = {}
ns:RegisterModule("ProfessionGuides", Profession)

local profiles = {}
for _, row in ipairs(ns.professionProfiles or {}) do profiles[row.id]=row end
local bySkillLine = {}
local lastRecommendation = {}
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
        if lastRecommendation[id] then return lastRecommendation[id] end
        return nil,"Open this profession's crafting window once to calculate its next skill-up recipe."
    end
    local ok,line=pcall(GetTradeSkillLine)
    if not ok or self:IdForName(line)~=id then
        if lastRecommendation[id] then return lastRecommendation[id] end
        return nil,"Open the "..profile.name.." window to calculate the next recipe from its learned plans."
    end
    local countOk,count=pcall(GetNumTradeSkills)
    if not countOk or type(count)~="number" then
        if lastRecommendation[id] then return lastRecommendation[id] end
        return nil,"The profession recipe list is not available yet."
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
                        reagents[#reagents+1]={name=reagentName,count=amount,owned=owned}
                    end
                end
            end
            if #reagents>0 then
                -- Prefer orange for its better skill-up chance, then minimize total
                -- reagent units and missing inventory. The client does not expose
                -- exact yellow skill-up odds, so do not claim an exact cost/point.
                local colorRank=colorName=="optimal" and 1 or 2
                candidates[#candidates+1]={name=name,color=colorRank==1 and "orange" or "yellow",reagents=reagents,
                    total=total,missing=missing,colorRank=colorRank}
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
        if lastRecommendation[id] then return lastRecommendation[id] end
        return nil,"No known orange or yellow recipe is visible. Learn recipes, or refresh the profession window."
    end
    lastRecommendation[id]=candidates[1]
    return lastRecommendation[id]
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

function Profession:Initialize()
    self:Sync()
end
