local _, ns = ...
local Compatibility = {}
ns:RegisterModule("Compatibility", Compatibility)

local function readBuild()
    if type(GetBuildInfo) ~= "function" then return "Unknown", "", "", 0 end
    local ok, version, build, date, interface = pcall(GetBuildInfo)
    if not ok then return "Unknown", "", "", 0 end
    return tostring(version or "Unknown"), tostring(build or ""), tostring(date or ""), tonumber(interface) or 0
end

function Compatibility:Detect()
    local version, build, date, interface = readBuild()
    local project = tonumber(WOW_PROJECT_ID) or 0
    local mainline = WOW_PROJECT_MAINLINE ~= nil and project == WOW_PROJECT_MAINLINE
    local forever = interface == ns.interfaceTarget and version:match("^1%.60") ~= nil
    -- Forever uses a modern engine despite its small interface number.
    -- Never treat the number alone as a Classic-era API detector.
    local modern = mainline or (type(C_QuestLog) == "table" and type(C_Map) == "table")
    local client = {
        version = version, build = build, date = date, interface = interface,
        project = project, mainline = mainline and true or false,
        forever = forever and true or false, modern = modern and true or false,
    }
    if forever then
        client.label = "WoW: Forever"
        client.supported = modern and true or false
    elseif interface == ns.interfaceTarget then
        client.label = "Forever-like (unverified build)"
        client.supported = false
    else
        client.label = "Other WoW client"
        client.supported = false
    end
    ns.client = client
    return client
end

function Compatibility:Report()
    local info = ns.client or self:Detect()
    if info.supported then return "Supported Forever client" end
    if info.forever then return "Forever API needs compatibility testing" end
    return "Untested client: features may not work"
end
