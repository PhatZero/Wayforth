-- Offline Zephras Isle quest-location catalog (Forever UI map 2521).
-- Locations are map percentages. "objective" is an approximate encounter/area center
-- where only spawn data exists; never treat it as a precise enemy position.
-- Every location and its evidence are documented in addon/docs/ZEPHRAS_COORDINATES.md.
-- No network requests occur in the game client.
local _, ns = ...
ns.zephrasQuestLocations = {
    -- Initial Thendal Village and training.
    [92460] = { pickup = {42.8, 23.4}, turnin = {42.1, 23.5} }, -- Coming of Age
    [92461] = { pickup = {42.1, 23.5}, objective = {44.9, 26.3}, turnin = {42.1, 23.5} },
    [92462] = { pickup = {43.4, 24.8}, objective = {45.8, 27.2}, turnin = {43.4, 24.8} },
    [92463] = { pickup = {43.4, 24.8}, objective = {48.0, 29.0} }, -- Cirrusfly Queen
    [92470] = { pickup = {42.8, 23.7}, objective = {36.0, 26.0} }, -- Foul Matriarch
    [92473] = { pickup = {42.4, 25.2}, objective = {40.0, 28.0} }, -- Aggressive Encroachment
    [92474] = { pickup = {43.7, 24.1}, turnin = {42.1, 23.5} }, -- Falling With Style
    [94414] = { pickup = {43.8, 24.1} }, -- The Anchors of Zephras
    [92597] = { pickup = {43.3, 24.9}, objective = {46.0, 18.0}, turnin = {43.3, 24.8} },
    [92598] = { pickup = {42.6, 24.4}, objective = {48.0, 21.0} },

    -- Shen'dar and upper island.
    [93461] = { turnin = {45.6, 45.4} }, -- Alliance Welcome to Shen'dar
    [92514] = { turnin = {45.6, 45.4} }, -- Horde Welcome to Shen'dar
    [96101] = { pickup = {41.6, 44.8} }, -- The Great Outdoors
    [92596] = { pickup = {45.0, 46.4}, turnin = {45.0, 46.4} }, -- High Order
    [92595] = { pickup = {43.5, 44.8}, turnin = {43.5, 44.8} }, -- Windshapers
    [92517] = { pickup = {45.7, 45.5}, objective = {51.0, 34.0} }, -- Criminal Element boss area
    [93036] = { pickup = {45.7, 45.5}, turnin = {44.9, 45.5} }, -- Infiltrating the Cult
    [93926] = { pickup = {45.7, 45.5}, turnin = {42.3, 62.0} }, -- Western Watch
    [92679] = { pickup = {62.1, 73.2}, turnin = {46.7, 82.0} }, -- Blood Tithe
    [93948] = { pickup = {45.7, 45.5}, turnin = {66.2, 76.5} }, -- Deliver the Signet

    -- Faction leaders and independent quest chains.
    [92699] = { pickup = {66.1, 76.7}, turnin = {66.6, 79.9} }, -- Alliance Supreme Magister
    [92700] = { pickup = {66.1, 76.7}, turnin = {59.1, 79.8} }, -- Horde Grand Skyseer
    [92727] = { pickup = {66.3, 79.8}, turnin = {53.3, 72.1} }, -- Missing Scholar part 1
    [92849] = { pickup = {53.3, 72.1}, objective = {50.0, 66.0}, turnin = {52.1, 69.4} },
    [92850] = {
        pickup = {52.1, 69.4}, entrance = {51.44, 68.99},
        objective = {51.9, 65.6}, turnin = {66.2, 79.9},
    }, -- Missing Scholar part 3
    [93735] = { pickup = {59.1, 79.8}, turnin = {59.1, 73.0} }, -- Broken Construct 1
    [93737] = { pickup = {59.1, 73.0} }, -- Broken Construct 2, multi-area search
    [93738] = { pickup = {59.1, 73.0}, turnin = {59.1, 79.8} }, -- Broken Construct 3
    [93746] = { pickup = {59.1, 79.8}, objective = {60.0, 57.0} }, -- A Firm Response

    -- Valanaar, eastern watchtower and the late campaign.
    [93320] = { pickup = {66.1, 76.7}, turnin = {69.7, 67.1} }, -- Tower Defense
    [92643] = { pickup = {66.2, 76.5}, turnin = {56.0, 58.8} }, -- Turncoat
    [92644] = { pickup = {56.0, 58.8}, turnin = {66.2, 76.5} }, -- Unfortunate News
    [94568] = { pickup = {66.2, 76.5}, turnin = {66.2, 76.5} }, -- Cult's True Plans
    [92947] = { pickup = {61.1, 70.9}, objective = {62.0, 50.0}, turnin = {63.8, 50.5} },
    [93958] = { pickup = {63.8, 50.5}, turnin = {65.2, 50.4} }, -- Inner Sanctum
    [93835] = { pickup = {65.2, 50.4}, objective = {74.9, 53.0}, turnin = {66.6, 79.9} }, -- Alliance Confront Lorthuna
    [92646] = { pickup = {65.2, 50.4}, objective = {74.9, 53.0}, turnin = {59.1, 79.8} }, -- Horde Confront Lorthuna
    [94369] = { pickup = {66.6, 79.9}, turnin = {66.2, 76.5} }, -- Alliance Fate of Zephras
    [93836] = { pickup = {59.1, 79.8}, turnin = {66.2, 76.5} }, -- Horde Fate of Zephras
    [93089] = { pickup = {66.2, 76.5}, turnin = {66.6, 79.9} }, -- Alliance What Comes Next
    [93090] = { pickup = {66.2, 76.5}, turnin = {59.1, 79.8} }, -- Horde What Comes Next
    [94946] = { pickup = {66.6, 79.9}, departure = {65.9, 83.5} }, -- Dalaran skyboat
    [95349] = { pickup = {59.1, 79.8}, departure = {57.9, 80.9} }, -- Thunder Bluff skyboat
}
ns.zephrasMapID = 2521
