-- Forever surname regression tests. Compatible with plain Lua 5.1.
local ns = { Modules = {}, client = { forever = true }, char = { snapshot = {} } }
function ns:RegisterModule(name, module) self.Modules[name] = module end
GetRealmName = function() return "Classic Beta PvE" end
GetNormalizedRealmName = function() return "ClassicBetaPvE" end
UnitName = function() return "Phat", "Birdsong" end
UnitFullName = function() return "Phat", "Birdsong" end
UnitClass = function() return "Mage" end
UnitRace = function() return "Skyborne" end
UnitLevel = function() return 10 end
UnitXP = function() return 500 end
UnitXPMax = function() return 1000 end
GetMoney = function() return 10000 end
GetZoneText = function() return "Zephras Isle" end
time = function() return 100 end

assert(loadfile("shared/core/Character.lua"))("WayForth", ns)
local char = ns.Modules.Character
local function expect(given, surname, display)
    local a, b, c = char:ReadNames()
    assert(a == given, "Wrong first name: " .. tostring(a))
    assert(b == surname, "Wrong surname: " .. tostring(b))
    assert(c == display, "Wrong display name: " .. tostring(c))
end

-- Modern Forever builds: second return is surname, not realm.
expect("Phat", "Birdsong", "Phat Birdsong")
char:Capture()
assert(ns.char.snapshot.name == "Phat", "Preserve legacy name key")
assert(ns.char.snapshot.firstName == "Phat")
assert(ns.char.snapshot.lastName == "Birdsong")
assert(ns.char.snapshot.displayName == "Phat Birdsong")
assert(char:Summary():find("Phat Birdsong", 1, true), "Summary should show full name")

-- Old Forever builds already returned both names inside the first value.
UnitName = function() return "Rambleon Birdsong" end
UnitFullName = function() return "Rambleon Birdsong", "ClassicBetaPvE" end
expect("Rambleon", "Birdsong", "Rambleon Birdsong")

-- The second value from ordinary WoW is a realm, not a surname.
UnitName = function() return "Rambleon", "Classic Beta PvE" end
UnitFullName = function() return "Rambleon", "ClassicBetaPvE" end
expect("Rambleon", nil, "Rambleon")

-- Fallback when UnitFullName reports a realm but UnitName carries surname.
UnitName = function() return "Rambleon", "Stonefist" end
UnitFullName = function() return "Rambleon", "ClassicBetaPvE" end
expect("Rambleon", "Stonefist", "Rambleon Stonefist")

-- Never reinterpret a realm as a surname outside the Forever client.
ns.client.forever = false
expect("Rambleon", nil, "Rambleon")

-- Unknown surname: safely use first name and do not fabricate data.
ns.client.forever = true
UnitName = function() return "Phat", nil end
UnitFullName = function() return "Phat", nil end
expect("Phat", nil, "Phat")
print("WayForth Forever surname tests passed")
