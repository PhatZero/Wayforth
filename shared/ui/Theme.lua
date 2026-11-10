local _, ns = ...
local Theme = {
    navy = { 0.028, 0.056, 0.091, 0.97 },
    panel = { 0.054, 0.096, 0.144, 0.98 },
    panelLight = { 0.085, 0.145, 0.195, 0.97 },
    elevated = { 0.103, 0.176, 0.227, 0.98 },
    gold = { 0.84, 0.66, 0.35, 1 },
    teal = { 0.22, 0.79, 0.85, 1 },
    ivory = { 0.93, 0.94, 0.93, 1 },
    muted = { 0.68, 0.76, 0.83, 1 },
    green = { 0.31, 0.74, 0.57, 1 },
    border = { 0.24, 0.31, 0.36, 0.8 },
    logoTexture = "Interface\\AddOns\\WayForth\\Textures\\WayForthCompass.tga",
    artAtlas = "Interface\\AddOns\\WayForth\\Textures\\WayForthArtAtlas.tga",
}
ns:RegisterModule("Theme", Theme)

function Theme:Text(parent, text, size, color, anchor)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if label.SetFont then
        label:SetFont("Fonts\\FRIZQT__.TTF", size or 13, "")
    end
    label:SetTextColor(unpack(color or self.ivory))
    label:SetJustifyH(anchor or "LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text or "")
    return label
end

local function line(parent, thickness, color, point1, point2, vertical)
    local texture = parent:CreateTexture(nil, "BORDER")
    texture:SetColorTexture(unpack(color))
    texture:SetPoint(point1, parent, point1)
    texture:SetPoint(point2, parent, point2)
    if vertical then texture:SetWidth(thickness) else texture:SetHeight(thickness) end
    return texture
end

function Theme:Panel(parent, color, borderColor)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(parent)
    bg:SetColorTexture(unpack(color or self.panel))
    local stroke = borderColor or self.border
    line(parent, 1, stroke, "TOPLEFT", "TOPRIGHT", false)
    line(parent, 1, stroke, "BOTTOMLEFT", "BOTTOMRIGHT", false)
    line(parent, 1, stroke, "TOPLEFT", "BOTTOMLEFT", true)
    line(parent, 1, stroke, "TOPRIGHT", "BOTTOMRIGHT", true)
    return bg
end

function Theme:Button(parent, width, height, text, callback, variant)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 100, height or 30)
    local tone = variant == "primary" and { 0.74, 0.51, 0.16, 1 }
        or variant == "quiet" and { 0.065, 0.117, 0.163, 0.95 }
        or { 0.12, 0.20, 0.26, 0.98 }
    local surface = self:Panel(button, tone, variant == "primary" and self.gold or self.border)
    button.surface = surface
    if variant == "primary" then
        local sheen = button:CreateTexture(nil, "ARTWORK")
        sheen:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        sheen:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        sheen:SetHeight(3)
        sheen:SetColorTexture(1, 0.91, 0.59, 0.46)
    end
    -- IMPORTANT: Draw exactly one label. GameFontNormal inherits its own
    -- shadow, and passing an already-rendered FontString to Button:SetFontString
    -- made the primary captions appear doubled/ghosted on Forever 1.60.1.
    -- Do not use Button:SetText or Button:SetFontString for these custom buttons.
    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", variant == "primary" and 12 or 11, "")
    label:SetTextColor(unpack(variant == "primary" and self.navy or self.ivory))
    label:SetShadowOffset(0, 0)
    label:SetShadowColor(0, 0, 0, 0)
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetSize(math.max(20, (width or 100) - 12), math.max(16, (height or 30) - 6))
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetText(text or "")
    button.label = label
    function button:SetLabel(value)
        self.label:SetText(value or "")
    end
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(0.25, 0.64, 0.68, 0.16)
    button:SetHighlightTexture(highlight)
    local press = button:CreateTexture(nil, "ARTWORK")
    press:SetAllPoints(button)
    press:SetColorTexture(0, 0, 0, 0.16)
    press:Hide()
    button:SetScript("OnMouseDown", function() press:Show() end)
    button:SetScript("OnMouseUp", function() press:Hide() end)
    button:SetScript("OnHide", function() press:Hide() end)
    button:SetScript("OnClick", function()
        local ok, err = pcall(callback or function() end)
        if not ok and ns.Modules.Diagnostics then ns.Modules.Diagnostics:Error("UI button", err) end
    end)
    return button
end

-- Official WayForth icon sourced from the user-approved gold/cyan compass.
-- This single transparent asset drives the dashboard, tracker and minimap.
-- Keep its aspect ratio and do not rotate or tint it.
function Theme:Compass(parent, size)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size or 40, size or 40)
    local image = icon:CreateTexture(nil, "ARTWORK")
    image:SetTexture(self.logoTexture)
    image:SetAllPoints(icon)
    if image.SetTexCoord then image:SetTexCoord(0, 1, 0, 1) end
    icon.image = image
    return icon
end

-- Five generated guide illustrations are in cells 1-5 of one bundled
-- 512x128 texture. The small settings gear occupies x=480..512, y=0..32.
function Theme:ArtCoords(index)
    if index == 6 then return 480/512, 1, 0, 32/128 end
    if type(index) ~= "number" or index < 1 or index > 5 then index = 2 end
    local left = (index-1)*96
    return left/512, (left+96)/512, 16/128, 112/128
end

function Theme:Gear(parent, size)
    local gear = parent:CreateTexture(nil, "ARTWORK")
    gear:SetTexture(self.artAtlas)
    gear:SetTexCoord(self:ArtCoords(6))
    gear:SetSize(size or 20,size or 20)
    return gear
end

function Theme:LabelButton(parent, width, height, glyph, callback)
    local button = self:Button(parent, width, height, glyph, callback, "quiet")
    return button
end
