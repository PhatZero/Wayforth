local _, ns = ...
local Guides = {}
ns:RegisterModule("Guides", Guides)

local byId = {}
for _, guide in ipairs(ns.starterGuides or {}) do
    if ns.Modules.QuestLocations then ns.Modules.QuestLocations:Prepare(guide) end
    byId[guide.id] = guide
end

local function progressStore()
    if not ns.char then return nil end
    if type(ns.char.guideProgress) ~= "table" then ns.char.guideProgress = {} end
    return ns.char.guideProgress
end

local function defaultGuide()
    if type(UnitRace) == "function" and type(UnitFactionGroup) == "function" then
        local _, token = UnitRace("player")
        if tostring(token or ""):lower():find("skyborne", 1, true) then
            local faction = UnitFactionGroup("player")
            if faction == "Alliance" then return "zephras-alliance" end
            if faction == "Horde" then return "zephras-horde" end
        end
    end
    return "first-steps"
end

local function stepKey(step, index)
    return step.id or index -- Legacy foundation-guide numeric saved keys stay valid.
end

function Guides:GetGuide(id)
    local active = id or (ns.char and ns.char.activeGuide) or defaultGuide()
    return byId[active] or byId["first-steps"]
end

function Guides:List(kind)
	local result = {}
    local classToken
    if type(UnitClass)=="function" then local _,token=UnitClass("player");classToken=token end
	for _, guide in ipairs(ns.starterGuides or {}) do
		if (not guide.class or guide.class==classToken) and (not guide.generatedChapter or #self:GetSteps(guide.id)>0) and (kind == "all"
			or kind == "professions" and guide.isProfession
			or kind ~= "all" and kind ~= "professions" and not guide.isProfession) then
			result[#result + 1] = guide
		end
	end
	return result
end

-- Test catalogs can contain quests restricted to one or several races.
-- Forever's Undead race token may appear as SCOURGE on older client APIs.
local function canUseRace(restrictions)
    if not restrictions then return true end
    if type(UnitRace) ~= "function" then return false end
    local ok, displayed, token = pcall(UnitRace, "player")
    if not ok then return false end
    local name = tostring(displayed or ""):upper()
    local code = tostring(token or ""):upper()
    if code == "SCOURGE" then code = "UNDEAD" end
    for _, wanted in ipairs(restrictions) do
        if wanted == name or wanted == code then return true end
    end
    return false
end

-- Static character conditions never change as the player levels. Keep dynamic
-- prerequisites on the step rather than removing it from the saved route.
local function member(values, token)
    if not values or not token then return false end
    for _,value in ipairs(values) do
        if tostring(value):upper()==tostring(token):upper() then return true end
    end
    return false
end

local function characterMatches(condition, classToken)
    if not condition then return true end
    local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player")
    if condition.classes and not member(condition.classes,classToken) then return false end
    if condition.excludeClasses and (not classToken or member(condition.excludeClasses,classToken)) then return false end
    if condition.factions and not member(condition.factions,faction) then return false end
    if condition.races and not canUseRace(condition.races) then return false end
    if condition.excludeRaces and (type(UnitRace)~="function" or canUseRace(condition.excludeRaces)) then return false end
    return true
end

function Guides:GetSteps(id, legacy)
    local guide = self:GetGuide(id)
    if not guide then return {} end
    local classToken
    if type(UnitClass) == "function" then
        local _, token = UnitClass("player")
        classToken = token
    end
    if guide.class and guide.class~=classToken then return {} end
    local visible = {}
    local locations = ns.Modules.QuestLocations
    local currentMap = C_Map and type(C_Map.GetBestMapForUnit) == "function"
        and C_Map.GetBestMapForUnit("player") or nil
    for _, step in ipairs(legacy and guide.legacySteps or guide.steps or {}) do
        if (legacy or not step.hidden)
            and (not step.faction or step.faction == (guide.faction or (type(UnitFactionGroup)=="function" and UnitFactionGroup("player"))))
            and (not step.class or step.class == classToken)
            and canUseRace(step.races) and (legacy or characterMatches(step.condition,classToken)) then
            -- Each visible step gets its own resolved metadata. Shared raw step IDs
            -- remain untouched so old SavedVariables checkpoints keep working.
            local resolved = {}
            for key, value in pairs(step) do resolved[key] = value end
            if step.questIds then resolved.questId = step.questIds[guide.faction] end
            if step.requiresByFaction then resolved.requires = step.requiresByFaction[guide.faction] end
            if step.coordsByFaction and step.coordsByFaction[guide.faction] then
                local loc = step.coordsByFaction[guide.faction]
                resolved.x, resolved.y = loc[1], loc[2]
            end
            -- Quest phase endpoints are explicit. A quest giver's location must
            -- never be silently reused for a different turn-in NPC.
            local catalog = ns.zephrasQuestLocations or {}
            local isZephras = guide.id == "zephras-alliance" or guide.id == "zephras-horde"
            local entry = isZephras and resolved.questId and catalog[resolved.questId] or nil
            local role = resolved.locationRole or (resolved.action == "accept" and "pickup" or resolved.action)
            local pin = entry and entry[role]
            if pin and type(pin[1]) == "number" and type(pin[2]) == "number" then
                resolved.x, resolved.y = pin[1], pin[2]
                resolved.mapId = ns.zephrasMapID or 2521
            end
            local requirements=(ns.foreverQuestRequirements or {})[resolved.questId]
            if requirements then
                resolved.minLevel=resolved.minLevel or requirements.minLevel
                -- Authored chain rules take precedence over imported source metadata.
                if resolved.requires==nil and resolved.requiresAny==nil then
                    resolved.requires=requirements.requires
                    resolved.requiresAny=requirements.requiresAny
                end
            end
            if locations then locations:Apply(resolved, guide, currentMap) end
            visible[#visible + 1] = resolved
        end
    end
    return visible
end

function Guides:GetProgress(id)
    local guide = self:GetGuide(id)
    if not guide then return nil end
    local store = progressStore()
    if not store then return nil end
    local saved = store[guide.id]
    if type(saved) ~= "table" then
        saved = { current = 1, completed = {} }
        store[guide.id] = saved
    end
    if type(saved.completed) ~= "table" then saved.completed = {} end
    if type(saved.skipped) ~= "table" then saved.skipped = {} end
    if type(saved.current) ~= "number" or saved.current ~= saved.current then saved.current = 1 end
    local steps = self:GetSteps(guide.id)
    if #steps == 0 then return nil end
    if not saved.currentStepId and guide.legacySteps then
        local previous = self:GetSteps(guide.id, true)[saved.current]
        if previous then saved.currentStepId = stepKey(previous, saved.current) end
    end
    if saved.currentStepId then
        local position
        for index, step in ipairs(steps) do
            if stepKey(step, index) == saved.currentStepId then position = index; break end
        end
        if not position and guide.legacySteps then
            local positions = {}
            for index, step in ipairs(steps) do positions[stepKey(step, index)] = index end
            -- A corrected faction restriction can remove an old cursor target.
            -- Continue with the next surviving legacy step in the same guide.
            local previous = self:GetSteps(guide.id, true)
            local afterCurrent = false
            for index, step in ipairs(previous) do
                local key = stepKey(step, index)
                if key == saved.currentStepId then afterCurrent = true end
                if afterCurrent and positions[key] then position = positions[key]; break end
            end
            position = position or #steps
        end
        saved.current = position or saved.current
    end
    saved.current = math.max(1, math.min(#steps, math.floor(saved.current)))
    saved.currentStepId = stepKey(steps[saved.current], saved.current)
    return saved
end

function Guides:SetActive(id)
    if not byId[id] or not ns.char then return false end
    ns.char.activeGuide = id
    ns.char.recentGuides = type(ns.char.recentGuides) == "table" and ns.char.recentGuides or {}
    local recent = { id }
    for _, past in ipairs(ns.char.recentGuides) do
        if past ~= id and #recent < 8 then recent[#recent + 1] = past end
    end
    ns.char.recentGuides = recent
    return self:GetProgress(id) ~= nil
end

function Guides:NextGuide()
    local all = self:List()
    local current = self:GetGuide()
    for index, guide in ipairs(all) do
        if guide.id == current.id then
            return self:SetActive(all[index % #all + 1].id)
        end
    end
    return false
end

function Guides:SetCurrent(index, id)
    local steps = self:GetSteps(id)
    local saved = self:GetProgress(id)
    if not saved or type(index) ~= "number" or index ~= index then return end
    saved.current = math.max(1, math.min(#steps, math.floor(index)))
    saved.currentStepId = stepKey(steps[saved.current], saved.current)
end

-- A checkpoint uses live character evidence, never estimated XP rewards.
-- XP is relative to the specified level, not lifetime experience.
function Guides:LevelCheckpoint(step)
    local target=step and step.checkpoint
    if not target then return nil end
    local function read(fn)
        if type(fn)~="function" then return nil end
        local ok,value=pcall(fn,"player")
        if ok and type(value)=="number" and value==value and value>=0 then return value end
    end
    local level,xp,maxXP=read(UnitLevel),read(UnitXP),read(UnitXPMax)
    local valid=type(target.level)=="number" and target.level>=1
        and target.level==math.floor(target.level)
        and (target.xp==nil or type(target.xp)=="number" and target.xp>=0 and target.xp<math.huge)
        and (target.remainingXP==nil or type(target.remainingXP)=="number" and target.remainingXP>=0 and target.remainingXP<math.huge)
        and not (target.xp~=nil and target.remainingXP~=nil)
    local done=false
    local status="Character XP unavailable"
    if not valid then status="Invalid authored level checkpoint"
    elseif level then
        if level>target.level then done=true
        elseif level==target.level then
            if target.xp~=nil then done=xp~=nil and xp>=target.xp
            elseif target.remainingXP~=nil then
                done=xp~=nil and maxXP~=nil and maxXP>0 and math.max(0,maxXP-xp)<=target.remainingXP
            else done=true end
        end
        status="Level "..level.." / "..target.level
        if target.xp~=nil then
            status=status.." | "..tostring(xp or "?").." / "..target.xp.." XP"
        elseif target.remainingXP~=nil then
            status=status.." | "..tostring(xp and maxXP and maxXP>0 and math.max(0,maxXP-xp) or "?").." XP remaining (target "..target.remainingXP..")"
        end
    end
    return {finished=done,display=status,valid=valid,level=level,xp=xp,maxXP=maxXP}
end

-- Inventory and training checkpoints verify state without performing purchases,
-- selling items, or learning spells on the player's behalf.
function Guides:Checkpoint(step)
    local target=step and step.checkpoint
    if not target then return nil end
    if not target.kind or target.kind=="xp" then return self:LevelCheckpoint(step) end
    local function read(fn,...)
        if type(fn)~="function" then return nil end
        local ok,value=pcall(fn,...)
        if ok then return value end
    end
    local function positive(n) return type(n)=="number" and n>0 and n<math.huge and n==math.floor(n) end
    local done,display=false,"Invalid authored checkpoint"
    if target.kind=="spell" and positive(target.spellId) then
        local known=read(IsPlayerSpell,target.spellId)
        if known~=true then
            local alternative=read(IsSpellKnown,target.spellId)
            if alternative~=nil then known=alternative end
        end
        done=known==true
        display=(target.name or ("Spell "..target.spellId))..(done and " learned" or known==nil and " | Spell verification unavailable" or " | Not learned")
    elseif target.kind=="item" and positive(target.itemId) and positive(target.count) then
        local count=read(C_Item and C_Item.GetItemCount,target.itemId,false)
        if type(count)~="number" then count=read(GetItemCount,target.itemId,false) end
        done=type(count)=="number" and count>=target.count
        display=(target.name or ("Item "..target.itemId)).." ("..tostring(count or "?").."/"..target.count..")"
    elseif target.kind=="money" and positive(target.copper) then
        local money=read(GetMoney)
        done=type(money)=="number" and money>=target.copper
        display=tostring(money or "?").." / "..target.copper.." copper"
    elseif target.kind=="vendor" then
        -- Opening a merchant window does not prove a sale or repair occurred.
        return {finished=false,manual=true,display="Confirm vendor tasks manually after completing them."}
    end
    return {finished=done,display=display}
end

function Guides:CompleteCurrent(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved or #steps == 0 then return end
    local checkpoint=self:Checkpoint(steps[saved.current])
    if checkpoint and not checkpoint.finished and not checkpoint.manual then return false,checkpoint.display end
    saved.completed[stepKey(steps[saved.current], saved.current)] = true
    if saved.current < #steps then self:SetCurrent(saved.current + 1, id) end
end

-- These query helpers are deliberately tolerant of the modern Forever client and
-- older aliases. A missing API never means the player has completed a quest.
local function queryBoolean(func, questID)
    if type(func) ~= "function" then return false end
    local ok, value = pcall(func, questID)
    return ok and value == true
end

local function questCompleted(questID, saved)
    if queryBoolean(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, questID)
        or queryBoolean(IsQuestFlaggedCompleted, questID) then return true end
    if saved and saved.rebuiltFromGame then
        -- A rebuilt guide must not re-import pre-rebuild addon-only turn-in
        -- history during normal Sync. New, observed turn-ins are recorded below.
        return type(saved.rebuiltTurnInEvents) == "table"
            and saved.rebuiltTurnInEvents[questID] == true
    end
    return ns.char and ns.char.turnedInQuests
        and ns.char.turnedInQuests[questID] == true
end

local function questActive(questID)
    if queryBoolean(C_QuestLog and C_QuestLog.IsOnQuest, questID) then return true end
    if type(C_QuestLog) == "table" and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    if type(GetQuestLogIndexByID) == "function" then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    -- In some builds the quest log has not updated by the time QUEST_ACCEPTED fires.
    return ns.state and ns.state.acceptedQuestIDs and ns.state.acceptedQuestIDs[questID] == true
end

local function questReady(questID)
    return queryBoolean(C_QuestLog and C_QuestLog.ReadyForTurnIn, questID)
        or queryBoolean(C_QuestLog and C_QuestLog.IsComplete, questID)
end

local function hasQuestAPIs()
    return type(C_QuestLog) == "table"
        and (type(C_QuestLog.IsQuestFlaggedCompleted) == "function"
            or type(C_QuestLog.IsOnQuest) == "function"
            or type(C_QuestLog.GetLogIndexForQuestID) == "function")
        or type(IsQuestFlaggedCompleted) == "function"
        or type(GetQuestLogIndexByID) == "function"
end

function Guides:RecordQuestEvent(event, first, second)
    if not ns.char then return end
    local questID = event == "QUEST_ACCEPTED" and (second or first) or first
    if type(questID) ~= "number" or questID < 1 then return end
    ns.state.acceptedQuestIDs = ns.state.acceptedQuestIDs or {}
    if event == "QUEST_ACCEPTED" then
        ns.state.acceptedQuestIDs[questID] = true
        ns.state.lastAcceptedQuestID = questID -- session-only hub sweep anchor
        ns.state.lastTurnedInQuestID = nil
        ns.state.lastHubEventAt = type(GetTime) == "function" and GetTime() or nil
    elseif event == "QUEST_REMOVED" then
        ns.state.acceptedQuestIDs[questID] = nil
        if ns.state.lastAcceptedQuestID == questID then ns.state.lastAcceptedQuestID = nil end
        if ns.state.lastTurnedInQuestID == questID then ns.state.lastTurnedInQuestID = nil end
    elseif event == "QUEST_TURNED_IN" then
        ns.state.acceptedQuestIDs[questID] = nil
        ns.state.lastAcceptedQuestID = nil
        ns.state.lastTurnedInQuestID = questID
        ns.state.lastHubEventAt = type(GetTime) == "function" and GetTime() or nil
        -- Turn-in events can arrive before completed quest flags are updated.
        -- This record is local to this character and survives /reload.
        if type(ns.char.turnedInQuests) ~= "table" then ns.char.turnedInQuests = {} end
        ns.char.turnedInQuests[questID] = true
        local selected = self:GetGuide()
        local progress = selected and ns.char.guideProgress
            and ns.char.guideProgress[selected.id]
        if progress and progress.rebuiltFromGame then
            progress.rebuiltTurnInEvents = progress.rebuiltTurnInEvents or {}
            progress.rebuiltTurnInEvents[questID] = true
        end
    end
end

local function readQuestStatus(questID, cache, saved)
    if cache[questID] then return cache[questID] end
    local status = {
        turnedIn = questCompleted(questID, saved),
        active = questActive(questID),
        ready = questReady(questID),
    }
    cache[questID] = status
    return status
end

local function satisfied(step, status)
    if not status then return false end
    -- Only quest phases can be completed from quest evidence. Travel,
    -- trainer and other manually authored checkpoints require Done / Next
    -- even if they include a quest ID for context.
    if step.action ~= "accept" and step.action ~= "objective"
        and step.action ~= "turnin" then return false end
    -- A fully turned-in quest also completes its earlier accept/objective steps.
    if status.turnedIn then return true end
    if step.action == "accept" then return status.active end
    if step.action == "objective" then return status.ready end
    return false -- Turn-ins need real completed quest evidence.
end

-- A walkthrough visit is an authored, contiguous set of atomic quest actions.
-- Keep the existing cursor and stable keys: no second route engine or saved schema.
-- Dynamic eligibility is informational and fail-closed. Never mark a
-- prerequisite complete, remove a saved step or invent availability.
function Guides:ConditionReason(step,id)
    local c=step and step.condition
    if not c then return nil end
    local saved=self:GetProgress(id)
    if not saved then return "Guide progress unavailable." end
    local level=type(UnitLevel)=="function" and UnitLevel("player")
    if c.minLevel and (type(level)~="number" or level<c.minLevel) then return "Requires level "..c.minLevel.."." end
    if c.maxLevel and (type(level)~="number" or level>c.maxLevel) then return "Intended for level "..c.maxLevel.." or below. Review or skip this step." end
    for _,qid in ipairs(c.requiresQuests or {}) do
        if not questCompleted(qid,saved) or questActive(qid) then return "Complete prerequisite quest "..qid.." first." end
    end
    if c.requiresAnyQuests and #c.requiresAnyQuests>0 then
        local met=false
        for _,qid in ipairs(c.requiresAnyQuests) do
            if questCompleted(qid,saved) and not questActive(qid) then met=true;break end
        end
        if not met then return "Complete one of the prerequisite quests first." end
    end
    for _,key in ipairs(c.requiresSteps or {}) do
        if not saved.completed[key] then return "Complete prerequisite guide step "..key.." first." end
    end
    return nil
end

-- Concurrent work is explicitly authored on a route step. It is advisory:
-- never changes the cursor, destination, completion or saved variables.
function Guides:ConcurrentSnapshot(index, id)
    local steps=self:GetSteps(id)
    local step=index and steps[index]
    local progress=ns.Modules.QuestProgress
    if not step or not progress or not step.concurrentQuestIds then return {} end
    local rows,seen={},{}
    for _,questId in ipairs(step.concurrentQuestIds) do
        if type(questId)=="number" and questId~=step.questId and not seen[questId] then
            seen[questId]=true
            local snapshot=progress:Get(questId)
            if snapshot and snapshot.active and not snapshot.ready and not snapshot.failed then
                local name
                for _,candidate in ipairs(steps) do
                    if candidate.questId==questId then
                        name=candidate.questName or tostring(candidate.title or "Quest"):gsub("^Pick up:%s*",""):gsub("^Work on:%s*",""):gsub("^Complete:%s*","")
                        break
                    end
                end
                if name then
                    for _,row in ipairs(snapshot.rows or {}) do
                        if not row.finished then
                            rows[#rows+1]={questId=questId,display=name..": "..row.display,finished=false,concurrent=true}
                        end
                    end
                end
            end
        end
    end
    return rows
end

function Guides:VisitSnapshot(index, id)
    local steps = self:GetSteps(id)
    local saved = self:GetProgress(id)
    local current = index and steps[index]
    local visit = current and current.visit
    if not saved or not visit or not visit.id then return nil end
    local first, last = index, index
    while first > 1 and steps[first-1].visit and steps[first-1].visit.id == visit.id do first=first-1 end
    while last < #steps and steps[last+1].visit and steps[last+1].visit.id == visit.id do last=last+1 end
    if first == last then return nil end
    local rows, cache, done, skipped = {}, {}, 0, 0
    for i=first,last do
        local action=steps[i]
        if type(action.questId)~="number" or (action.action~="accept" and action.action~="turnin") then return nil end
        local status=readQuestStatus(action.questId,cache,saved)
        local complete=satisfied(action,status)
        local wasSkipped=not complete and saved.skipped[stepKey(action,i)]==true
        if complete then done=done+1 elseif wasSkipped then skipped=skipped+1 end
        local title=action.questName or tostring(action.title or "Quest"):gsub("^Pick up:%s*",""):gsub("^Complete:%s*","")
        rows[#rows+1]={index=i,finished=not not complete,skipped=wasSkipped,
            display=(wasSkipped and "Skipped: " or "")..(action.action=="accept" and "Accept " or "Turn in ")..title}
    end
    return {questID="visit:"..visit.id, first=first,last=last,title=visit.title,rows=rows,
        completed=done, state=done==#rows and "ready" or "active",
        status=done.."/"..#rows.." ACTIONS COMPLETE"..(skipped>0 and " | "..skipped.." skipped" or "")}
end

function Guides:Sync(id, catchUp)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved then return false, "No active guide." end
    local found, newCompletions, anchor = 0, 0, nil
    local foundIDs, cache = {}, {}
    local previous = saved.current

    -- Scan ALL quest-linked steps. The old implementation stopped at the first
    -- manual checkpoint, making Sync appear broken for returning characters.
    for index, step in ipairs(steps) do
        local checkpoint=self:Checkpoint(step)
        if checkpoint then
            local key=stepKey(step,index)
            if checkpoint.finished and not saved.completed[key] then
                saved.completed[key]=true
                newCompletions=newCompletions+1
            end
        elseif type(step.questId) == "number" then
            local status = readQuestStatus(step.questId, cache, saved)
            if (status.turnedIn or status.active or status.ready) and not foundIDs[step.questId] then
                foundIDs[step.questId] = true
                found = found + 1
            end
            local key = stepKey(step, index)
            local done = satisfied(step, status)
            if done then
                if not saved.completed[key] then
                    saved.completed[key] = true
                    newCompletions = newCompletions + 1
                end
                -- Only use actual quest evidence as a catch-up anchor.
                -- Manual steps with no quest ID never get marked complete.
                if not anchor or index > anchor then anchor = index end
            end
        end
    end

    -- Automatic event updates only advance through contiguous completed steps.
    -- Explicit "Sync Quests" can catch up to newer proven quests beyond an
    -- unverified manual checkpoint. Those earlier steps stay available via Prev.
    local settings = ns.Modules.Database
    local simple = settings and settings:Get("simpleStepReader") == true
    local automatic = (not settings or settings:Get("autoAdvance") ~= false)
        and (simple or not settings or settings:Get("autoRecovery") ~= false)
        and (not settings or settings:Get("guidePaused") ~= true)
    if catchUp and anchor and anchor > saved.current then
        self:SetCurrent(anchor, id)
    end
    while (catchUp or automatic) and saved.current < #steps do
        local step = steps[saved.current]
        if not saved.completed[stepKey(step, saved.current)] then break end
        -- Old acceptance evidence is not proof that an abandoned quest is
        -- still active. Never race past a missing quest on stale checkpoints.
        local checkpoint=self:Checkpoint(step)
        if checkpoint and not checkpoint.finished and not checkpoint.manual then break end
        if simple and not checkpoint and type(step.questId) == "number"
            and not satisfied(step, readQuestStatus(step.questId, cache, saved)) then break end
        self:SetCurrent(saved.current + 1, id)
    end
    local recoveryReason
    if simple then
        -- Only the guide reader owns automatic cursor progression. Hub sweeps,
        -- log-capacity helpers and smart routes may provide information but may
        -- not silently replace the player's selected step.
        saved.hubVisit = nil
        saved.awaitingQuestMatch = false
        saved.recoveryReason = nil
        if catchUp and (not anchor or anchor < saved.current) then
            -- When the current quest is missing, explicit Sync can point back
            -- to its authored pickup or prerequisites. It never marks them done.
            local routes = ns.Modules.SmartRoutes
            local guide = self:GetGuide(id)
            if routes and guide and routes:NeedsLiveQuest(guide.id) then
                local pickup, reason = routes:Preview(guide.id, "recommended")
                if pickup and pickup < saved.current then
                    self:SetCurrent(pickup, id)
                    recoveryReason = reason
                end
            end
        end
    else
        local hubs=ns.Modules.HubRoutes
        if hubs and (catchUp or automatic) then
            local hubIndex,hubReason=hubs:Update(self:GetGuide(id).id,steps,saved,steps[previous],catchUp)
            if hubIndex then
                self:SetCurrent(hubIndex,id)
                recoveryReason,saved.recoveryReason=hubReason,hubReason
            end
        end
        local space=ns.Modules.QuestLogSpace
        if space and (catchUp or automatic) then
            local priority,reason=space:Priority(steps,saved)
            if priority then
                self:SetCurrent(priority,id)
                saved.awaitingQuestMatch=false
                saved.recoveryReason=reason
                recoveryReason=reason
            end
        end
        if catchUp and ns.Modules.SmartRoutes
            and ns.Modules.SmartRoutes:NeedsLiveQuest(self:GetGuide(id).id) then
            -- Explicit Sync means rebuild the cursor from actual quest evidence and
            -- authored prerequisites, even when the player selected Story mode.
            -- We do NOT mark unavailable/older steps complete just to catch up.
            ns.Modules.SmartRoutes:Recalculate(true)
            recoveryReason = saved.recoveryReason
        end
    end
    local moved = saved.current ~= previous
    local changed = newCompletions > 0 or moved
    local report
    if not hasQuestAPIs() and not (ns.char.turnedInQuests or ns.state.acceptedQuestIDs) then
        report = "Quest APIs unavailable. Use Done/Next to advance."
    elseif catchUp and recoveryReason and saved.awaitingQuestMatch ~= true then
        report = recoveryReason .. " Now at " .. saved.current .. "/" .. #steps .. "."
    elseif catchUp and recoveryReason and saved.awaitingQuestMatch == true then
        report = "Quest prerequisite needs review: " .. recoveryReason
    elseif found == 0 then
        report = "No matching active/completed quests. Check selected guide."
    elseif catchUp and moved then
        report = "Synced " .. found .. " quests, +" .. newCompletions
            .. " steps. Now at " .. saved.current .. "/" .. #steps
            .. ". Earlier manual steps are still reviewable."
    elseif moved or newCompletions > 0 then
        report = "Synced " .. found .. " quests, +" .. newCompletions
            .. " steps. Now at " .. saved.current .. "/" .. #steps .. "."
    else
        report = "Checked " .. found .. " quests. No new progress to apply."
    end
    self.syncStatus = { guideId = self:GetGuide(id).id, matched = found, completed = newCompletions }
    if ns.Modules.UI and ns.Modules.UI.RefreshFooter then ns.Modules.UI:RefreshFooter() end
    if catchUp then self.lastSyncReport = report end
    return changed, report
end

-- One-time login recovery for characters with old, noncontiguous progress.
-- A stale step-1 cursor is not a reason to discard completed quest history.
-- Only a real active quest in the selected guide can move the cursor here;
-- ordinary quest/zone updates never invoke this recovery.
function Guides:ResumeOnLogin()
    local settings=ns.Modules.Database
    if not settings or settings:Get("simpleStepReader") ~= true then return false end
    local guide=self:GetGuide()
    local saved=guide and self:GetProgress(guide.id)
    if not saved or saved.current ~= 1
        or (saved.routeMode and saved.routeMode ~= "recommended") then return false end
    local steps=self:GetSteps(guide.id)
    local hasHistory=false
    for i=2,#steps do
        if saved.completed[stepKey(steps[i],i)] then
            hasHistory=true
            break
        end
    end
    if not hasHistory then return false end
    local routes=ns.Modules.SmartRoutes
    if not routes then return false end
    local index=routes:Preview(guide.id,"recommended")
    local step=index and steps[index]
    if not step or index<=1 or type(step.questId)~="number"
        or not questActive(step.questId) or questCompleted(step.questId, saved) then
        return false
    end
    self:SetCurrent(index,guide.id)
    saved.awaitingQuestMatch=false
    saved.recoveryReason=nil
    return true
end

-- Read authoritative game evidence without consulting previous WayForth
-- completion flags or addon-cached turn-ins. A failed API query aborts the entire
-- rebuild before any SavedVariables are modified.
local function liveFlagged(id)
    local methods = {}
    if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
        methods[#methods+1] = C_QuestLog.IsQuestFlaggedCompleted
    end
    if type(IsQuestFlaggedCompleted) == "function" then
        methods[#methods+1] = IsQuestFlaggedCompleted
    end
    local checked = false
    for _, fn in ipairs(methods) do
        if type(fn) == "function" then
            local ok, value = pcall(fn, id)
            if ok and type(value) == "boolean" then
                if value then return true end
                checked = true
            end
        end
    end
    if checked then return false end
    return nil
end

local function liveActive(id)
    local checked = false
    local onQuest = C_QuestLog and C_QuestLog.IsOnQuest
    if type(onQuest) == "function" then
        local ok, value = pcall(onQuest, id)
        if ok and type(value) == "boolean" then
            if value then return true end
            checked = true
        end
    end
    local indexMethods = {}
    if C_QuestLog and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
        indexMethods[#indexMethods+1] = C_QuestLog.GetLogIndexForQuestID
    end
    if type(GetQuestLogIndexByID) == "function" then
        indexMethods[#indexMethods+1] = GetQuestLogIndexByID
    end
    for _, fn in ipairs(indexMethods) do
        if type(fn) == "function" then
            local ok, value = pcall(fn, id)
            if ok and (value == nil or type(value) == "number") then
                if type(value) == "number" and value > 0 then return true end
                checked = true
            end
        end
    end
    if checked then return false end
    return nil
end

local function liveReady(id)
    local readyMethods = {}
    if C_QuestLog and type(C_QuestLog.ReadyForTurnIn) == "function" then
        readyMethods[#readyMethods+1] = C_QuestLog.ReadyForTurnIn
    end
    if C_QuestLog and type(C_QuestLog.IsComplete) == "function" then
        readyMethods[#readyMethods+1] = C_QuestLog.IsComplete
    end
    for _, fn in ipairs(readyMethods) do
        if type(fn) == "function" then
            local ok, value = pcall(fn, id)
            if ok and type(value) == "boolean" then
                if value then return true end
            end
        end
    end
    return false -- Never infer objective completion from missing APIs.
end

local function copyProgress(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local duplicate = {}
    seen[value] = duplicate
    for key, entry in pairs(value) do
        duplicate[copyProgress(key, seen)] = copyProgress(entry, seen)
    end
    return duplicate
end

function Guides:HasProgressBackup(id)
    local guide = self:GetGuide(id)
    return guide and ns.char and type(ns.char.guideProgressBackups) == "table"
        and type(ns.char.guideProgressBackups[guide.id]) == "table" or false
end

-- Deliberately explicit and reversible. Never run this from regular Sync.
function Guides:RebuildProgress(id)
    local guide = self:GetGuide(id)
    if not guide or (id and guide.id ~= id) or guide.isProfession then
        return false, "Rebuild is for quest guides only. Profession progress was not changed."
    end
    if not ns.char or type(ns.char.guideProgress) ~= "table" then
        return false, "Character progress is unavailable. Nothing was changed."
    end
    local steps, saved = self:GetSteps(guide.id), self:GetProgress(guide.id)
    if not saved or #steps == 0 then
        return false, "This guide has no steps. Nothing was changed."
    end
    local statuses, unique, matched = {}, 0, 0
    for _, step in ipairs(steps) do
        local id = step.questId
        if type(id) == "number" and id > 0 and not statuses[id] then
            local flagged, active = liveFlagged(id), liveActive(id)
            if flagged == nil or active == nil then
                return false, "WoW quest verification is unavailable for quest "..id..
                    ". No guide progress was changed."
            end
            -- The player can repeat a quest whose historical flag is true.
            -- While it is currently in the log, use the live phase instead
            -- of treating that older turn-in as completion of this run.
            local status = { turnedIn=flagged and not active, active=active,
                ready=active and liveReady(id) or false }
            statuses[id] = status
            unique = unique + 1
            if flagged or active then matched = matched + 1 end
        end
    end
    if unique == 0 then
        return false, "No quest IDs to verify. Nothing was changed."
    end

    local rebuilt = { current=1, completed={}, skipped={},
        routeMode="recommended", rebuiltFromGame=true, rebuiltTurnInEvents={} }
    local oldCount, newCount = 0, 0
    for index, step in ipairs(steps) do
        if saved.completed[stepKey(step,index)] then oldCount=oldCount+1 end
        if type(step.questId) == "number" and statuses[step.questId]
            and satisfied(step, statuses[step.questId]) then
            rebuilt.completed[stepKey(step,index)] = true
            newCount = newCount + 1
        end
    end

    -- An active quest is a trustworthy resume point. Do not mark unvisited
    -- manual steps complete, and never select a pickup already in the log.
    local target, match = nil, false
    for index, step in ipairs(steps) do
        local status = statuses[step.questId]
        if status and status.active and not status.turnedIn
            and not rebuilt.completed[stepKey(step,index)]
            and (step.action == "objective" or step.action == "turnin") then
            target, match = index, true
            break
        end
    end
    if not target then
        for index, step in ipairs(steps) do
            if not rebuilt.completed[stepKey(step,index)] then
                target = index
                break
            end
        end
    end
    target = target or #steps
    rebuilt.current = target
    rebuilt.currentStepId = stepKey(steps[target], target)

    -- Back up the entire selected-guide record, including old skip markers
    -- and metadata, before replacing it. Other guides and preferences remain
    -- untouched. Only the most recent rebuild is available for restoration.
    ns.char.guideProgressBackups = type(ns.char.guideProgressBackups) == "table"
        and ns.char.guideProgressBackups or {}
    ns.char.guideProgressBackups[guide.id] = copyProgress(saved)
    ns.char.guideProgress[guide.id] = rebuilt
    local report = guide.title..": rebuilt "..oldCount.." -> "..newCount..
        " verified steps. "..matched.." of "..unique.." quests matched; now at "..
        target.."/"..#steps..(match and " (active quest)." or " (first unverified step).")..
        " Previous progress backed up. Use Restore Previous Progress to undo."
    self.lastSyncReport = report
    return true, report
end

function Guides:RestorePreviousProgress(id)
    local guide = self:GetGuide(id)
    if not guide or (id and guide.id ~= id)
        or not self:HasProgressBackup(guide.id)
        or not ns.char or type(ns.char.guideProgress) ~= "table" then
        return false, "No progress backup exists for this guide."
    end
    local backup = ns.char.guideProgressBackups[guide.id]
    ns.char.guideProgress[guide.id] = copyProgress(backup)
    ns.char.guideProgressBackups[guide.id] = nil
    -- Normal Sync will subsequently incorporate any genuinely new quest
    -- events; restoration itself does not force progression.
    local progress = self:GetProgress(guide.id)
    local report = guide.title..": previous progress restored at step "..
        tostring(progress and progress.current or 1).."."
    self.lastSyncReport = report
    return true, report
end

function Guides:LastSyncReport()
    return self.lastSyncReport or "Sync checks completed, active and ready quests."
end

function Guides:Reset(id)
    local guide = self:GetGuide(id)
    local store = progressStore()
    if guide and store then store[guide.id] = { current = 1, completed = {} } end
end

function Guides:Summary(id)
    local guide = self:GetGuide(id)
    local saved = self:GetProgress(id)
    if not guide or not saved then return "No guides available" end
    local steps = self:GetSteps(id)
    local done = 0
    for index, step in ipairs(steps) do
        if saved.completed[stepKey(step, index)] then done = done + 1 end
    end
    return guide.title .. ": " .. done .. "/" .. #steps .. " steps"
end

function Guides:CurrentStep(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    return saved and steps[saved.current], saved and saved.current, #steps
end

-- Place a real Blizzard user waypoint for the displayed step, including
-- selected side steps. This intentionally does not advance quest progression.
function Guides:PinCurrent(index)
    local saved=self:GetProgress()
    if saved and saved.awaitingQuestMatch then
        return false, "Quest recovery is unresolved. No map pin was placed."
    end
    local navigator=ns.Modules.Navigator
    if not navigator or type(navigator.SetMapPin)~="function" then
        return false, "Map pin support is not initialized."
    end
    local steps=self:GetSteps()
    local current=self:CurrentStep()
    local focus=index or navigator.overrideIndex
    local step=focus and steps[focus] or current
    if not step then return false, "No guide objective selected." end
    local ok, status=navigator:SetMapPin(step)
    if ok then
        local destination=navigator:TargetForStep(step)
        if destination and type(navigator.SetOverride)=="function" and focus then
            navigator:SetOverride(focus,true)
        end
    end
    return ok, status
end

-- Guide steps may be skipped without ever forging a completed-quest flag.
function Guides:SkipCurrent(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    if not saved or #steps == 0 then return false end
    local index = saved.current
    local key = stepKey(steps[index], index)
    saved.skipped = type(saved.skipped) == "table" and saved.skipped or {}
    saved.skipped[key] = true
    saved.lastSkippedIndex = index
    if index < #steps then self:SetCurrent(index + 1, id) end
    return true
end

function Guides:UndoSkip(id)
    local saved = self:GetProgress(id)
    local steps = self:GetSteps(id)
    local index = saved and saved.lastSkippedIndex
    if not index or not steps[index] then return false end
    local key = stepKey(steps[index], index)
    if saved.skipped then saved.skipped[key] = nil end
    saved.lastSkippedIndex = nil
    self:SetCurrent(index, id)
    return true
end

function Guides:IsFavorite(id)
    return ns.char and type(ns.char.favorites) == "table" and ns.char.favorites[id] == true
end

function Guides:ToggleFavorite(id)
    if not ns.char or not byId[id] then return false end
    ns.char.favorites = type(ns.char.favorites) == "table" and ns.char.favorites or {}
    ns.char.favorites[id] = not ns.char.favorites[id]
    return ns.char.favorites[id]
end

function Guides:Status(id)
    local saved = self:GetProgress(id)
    if not saved then return "Not Started" end
    local steps = self:GetSteps(id)
    local done = 0
    for index, step in ipairs(steps) do
        if saved.completed[stepKey(step, index)] then done = done + 1 end
    end
    if done == #steps and #steps > 0 then return "Completed" end
    local skipped = type(saved.skipped) == "table" and next(saved.skipped) ~= nil
    if done > 0 or skipped or saved.current > 1 or (ns.char and ns.char.activeGuide == id) then
        return "In Progress"
    end
    return "Not Started"
end

function Guides:View(id)
    self:Sync(id)
    local guide = self:GetGuide(id)
    local saved = self:GetProgress(id)
    if not guide or not saved then return "Guide data unavailable" end
    local steps = self:GetSteps(id)
    local step = steps[saved.current]
    local check = saved.completed[stepKey(step, saved.current)] and "Done" or "Next objective"
    local where = step.hub or "Check your quest log"
    if step.x and step.y then where = where .. " (" .. step.x .. ", " .. step.y .. ")" end
    return table.concat({
        guide.title,
        "Step " .. saved.current .. "/" .. #steps .. " | Level " .. tostring(step.level or "?") .. " | " .. check,
        "",
        step.title,
        step.text,
        "",
        "Location: " .. where,
        step.questId and ("Quest ID: " .. step.questId .. " | " .. (step.action == "manual" and "manual" or "quest sync")) or "Manual checkpoint",
        "",
        self:Summary(id),
        "Switch Guide cycles the addon tutorial and both Skyborne factions.",
    }, "\n")
end
