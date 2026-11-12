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
-- Bounded to the active guide. Compare resolved metadata so map/race/class
-- changes and edited steps cannot leave a stale search index.
function Search:Document(step,index,guideID)
    if self.guideID~=guideID then self.guideID=guideID;self.documents={} end
    local record=(ns.foreverQuestLocations or {})[step.questId]
    local values={step.title,step.questName,step.hub,step.zone,step.text,step.id,step.questId,step.npc,step.npcName}
    local cached=self.documents[index]
    local same=cached and cached.record==record
    if same then for i=1,9 do if cached.values[i]~=values[i] then same=false;break end end end
    if same then return cached.text end
    local document=searchable(step,index)
    self.documents[index]={values=values,record=record,text=document}
    self.indexBuilds=(self.indexBuilds or 0)+1
    return document
end
function Search:Find(query)
    local guides=ns.Modules.Guides
    local guide=guides:GetGuide()
    local steps,saved=guides:GetSteps(),guides:GetProgress()
    local tokens={}
    for word in tostring(query or ""):lower():gmatch("%S+") do tokens[#tokens+1]=word end
    local results={}
    for i,step in ipairs(steps) do
        local haystack=self:Document(step,i,guide.id)
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
