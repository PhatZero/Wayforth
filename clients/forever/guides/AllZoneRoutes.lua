-- Source-guided pickup/work/turn-in circuits for the remaining Forever leveling zones.
-- This is a deterministic guide-data authoring pass, NOT a second runtime route
-- engine. Real quest availability, eligibility and travel remain authoritative.
-- Preserve curated guides such as Zephras, the tutorial, dungeons and Westfall.
local _, ns = ...
local stats = {converted=0, preserved=0, quests=0, circuits=0, deferred=0}
ns.zoneRouteBuildStats = stats

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
    if a.mapId and b.mapId and a.mapId~=b.mapId then return false end
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy<=144 -- 12% of a zone map is a modest pickup circuit.
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

local starterZones={
    ["alliance-elwynn"]=true,["alliance-dun-morogh"]=true,["alliance-teldrassil"]=true,
    ["horde-durotar"]=true,["horde-mulgore"]=true,["horde-tirisfal-glades"]=true,
}
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
    if not starterZones[guide.id] then return end
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

local function createCircuit(guide, batch, output, chapter, nodes)
    -- Every pickup is listed before leaving the hub. Never silently pick up
    -- a quest behind its unturned-in prerequisite inside the same batch.
    for _,node in ipairs(batch) do
        local step=node.accept
        step.routeChapter=chapter
        step.optional=node.optional or nil
        output[#output+1]=step
    end
    groupVisits(guide,batch,"pickup",output)
    -- The reader's original stable objective keys survive the migration.
    -- Objective destination and quantities come from actual source metadata.
    for _,node in ipairs(batch) do
        if node.record and node.record.hasObjective then
            local step=copyStep(node.turnin)
            step.id=node.turnin.id.."-objective"
            step.action="objective"
            step.title="Work on: "..tostring(node.turnin.title or "Quest")
                :gsub("^Complete: ","")
            step.text="Complete the live quest objectives before returning to the quest giver."
            step.x,step.y,step.mapId=nil,nil,nil
            step.routeChapter=chapter
            step.optional=node.optional or nil
            output[#output+1]=step
        end
    end
    for _,node in ipairs(batch) do
        local step=node.turnin
        step.routeChapter=chapter
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
        node.level=tonumber(node.accept.level) or guide.levelMin or 1
        local requirements=(ns.foreverQuestRequirements or {})[node.id]
        node.minLevel=requirements and requirements.minLevel or nil
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
        node.optional=beyond or external or specialty or node.accept.class
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
                local an,bn=near(a.point,currentPoint),near(b.point,currentPoint)
                if an~=bn then return an end
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
            createCircuit(guide,batch,output,chapter,nodes)
            stats.circuits=stats.circuits+1
            currentPoint=first.point or currentPoint
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
