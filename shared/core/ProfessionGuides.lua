-- Skill-aware profession guides; no fixed recipe or item-price assumptions.
local _, ns = ...
local Profession = {}
ns:RegisterModule("ProfessionGuides", Profession)

local profiles = {}
for _, row in ipairs(ns.professionProfiles or {}) do profiles[row.id]=row end
local bySkillLine = {}
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
