local _,ns=...
local Search={}
ns:RegisterModule("GuideSearch",Search)
local function text(v) return type(v)=="string" and v or type(v)=="number" and tostring(v) or "" end
local function searchable(step,index)
    local fields={step.title,step.questName,step.hub,step.zone,step.text,step.id,step.questId,step.npc,step.npcName}
    local result={tostring(index)}
    -- Explicit numeric bounds: nil metadata must not truncate subsequent fields.
    for i=1,9 do result[#result+1]=text(fields[i]) end
    local record=step.questId and (ns.foreverQuestLocations or {})[step.questId]
    if record then
        for _,key in ipairs({"name","pickupName","turninName"}) do result[#result+1]=text(record[key]) end
        for _,role in ipairs({"pickup","objective","turnin"}) do
            for _,point in ipairs(type(record[role])=="table" and record[role] or {}) do result[#result+1]=text(point.name) end
        end
    end
    return table.concat(result," "):lower()
end
function Search:Find(query)
    local guides=ns.Modules.Guides
    local guide=guides:GetGuide()
    local steps,saved=guides:GetSteps(),guides:GetProgress()
    local tokens={}
    for word in tostring(query or ""):lower():gmatch("%S+") do tokens[#tokens+1]=word end
    local results={}
    for i,step in ipairs(steps) do
        local haystack=searchable(step,i)
        local matches=true
        for _,word in ipairs(tokens) do if not haystack:find(word,1,true) then matches=false;break end end
        if matches then
            local status=saved and saved.completed[step.id or i] and "Completed"
                or saved and saved.skipped[step.id or i] and "Skipped" or "Guide step"
            results[#results+1]={guideId=guide.id,index=i,stepId=step.id,questId=step.questId,title=step.title,
                action=step.action,status=status}
        end
    end
    return results
end
function Search:Resolve(result)
    local guides=ns.Modules.Guides
    if not result or guides:GetGuide().id~=result.guideId then return nil,"The active guide changed. Search again." end
    local step=guides:GetSteps()[result.index]
    if not step or step.id~=result.stepId or step.questId~=result.questId then return nil,"This step changed. Search again." end
    return step
end
