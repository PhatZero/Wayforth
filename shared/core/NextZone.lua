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
local horde={
    ["zephras-horde"]={id="horde-the-barrens",level=13},
    ["horde-durotar"]={id="horde-the-barrens",level=10},
    ["horde-mulgore"]={id="horde-the-barrens",level=10},
    ["horde-tirisfal-glades"]={id="horde-silverpine-forest",level=10},
    ["horde-the-barrens"]={id="horde-stonetalon-mountains",level=18},
    ["horde-stonetalon-mountains"]={id="horde-ashenvale",level=24},
    ["horde-ashenvale"]={id="horde-thousand-needles",level=30},
    ["horde-thousand-needles"]={id="horde-desolace",level=35},
    ["horde-desolace"]={id="horde-feralas",level=42},
    ["horde-dustwallow-marsh"]={id="horde-feralas",level=42},
    ["horde-feralas"]={id="horde-tanaris",level=46},
    ["horde-tanaris"]={id="horde-un-goro-crater",level=51},
    ["horde-un-goro-crater"]={id="horde-winterspring",level=55},
    ["horde-felwood"]={id="horde-winterspring",level=55},
    ["horde-silverpine-forest"]={id="horde-hillsbrad-foothills",level=20},
    ["horde-hillsbrad-foothills"]={id="horde-arathi-highlands",level=30},
    ["horde-alterac-mountains"]={id="horde-arathi-highlands",level=32},
    ["horde-arathi-highlands"]={id="horde-stranglethorn-vale",level=36},
    ["horde-stranglethorn-vale"]={id="horde-the-hinterlands",level=44},
    ["horde-the-hinterlands"]={id="horde-searing-gorge",level=49},
    ["horde-searing-gorge"]={id="horde-burning-steppes",level=53},
    ["horde-burning-steppes"]={id="horde-western-plaguelands",level=55},
    ["horde-western-plaguelands"]={id="horde-eastern-plaguelands",level=57},
}
Zones.hordeChapters=horde
Zones.allianceChapters=alliance
function Zones:ChapterOption()
    self:Tick()
    if not enabled() or not self.ready then return nil end
    local guides=ns.Modules.Guides
    local current=guides and guides:GetGuide()
    local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
    if not current or current.faction~=faction then return nil end
    local chapters=faction=="Alliance" and alliance or faction=="Horde" and horde
    local link=chapters and chapters[current.id]
    if current.generatedChapter and current.nextChapterId then
        local nextGuide=guides:GetGuide(current.nextChapterId)
        if nextGuide and nextGuide.id==current.nextChapterId then
            link={id=nextGuide.id,level=nextGuide.levelMin}
        end
    end
    local level=type(UnitLevel)=="function" and UnitLevel("player")
    if not link or type(level)~="number" or level<link.level then return nil end
    local target=guides:GetGuide(link.id)
    if not target or target.id~=link.id or target.faction~=faction
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
    return {id=target.id,title=target.generatedChapter and target.title or target.zone or target.title,reason="Next "..faction.." chapter",chapter=true}
end

-- Rank original generated chapters using live quest evidence, not estimated
-- XP or invented inter-zone distances. Only recommend after a safe handoff.
function Zones:OptimizedChapter(current,level)
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    if not current or not (current.generatedChapter or current.allianceProgression) or not routes then return nil end
    local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
    if not faction or current.faction~=faction then return nil end
    local states={}
    local function state(id)
        if not states[id] then states[id]=routes:QuestState(id) end
        return states[id]
    end
    local saved=guides:GetProgress(current.id)
    if not saved then return nil end
    for i,step in ipairs(guides:GetSteps(current.id)) do
        local q=step.questId and state(step.questId)
        -- Do not strand active quests even when their steps were skipped.
        if q and q.active and not q.turnedIn then return nil end
        if not step.optional and not (q and q.turnedIn)
            and not saved.completed[step.id or i]
            and not (saved.skipped and saved.skipped[step.id or i]) then return nil end
    end
    local map=C_Map and type(C_Map.GetBestMapForUnit)=="function"
        and C_Map.GetBestMapForUnit("player") or nil
    local best
    for _,g in ipairs(routes:ListGuides()) do
        if (g.generatedChapter or g.allianceProgression) and g.id~=current.id and g.faction==faction
            and not g.isOptional and not g.isDungeon and not g.isProfession
            and g.levelMin and g.levelMax and level>=g.levelMin and level<=g.levelMax then
            local steps=guides:GetSteps(g.id)
            local progress=guides:GetProgress(g.id)
            local index=progress and routes:Preview(g.id,"recommended")
            local candidate=index and steps[index]
            -- Preview must actually lead to actionable unfinished work.
            local q=candidate and candidate.questId and state(candidate.questId)
            if candidate and not candidate.optional and q and not q.turnedIn
                and not progress.completed[candidate.id or index]
                and not (progress.skipped and progress.skipped[candidate.id or index])
                and not routes:BlockedReason(candidate,steps)
                and not (guides.ConditionReason and guides:ConditionReason(candidate,g.id)) then
                local count,active,seen=0,0,{}
                for i,step in ipairs(steps) do
                    if step.questId and not step.optional and not seen[step.questId]
                        and not progress.completed[step.id or i]
                        and not (progress.skipped and progress.skipped[step.id or i]) then
                        seen[step.questId]=true
                        local status=state(step.questId)
                        if not status.turnedIn then
                            count=count+1
                            if status.active then active=active+1 end
                        end
                    end
                end
                local travel=(map and candidate.mapId==map) and 0
                    or g.zone==current.zone and 2
                    or g.continent and current.continent and g.continent==current.continent and 6
                    or 15
                local score=travel+math.abs(level-(g.levelMin+g.levelMax)/2)
                    -math.min(count,10)*0.25-math.min(active,5)*8
                if not best or score<best.score or score==best.score and g.id<best.id then
                    best={id=g.id,title=g.title,reason="Recommended level-appropriate chapter",
                        chapter=true,score=score}
                end
            end
        end
    end
    return best
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
    local chapter
    if current.generatedChapter or current.allianceProgression then
        chapter=self:OptimizedChapter(current,level)
        -- Generated routes must not fall back to legacy suggestions that can
        -- bypass the active quest and chapter completion safety gates.
        local options=chapter and {chapter} or {}
        if now then self.cache={key=cacheKey,time=now,options=options} end
        return options
    end
    chapter=self:ChapterOption()
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
    local current=ns.Modules.Guides:GetGuide()
    local chapter=not (current and (current.generatedChapter or current.allianceProgression)) and self:ChapterOption()
    if chapter and chapter.id==id then
        return ns.Modules.SmartRoutes:Switch(id,"recommended")
    end
    for _,option in ipairs(self:Options(true)) do
        if option.id==id then return ns.Modules.SmartRoutes:Switch(id,"recommended") end
    end
    return false,"That recommendation changed or your flight has not settled yet. Use the Guide Library to switch manually."
end
