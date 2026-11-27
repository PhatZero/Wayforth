-- Source-guided pickup/work/turn-in circuits for the remaining Forever leveling zones.
-- This is a deterministic guide-data authoring pass, NOT a second runtime route
-- engine. Real quest availability, eligibility and travel remain authoritative.
-- Preserve curated guides such as Zephras, the tutorial, dungeons and Westfall.
local _, ns = ...
local stats = {converted=0, preserved=0, quests=0, circuits=0, deferred=0}
ns.zoneRouteBuildStats = stats

-- Independent gap review: factual IDs observed by ForeverDB. Entries are
-- attached to the existing faction-zone guide, never a duplicate zone guide.
-- Optional because live eligibility, exclusive alternatives and travel need
-- a real player check. Source chain corrections: QuestieDB c6745129.
local coverageAdditions={
    ["alliance-dun-morogh"]={291,311,312,313,315,317,319,320,400,413,414,417,432,433,2160,3364,3365,5541,95212,96390,96392,96408,96608,96628,97277,98321,99160,99161,99162},
    ["alliance-teldrassil"]={488,489,490,917,918,919,922,923,930,931,937,938,940,2459,4495,96606,96630,98391,98392,98398,99046,99047},
    ["alliance-ashenvale"]={1038,1039},
    ["alliance-darkshore"]={6341,6342,98461},
    ["alliance-loch-modan"]={6387,6388,6391,6392},
    ["alliance-elwynn"]={95998,96627},
    ["alliance-westfall"]={6181,6281,6261,6285},
    ["horde-mulgore"]={854},
    ["horde-the-barrens"]={6361,6362,6363,6364},
    ["horde-ashenvale"]={6562},
    ["horde-hillsbrad-foothills"]={93680},
}
local coveragePrerequisites={
    [291]={287,98323},[96390]={96392},[96392]={96408},
    [96608]={96628},[96628]={282},[99160]={99159},[99161]={99160},[99162]={99159},
    [96606]={96630},[96630]={921},[98392]={937},[98398]={98392},[940]={98398},
    [99047]={99046},[95998]={96627},[96627]={21},
    [6281]={6181},[6261]={6281},[6285]={6261},[6362]={6361},[6363]={6362},[6364]={6363},
}
local function observedCoveragePoint(entry,role)
    local p=entry and entry[role]
    if entry and entry.source=="forever" and p and p.source=="ForeverDB: seen in WoW Forever"
        and (p.kind=="npc" or p.kind=="object") and type(p.mapId)=="number" and p.mapId>0
        and type(p.x)=="number" and p.x>0 and p.x<100
        and type(p.y)=="number" and p.y>0 and p.y<100 then return p end
end
local function coveredFaction(entry,faction)
    return entry and (entry.side=="both" or entry.side==(faction=="Alliance" and "a" or "h"))
end
local function coverageStep(guide,id,entry,action,required,any)
    local role=action=="accept" and "pickup" or action
    local point=observedCoveragePoint(entry,role)
    local label=action=="accept" and "Pick up: " or action=="objective" and "Work on: " or "Complete: "
    local instruction
    if action=="accept" then
        instruction="Accept "..entry.name.." from "..(point and point.name or "the quest source").." if offered."
    elseif action=="turnin" then
        instruction="Return to "..(point and point.name or "the quest recipient").." when the live quest is ready."
    else
        instruction="Complete the remaining objectives shown in your quest log."
    end
    return {id="coverage-"..guide.id.."-"..id.."-"..action,questId=id,action=action,
        title=label..entry.name,text=instruction,zone=guide.zone,level=entry.level or guide.levelMin,
        minLevel=entry.minLevel,requires=required,requiresAny=any,optional=true,coverageSupplement=true,
        x=point and point.x,y=point and point.y,mapId=point and point.mapId,hub=point and point.name,
        locationSource=point and point.source,useLiveInstructions=action=="objective" or nil,
        sourceStatus="Observed ForeverDB factual quest coverage; live eligibility and travel pending"}
end
stats.supplemental=0
for _,guide in ipairs(ns.starterGuides or {}) do
    local ids=coverageAdditions[guide.id]
    if ids then
        local present={}
        for _,step in ipairs(guide.steps or {}) do
            if step.questId then present[step.questId]=true end
        end
        for _,id in ipairs(ids) do
            local entry=(ns.foreverDBQuests or {})[id]
            if not present[id] and coveredFaction(entry,guide.faction) and entry.zone==guide.zone
                and observedCoveragePoint(entry,"pickup") and observedCoveragePoint(entry,"turnin") then
                local rules=(ns.foreverQuestRequirements or {})[id]
                local required=coveragePrerequisites[id] or (rules and rules.requires)
                local any=not required and rules and rules.requiresAny or nil
                if not required and not any and entry.previous and #entry.previous==1 then required=entry.previous end
                local phases=guide.routeStyle and {"accept","objective","turnin"} or {"accept","turnin"}
                for _,action in ipairs(phases) do
                    local step=coverageStep(guide,id,entry,action,required,any)
                    if guide.routeStyle then step.routeChapter="Optional source-backed quest: "..entry.name end
                    guide.steps[#guide.steps+1]=step
                end
                present[id]=true
                stats.supplemental=stats.supplemental+1
            end
        end
    end
end

-- Complete the missing phases of the existing shared Skyborne story.
-- Source: observed ForeverDB endpoints and QuestieDB corrected chain facts.
-- Keep the old stable keys and the same shared step array for both factions.
local function expandSkyborne()
    local sky, variants
    variants={}
    for _,guide in ipairs(ns.starterGuides or {}) do
        if guide.id=="zephras-alliance" or guide.id=="zephras-horde" then
            sky=sky or guide
            variants[#variants+1]=guide
        end
    end
    if not sky or not ns.foreverDBQuests then return end
    local before,after,present={}, {}, {}
    local context={id="zephras",zone="Zephras Isle",levelMin=1}
    local function mark(q,phase)
        if q then present[q]=present[q] or {};present[q][phase]=true end
    end
    for _,step in ipairs(sky.steps) do
        mark(step.questId,step.action)
        for _,q in pairs(step.questIds or {}) do mark(q,step.action) end
    end
    local function add(target,anchor,id,phases,req,any,faction,class,optional)
        local entry=ns.foreverDBQuests[id]
        if not entry or entry.source~="forever" or entry.zone~="Zephras Isle" then return end
        if faction and not coveredFaction(entry,faction) then return end
        for token in phases:gmatch(".") do
            local action=({a="accept",o="objective",t="turnin"})[token]
            if not (present[id] and present[id][action])
                and (action=="objective" or observedCoveragePoint(entry,action=="accept" and "pickup" or action)) then
                local rules=(ns.foreverQuestRequirements or {})[id] or {}
                local step=coverageStep(context,id,entry,action,req or (not any and rules.requires),any or (not req and rules.requiresAny))
                step.optional=optional and true or nil
                step.faction=faction
                step.class=class
                step.liveLocationOnly=action=="objective" and true or nil
                target[anchor]=target[anchor] or {}
                target[anchor][#target[anchor]+1]=step
                mark(id,action)
                stats.skybornePhases=(stats.skybornePhases or 0)+1
            end
        end
    end
    for _,row in ipairs({
        {"class-mage",92481,"MAGE"},{"class-hunter",92482,"HUNTER"},
        {"class-rogue",92483,"ROGUE"},{"class-shaman",92484,"SHAMAN"},
        {"class-druid",92485,"DRUID"},{"class-warrior",92532,"WARRIOR"},
    }) do add(before,row[1],row[2],"at",{92461},nil,nil,row[3],true) end
    add(before,"racial-alliance",92597,"ao",{92461},nil,"Alliance")
    add(before,"racial-horde",92598,"ao",nil,nil,"Horde")
    add(after,"thendal-cleanup",92464,"at")
    add(after,"thendal-cleanup",92465,"aot",{92464})
    add(after,"thendal-cleanup",92469,"at",{92465})
    add(after,"thendal-cleanup",93552,"aot",{92461},nil,nil,nil,true)
    add(before,"matriarch-objective",92471,"at")
    add(before,"matriarch-objective",92470,"a",{92471})
    add(after,"matriarch-objective",92470,"t",{92471})
    add(before,"encroachment-objective",92473,"a",nil,nil,nil,nil,true)
    add(after,"encroachment-objective",92473,"t",nil,nil,nil,nil,true)
    add(after,"encroachment-objective",92472,"at",{92470})
    add(before,"village-arrival",93461,"a",{92472},nil,"Alliance")
    add(before,"village-arrival",92514,"a",{92472},nil,"Horde")
    add(before,"camp-outdoors",96638,"at",{92470},nil,nil,nil,true)
    add(before,"camp-outdoors",96101,"ao",{96638},nil,nil,nil,true)
    add(before,"shendar-highorder",92596,"a",{93461},nil,"Alliance")
    add(after,"shendar-highorder",94413,"aot",{92596},nil,"Alliance",nil,true)
    add(before,"shendar-windshaper",92595,"a",{92514},nil,"Horde")
    add(after,"shendar-windshaper",94411,"aot",{92595},nil,"Horde",nil,true)
    for _,id in ipairs({92515,92516,92553,93319,93951}) do
        add(before,"bandits-accept",id,"aot",nil,{92514,93461},nil,nil,true)
    end
    add(after,"bandits",92517,"t")
    add(before,"cult-infiltration",93036,"a",{92517})
    add(after,"cult-infiltration",92529,"at",{93036})
    add(after,"cult-infiltration",92528,"aot",{92529})
    add(after,"cult-infiltration",92550,"aot",{92528})
    add(after,"cult-infiltration",92551,"aot",{92528},nil,nil,nil,true)
    add(before,"west-watch",93926,"a")
    add(after,"west-watch",93927,"aot",{93926})
    add(after,"west-watch",93948,"at",{92550,93927})
    add(after,"west-watch",92701,"at",{92550,93927},nil,"Alliance")
    add(after,"west-watch",92579,"at",{92550,93927},nil,"Horde")
    add(before,"orchard",92679,"a")
    for _,id in ipairs({92682,92683,92684,92698}) do
        add(after,"orchard",id,"aot",{92679},nil,nil,nil,true)
    end
    add(after,"orchard",92685,"aot",{92682,92683,92684},nil,nil,nil,true)
    add(after,"orchard",92693,"aot",{92685},nil,nil,nil,true)
    add(after,"orchard",92703,"at",{92693},nil,nil,nil,true)
    add(after,"valanaar",93949,"aot",{93948},nil,nil,nil,true)
    add(after,"horde-leader",93736,"aot",{92700},nil,"Horde",nil,true)
    add(after,"construct-93737-accept",93737,"ot",{93735},nil,"Horde")
    add(after,"firm-response-93746-objective",93746,"t",nil,nil,"Horde")
    local expanded={}
    for _,step in ipairs(sky.steps) do
        for _,extra in ipairs(before[step.id] or {}) do expanded[#expanded+1]=extra end
        if step.id=="camp-outdoors" then
            local copy={}
            for k,v in pairs(step) do copy[k]=v end
            copy.optional=true
            expanded[#expanded+1]=copy
        else expanded[#expanded+1]=step end
        for _,extra in ipairs(after[step.id] or {}) do expanded[#expanded+1]=extra end
    end
    for _,guide in ipairs(variants) do guide.steps=expanded end
end
expandSkyborne()

local function validQuestGuide(guide)
    if not guide or guide.isProfession or guide.isDungeon
        or guide.id=="first-steps" or guide.routeStyle
        or guide.id:find("^zephras%-") then return false end
    if type(guide.steps)~="table" or #guide.steps<2 then return false end
    local phases={}
    for _,step in ipairs(guide.steps) do
        if type(step.questId)~="number"
            or (step.action~="accept" and step.action~="turnin") then return false end
        phases[step.questId]=phases[step.questId] or {}
        if phases[step.questId][step.action] then return false end
        phases[step.questId][step.action]=true
    end
    for _,entry in pairs(phases) do
        if not entry.accept or not entry.turnin then return false end
    end
    return true
end

local function copyStep(source)
    local target={}
    for key,value in pairs(source) do target[key]=value end
    return target
end

local function knownPoint(guide, step, record)
    local entries=record and record.pickup or nil
    local chosen
    for _,point in ipairs(entries or {}) do
        if type(point.x)=="number" and type(point.y)=="number"
            and (not point.faction or point.faction==guide.faction) then
            local zone=(ns.foreverLocationMaps or {})[point.mapId]
            if zone==guide.zone then chosen=point; break end
            chosen=chosen or point
        end
    end
    if chosen then
        return {x=chosen.x,y=chosen.y,mapId=chosen.mapId,
            name=chosen.name or (record and record.pickupName)}
    end
    if type(step.x)=="number" and type(step.y)=="number" then
        -- Older catalogs have zone-relative pickup coordinates but no map ID.
        -- These are only used to GROUP steps, never to fabricate a map pin.
        return {x=step.x,y=step.y,mapId=step.mapId,name=step.hub}
    end
    return nil
end

local function prerequisites(step, record, requirements)
    local source=(ns.foreverQuestRequirements or {})[step.questId] or {}
    -- Authored prerequisites take precedence over imported candidate metadata.
    -- Do not infer 'no prerequisite' from missing data.
    local required=step.requires
    local any=step.requiresAny
    if required==nil and any==nil then
        required=source.requires or (requirements and requirements.requires)
        any=source.requiresAny or (requirements and requirements.requiresAny)
    end
    return required or {},any or {}
end

local function near(a,b)
    if not a or not b then return false end
    if not a.mapId or not b.mapId or a.mapId~=b.mapId then return false end
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy<=144 -- 12% of a zone map is a modest pickup circuit.
end

local function distance(a,b)
    if not a or not b or not a.mapId or a.mapId~=b.mapId then return math.huge end
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end

local function dependsOn(dependent,parent)
    for _,id in ipairs(dependent.required) do if id==parent then return true end end
    for _,id in ipairs(dependent.any) do if id==parent then return true end end
    return false
end

local function canRelease(node, completed, nodes)
    for _,id in ipairs(node.required) do
        if nodes[id] and not completed[id] then return false end
    end
    local internal=false
    local oneMet=false
    for _,id in ipairs(node.any) do
        if nodes[id] then
            internal=true
            if completed[id] then oneMet=true end
        end
    end
    return not internal or oneMet
end

-- Only group identical source NPC endpoints, not merely nearby quest givers.
local function endpoint(guide,node,role)
    local found
    for _,point in ipairs(node.record and node.record[role] or {}) do
        if (not point.faction or point.faction==guide.faction) and point.kind=="npc"
            and type(point.mapId)=="number" and type(point.x)=="number" and type(point.y)=="number"
            and type(point.name)=="string" and point.name~="" then
            local key=point.mapId..":"..point.x..":"..point.y..":"..point.name
            if found and found.key~=key then return nil end
            found={key=key,name=point.name}
        end
    end
    return found
end
local function groupVisits(guide,batch,role,output)
    local action=role=="pickup" and "accept" or "turnin"
    local first=#output-#batch+1
    local previous,start
    for i,node in ipairs(batch) do
        local point=endpoint(guide,node,role)
        local step=output[first+i-1]
        if point and previous and point.key==previous.key
            and not node.accept.races and not node.accept.class
            and not batch[i-1].accept.races and not batch[i-1].accept.class
            and not node.optional and not batch[i-1].optional then
            local visit={id=guide.id..":"..action..":"..output[start].id,title="Speak with "..point.name}
            output[start].visit=visit
            step.visit=visit
        else start=first+i-1 end
        previous=point
    end
end

local function createCircuit(guide, batch, output, chapter, nodes, circuitId, chapterLevel)
    -- Every pickup is listed before leaving the hub. Never silently pick up
    -- a quest behind its unturned-in prerequisite inside the same batch.
    for _,node in ipairs(batch) do
        local step=copyStep(node.accept)
        step.routeChapter=chapter
        step.routeCircuitId=circuitId
        step.routeChapterLevel=chapterLevel
        step.optional=node.optional or nil
        output[#output+1]=step
    end
    groupVisits(guide,batch,"pickup",output)
    -- The reader's original stable objective keys survive the migration.
    -- Objective destination and quantities come from actual source metadata.
    for _,node in ipairs(batch) do
        if (node.record and node.record.hasObjective) or node.accept.coverageSupplement then
            local step=copyStep(node.turnin)
            step.id=node.turnin.id.."-objective"
            step.action="objective"
            step.title="Work on: "..tostring(node.turnin.title or "Quest")
                :gsub("^Complete: ","")
            step.text="Complete the live quest objectives before returning to the quest giver."
            step.x,step.y,step.mapId=nil,nil,nil
            step.routeChapter=chapter
        step.routeCircuitId=circuitId
        step.routeChapterLevel=chapterLevel
            step.optional=node.optional or nil
            output[#output+1]=step
        end
    end
    for _,node in ipairs(batch) do
        local step=copyStep(node.turnin)
        step.routeChapter=chapter
        step.routeCircuitId=circuitId
        step.routeChapterLevel=chapterLevel
        step.optional=node.optional or nil
        output[#output+1]=step
    end
    groupVisits(guide,batch,"turnin",output)
end

local function convert(guide)
    local original=guide.steps
    local nodes,order,priorities={}, {}, {}
    for index,step in ipairs(original) do
        local node=nodes[step.questId]
        if not node then
            node={id=step.questId,sourceIndex=index}
            nodes[step.questId]=node
            order[#order+1]=node
        end
        node[step.action]=step
    end
    for _,node in ipairs(order) do
        local record=(ns.foreverQuestLocations or {})[node.id]
        node.record=record
        node.point=knownPoint(guide,node.accept,record)
        local required,any=prerequisites(node.accept,record)
        node.required,node.any=required,any
        local catalog=(ns.foreverDBQuests or {})[node.id]
        node.level=(catalog and catalog.source=="forever" and tonumber(catalog.level) and catalog.level>0 and catalog.level<=60 and catalog.level) or tonumber(node.accept.level) or guide.levelMin or 1
        local requirements=(ns.foreverQuestRequirements or {})[node.id]
        node.minLevel=requirements and requirements.minLevel or (catalog and catalog.source=="forever" and catalog.minLevel) or nil
        local beyond=(guide.levelMax and node.level>guide.levelMax+2)
            or (guide.levelMax and node.minLevel and node.minLevel>guide.levelMax+2)
        local external=false
        for _,id in ipairs(required) do
            if not nodes[id] then external=true end
        end
        if #any>0 then
            local found=false
            for _,id in ipairs(any) do if nodes[id] then found=true end end
            if not found then external=true end
        end
        local label=tostring(node.accept.title or "")
        local specialty=label:find("Camping 101:",1,true)
            or label:find("Alchemy",1,true) and label:find("My First",1,true)
        node.optional=node.accept.optional or beyond or external or specialty or node.accept.class
            or node.accept.races or (record and (record.hidden or record.startItem))
            or (not node.point) or nil
        node.routeReason=beyond and "Higher-level optional quest"
            or external and "Requires a quest from outside this guide"
            or specialty and "Profession-specific quest"
            or not node.point and "Quest giver not yet verified"
            or nil
    end
    -- Any quest locked behind optional content must also stay optional.
    -- This avoids blocking a main circuit on a missing outside-zone chain.
    local changed=true
    while changed do
        changed=false
        for _,node in ipairs(order) do
            if not node.optional then
                for _,id in ipairs(node.required) do
                    if nodes[id] and nodes[id].optional then
                        node.optional=true;changed=true;break
                    end
                end
                if not node.optional and #node.any>0 then
                    local hasInternal,hasMain=false,false
                    for _,id in ipairs(node.any) do
                        if nodes[id] then
                            hasInternal=true
                            if not nodes[id].optional then hasMain=true end
                        end
                    end
                    if hasInternal and not hasMain then
                        node.optional=true;changed=true
                    end
                end
            end
        end
    end

    local output,done,remaining={}, {}, {}
    for _,node in ipairs(order) do remaining[node.id]=node end
    local currentPoint=nil
    local function orderedCandidates(isOptional)
        local candidates={}
        for _,node in ipairs(order) do
            if remaining[node.id] and not not node.optional==isOptional
                and canRelease(node,done,nodes) then
                candidates[#candidates+1]=node
            end
        end
        table.sort(candidates,function(a,b)
            if a.level~=b.level then return a.level<b.level end
            if currentPoint then
                local ad,bd=distance(a.point,currentPoint),distance(b.point,currentPoint)
                if ad~=bd then return ad<bd end
            end
            return a.sourceIndex<b.sourceIndex
        end)
        return candidates
    end
    for _,optional in ipairs({false,true}) do
        local total=0
        for _,node in ipairs(order) do
            if not not node.optional==optional then total=total+1 end
        end
        while total>0 do
            local candidates=orderedCandidates(optional)
            local first=candidates[1]
            if not first then
                -- Imported prerequisite cycles or incomplete source metadata
                -- cannot become a hard block or be guessed as completed.
                for _,node in ipairs(order) do
                    if remaining[node.id] and not not node.optional==optional then
                        first=node
                        node.routeUnverified=true
                        node.accept=copyStep(node.accept)
                        node.accept.routeWarning="Source prerequisite graph unresolved; confirm quest availability before continuing."
                        stats.deferred=stats.deferred+1
                        break
                    end
                end
            end
            if not first then break end
            local batch={first}
            if not first.routeUnverified then
                for _,node in ipairs(candidates) do
                    if #batch>=5 then break end
                    if node~=first and node.level<=first.level+3 and near(first.point,node.point) then
                        -- Both quests were eligible at the START of the circuit.
                        -- Never include one that is unlocked by this batch.
                        local dependent=false
                        for _,member in ipairs(batch) do
                            if dependsOn(node,member.id) then dependent=true end
                        end
                        if not dependent then batch[#batch+1]=node end
                    end
                end
            end
            local hub=(first.point and first.point.name)
                or first.accept.hub or guide.zone or guide.title
            local chapter=(optional and "Optional: " or "Quest circuit: ")
                ..tostring(hub).." (around level "..tostring(first.level)..")"
            local chapterLevel=1
            for _,node in ipairs(batch) do
                chapterLevel=math.max(chapterLevel,node.level,node.minLevel or 1)
            end
            createCircuit(guide,batch,output,chapter,nodes,first.id,chapterLevel)
            stats.circuits=stats.circuits+1
            -- The next circuit starts at the last verified turn-in, not at the pickup.
            local last=batch[#batch]
            local lastPoint
            for _,point in ipairs(last.record and last.record.turnin or {}) do
                if (not point.faction or point.faction==guide.faction)
                    and type(point.mapId)=="number" and type(point.x)=="number" and type(point.y)=="number" then
                    if lastPoint then lastPoint=nil;break end
                    lastPoint=point
                end
            end
            currentPoint=lastPoint
            for _,node in ipairs(batch) do
                remaining[node.id]=nil
                done[node.id]=true
                total=total-1
            end
        end
    end

    -- Keep the exact old source steps and numeric-only SavedVariable cursors.
    guide.legacySteps=original
    guide.steps=output
    guide.routeStyle="source-circuits"
    guide.routeCircuits=true
    guide.description=(guide.description or "")..
        " Pick up quests together at nearby source-backed hubs, complete their objectives, and group turn-ins. Verify live quest availability and optional prerequisites."
    guide.contentStatus="Grouped source-backed quest circuits; in-game route and eligibility verification pending"
    guide.testingOnly=guide.testingOnly~=false
    stats.converted=stats.converted+1
    stats.quests=stats.quests+#order
end

for _,guide in ipairs(ns.starterGuides or {}) do
    if validQuestGuide(guide) then
        convert(guide)
    else
        stats.preserved=stats.preserved+1
    end
end

-- Build optional, independently resumable chapter guides from whole circuits.
-- Never split a pickup/objective/turn-in circuit or move a dependent ahead
-- of its source ordering. The original zone guide remains available.
local function generateChapters(guide)
    if not guide.routeCircuits or not guide.levelMin or not guide.levelMax
        or not guide.faction then return {} end
    local chapters, current, circuit, previousBand = {}, nil, nil, nil
    local function flush()
        if current and #current.steps>0 then chapters[#chapters+1]=current end
        current=nil
    end
    local function addCircuit(steps)
        if #steps==0 then return end
        local first=steps[1]
        local level=math.max(1,math.min(60,math.floor(first.routeChapterLevel or guide.levelMin)))
        -- Five-level bands are an editorial default, not an XP prediction.
        local band=math.min(56,math.floor((level-1)/5)*5+1)
        -- The source is already dependency ordered. Do not reorder circuits.
        band=math.max(previousBand or band,band)
        previousBand=band
        if not current or current.chapterBand~=band then
            flush()
            current=copyStep(guide)
            current.id=guide.id.."-chapter-"..band
            current.title=string.format("%d-%d %s",band,math.min(60,band+4),guide.zone or guide.title)
            current.levelMin=band
            current.levelMax=math.min(60,band+4)
            current.chapterBand=band
            current.parentGuideId=guide.id
            current.generatedChapter=true
            current.testingOnly=true
            current.legacySteps=nil
            current.steps={}
            current.description="Original level-band quest circuits. Check live eligibility; XP and travel have not been playtested."
            current.contentStatus="Generated chapter; in-game verification pending"
        end
        for _,step in ipairs(steps) do current.steps[#current.steps+1]=copyStep(step) end
    end
    for _,step in ipairs(guide.steps) do
        if not step.routeCircuitId then return {} end
        if not circuit or circuit[1].routeCircuitId~=step.routeCircuitId then
            if circuit then addCircuit(circuit) end
            circuit={}
        end
        circuit[#circuit+1]=step
    end
    if circuit then addCircuit(circuit) end
    flush()
    -- Include single-band zones for both faction progression inventories.
    for i,chapter in ipairs(chapters) do
        chapter.chapterIndex=i
        chapter.chapterCount=#chapters
        chapter.nextChapterId=chapters[i+1] and chapters[i+1].id or nil
    end
    return chapters
end

ns.GenerateLevelChapters=generateChapters
local generated={}
local ids={}
for _,guide in ipairs(ns.starterGuides or {}) do ids[guide.id]=true end
for _,guide in ipairs(ns.starterGuides or {}) do
    for _,chapter in ipairs(generateChapters(guide)) do
        if not ids[chapter.id] then
            ids[chapter.id]=true
            generated[#generated+1]=chapter
        end
    end
end
for _,chapter in ipairs(generated) do
    ns.starterGuides[#ns.starterGuides+1]=chapter
end
stats.chapters=#generated

-- Both factions use the same progression inventory and coverage contract.
local function buildProgression(faction)
    local inventory={chapters={},coverage={},gaps={}}
    local splitParents={}
    for _,g in ipairs(ns.starterGuides or {}) do
        if g.generatedChapter and g.faction==faction then splitParents[g.parentGuideId]=true end
    end
    for _,g in ipairs(ns.starterGuides or {}) do
        if g.faction==faction and not g.isProfession and not g.isDungeon
            and not g.isOptional and not g.isSpecialized and g.id~="first-steps"
            and g.levelMin and g.levelMax and #g.steps>0
            and (g.generatedChapter or not splitParents[g.id]) then
            g.factionProgression=true
            if faction=="Alliance" then g.allianceProgression=true else g.hordeProgression=true end
            inventory.chapters[#inventory.chapters+1]=g.id
            for level=math.max(1,g.levelMin),math.min(60,g.levelMax) do
                inventory.coverage[level]=(inventory.coverage[level] or 0)+1
            end
        end
    end
    table.sort(inventory.chapters)
    for level=1,60 do
        if not inventory.coverage[level] then inventory.gaps[#inventory.gaps+1]=level end
    end
    return inventory
end
ns.allianceProgression=buildProgression("Alliance")
ns.hordeProgression=buildProgression("Horde")
