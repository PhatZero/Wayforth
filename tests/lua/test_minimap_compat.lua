-- Check native minimap button positioning and EllesmereUI handoff without a WoW client.
-- Run: lua5.1 tests/lua/test_minimap_compat.lua
local ns = { Modules = {} }
function ns:RegisterModule(name, module) self.Modules[name] = module end

local db = { minimapAngle = 220, showMinimap = true }
ns.Modules.Database = {
    Get = function(_, key) return db[key] end,
    Set = function(_, key, value) db[key] = value end,
}
ns.Modules.Theme = { logoTexture = "Interface\\AddOns\\WayForth\\Textures\\WayForthCompass.tga" }

local openCount, settingsCount = 0, 0
ns.Modules.UI = {
    Toggle = function() openCount = openCount + 1 end,
    Show = function() openCount = openCount + 1 end,
    ShowTab = function(_, name) if name == "Settings" then settingsCount = settingsCount + 1 end end,
}

local function texture()
    local t = {}
    for _, fn in ipairs({ "SetTexture", "SetSize", "SetPoint", "SetTexCoord" }) do
        t[fn] = function() end
    end
    return t
end

local function newFrame(name, parent)
    local f = { name = name, parent = parent, scripts = {}, width = 160, height = 160 }
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:SetParent(newParent) self.parent = newParent end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:GetCenter() return 500, 400 end
    function f:GetEffectiveScale() return 1 end
    function f:ClearAllPoints() self.point = nil end
    function f:SetPoint(...) self.point = { ... } end
    function f:SetFrameStrata() end
    function f:SetFrameLevel() end
    function f:SetHighlightTexture() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:RegisterForClicks() end
    function f:CreateTexture() return texture() end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:HookScript(name, fn) self.scripts[name] = fn end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    return f
end
Minimap = newFrame("Minimap", nil)
function CreateFrame(_, name, parent) return newFrame(name, parent) end
local eui = false
C_AddOns = { IsAddOnLoaded = function(name)
    return name == "EllesmereUIMinimap" and eui
end }
local shape = "ROUND"
function GetMinimapShape() return shape end
local mouseX, mouseY = 600, 400
function GetCursorPosition() return mouseX, mouseY end

local function near(a, b)
    return math.abs(a - b) < 0.001
end
local function offset(button)
    assert(button.point, "Button needs an anchor")
    return button.point[4], button.point[5]
end
local function length(x, y)
    return math.sqrt(x*x + y*y)
end

assert(loadfile("shared/ui/Minimap.lua"))("WayForth", ns)
local module = ns.Modules.Minimap
module:Initialize()
local button = module.button
assert(button:GetName() == "WayForthMinimapButton")
assert(button.icon, "Icon must be exposed for minimap button collectors")
assert(button:GetParent() == Minimap)
local x, y = offset(button)
assert(near(length(x, y), 90), "The 160px round minimap needs a 90px edge radius")

-- Native Edit Mode resize must update button placement.
Minimap:SetSize(240, 240)
Minimap.scripts.OnSizeChanged()
x, y = offset(button)
assert(near(length(x, y), 130), "Native radius must follow minimap size")

-- Square maps use the square's visible edge, not the circular orbit.
shape = "SQUARE"
module:Position()
x, y = offset(button)
assert(near(math.max(math.abs(x), math.abs(y)), 130),
    "Square minimap button must follow a square perimeter")
shape = "ROUND"

-- Native drag persists the angle, taking minimap effective scale into account.
button.scripts.OnDragStart(button)
button.scripts.OnUpdate(button)
button.scripts.OnDragStop(button)
assert(near(db.minimapAngle, 0), "Native drag must save the new angle")

-- Once EllesmereUI loads, keep the anchor supplied by its button row.
eui = true
button:ClearAllPoints()
button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 9, -11)
Minimap:SetSize(300, 300)
Minimap.scripts.OnSizeChanged()
module:Position()
assert(button.point[1] == "TOPLEFT" and button.point[4] == 9 and button.point[5] == -11,
    "WayForth must not overwrite EllesmereUI's row position")
button.scripts.OnDragStart(button)
assert(not button.isDragging, "EllesmereUI owns dragging while loaded")

-- A flyout may reparent WayForth away from the minimap entirely.
local flyout = newFrame("EllesmereFlyout", nil)
button:SetParent(flyout)
module:Position(true)
assert(button:GetParent() == flyout and button.point[1] == "TOPLEFT",
    "WayForth must not move an externally reparented button")

-- Restore native position if the optional module is no longer loaded.
eui = false
button:SetParent(Minimap)
module:Position()
x, y = offset(button)
assert(button.point[1] == "CENTER" and near(length(x, y), 160))
button.scripts.OnClick(button, "LeftButton")
button.scripts.OnClick(button, "RightButton")
assert(openCount == 2 and settingsCount == 1,
    "Both minimap button click actions must still work")

db.showMinimap = false
module:UpdateVisibility()
assert(button.shown == false)
db.showMinimap = true
module:UpdateVisibility()
assert(button.shown == true)

print("WayForth minimap and EllesmereUI compatibility tests passed")
