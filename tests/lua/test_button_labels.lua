-- Regresses WayForth's double/ghosted button captions on Forever 1.60.1.
-- Run with lua5.1; no WoW client or addon SavedVariables required.
local ns = { Modules = {} }
function ns:RegisterModule(name, module) self.Modules[name] = module end

local labelsCreated, nativeTextCalls, nativeFontCalls = 0, 0, 0

local function region()
    local obj = {}
    for _, method in ipairs({
        "SetAllPoints", "SetColorTexture", "SetPoint", "SetWidth", "SetHeight",
        "SetSize", "SetTextColor", "SetJustifyH", "SetJustifyV", "SetFont",
        "SetShadowOffset", "SetShadowColor", "SetText", "Show", "Hide",
    }) do
        obj[method] = function(self, ...)
            self[method .. "Args"] = { ... }
        end
    end
    return obj
end
function CreateFrame(kind)
    local frame = { kind = kind }
    function frame:SetSize(w,h) self.width,self.height=w,h end
    function frame:CreateTexture() return region() end
    function frame:CreateFontString()
        labelsCreated=labelsCreated+1
        return region()
    end
    function frame:SetFontString() nativeFontCalls=nativeFontCalls+1 end
    function frame:SetText() nativeTextCalls=nativeTextCalls+1 end
    function frame:SetHighlightTexture() end
    function frame:SetScript(_, fn) self.fn=fn end
    return frame
end

assert(loadfile("shared/ui/Theme.lua"))("WayForth",ns)
local theme=ns.Modules.Theme
local parent=CreateFrame("Frame")
local button=theme:Button(parent,175,38,"Continue Guide",nil,"primary")
assert(labelsCreated==1, "A primary button must create only one label")
assert(nativeFontCalls==0 and nativeTextCalls==0,
    "Custom buttons must not use a second native text renderer")
assert(button.label.SetTextArgs[1]=="Continue Guide", "Primary caption missing")
assert(button.label.SetShadowOffsetArgs[1]==0 and button.label.SetShadowOffsetArgs[2]==0,
    "Button caption must not inherit a visible shadow")
assert(button.label.SetShadowColorArgs[4]==0,
    "Button caption shadow alpha must be zero")
button:SetLabel("Continue Guide")
assert(labelsCreated==1 and nativeTextCalls==0,
    "Updating a button must not create duplicate text")
local nextButton=theme:Button(parent,97,34,"Next Step",nil,"primary")
assert(nextButton.label.SetTextArgs[1]=="Next Step")
assert(labelsCreated==2 and nativeTextCalls==0 and nativeFontCalls==0)
nextButton:SetLabel("Next Step")
assert(labelsCreated==2 and nativeTextCalls==0 and nativeFontCalls==0,
    "Reused button still has a single rendered label")
print("WayForth primary button single-label tests passed")
