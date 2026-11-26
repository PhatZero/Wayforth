-- Authored travel legs and known phase destinations; no guessed transport or pathfinding.
local _,ns=...
local Travel={}
ns:RegisterModule("Travel",Travel)
local function selected()
    local guides=ns.Modules.Guides
    if not guides or type(guides.CurrentStep)~="function" or type(guides.GetGuide)~="function" then return nil,nil end
    local step=guides:CurrentStep()
    local nav=ns.Modules.Navigator
    if nav and nav.overrideIndex then step=guides:GetSteps()[nav.overrideIndex] end
    return step,guides:GetGuide()
end
-- Read-only checkpoint evidence. A missing client API is unknown, not success.
local function query(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok then return value end
end
local function atDestination(leg)
    if not leg.destinationMapId then return nil end
    if query(C_Map and C_Map.GetBestMapForUnit,"player")~=leg.destinationMapId then return false end
    if leg.destinationSubzone then
        return query(GetSubZoneText)==leg.destinationSubzone
    end
    return true
end
function Travel:CheckpointStatus(leg)
    if not leg then return nil end
    if leg.kind=="arriveZone" then
        local map=query(C_Map and C_Map.GetBestMapForUnit,"player")
        if type(map)~="number" or type(leg.destinationMapId)~="number" then return nil end
        return atDestination(leg)
    elseif leg.kind=="flightPath" then
        if type(leg.nodeId)~="number" then return nil end
        local nodes=query(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap,leg.mapId)
        if type(nodes)~="table" then return nil end
        for _,node in ipairs(nodes) do
            if node.nodeID==leg.nodeId then
                local states=Enum and Enum.FlightPathState
                if states and states.Current~=nil and node.state==states.Current then return true end
                if states and states.Reachable~=nil and node.state==states.Reachable then return true end
                if states and states.Unreachable~=nil and node.state==states.Unreachable then return nil end
                return nil
            end
        end
        return nil
    elseif leg.kind=="bindHearth" then
        if not leg.bindName then return nil end
        local bind=query(GetBindLocation)
        if type(bind)~="string" then return nil end
        return bind==leg.bindName
    elseif leg.kind=="fly" then
        -- Require observed taxi travel followed by landing at the authored
        -- destination. Merely walking into a destination map proves nothing.
        local taxi=query(UnitOnTaxi,"player")
        if taxi==true then self.observedTaxi=true;return false end
        if taxi==false and self.observedTaxi then return atDestination(leg) end
        return nil
    elseif leg.kind=="hearth" then
        -- Location alone cannot prove the hearthstone was cast.
        -- Return steps are confirmed manually by the player.
        return nil
    end
    return nil
end
function Travel:CheckpointInstruction(leg)
    local state=self:CheckpointStatus(leg)
    if state==true then return "Verified in game. Continue to the next travel leg." end
    if state==false then return "Travel requirement not yet met." end
    return "Confirm this travel action yourself if the client cannot verify it."
end
function Travel:Plan(step)
    local current,guide=selected()
    step=step or current
    if not step then return {legs={},message="Select a guide step."} end
    local legs={}
    for _,leg in ipairs(step.travel or {}) do
        if (leg.kind=="flightPath" or leg.kind=="fly" or leg.kind=="bindHearth" or leg.kind=="hearth")
            and type(leg.text)~="string" then
            return {legs={},message="Travel checkpoint requires authored instructions."}
        end
        legs[#legs+1]=leg
    end
    if #legs==0 and step.waypoints then
        for _,point in ipairs(step.waypoints) do
            if type(point.mapId)~="number" or type(point.x)~="number" or type(point.y)~="number"
                or not (point.x>=0 and point.x<=100 and point.y>=0 and point.y<=100) then
                return {legs={},message="Invalid authored waypoint; route not started."}
            end
            legs[#legs+1]={kind="waypoint",mapId=point.mapId,x=point.x,y=point.y,
                text=point.text or string.format("Travel to %.1f, %.1f.",point.x,point.y)}
        end
    end
    if #legs==0 and step.questId==92850 and step.action=="objective"
        and (guide.id=="zephras-alliance") then
        local source=ns.zephrasQuestLocations and ns.zephrasQuestLocations[92850]
        if source and source.entrance then
            legs={
                {kind="entrance",text="Enter the Shriekling Den through the documented cave entrance, not the cliff above.",mapId=2521,x=source.entrance[1],y=source.entrance[2]},
                {kind="walk",text="Follow the cave passages to the Shriekling Matriarch. Check the quest objective inside."},
            }
        end
    end
    if #legs==0 and type(step.mapId)=="number" and type(step.x)=="number" and type(step.y)=="number"
        and step.x>0 and step.x<100 and step.y>0 and step.y<100 then
        local currentMap
        if C_Map and type(C_Map.GetBestMapForUnit)=="function" then
            local ok,value=pcall(C_Map.GetBestMapForUnit,"player")
            if ok then currentMap=value end
        end
        if guide.travelHint and currentMap~=step.mapId then legs[#legs+1]={kind="travel",text=guide.travelHint} end
        legs[#legs+1]={kind="destination",mapId=step.mapId,x=step.x,y=step.y,
            text=(step.text or step.title or "Follow the guide objective.").." Destination: "..
                tostring(step.zone or guide.zone or "quest area")..string.format(" (%.1f, %.1f). ",step.x,step.y)..
                "This pin marks the destination, not a walkable path. Use roads and available transport shown in game."}
    end
    return {guideId=guide.id,stepId=step.id,legs=legs,loop=step.waypointLoop==true and step.waypoints~=nil and #legs>1,questId=step.questId,message=#legs>0 and "Follow each leg, then click Next Travel Leg. Guide progress stays unchanged."
        or guide.travelHint or "No verified travel route is bundled for this step. Use the guide instructions and in-game map; no transport connection is assumed."}
end
-- Cross-zone handoffs are destination-backed, not a fabricated transport graph.
-- A player chooses a usable transport in the live client.
function Travel:ChapterPlan(origin, guide, step)
    if not guide or not step then return nil end
    local map=query(C_Map and C_Map.GetBestMapForUnit,"player")
    if type(map)~="number" or type(step.mapId)~="number" or map==step.mapId then return nil end
    local zone=tostring(step.zone or guide.zone or guide.title or "the next quest area")
    local cross=origin and origin.continent and guide.continent and origin.continent~=guide.continent
    local text="Travel to "..zone..". "
    if cross then
        text=text.."Check the in-game map for a faction-accessible boat, zeppelin or other inter-continent connection. "
    else
        text=text.."Check the flight master for an unlocked reachable destination, or use safe ground routes. "
    end
    local bind=query(GetBindLocation)
    if type(bind)=="string" and bind~="" then
        text=text.."Your hearthstone is bound to "..bind.."; use it only if ready and useful for this journey. "
    end
    text=text.."No specific transport connection is verified. Confirm arrival before continuing."
    local legs={{kind="arriveZone",destinationMapId=step.mapId,text=text}}
    if type(step.x)=="number" and type(step.y)=="number" and step.x>0 and step.x<100 and step.y>0 and step.y<100 then
        legs[#legs+1]={kind="destination",mapId=step.mapId,x=step.x,y=step.y,
            text="Continue to "..tostring(step.hub or step.questName or step.title or zone)
                .." in "..zone..string.format(" (%.1f, %.1f). Follow safe roads and terrain; this pin is not a path.",step.x,step.y)}
    end
    return {guideId=guide.id,stepId=step.id,legs=legs,index=1,chapterTravel=true,
        message="Travel to the next chapter; quest completion is unchanged."}
end

function Travel:StartChapter(origin)
    local step,guide=selected()
    if not step or not guide then return false end
    local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
    if routes and routes.BlockedReason and routes:BlockedReason(step,guides:GetSteps()) then return false end
    if guides.ConditionReason and guides:ConditionReason(step,guide.id) then return false end
    local plan=self:ChapterPlan(origin,guide,step)
    if not plan then return false end
    self.route=plan
    self.observedTaxi=nil
    ns:Call("Navigator","Refresh")
    ns:Call("Tracker","Refresh")
    return true
end

function Travel:Current(step)
    local route=self.route
    if not route then return nil end
    local current,guide=selected()
    step=step or current
    if not current or route.guideId~=guide.id or route.stepId~=current.id then self.route=nil;return nil end
    -- Probing another candidate for distance/search must not cancel active travel.
    if not step or step.id~=route.stepId then return nil end
    return route.legs[route.index]
end
function Travel:Start()
    local plan=self:Plan()
    if #plan.legs==0 then return false,plan.message end
    local step=selected()
    local routes=ns.Modules.SmartRoutes
    local reason=routes and routes.BlockedReason and routes:BlockedReason(step,ns.Modules.Guides:GetSteps())
    if reason then return false,reason end
    local guides=ns.Modules.Guides
    if guides.ConditionReason then
        local blocked=guides:ConditionReason(step)
        if blocked then return false,blocked end
    end
    plan.index=1;self.route=plan;self.observedTaxi=nil
    ns:Call("Navigator","Refresh")
    return true,plan.legs[1].text
end
function Travel:Next()
    if not self:Current() then return false,"No travel route is active." end
    local route=self.route
    local leg=route.legs[route.index]
    local status=self:CheckpointStatus(leg)
    if status==false then return false,self:CheckpointInstruction(leg) end
    self.observedTaxi=nil
    route.index=route.index+1
    if route.index>#route.legs and route.loop then
        local progress=ns.Modules.QuestProgress
        local snapshot=progress and route.questId and progress:Get(route.questId)
        if snapshot and snapshot.active and not snapshot.ready and not snapshot.failed then
            route.index=1
        end
    end
    local leg=route.legs[route.index]
    if not leg then self.route=nil end
    ns:Call("Navigator","Refresh")
    return true,leg and leg.text or "Travel directions finished. Continue the guide objective."
end
function Travel:Stop()
    self.route=nil
    self.observedTaxi=nil
    ns:Call("Navigator","Refresh")
end
