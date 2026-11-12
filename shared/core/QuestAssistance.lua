-- Read-only recovery proposals. Choosing one changes focus, never completion.
local _,ns=...
local Help={}
ns:RegisterModule("QuestAssistance",Help)
function Help:Selected()
    local guides=ns.Modules.Guides
    local step,index=guides:CurrentStep()
    local nav=ns.Modules.Navigator
    if nav and nav.overrideIndex then index=nav.overrideIndex;step=guides:GetSteps()[index] end
    return step,index
end
function Help:Recovery()
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    local step=self:Selected()
    local steps,saved=guides:GetSteps(),guides:GetProgress()
    local result={guideId=guides:GetGuide().id,stepId=step and step.id,options={}}
    if not step or not step.questId then
        result.message="This is a travel or manual checkpoint. Follow its instructions or choose another guide step."
        return result
    end
    local state=routes:QuestState(step.questId)
    result.message=routes:BlockedReason(step,steps)
    if not result.message then
        result.message=state.active and "This quest is already in your log. Follow its active objective or turn-in."
            or state.turnedIn and "This quest has already been turned in. Use Sync Guide Now to refresh your route."
            or "The game has not confirmed why this quest is unavailable. Check the NPC, earlier quests, level and phase. No progress has been marked complete."
    end
    local seen={}
    local function offer(index,reason)
        local s=steps[index]
        if not s or seen[s.questId or s.id] or #result.options>=3 then return end
        if saved.skipped[s.id or index] or saved.completed[s.id or index] then return end
        if routes:BlockedReason(s,steps) then return end
        seen[s.questId or s.id]=true
        result.options[#result.options+1]={index=index,stepId=s.id,title=s.title,reason=reason,questId=s.questId}
    end
    local function phase(id)
        local st=routes:QuestState(id)
        local action=st.active and (st.ready and "turnin" or "objective") or "accept"
        for i,s in ipairs(steps) do if s.questId==id and s.action==action then return i end end
        if st.active then
            for i,s in ipairs(steps) do if s.questId==id and s.action=="turnin" then return i end end
        end
    end
    local visited={}
    local function prerequisite(id)
        if visited[id] then return end
        visited[id]=true
        if routes:QuestState(id).turnedIn then return end
        local found
        for _,s in ipairs(steps) do
            if s.questId==id then
                found=found or s
                if s.action=="accept" then found=s;break end
            end
        end
        if found then for _,req in ipairs(found.requires or {}) do prerequisite(req) end end
        local index=phase(id)
        if index then offer(index,"Resolve this quest chain") end
    end
    for _,s in ipairs(steps) do
        if s.questId==step.questId and s.action=="accept" then
            for _,req in ipairs(s.requires or {}) do prerequisite(req) end
            break
        end
    end
    if state.active then local index=phase(step.questId);if index then offer(index,"Continue your active quest") end end
    for _,entry in ipairs(routes:ConcurrentQuestSteps(30)) do
        if entry.step.questId~=step.questId then offer(entry.index,"Another quest already in your log") end
    end
    -- Do not claim another catalog pickup is offered simply because its known gates pass.
    if #result.options==0 then result.message=result.message.." No safe alternative is currently known; resolve the requirement and retry Sync." end
    return result
end
function Help:Choose(proposal,option)
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    if not proposal or not option or proposal.guideId~=guides:GetGuide().id then return false,"Guide changed; reopen quest recovery." end
    local steps=guides:GetSteps()
    local s=steps[option.index]
    if not s or s.id~=option.stepId or s.questId~=option.questId then return false,"Step changed; reopen quest recovery." end
    local reason=routes:BlockedReason(s,steps)
    local saved=guides:GetProgress()
    if reason or saved.completed[s.id or option.index] or saved.skipped[s.id or option.index] then
        return false,reason or "That step is no longer available. Retry Sync."
    end
    -- Clear stale unknown-chain state only after rechecking a concrete candidate.
    guides:SetCurrent(option.index)
    saved.awaitingQuestMatch=false
    saved.recoveryReason=option.reason
    return ns.Modules.Navigator:SetOverride(option.index,true)
end
