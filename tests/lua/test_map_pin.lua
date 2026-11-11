-- Test actual world-map pins and cross-zone navigation on Forever's APIs.
local ns={Modules={Theme={}},state={},char={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local current=101
local unsupported=false
local pin,tracked,opened
local worldEnabled=true
local playerPos={x=0.4,y=0.6}
C_Map={
    GetBestMapForUnit=function() return current end,
    GetPlayerMapPosition=function(id)
        if id==current then return playerPos end
        return nil
    end,
    GetWorldPosFromMapPos=function(id,pos)
        if not worldEnabled then error("no world conversion") end
        if id==101 then return 1,{x=0,y=0} end
        if id==102 then return 1,{x=0,y=-100} end
        if id==201 then return 2,{x=0,y=0} end
        if id==103 then return 1,{x=0,y=-100} end
    end,
    GetMapPosFromWorldPos=function(continent,point,target)
        if continent==1 and target==102 then return 102,{x=0.6,y=0.7} end
    end,
    GetMapWorldSize=function() return 500,250 end,
    CanSetUserWaypointOnMap=function(id)
        return id~=103 and not unsupported
    end,
    GetMapInfo=function(id)
        if id==103 then return {name="Micro",parentMapID=102} end
        return {name="Zone",parentMapID=0}
    end,
    SetUserWaypoint=function(p)
        pin=p
        return true
    end,
}
C_SuperTrack={SetSuperTrackedUserWaypoint=function(v) tracked=v end}
UiMapPoint={CreateFromCoordinates=function(id,x,y)
    return {uiMapID=id,position={x=x,y=y}}
end}
GetPlayerFacing=function() return 0 end
assert(loadfile("shared/navigation/Navigator.lua"))("WayForth",ns)
local nav=ns.Modules.Navigator
local target={mapId=102,x=0.6,y=0.7,action="accept",title="Remote quest"}
local angle,distance,reason=nav:DirectionForTarget({mapId=102,x=0.6,y=0.7})
assert(angle and math.abs(angle+math.pi/2)<0.001,"Eastward cross-zone target needs an eastward arrow")
assert(distance==100,"World-distance is 100 yards on same continent")
local ok,message=nav:SetMapPin(target)
assert(ok and pin.uiMapID==102 and pin.position.x==0.6 and tracked,
    "MAP PIN must set a real Blizzard user waypoint in the remote zone")
assert(message:find("Map pin set"),"Report actual pin placement")
-- Unsupported child map converts through world position to supported parent.
pin=nil
ok,message=nav:SetMapPin({mapId=103,x=0.1,y=0.2,action="accept"})
assert(ok and pin.uiMapID==102 and pin.position.x==0.6 and pin.position.y==0.7,
    "Use accurate parent-map conversion for unsupported local map")
-- Different continent has no misleading directional arrow.
angle,distance,reason=nav:DirectionForTarget({mapId=201,x=0.4,y=0.5})
assert(angle==nil and reason:find("continent"),"Never point across unsupported continent travel")
-- A failed pin must not be reported as success.
C_Map.SetUserWaypoint=function() return false end
ok,message=nav:SetMapPin(target)
assert(ok==false and message:find("could not"),"Respect map API rejection")
-- Disabled conversion cannot invent cross-zone bearings.
worldEnabled=false
angle,distance,reason=nav:DirectionForTarget({mapId=102,x=0.6,y=0.7})
assert(angle==nil and reason:find("zone"),"No percent-space arrow across unconvertible zones")
-- Same-map fallback respects rectangular dimensions and still provides bearing.
C_Map.GetPlayerMapPosition=function(id)
    if id==101 then return {x=0.5,y=0.5} end
end
angle,distance=nav:DirectionForTarget({mapId=101,x=0.6,y=0.5})
assert(angle and math.abs(angle+math.pi/2)<0.001,"Same-map east target")
assert(distance and math.abs(distance-50)<0.001,"Map width, not height, scales east/west distance")
-- Missing map coordinate must fail safely.
ok,message=nav:SetMapPin({questId=999,action="accept"})
assert(not ok and message:find("No verified"),"No fabricated map pins")
print("WayForth cross-zone map pins and premium arrow bearings passed")
