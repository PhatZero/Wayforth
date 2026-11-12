-- Optional interaction with quests actually offered by the game's quest dialog.
local _,ns=...
local Interact={handled={}}
ns:RegisterModule("QuestInteractions",Interact)
local function call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a=pcall(fn,...)
    if ok then return a end
end
function Interact:Enabled(key)
    local db=ns.Modules.Database
    return ns.state and ns.state.loggedIn and db and db:Get(key)==true
        and db:Get("guidePaused")~=true and call(IsShiftKeyDown)~=true and call(InCombatLockdown)~=true
end
function Interact:Allowed(id,action)
    if type(id)~="number" or id<=0 then return false end
    if action=="accept" and ns.Modules.QuestLogSpace and not ns.Modules.QuestLogSpace:CanAccept() then return false end
    local guides=ns.Modules.Guides
    local guide=guides:GetGuide()
    if not guide or guide.id=="first-steps" then return false end
    local steps,saved=guides:GetSteps(),guides:GetProgress()
    for i,step in ipairs(steps) do
        if step.questId==id and step.action==action and not saved.skipped[step.id or i]
            and not saved.completed[step.id or i] then
            local audit=ns.Modules.QuestAudit
            if audit and audit:IsMismatched(id) then return false end
            return action~="accept" or not ns.Modules.SmartRoutes:BlockedReason(step,steps)
        end
    end
    return false
end
function Interact:Once(event,id,fn,...)
    if type(fn)~="function" then return end
    local key=event..":"..id
    if self.handled[key] then return end
    self.handled[key]=true -- no retry loop when the client refuses an action
    local ok,err=pcall(fn,...)
    if not ok and ns.Modules.Diagnostics then ns.Modules.Diagnostics:Warn("Quest interaction",err) end
end
function Interact:Event(event)
    if event=="GOSSIP_CLOSED" or event=="QUEST_FINISHED" then self.handled={};return end
    if event=="GOSSIP_SHOW" then
        local api=type(C_GossipInfo)=="table" and C_GossipInfo or {}
        if self:Enabled("autoTurnInQuests") then
            for _,q in ipairs(call(api.GetActiveQuests) or {}) do
                if (q.isComplete==true or q.isComplete==1) and self:Allowed(q.questID,"turnin") then
                    self:Once("selectTurnin",q.questID,api.SelectActiveQuest,q.questID);return
                end
            end
        end
        if self:Enabled("autoAcceptQuests") then
            for _,q in ipairs(call(api.GetAvailableQuests) or {}) do
                if self:Allowed(q.questID,"accept") then
                    self:Once("selectAccept",q.questID,api.SelectAvailableQuest,q.questID);return
                end
            end
        end
        return
    end
    local id=call(GetQuestID)
    if event=="QUEST_DETAIL" and self:Enabled("autoAcceptQuests") and self:Allowed(id,"accept") then
        self:Once(event,id,AcceptQuest)
    elseif self:Enabled("autoTurnInQuests") and self:Allowed(id,"turnin") then
        if event=="QUEST_PROGRESS" and call(IsQuestCompletable)==true then
            self:Once(event,id,CompleteQuest)
        elseif event=="QUEST_COMPLETE" then
            local count=call(GetNumQuestChoices)
            if count==0 or count==1 then self:Once(event,id,GetQuestReward,count) end
            -- Two or more reward choices always stay with the player.
        end
    end
end
function Interact:Initialize()
    if self.frame then return end
    self.frame=CreateFrame("Frame")
    for _,event in ipairs({"GOSSIP_SHOW","GOSSIP_CLOSED","QUEST_DETAIL","QUEST_PROGRESS","QUEST_COMPLETE","QUEST_FINISHED"}) do
        pcall(self.frame.RegisterEvent,self.frame,event)
    end
    self.frame:SetScript("OnEvent",function(_,event)
        local ok,err=pcall(self.Event,self,event)
        if not ok and ns.Modules.Diagnostics then ns.Modules.Diagnostics:Warn("Quest interaction",err) end
    end)
end
