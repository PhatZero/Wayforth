local _,ns=...
local Space={}
ns:RegisterModule("QuestLogSpace",Space)
local function read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
local function integer(n)
    if type(issecretvalue)=="function" then
        local ok,secret=pcall(issecretvalue,n)
        if not ok or secret then return nil end
    end
    if type(n)=="number" and n==n and n>=0 and n<math.huge and n==math.floor(n) then return n end
end
function Space:Status()
    local api=type(C_QuestLog)=="table" and C_QuestLog or {}
    local _,count=read(api.GetNumQuestLogEntries)
    count=integer(count)
    if not count then local ignored;ignored,count=read(GetNumQuestLogEntries);count=integer(count) end
    -- The all-quests limit includes hidden/world quests and is not the ordinary log cap.
    local maximum=integer(read(api.GetMaxNumQuestsCanAccept)) or integer(MAX_QUESTLOG_QUESTS)
    if not count or not maximum or maximum==0 then return {known=false} end
    local free=math.max(0,maximum-count)
    return {known=true,count=count,maximum=maximum,free=free,full=free==0,near=free<=3}
end
function Space:Message(status)
    status=status or self:Status()
    if not status.known or not status.near then return nil end
    if status.full then return "QUEST LOG FULL | "..status.count.."/"..status.maximum.." | Turn in quests" end
    return "QUEST LOG "..status.count.."/"..status.maximum.." | "..status.free.." slots left"
end
function Space:ReadyTurnIns(steps,saved)
    local routes=ns.Modules.SmartRoutes
    local result,seen={},{}
    for i,s in ipairs(steps or {}) do
        local id=s.questId
        local state=id and routes:QuestState(id)
        local audit=ns.Modules.QuestAudit
        if s.action=="turnin" and state and state.active and state.ready and not state.turnedIn
            and not seen[id] and not saved.completed[s.id or i] and not saved.skipped[s.id or i]
            and not (audit and audit:IsMismatched(id)) then
            seen[id]=true
            local nav=ns.Modules.Navigator
            local distance=nav and read(nav.DistanceForStep,nav,s)
            if not integer(distance and math.floor(distance)) then distance=nil end
            result[#result+1]={index=i,step=s,distance=distance}
        end
    end
    table.sort(result,function(a,b)
        if (a.distance~=nil)~=(b.distance~=nil) then return a.distance~=nil end
        if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
        return a.index<b.index
    end)
    return result
end
function Space:Priority(steps,saved)
    local db=ns.Modules.Database
    if db and (db:Get("smartRouting")==false or db:Get("guidePaused")==true
        or db:Get("autoAdvance")==false or db:Get("autoRecovery")==false) then return nil end
    if not saved or not self:Status().near then return nil end
    local current=steps[saved.current]
    if not current or (current.action~="accept" and not (saved.hubVisit and saved.hubVisit.phase=="pickups")) then return nil end
    local candidate=self:ReadyTurnIns(steps,saved)[1]
    if candidate then return candidate.index,"Quest log nearly full. Turn in a ready quest before collecting more." end
end
function Space:CanAccept()
    local status=self:Status()
    if not status.known then return true end -- client still enforces its own limit
    if status.full then return false end
    if status.near then
        local guides=ns.Modules.Guides
        if #self:ReadyTurnIns(guides:GetSteps(),guides:GetProgress())>0 then return false end
    end
    return true
end

function Space:Notify()
    local status=self:Status()
    local state=status.full and "full" or status.near and "near" or "normal"
    if state~=self.lastNotice then
        self.lastNotice=state
        if status.near and type(ns.Print)=="function" then
            ns:Print(self:Message(status)..". Finish ready turn-ins before picking up more quests.")
        end
    end
end
