-- Alliance starter region quest seeds for the ORIGINAL WayForth addon.
-- IDs match public WoW Forever zone catalogs; live-client validation is still required.
-- This is a curated starter route, not an assertion of complete optional/class quest coverage.
local _, ns = ...
ns.starterGuides = ns.starterGuides or {}

local zones = {
  {
    id = "alliance-elwynn", title = "Alliance: Elwynn Forest", zone = "Elwynn Forest",
    low = 1, high = 12, description = "Northshire to Goldshire. Switch here from any Alliance race.",
    quests = {
      {783,"A Threat Within",1,"Northshire"},{7,"Kobold Camp Cleanup",2,"Northshire"},
      {33,"Wolves Across the Border",2,"Northshire"},{18,"Brotherhood of Thieves",3,"Northshire"},
      {92124,"Book Inventory",3,"Northshire"},{91752,"The Big Picture",3,"Northshire"},
      {15,"Investigate Echo Ridge",3,"Northshire"},{21,"Skirmish at Echo Ridge",4,"Northshire"},
      {54,"Report to Goldshire",5,"Northshire / Goldshire"},
      {62,"The Fargodeep Mine",5,"Goldshire"},{47,"Gold Dust Exchange",5,"Goldshire"},
      {60,"Kobold Candles",5,"Goldshire"},{85,"Lost Necklace",5,"Goldshire"},
      {86,"Pie for Billy",5,"Goldshire",85},{84,"Back to Billy",5,"Goldshire",86},
      {76,"The Jasperlode Mine",6,"Goldshire"},{52,"Protect the Frontier",8,"Eastvale"},
      {37,"Find the Lost Guards",8,"Eastvale"},{39,"Deliver Thomas' Report",8,"Eastvale"},
      {123,"The Collector",8,"Elwynn Forest"},{91733,"Downstream",8,"Elwynn Forest"},
      {91738,"An Apple Treat",8,"Elwynn Forest"},
      {239,"Westbrook Garrison Needs Help!",9,"Westbrook"},
      {176,'Wanted: "Hogger"',10,"Westbrook"}
    }
  },
  {
    id = "alliance-dun-morogh", title = "Alliance: Dun Morogh", zone = "Dun Morogh",
    low = 1, high = 12, description = "Coldridge Valley, Kharanos and the dwarven foothills.",
    quests = {
      {179,"Dwarven Outfitters",1,"Coldridge Valley"},
      {233,"Coldridge Valley Mail Delivery (1/2)",2,"Coldridge Valley"},
      {170,"A New Threat",3,"Coldridge Valley"},{183,"The Boar Hunter",3,"Coldridge Valley"},
      {3361,"A Refugee's Quandary",3,"Coldridge Valley"},
      {234,"Coldridge Valley Mail Delivery (2/2)",3,"Coldridge Valley",233},
      {182,"The Troll Cave",4,"Coldridge Valley"},{218,"The Stolen Journal",5,"Coldridge Valley"},
      {282,"Senir's Observations (1/2)",5,"Coldridge Valley"},
      {420,"Senir's Observations (2/2)",5,"Coldridge Valley",282},
      {318,"Evershine",5,"Kharanos"},{98322,"Secure the Mountain (1/3)",6,"Dun Morogh"},
      {310,"Bitter Rivals",6,"Kharanos"},{98319,"Secure the Mountain (2/3)",7,"Dun Morogh",98322},
      {98323,"Secure the Mountain (3/3)",7,"Dun Morogh",98319},
      {99158,"Dawn in the Mountains",6,"Dun Morogh"},
      {99159,"Finding Warmth",7,"Dun Morogh",99158},
      {98326,"Frosthowl",7,"Dun Morogh"},{287,"Frostmane Hold",8,"Dun Morogh"},
      {412,"Operation Recombobulation",9,"Dun Morogh"},
      {419,"The Lost Pilot",10,"Dun Morogh"}
    }
  },
  {
    id = "alliance-teldrassil", title = "Alliance: Teldrassil", zone = "Teldrassil",
    low = 1, high = 12, description = "Shadowglen, Dolanaar, and the road to Darnassus.",
    quests = {
      {458,"The Woodland Protector (1/2)",1,"Shadowglen"},
      {456,"The Balance of Nature (1/2)",2,"Shadowglen"},
      {459,"The Woodland Protector (2/2)",3,"Shadowglen",458},
      {457,"The Balance of Nature (2/2)",3,"Shadowglen",456},
      {916,"Webwood Venom",4,"Shadowglen"},
      {920,"Tenaron's Summons",4,"Shadowglen"},
      {921,"Crown of the Earth (1/6)",4,"Shadowglen",920},
      {928,"Crown of the Earth (2/6)",5,"Shadowglen",921},
      {929,"Crown of the Earth (3/6)",6,"Teldrassil",928},
      {933,"Crown of the Earth (4/6)",7,"Teldrassil",929},
      {7383,"Crown of the Earth (5/6)",8,"Teldrassil",933},
      {935,"Crown of the Earth (6/6)",9,"Teldrassil",7383},
      {3519,"A Friend in Need",3,"Shadowglen"},
      {3521,"Iverron's Antidote (1/2)",3,"Shadowglen",3519},
      {3522,"Iverron's Antidote (2/2)",4,"Shadowglen",3521},
      {2159,"Dolanaar Delivery",5,"Dolanaar"},
      {475,"A Troubling Breeze",6,"Dolanaar"},{997,"Denalan's Earth",6,"Dolanaar"},
      {2438,"The Emerald Dreamcatcher",7,"Teldrassil"},
      {476,"Gnarlpine Corruption",7,"Teldrassil",475},
      {483,"The Relics of Wakening",7,"Teldrassil",476},
      {932,"Twisted Hatred",8,"Teldrassil"},
      {487,"The Road to Darnassus",9,"Teldrassil"}
    }
  }
}
for _, zone in ipairs(zones) do
    local guide = {
        id = zone.id, title = zone.title, faction = "Alliance",
        description = zone.description, zone = zone.zone,
        levelMin = zone.low, levelMax = zone.high, steps = {},
    }
    for _, entry in ipairs(zone.quests) do
        local id, title, level, hub, requires = entry[1], entry[2], entry[3], entry[4], entry[5]
        guide.steps[#guide.steps + 1] = {
            id = "quest-" .. tostring(id), questId = id, title = title,
            text = "Complete and turn in " .. title .. ". Check the quest log for live objectives; WayForth will sync the quest ID after turn-in.",
            level = level, hub = hub, action = "turnin",
            requires = requires and { requires } or nil,
            sourceStatus = "public-catalog-match",
        }
    end
    ns.starterGuides[#ns.starterGuides + 1] = guide
end
