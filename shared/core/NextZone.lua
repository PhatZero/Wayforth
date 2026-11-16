local _,ns=...
local Zones={}
ns:RegisterModule("NextZone",Zones)

local SETTLE_SECONDS=30

local function clock()
    return type(GetTime)=="function" and GetTime() or nil
end

local function playerIdentity()
    if type(UnitGUID)~="function" then return nil end
    local ok,value=pcall(UnitGUID,"player")
    return ok and value or nil
end

local function currentGuideId()
    local guides=ns.Modules.Guides
    local guide=guides and guides:GetGuide()
    return guide and guide.id or nil
end

local function enabled()
    local db=ns.Modules.Database
    return db and db:Get("zoneSuggestions")~=false and db:Get("guidePaused")~=true
end

-- APIs differ across Forever clients. Use only supported functions and fail
-- safely if a flight-state API is missing or temporarily throws during zoning.
function Zones:IsTraveling()
    if type(UnitOnTaxi)=="function" then
        local ok,onTaxi=pcall(UnitOnTaxi,"player")
        if ok and onTaxi then return true end
    end
    if type(IsFlying)=="function" then
        local ok,flying=pcall(IsFlying)
        if ok and flying then return true end
    end
    return false
end

-- Reset the grace period on every zone crossing, login, new character,
-- setting change, manual guide switch, or when flight first begins/ends.
-- This state is transient and never changes SavedVariables/guide progress.
function Zones:Reset()
    local now=clock()
    self.initialized=true
    self.guideId=currentGuideId()
    self.playerGuid=playerIdentity()
    self.enabled=enabled()
    self.inFlight=self:IsTraveling()
    self.stableSince=not self.inFlight and now or nil
    -- No clock is available only in limited offline test environments.
    self.ready=self.enabled and not self.inFlight and now==nil
    self.cache=nil
end

function Zones:OnZoneChanged()
    self:Reset()
end

-- Called at most once per second by Bootstrap while logged in, and whenever
-- a tracker refresh asks for Options(). True means redraw is needed once.
function Zones:Tick()
    local guideId=currentGuideId()
    local identity=playerIdentity()
    local allowed=enabled()
    if not self.initialized or guideId~=self.guideId
        or identity~=self.playerGuid or allowed~=self.enabled then
        self:Reset()
        return true
    end
    local traveling=self:IsTraveling()
    if traveling then
        if not self.inFlight then
            self.inFlight=true
            self.ready=false
            self.stableSince=nil
            self.cache=nil
            return true  -- Remove any previously visible NEXT ZONE entry.
        end
        return false
    end
    if self.inFlight then
        self.inFlight=false
        self.ready=false
        self.stableSince=clock()
        self.cache=nil
        return false -- Stay hidden until 30 seconds after landing.
    end
    local now=clock()
    if allowed and not self.ready and now and self.stableSince
        and now-self.stableSince>=SETTLE_SECONDS then
        self.ready=true
        self.cache=nil
        return true  -- Exactly one redraw on becoming eligible.
    end
    return false
end

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
    -- This must run before consulting the short-lived recommendation cache.
    -- force bypasses ranking cache only; it cannot bypass flight safety.
    self:Tick()
    if not enabled() or not self.ready then return {} end
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    local current=guides:GetGuide()
    if not current then return {} end
    local level=type(UnitLevel)=="function" and UnitLevel("player") or 1
    local now=clock()
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
    -- Don't spam several alternative switch prompts as the player arrives.
    while #options>1 do table.remove(options) end
    if now then self.cache={key=cacheKey,time=now,options=options} end
    return options
end

function Zones:Switch(id)
    for _,option in ipairs(self:Options(true)) do
        if option.id==id then return ns.Modules.SmartRoutes:Switch(id,"recommended") end
    end
    return false,"That recommendation changed or your flight has not settled yet. Use the Guide Library to switch manually."
end
