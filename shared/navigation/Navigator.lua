local _, ns = ...
local Navigator = {}
ns:RegisterModule("Navigator", Navigator)

local theme = ns.Modules.Theme
local tau = math.pi * 2

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    return y >= 0 and math.pi / 2 or -math.pi / 2
end

local function getXY(position)
    if not position then return nil end
    if type(position.GetXY) == "function" then return position:GetXY() end
    return position.x, position.y
end

local function validCoord(x, y)
    return type(x) == "number" and type(y) == "number"
        and x == x and y == y and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

-- Resolve only a map currently containing the player. Prevent a different
-- zone's percent coordinates being interpreted on Zephras or Kalimdor.
local function getCurrentZoneMap(expectedZone)
    if type(C_Map) ~= "table" or type(C_Map.GetBestMapForUnit) ~= "function"
        or type(C_Map.GetMapInfo) ~= "function" then return nil end
    local map = C_Map.GetBestMapForUnit("player")
    local visited = {}
    local wanted = expectedZone or "Zephras Isle"
    for _ = 1, 10 do
        if not map or visited[map] then return nil end
        visited[map] = true
        local info = C_Map.GetMapInfo(map)
        if not info then return nil end
        if info.name == wanted then return map end
        map = info.parentMapID
    end
end

local function activeQuest(id)
    if type(C_QuestLog) ~= "table" then return false end
    if type(C_QuestLog.IsOnQuest) == "function" then
        local ok, result = pcall(C_QuestLog.IsOnQuest, id)
        if ok and result == true then return true end
    end
    if type(C_QuestLog.GetLogIndexForQuestID) == "function" then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, id)
        if ok and type(index) == "number" and index > 0 then return true end
    end
    return false
end

local function questWaypoint(questId, preferredMapId)
    if type(questId) ~= "number" or not activeQuest(questId)
        or type(C_QuestLog) ~= "table" then return nil end

    if type(C_QuestLog.GetNextWaypoint) == "function" then
        local ok, mapId, x, y = pcall(C_QuestLog.GetNextWaypoint, questId)
        if ok and type(mapId) == "number" and validCoord(x, y) then
            return { mapId = mapId, x = x, y = y, source = "Quest waypoint" }
        end
    end

    -- On Forever some quests have map POIs but no GetNextWaypoint result.
    if type(preferredMapId) == "number" then
        if type(C_QuestLog.GetNextWaypointForMap) == "function" then
            local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questId, preferredMapId)
            if ok and validCoord(x, y) then
                return { mapId = preferredMapId, x = x, y = y, source = "Quest map waypoint" }
            end
        end
        if type(C_QuestLog.GetQuestsOnMap) == "function" then
            local ok, quests = pcall(C_QuestLog.GetQuestsOnMap, preferredMapId)
            if ok and type(quests) == "table" then
                for _, poi in ipairs(quests) do
                    if poi.questID == questId and validCoord(poi.x, poi.y) then
                        return { mapId = preferredMapId, x = poi.x, y = poi.y, source = "Quest map pin" }
                    end
                end
            end
        end
    end
end

local function targetForStep(step)
    if not step then return nil end
    local mapId = step.mapId or getCurrentZoneMap(step.zone)
    local authored
    if type(mapId) == "number" and type(step.x) == "number" and type(step.y) == "number" then
        local x, y = step.x / 100, step.y / 100
        if validCoord(x, y) then
            authored = { mapId = mapId, x = x, y = y, source = step.locationSource and (step.locationSource .. " " .. tostring(step.action) .. " location")
                or (step.zone and "Public catalog pickup (client unverified)" or "Verified guide location") }
        end
    end
    -- Turn-ins, pickups and trainer visits should point to their verified NPC
    -- instead of a quest's *next* objective after it has already been accepted.
    if authored and step.action ~= "objective" then return authored end
    local live = questWaypoint(step.questId, mapId)
    -- Preserve a legitimate client waypoint even when the player is in a
    -- different zone. Map pins can be placed remotely, and world-space
    -- navigation handles reachable maps on the same continent.
    return live or authored
end

local function safeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c = pcall(func, ...)
    if ok then return a, b, c end
end

local function vectorFor(x, y)
    if type(CreateVector2D) == "function" then
        local vector = safeCall(CreateVector2D, x, y)
        if vector then return vector end
    end
    return { x = x, y = y }
end

-- Distances and bearings must be computed in yards, not raw 0..1 percent
-- map coordinates (which are distorted in non-square or differently sized zones).
-- WoW world x is north-positive and world y is west-positive, matching facing.
local function waypointVector(target)
    if not target or not target.mapId or not validCoord(target.x, target.y)
        or type(C_Map) ~= "table" then return nil, nil, "No waypoint" end
    local currentMap = safeCall(C_Map.GetBestMapForUnit, "player")
    if type(currentMap) ~= "number" then return nil, nil, "Position unavailable" end
    local currentPos = safeCall(C_Map.GetPlayerMapPosition, currentMap, "player")
    local px, py = getXY(currentPos)
    if not validCoord(px, py) then return nil, nil, "Position unavailable" end

    local north, west, distance
    if type(C_Map.GetWorldPosFromMapPos) == "function" then
        local fromContinent, fromWorld = safeCall(C_Map.GetWorldPosFromMapPos,
            currentMap, vectorFor(px, py))
        local toContinent, toWorld = safeCall(C_Map.GetWorldPosFromMapPos,
            target.mapId, vectorFor(target.x, target.y))
        local ax, ay = getXY(fromWorld)
        local bx, by = getXY(toWorld)
        if fromContinent and toContinent and fromContinent == toContinent
            and type(ax) == "number" and type(ay) == "number"
            and type(bx) == "number" and type(by) == "number" then
            north, west = bx - ax, by - ay
            distance = math.sqrt(north * north + west * west)
        elseif fromContinent and toContinent and fromContinent ~= toContinent then
            return nil, nil, "Travel to destination continent"
        end
    end

    if north == nil then
        -- Safe local fallback for clients without world-position conversions.
        -- Never interpret a different zone's percentages as a local target.
        local pos = safeCall(C_Map.GetPlayerMapPosition, target.mapId, "player")
        local tx, ty = getXY(pos)
        if not validCoord(tx, ty) then
            return nil, nil, "Travel to destination zone"
        end
        local width, height = safeCall(C_Map.GetMapWorldSize, target.mapId)
        if type(width) ~= "number" or width <= 0
            or type(height) ~= "number" or height <= 0 then
            width, height = nil, nil
        end
        local east = target.x - tx
        local south = target.y - ty
        north, west = -south * (height or 1), -east * (width or 1)
        if width then distance = math.sqrt(north * north + west * west) end
    end

    local facing = safeCall(GetPlayerFacing)
    if type(facing) ~= "number" or facing ~= facing then
        return nil, distance, "Facing unavailable"
    end
    local bearing = atan2(west, north)
    local relative = (bearing - facing + math.pi) % tau - math.pi
    return relative, distance
end

function Navigator:DirectionForTarget(target)
    return waypointVector(target)
end

-- The built-in WayForth map-pin API is independent of the navigation
-- pointer. A pin is an actual Blizzard user waypoint, not an arrow override.
function Navigator:SetMapPin(step)
    local target = targetForStep(step)
    if not target then return false, "No verified coordinate for this quest step." end
    if not (type(C_Map) == "table" and type(C_Map.SetUserWaypoint) == "function") then
        return false, "Map waypoint API is unavailable on this client."
    end
    local mapID, x, y = target.mapId, target.x, target.y
    if type(mapID) ~= "number" or not validCoord(x, y) then
        return false, "This quest has no usable map location."
    end

    local function supported(id)
        if type(C_Map.CanSetUserWaypointOnMap) ~= "function" then return true end
        return safeCall(C_Map.CanSetUserWaypointOnMap, id) == true
    end
    local originalMap, originalX, originalY = mapID, x, y
    local visited = {}
    while not supported(mapID) do
        if visited[mapID] then return false, "No supported map for this pin." end
        visited[mapID] = true
        local info = safeCall(C_Map.GetMapInfo, mapID)
        local parent = info and info.parentMapID
        if type(parent) ~= "number" or parent == 0 then
            return false, "The destination map does not allow user pins."
        end
        if type(C_Map.GetWorldPosFromMapPos) ~= "function"
            or type(C_Map.GetMapPosFromWorldPos) ~= "function" then
            return false, "This map needs coordinate conversion before pinning."
        end
        local continent, world = safeCall(C_Map.GetWorldPosFromMapPos,
            originalMap, vectorFor(originalX, originalY))
        if not continent or not world then
            return false, "Cannot translate this quest location to a pin-enabled map."
        end
        local foundMap, mapped = safeCall(C_Map.GetMapPosFromWorldPos,
            continent, world, parent)
        local mx, my = getXY(mapped)
        if foundMap ~= parent or not validCoord(mx, my) then
            return false, "Cannot translate this quest location accurately."
        end
        mapID, x, y = parent, mx, my
    end

    local point
    if UiMapPoint and type(UiMapPoint.CreateFromCoordinates) == "function" then
        point = safeCall(UiMapPoint.CreateFromCoordinates, mapID, x, y)
    end
    if not point then
        point = { uiMapID = mapID, position = vectorFor(x, y) }
    end
    local ok, set = pcall(C_Map.SetUserWaypoint, point)
    if not ok or set == false then
        return false, "The game could not place this world-map pin."
    end
    local tracked = false
    if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        local success = pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        tracked = success
    end
    self.lastMapPin = {mapId=mapID, x=x, y=y}
    return true, string.format("Map pin set at %.1f, %.1f%s.",
        x * 100, y * 100, tracked and " (tracked)" or "")
end

function Navigator:MakeFrame()
    if self.frame then return end
    local window = CreateFrame("Frame", "WayForthNavigator", UIParent)
    -- Only the arrow itself is visible: the frame is an invisible drag target.
    -- No panel, header, borders or destination box over the game world.
    window:SetSize(146, 142)
    window:SetFrameStrata("HIGH")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetPoint("TOP", UIParent, "TOP", ns.Modules.Database:Get("navX") or 0, ns.Modules.Database:Get("navY") or -110)

    -- Original WayForth needle: gold rim, dark core and cyan bearing stripe.
    -- It has its own transparent halo so no intrusive box or cloned minimap icon.
    local arrow = window:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\AddOns\\WayForth\\Textures\\WayForthArrow.tga")
    arrow:SetSize(105, 105)
    arrow:SetPoint("TOP", window, "TOP", 0, 0)
    self.arrow = arrow
    window:SetScale(ns.Modules.Database:Get("arrowScale") or 1)

    -- Small distance only, below the frameless arrow.
    local distanceText = theme:Text(window, "", 15, theme.gold, "CENTER")
    distanceText:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
    distanceText:SetWidth(145)
    self.distanceText = distanceText
    local destinationText = theme:Text(window, "", 10, theme.teal, "CENTER")
    destinationText:SetPoint("TOP", distanceText, "BOTTOM", 0, -2)
    destinationText:SetWidth(145)
    self.destinationText = destinationText

    window:SetScript("OnDragStart", function(frame)
        if not ns.Modules.Database:Get("trackerLocked") then frame:StartMoving() end
    end)
    window:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local centerX, top = UIParent:GetCenter(), UIParent:GetTop()
        local x, y = frame:GetCenter()
        if centerX and top and x and y then
            ns.Modules.Database:Set("navX", x - centerX)
            ns.Modules.Database:Set("navY", y + frame:GetHeight() / 2 - top)
        end
    end)
    window:SetScript("OnUpdate", function(_, elapsed)
        Navigator.elapsed = (Navigator.elapsed or 0) + elapsed
        if Navigator.elapsed < 0.16 then return end
        Navigator.elapsed = 0
        Navigator:UpdateDirection()
    end)
    window:Hide()
    self.frame = window
end

-- Shared waypoint resolution also lets the Pin button navigate objective steps
-- that have a client POI but no authored coordinates.
function Navigator:TargetForStep(step)
    return targetForStep(step)
end

function Navigator:Refresh()
    if not self.frame then return end
    local guides = ns.Modules.Guides
    local step = guides:CurrentStep()
    local saved = guides:GetProgress()
    -- Never display a direction to an unverified Zephras step when the
    -- recommended guide has no matching quest in the actual player log.
    if saved and saved.awaitingQuestMatch then
        self.target = nil
        self:UpdateDirection()
        return
    end
    if self.overrideIndex then
        local steps = guides:GetSteps()
        local alternate = steps[self.overrideIndex]
        local key = alternate and (alternate.id or self.overrideIndex)
        if not alternate or (saved and saved.completed[key]) then
            self.overrideIndex, self.pinnedIndex = nil, nil
        else
            step = alternate
        end
    end
    -- Do not secretly redirect the arrow to another grouped step. The
    -- tracker must always describe the active navigation target. Players can
    -- explicitly select a suggested nearby step without altering quest flags.
    local ok, target = pcall(targetForStep, step)
    local previous = self.target
    self.target = ok and target or nil
    if not previous or not self.target or previous.mapId ~= self.target.mapId
        or previous.x ~= self.target.x or previous.y ~= self.target.y then
        self.lastAngle = nil
    end
    self.currentDestination = step and tostring(step.title or step.hub or "Objective")
    self:UpdateDirection()
end

function Navigator:UpdateDirection()
    if not self.frame or not self.frame:IsShown() then return end
    local settings = ns.Modules.Database
    local scale = settings and settings:Get("arrowScale") or 1
    local opacity = settings and settings:Get("arrowOpacity") or 1
    if self.frame.SetScale then self.frame:SetScale(scale) end
    if self.arrow.SetAlpha then self.arrow:SetAlpha(opacity) end
    if self.distanceText.SetAlpha then self.distanceText:SetAlpha(opacity) end
    if self.destinationText and self.destinationText.SetAlpha then
        self.destinationText:SetAlpha(opacity)
    end
    if settings and settings:Get("showArrow") == false then
        self.arrow:Hide()
        self.distanceText:Hide()
        if self.destinationText then self.destinationText:Hide() end
        return
    end
    if self.distanceText.Show then self.distanceText:Show() end
    if self.destinationText then
        self.destinationText:Show()
        local title=tostring(self.currentDestination or "Destination")
        self.destinationText:SetText(title:sub(1, 30))
    end
    if not self.target then
        self.arrow:Hide()
        self.distanceText:SetText("No waypoint")
        return
    end

    local ok, angle, distance, reason = pcall(waypointVector, self.target)
    if not ok or type(angle) ~= "number" or not self.arrow.SetRotation then
        self.arrow:Hide()
        self.distanceText:SetText(reason or "Navigation unavailable")
        return
    end
    local delta = self.lastAngle and ((angle - self.lastAngle + math.pi) % tau - math.pi)
    local smoothed = delta and (self.lastAngle + delta * 0.44) or angle
    self.lastAngle = smoothed
    if not pcall(self.arrow.SetRotation, self.arrow, smoothed) then
        self.arrow:Hide()
        self.distanceText:SetText("Arrow unavailable")
        return
    end
    self.arrow:Show()
    if self.arrow.SetVertexColor then self.arrow:SetVertexColor(1, 1, 1, 1) end
    if type(distance) == "number" then
        if distance < 9 then
            self.distanceText:SetText("ARRIVED")
        elseif distance >= 1000 then
            self.distanceText:SetText(string.format("%.1f kyd", distance / 1000))
        else
            self.distanceText:SetText(string.format("%d yd", math.floor(distance + 0.5)))
        end
    else
        self.distanceText:SetText("Follow arrow")
    end
end

-- Manual selection and pinning never advance guide progress.
function Navigator:SetOverride(index, persistent)
    local steps = ns.Modules.Guides:GetSteps()
    local step = steps[index]
    if not step then return false, "That objective is unavailable." end
    local ok, target = pcall(targetForStep, step)
    self.overrideIndex = index
    self.pinnedIndex = persistent and index or nil
    self:Refresh()
    if not ok or not target then
        -- No coordinates must not make an objective impossible to select.
        return true, "Objective selected. No verified waypoint; follow the quest instructions."
    end
    return true, persistent and "Destination pinned." or "Temporary destination selected."
end

function Navigator:ResetTarget()
    self.overrideIndex, self.pinnedIndex = nil, nil
    self:Refresh()
end

function Navigator:Show()
    self:MakeFrame()
    self.frame:Show()
    self:Refresh()
end

function Navigator:Hide()
    if self.frame then self.frame:Hide() end
end
