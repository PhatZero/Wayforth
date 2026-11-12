local _, ns = ...

-- WoWForever Fortune's Professions-tree subset of the Legacy planner.
-- Effects are preserved as source notes and must be verified against live game values.
ns.legacyProfessionPerks = {
    maxPoints = 16,
    presets = {
        gathering = { name = "Gathering starter (5)", ranks = { bh = 5 } },
        fortune = { name = "Fortune all-rounder (16)", ranks = { bh = 5, ba = 2, pb = 3, mc = 5, ds = 1 } },
    },
    perks = {
        { id = "bh", name = "Bountiful Harvest", maxRank = 5, need = 0,
            effect = "+20% Scarce materials per rank from Mining, Herbalism and Skinning.", category = "Gathering" },
        { id = "wo", name = "Working Overtime", maxRank = 5, need = 0,
            effect = "+4% tradeskill skill-up chance per rank.", category = "Profession leveling" },
        { id = "ba", name = "Bartering", maxRank = 2, need = 5,
            effect = "Reduces vendor purchase prices by 5% per rank.", category = "Cost reduction" },
        { id = "pb", name = "Performance Bonus", maxRank = 3, need = 5, requires = { id = "bh", rank = 5 },
            effect = "+5% chance per rank of 100% additional Merchant's Favor from supply crate turn-ins.", category = "Crate rewards" },
        { id = "mc", name = "Master Chef", maxRank = 5, need = 10,
            effect = "+10% chance per rank of an extra cooked result.", category = "Cooking" },
        { id = "lu", name = "Luremaster", maxRank = 2, need = 10,
            effect = "+25% chance per rank to catch an extra fish with a lure.", category = "Fishing" },
        { id = "ds", name = "Dedicated Study", maxRank = 1, need = 10, requires = { id = "ba", rank = 2 },
            effect = "23-hour cooldown: +1 to your lowest tradeskill, or 2–4 random Elemental Essences when applicable tradeskills are at 300.", category = "Daily profession bonus" },
    },
}
