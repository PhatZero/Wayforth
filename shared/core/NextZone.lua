local _,ns=...
local Zones={}
ns:RegisterModule("NextZone",Zones)
local function finished(guide)
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    local saved=guides:GetProgress(guide.id)
    local steps=guides:GetSteps(guide.id)
    if not saved or #steps==0 then return false end
    for i,s in ipairs(steps) do
        if not saved.completed[s.id or i] and not (s.questId and routes:QuestState(s.questId).turnedIn) then return false end
    end
    return true
end
function Zones:Options(force)
    local db=ns.Modules.Database
    if db:Get("zoneSuggestions")==false or db:Get("guidePaused")==true then return {} end
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    local current=guides:GetGuide()
    local level=type(UnitLevel)=="function" and UnitLevel("player") or 1
    local now=type(GetTime)=="function" and GetTime() or nil
    local cacheKey=current.id..":"..level
    if not force and now and self.cache and self.cache.key==cacheKey and now-self.cache.time<2 then return self.cache.options end
    local reason=finished(current) and "Guide complete" or nil
    local steps=guides:GetSteps()
    local remaining,overleveled=false,true
    local saved=guides:GetProgress()
    for i,s in ipairs(steps) do
        if not saved.completed[s.id or i] and not (s.questId and routes:QuestState(s.questId).turnedIn) then
            remaining=true
            if not s.questId or not s.level or level-s.level<5 or routes:QuestState(s.questId).active then overleveled=false end
        end
    end
    if not reason and remaining and overleveled then reason="Remaining quests are below your level" end
    if not reason then
        if now then self.cache={key=cacheKey,time=now,options={}} end
        return {}
    end
    local options={}
    for _,g in ipairs(routes:ListGuides()) do
        if g.id~=current.id and not g.isOptional and g.levelMin and g.levelMax
            and level>=g.levelMin and level<=g.levelMax and #guides:GetSteps(g.id)>0 and not finished(g) then
            local index=routes:Preview(g.id,"recommended")
            if index and not routes:BlockedReason(guides:GetSteps(g.id)[index],guides:GetSteps(g.id)) then options[#options+1]={id=g.id,title=g.zone or g.title,reason=reason,
                score=math.abs(level-(g.levelMin+g.levelMax)/2)+(g.continent~=current.continent and 5 or 0)} end
        end
    end
    table.sort(options,function(a,b) if a.score==b.score then return a.id<b.id end;return a.score<b.score end)
    while #options>3 do table.remove(options) end
    if now then self.cache={key=cacheKey,time=now,options=options} end
    return options
end
function Zones:Switch(id)
    for _,option in ipairs(self:Options(true)) do
        if option.id==id then return ns.Modules.SmartRoutes:Switch(id,"recommended") end
    end
    return false,"That recommendation changed. Refresh the guide to see current options."
end
