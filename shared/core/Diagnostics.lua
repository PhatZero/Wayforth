local _, ns = ...
local Diagnostics = { entries = {}, maxEntries = 20 }
ns:RegisterModule("Diagnostics", Diagnostics)

local function add(self, level, source, message)
    local timeText = type(date) == "function" and date("%H:%M:%S") or "--:--:--"
    table.insert(self.entries, 1, {
        time = timeText,
        level = level,
        source = tostring(source),
        message = tostring(message):sub(1, 220),
    })
    if #self.entries > self.maxEntries then table.remove(self.entries) end
end

function Diagnostics:Info(source, message)
    add(self, "INFO", source, message)
end

function Diagnostics:Warn(source, message)
    ns.state.warning = tostring(message)
    add(self, "WARN", source, message)
end

function Diagnostics:Error(source, message)
    ns.state.errors = ns.state.errors + 1
    ns.state.warning = tostring(source) .. ": " .. tostring(message)
    add(self, "ERROR", source, message)
end

function Diagnostics:Summary()
    local client = ns.client or {}
    local health = ns:Call("Database", "Health")
    local databaseHealthy = health and ns.Modules.Database:Health() or false
    local lines = {
        "Addon version: " .. ns.version,
        "Target interface: " .. ns.interfaceTarget,
        "Client: " .. (client.label or "Unknown") .. " " .. (client.version or ""),
        "Client interface: " .. tostring(client.interface or "Unknown"),
        "Client build: " .. tostring(client.build or "Unknown"),
        "API: " .. (client.modern and "Modern detected" or "Modern API not verified"),
        "Compatibility: " .. ns.Modules.Compatibility:Report(),
        "SavedVariables: " .. (databaseHealthy and "Healthy" or "Unavailable"),
        "Lua errors caught: " .. tostring(ns.state.errors),
        "Loaded modules: " .. tostring(self:ModuleCount()),
    }
    if ns.state.warning then table.insert(lines, "Last warning: " .. ns.state.warning:sub(1, 85)) end
    return table.concat(lines, "\n")
end

function Diagnostics:ModuleCount()
    local count = 0
    for _ in pairs(ns.Modules) do count = count + 1 end
    return count
end

function Diagnostics:Recent()
    local lines = {}
    for i = 1, math.min(5, #self.entries) do
        local entry = self.entries[i]
        table.insert(lines, entry.time .. "  " .. entry.level .. "  " .. entry.source .. "  " .. entry.message)
    end
    return #lines > 0 and table.concat(lines, "\n") or "No diagnostic events yet."
end
