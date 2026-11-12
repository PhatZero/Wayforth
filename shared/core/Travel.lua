-- Explicit authored travel legs only; no guessed transport or straight-line pathfinding.
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
    return {guideId=guide.id,stepId=step.id,legs=legs,message=#legs>0 and "Follow each leg, then click Next Travel Leg. Guide progress stays unchanged."
        or guide.travelHint or "No verified travel route is bundled for this step. Use the guide instructions and in-game map; no transport connection is assumed."}
end
function Travel:Current(step)
    local route=self.route
    local current,guide=selected()
    step=step or current
    if route and (not step or route.guideId~=guide.id or route.stepId~=step.id) then self.route=nil;return nil end
    return route and route.legs[route.index]
end
function Travel:Start()
    local plan=self:Plan()
    if #plan.legs==0 then return false,plan.message end
    local step=selected()
    local reason=ns.Modules.SmartRoutes:BlockedReason(step,ns.Modules.Guides:GetSteps())
    if reason then return false,reason end
    plan.index=1;self.route=plan
    ns:Call("Navigator","Refresh")
    return true,plan.legs[1].text
end
function Travel:Next()
    if not self:Current() then return false,"No travel route is active." end
    self.route.index=self.route.index+1
    local leg=self.route.legs[self.route.index]
    if not leg then self.route=nil end
    ns:Call("Navigator","Refresh")
    return true,leg and leg.text or "Travel directions finished. Continue the guide objective."
end
function Travel:Stop()
    self.route=nil
    ns:Call("Navigator","Refresh")
end
