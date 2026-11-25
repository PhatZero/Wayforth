-- Authored travel legs and known phase destinations; no guessed transport or pathfinding.
local _,ns=...
local Travel={}
ns:RegisterModule("Travel",Travel)
local function selected()
    local guides=ns.Modules.Guides
    local step=guides:CurrentStep()
    local nav=ns.Modules.Navigator
    if nav and nav.overrideIndex then step=guides:GetSteps()[nav.overrideIndex] end
    return step,guides:GetGuide()
end
function Travel:Plan(step)
    local current,guide=selected()
    step=step or current
    if not step then return {legs={},message="Select a guide step."} end
    local legs={}
    for _,leg in ipairs(step.travel or {}) do legs[#legs+1]=leg end
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
    plan.index=1;self.route=plan
    ns:Call("Navigator","Refresh")
    return true,plan.legs[1].text
end
function Travel:Next()
    if not self:Current() then return false,"No travel route is active." end
    local route=self.route
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
    ns:Call("Navigator","Refresh")
end
