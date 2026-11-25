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

-- Editorial chapter links based on the existing Forever zone ranges.
-- These are suggested handoffs, not an optimized or playtested speedrun.
local alliance={
    ["zephras-alliance"]={id="alliance-westfall",level=13},
    ["alliance-elwynn"]={id="alliance-westfall",level=10},
    ["alliance-dun-morogh"]={id="alliance-loch-modan",level=10},
    ["alliance-teldrassil"]={id="alliance-darkshore",level=10},
    ["alliance-loch-modan"]={id="alliance-wetlands",level=20},
    ["alliance-westfall"]={id="alliance-redridge-mountains",level=18},
    ["alliance-redridge-mountains"]={id="alliance-duskwood",level=24},
    ["alliance-darkshore"]={id="alliance-ashenvale",level=20},
    ["alliance-ashenvale"]={id="alliance-thousand-needles",level=28},
    ["alliance-stonetalon"]={id="alliance-ashenvale",level=20},
    ["alliance-wetlands"]={id="alliance-arathi-highlands",level=30},
    ["alliance-duskwood"]={id="alliance-stranglethorn-vale",level=30},
    ["alliance-arathi-highlands"]={id="alliance-the-hinterlands",level=40},
    ["alliance-thousand-needles"]={id="alliance-desolace",level=33},
    ["alliance-desolace"]={id="alliance-feralas",level=40},
    ["alliance-stranglethorn-vale"]={id="alliance-the-hinterlands",level=42},
    ["alliance-the-hinterlands"]={id="alliance-searing-gorge",level=48},
    ["alliance-searing-gorge"]={id="alliance-burning-steppes",level=52},
    ["alliance-burning-steppes"]={id="alliance-western-plaguelands",level=54},
    ["alliance-western-plaguelands"]={id="alliance-eastern-plaguelands",level=57},
    ["alliance-feralas"]={id="alliance-tanaris",level=45},
    ["alliance-tanaris"]={id="alliance-ungoro",level=50},
    ["alliance-ungoro"]={id="alliance-winterspring",level=55},
}
Zones.allianceChapters=alliance
function Zones:ChapterOption()
    self:Tick()
    if not enabled() or not self.ready then return nil end
    local guides=ns.Modules.Guides
    local current=guides and guides:GetGuide()
    if not current or current.faction~="Alliance" then return nil end
    if type(UnitFactionGroup)~="function" or UnitFactionGroup("player")~="Alliance" then return nil end
    local link=alliance[current.id]
    local level=type(UnitLevel)=="function" and UnitLevel("player")
    if not link or type(level)~="number" or level<link.level then return nil end
    local target=guides:GetGuide(link.id)
    if not target or target.id~=link.id or target.faction~="Alliance"
        or level<target.levelMin or level>target.levelMax or finished(target) then return nil end
    local saved=guides:GetProgress()
    local steps=guides:GetSteps()
    if not saved or #steps==0 then return nil end
    -- Require completion or explicit skip of every nonoptional step.
    -- Active unfinished quests never become completed from a zone handoff.
    for i,step in ipairs(steps) do
        if not step.optional and not saved.completed[step.id or i]
            and not (saved.skipped and saved.skipped[step.id or i]) then return nil end
    end
    return {id=target.id,title=target.zone or target.title,reason="Next Alliance chapter",chapter=true}
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
    local chapter=self:ChapterOption()
    if chapter then return {chapter} end
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
    local chapter=self:ChapterOption()
    if chapter and chapter.id==id then
        return ns.Modules.SmartRoutes:Switch(id,"recommended")
    end
    for _,option in ipairs(self:Options(true)) do
        if option.id==id then return ns.Modules.SmartRoutes:Switch(id,"recommended") end
    end
    return false,"That recommendation changed or your flight has not settled yet. Use the Guide Library to switch manually."
end
