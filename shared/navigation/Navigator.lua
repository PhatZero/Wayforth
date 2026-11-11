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
    if live and type(C_Map) == "table" and type(C_Map.GetPlayerMapPosition) == "function" then
        local ok, position = pcall(C_Map.GetPlayerMapPosition, live.mapId, "player")
        if not ok or not position then live = nil end
    end
    return live or authored
end

local function waypointVector(target)
    if not (C_Map and type(C_Map.GetPlayerMapPosition) == "function") then return nil end
    local pos = C_Map.GetPlayerMapPosition(target.mapId, "player")
    local px, py = getXY(pos)
    if not validCoord(px, py) then return nil end
    local dx, dy = target.x - px, target.y - py

    -- Map north is negative Y. GetPlayerFacing() is zero at north and increases
    -- counterclockwise, so a destination to the right has bearing -pi/2.
    local bearing = atan2(-dx, -dy)
    local distance
    -- Distance is optional. A failing or protected world-space API must not
    -- suppress the valid directional arrow.
    local okDistance, measured = pcall(function()
        if type(C_Map.GetWorldPosFromMapPos) == "function" and type(CreateVector2D) == "function" then
            local fromContinent, fromWorld = C_Map.GetWorldPosFromMapPos(target.mapId, CreateVector2D(px, py))
            local toContinent, toWorld = C_Map.GetWorldPosFromMapPos(target.mapId, CreateVector2D(target.x, target.y))
            if fromContinent and fromContinent == toContinent and fromWorld and toWorld then
                local ax, ay = getXY(fromWorld)
                local bx, by = getXY(toWorld)
                if ax and ay and bx and by then
                    return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
                end
            end
        end
        if type(C_Map.GetMapWorldSize) == "function" then
            local w, h = C_Map.GetMapWorldSize(target.mapId)
            if type(w) == "number" and type(h) == "number" then
                return math.sqrt((dx * w) ^ 2 + (dy * h) ^ 2)
            end
        end
    end)
    if okDistance then distance = measured end
    local facing = type(GetPlayerFacing) == "function" and GetPlayerFacing() or nil
    if type(facing) ~= "number" then return nil, distance end
    local relative = (bearing - facing + math.pi) % tau - math.pi
    return relative, distance
end

function Navigator:MakeFrame()
    if self.frame then return end
    local window = CreateFrame("Frame", "WayForthNavigator", UIParent)
    -- Only the arrow itself is visible: the frame is an invisible drag target.
    -- No panel, header, borders or destination box over the game world.
    window:SetSize(88, 92)
    window:SetFrameStrata("HIGH")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetPoint("TOP", UIParent, "TOP", ns.Modules.Database:Get("navX") or 0, ns.Modules.Database:Get("navY") or -110)

    local arrow = window:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrow:SetSize(63, 63)
    arrow:SetPoint("TOP", window, "TOP", 0, -4)
    self.arrow = arrow
    local glow = window:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\\\Minimap\\\\MinimapArrow")
    glow:SetSize(77, 77)
    glow:SetPoint("CENTER", arrow, "CENTER")
    glow:SetVertexColor(0.96, 0.65, 0.18, 0.35)
    self.glow = glow
    window:SetScale(ns.Modules.Database:Get("arrowScale") or 1)

    -- Small distance only, below the frameless arrow.
    local distanceText = theme:Text(window, "", 12, theme.ivory, "CENTER")
    distanceText:SetPoint("TOP", arrow, "BOTTOM", 0, -1)
    distanceText:SetWidth(88)
    self.distanceText = distanceText

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
        if Navigator.elapsed < 0.25 then return end
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
    self.target = ok and target or nil
    self:UpdateDirection()
end

function Navigator:UpdateDirection()
    if not self.frame or not self.frame:IsShown() then return end
    local settings = ns.Modules.Database
    local scale = settings and settings:Get("arrowScale") or 1
    local opacity = settings and settings:Get("arrowOpacity") or 1
    if self.frame.SetScale then self.frame:SetScale(scale) end
    if self.arrow.SetAlpha then self.arrow:SetAlpha(opacity) end
    if self.glow and self.glow.SetAlpha then self.glow:SetAlpha(opacity * 0.5) end
    if self.distanceText.SetAlpha then self.distanceText:SetAlpha(opacity) end
    if settings and settings:Get("showArrow") == false then
        self.arrow:Hide()
        if self.glow then self.glow:Hide() end
        self.distanceText:Hide()
        return
    end
    if self.distanceText.Show then self.distanceText:Show() end
    if not self.target then
        self.arrow:Hide()
        if self.glow then self.glow:Hide() end
        self.distanceText:SetText("No waypoint")
        return
    end
    local ok, angle, distance = pcall(waypointVector, self.target)
    if not ok or type(angle) ~= "number" or not self.arrow.SetRotation then
        self.arrow:Hide()
        if self.glow then self.glow:Hide() end
        self.distanceText:SetText("Position unavailable")
        return
    end
    local rotated = pcall(self.arrow.SetRotation, self.arrow, angle)
    if not rotated then
        self.arrow:Hide()
        if self.glow then self.glow:Hide() end
        self.distanceText:SetText("Arrow unavailable")
        return
    end
    self.arrow:Show()
    self.arrow:SetVertexColor(1, 0.75, 0.24)
    if self.glow then
        self.glow:Show()
        if self.glow.SetRotation then pcall(self.glow.SetRotation, self.glow, angle) end
    end
    if type(distance) == "number" then
        self.distanceText:SetText(string.format("%d yd", math.floor(distance + 0.5)))
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
