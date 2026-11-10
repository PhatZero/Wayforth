local addonName, ns = ...

ns.name = addonName
ns.version = "1.0.0-beta"
ns.schemaVersion = 1
ns.interfaceTarget = 16001
ns.Modules = {}
ns.state = { loaded = false, loggedIn = false, errors = 0, initialized = {}, warning = nil }

function ns:RegisterModule(name, module)
    assert(type(name) == "string" and type(module) == "table", "Invalid module registration")
    self.Modules[name] = module
end

function ns:Call(module, method, ...)
    local target = self.Modules[module]
    if not target or type(target[method]) ~= "function" then return false end
    local ok, result = pcall(target[method], target, ...)
    if not ok then
        if self.Modules.Diagnostics then self.Modules.Diagnostics:Error(module .. "." .. method, result) end
        return false
    end
    return true, result
end

function ns:Print(message)
    local chat = DEFAULT_CHAT_FRAME
    if chat and chat.AddMessage then
        chat:AddMessage("|cff24c9e0Way|r|cffffcd73Forth|r: " .. tostring(message))
    end
end
