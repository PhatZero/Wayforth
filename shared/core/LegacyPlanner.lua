local _, ns = ...
local Planner = {}
ns:RegisterModule("LegacyPlanner", Planner)

local function perks()
    return ns.legacyProfessionPerks or { maxPoints = 16, perks = {}, presets = {} }
end

local function state()
    if not ns.char then return nil end
    ns.char.legacyBuild = type(ns.char.legacyBuild) == "table" and ns.char.legacyBuild or {}
    ns.char.legacyBuild.professions = type(ns.char.legacyBuild.professions) == "table"
        and ns.char.legacyBuild.professions or {}
    local ranks = ns.char.legacyBuild.professions
    for _, perk in ipairs(perks().perks) do
        local rank = tonumber(ranks[perk.id]) or 0
        ranks[perk.id] = math.max(0, math.min(perk.maxRank, math.floor(rank)))
    end
    return ranks
end

function Planner:Read()
    local ranks = state() or {}
    local total = 0
    for _, perk in ipairs(perks().perks) do total = total + (ranks[perk.id] or 0) end
    return ranks, total, perks().maxPoints
end

function Planner:CanSet(id, rank, source)
    local def
    for _, perk in ipairs(perks().perks) do if perk.id == id then def = perk; break end end
    if not def then return false, "Unknown Legacy perk." end
    rank = tonumber(rank)
    if not rank or rank ~= math.floor(rank) or rank < 0 or rank > def.maxRank then
        return false, "That rank is outside this perk's rank limit."
    end
    local ranks = source or state() or {}
    local total = 0
    for _, perk in ipairs(perks().perks) do total = total + (ranks[perk.id] or 0) end
    local current = ranks[id] or 0
    local nextTotal = total - current + rank
    if nextTotal > perks().maxPoints then return false, "The Professions tree is limited to 16 points." end
    if rank > current then
        if total - current < def.need then
            return false, "Spend " .. def.need .. " points elsewhere in the Professions tree first."
        end
        if def.requires and (ranks[def.requires.id] or 0) < def.requires.rank then
            local required
            for _, perk in ipairs(perks().perks) do if perk.id == def.requires.id then required = perk.name end end
            return false, "Requires " .. tostring(required or def.requires.id) .. " " .. def.requires.rank .. "/" .. def.requires.rank .. "."
        end
    end
    local candidate = {}
    for key, value in pairs(ranks) do candidate[key] = value end
    candidate[id] = rank
    for _, perk in ipairs(perks().perks) do
        if (candidate[perk.id] or 0) > 0 then
            local spentElsewhere = nextTotal - candidate[perk.id]
            if spentElsewhere < perk.need then return false, perk.name .. " would be locked by this change." end
            if perk.requires and (candidate[perk.requires.id] or 0) < perk.requires.rank then
                return false, perk.name .. " would lose its prerequisite." end
        end
    end
    return true
end

function Planner:SetRank(id, rank)
    local ranks = state()
    if not ranks then return false, "Character data is not ready." end
    local valid, message = self:CanSet(id, rank, ranks)
    if not valid then return false, message end
    ranks[id] = rank
    return true
end

function Planner:ApplyPreset(id)
    local preset = perks().presets[id]
    if not preset then return false, "Unknown Legacy preset." end
    local candidate = {}
    for _, perk in ipairs(perks().perks) do candidate[perk.id] = 0 end
    for perkId, rank in pairs(preset.ranks) do candidate[perkId] = rank end
    for _, perk in ipairs(perks().perks) do
        local valid, message = self:CanSet(perk.id, candidate[perk.id] or 0, candidate)
        if not valid then return false, message end
    end
    local ranks = state()
    if not ranks then return false, "Character data is not ready." end
    for _, perk in ipairs(perks().perks) do ranks[perk.id] = candidate[perk.id] or 0 end
    return true
end

function Planner:Reset()
    local ranks = state()
    if not ranks then return false end
    for _, perk in ipairs(perks().perks) do ranks[perk.id] = 0 end
    return true
end

function Planner:Perks()
    return perks().perks
end
