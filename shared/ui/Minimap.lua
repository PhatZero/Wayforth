local _, ns = ...
local MinimapButton = {}
ns:RegisterModule("Minimap", MinimapButton)

local pi, cos, sin = math.pi, math.cos, math.sin

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and pi or -pi) end
    return y >= 0 and pi / 2 or -pi / 2
end

function MinimapButton:Position()
    if not self.button or not Minimap then return end
    local angle = math.rad(ns.Modules.Database:Get("minimapAngle") or 220)
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", 81 * cos(angle), 81 * sin(angle))
end

function MinimapButton:UpdateVisibility()
    if not self.button then return end
    local visible = ns.Modules.Database:Get("showMinimap") ~= false
    if visible then self.button:Show() else self.button:Hide() end
end

function MinimapButton:Initialize()
    if self.button or not Minimap then return end
    local button = CreateFrame("Button", "WayForthMinimapButton", Minimap)
    button:SetSize(33, 33)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    self.button = button

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.Modules.Theme.logoTexture)
    icon:SetSize(32, 32)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)
    -- The approved compass already contains its own circular gold rim.
    -- Do not overlay Blizzard's large tracking border or crop its needles.

    button:SetScript("OnClick", function(_, which)
        if which == "RightButton" then
            ns.Modules.UI:Show()
            ns.Modules.UI:ShowTab("Settings")
        else
            ns.Modules.UI:Toggle()
        end
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnEnter", function(frame)
        if not GameTooltip then return end
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
        GameTooltip:AddLine("WayForth", 0.98, 0.78, 0.39)
        GameTooltip:AddLine("Left click: Open addon", 1, 1, 1)
        GameTooltip:AddLine("Right click: Settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: Reposition", 0.2, 0.85, 0.95)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnDragStart", function(frame) frame.isDragging = true end)
    button:SetScript("OnDragStop", function(frame) frame.isDragging = false end)
    button:SetScript("OnUpdate", function(frame)
        if not frame.isDragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        if not mx or not my or not cx or not cy or not scale or scale == 0 then return end
        local degrees = math.deg(atan2(cy / scale - my, cx / scale - mx))
        degrees = (degrees + 360) % 360
        ns.Modules.Database:Set("minimapAngle", degrees)
        MinimapButton:Position()
    end)
    self:Position()
    self:UpdateVisibility()

    if AddonCompartmentFrame and type(AddonCompartmentFrame.RegisterAddon) == "function" then
        local ok = pcall(AddonCompartmentFrame.RegisterAddon, AddonCompartmentFrame, {
            text = "WayForth",
            icon = ns.Modules.Theme.logoTexture,
            notCheckable = true,
            func = function() ns.Modules.UI:Toggle() end,
            funcOnEnter = function(menuItem)
                if not GameTooltip then return end
                GameTooltip:SetOwner(menuItem, "ANCHOR_RIGHT")
                GameTooltip:AddLine("WayForth - open addon")
                GameTooltip:Show()
            end,
            funcOnLeave = function() if GameTooltip then GameTooltip:Hide() end end,
        })
        if not ok then ns.Modules.Diagnostics:Warn("Minimap", "Addon Compartment registration unavailable") end
    end
end
