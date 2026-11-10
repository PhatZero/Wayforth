-- WayForth original editorial route based on publicly verifiable quest metadata.
-- Quest IDs and early coordinates were checked against the Forever 1.60.1 quest databases.
-- Later hub checkpoints without confirmed coordinates deliberately omit waypoints.
-- Map ID 2521 is the Zephras Isle UI map (not area/zone ID 16593).
-- Coordinates and faction quest IDs source-checked against public WoW Forever references.
-- See addon/README.md for attribution and offline source documentation.
-- This is a curated main-story route, not a claim to include every optional quest.
local _, ns = ...
local allSteps = {
    { id = "start-accept", title = "Begin: Coming of Age", text = "Talk to Ailee Farheart at Thendal Village and accept Coming of Age.", hub = "Thendal Grove", level = 1, questId = 92460, action = "accept", x = 42.8, y = 23.4 },
    { id = "start-report", title = "Report to Rorian", text = "Meet Rorian the Dayseeker near the greatfather tree and hand in Coming of Age.", hub = "Thendal Grove", level = 1, questId = 92460, action = "turnin", x = 42.1, y = 23.5 },
    { id = "harmony-accept", title = "Pick up Harmony in Balance", text = "Take Rorian's task before going into the grove. You'll deal with the juvenile vuldren on the way.", hub = "Thendal Grove", level = 1, questId = 92461, action = "accept", x = 42.1, y = 23.5 },
    { id = "flies-accept", title = "Add Infestation Investigation", text = "Find Elatrell Featherlight. Pick up the cirrusfly problem so you can finish both tasks on one loop.", hub = "Thendal Village", level = 1, questId = 92462, action = "accept", x = 43.4, y = 24.8 },
    { id = "harmony-clear", title = "Thin the vuldren", text = "Fight the juvenile vuldren east of the village. Complete Harmony in Balance while heading toward the cirrusflies.", hub = "Thendal Grove", level = 1, questId = 92461, action = "objective", x = 44.9, y = 26.3 },
    { id = "flies-clear", title = "Clear the cirrusflies", text = "Defeat the cirrusflies in the grove. Check Infestation Investigation in your quest log before returning.", hub = "Thendal Grove", level = 2, questId = 92462, action = "objective", x = 45.8, y = 27.2 },
    { id = "flies-return", title = "Return to Elatrell", text = "Go back to Elatrell Featherlight and hand in Infestation Investigation.", hub = "Thendal Village", level = 2, questId = 92462, action = "turnin", x = 43.4, y = 24.8 },
    { id = "harmony-return", title = "Return to Rorian", text = "Hand Harmony in Balance to Rorian and pick up any follow-up tasks in the village.", hub = "Thendal Village", level = 2, questId = 92461, action = "turnin", x = 42.1, y = 23.5 },
    { id = "class-mage", title = "Mage: first training", text = "Check with Dorii Brightwhisper for A Student of the Arcane. Follow the class instructions before leaving Thendal.", hub = "Thendal Grove", level = 2, questId = 92481, action = "manual", class = "MAGE", x = 41.6, y = 23.6 },
    { id = "class-hunter", title = "Hunter: first training", text = "Check with Tai'ree Farsight for The Way of the Hunter. More pet training follows later in Valanaar.", hub = "Thendal Grove", level = 2, questId = 92482, action = "manual", class = "HUNTER", x = 42.4, y = 23.6 },
    { id = "class-rogue", title = "Rogue: first training", text = "Look for Akeri Duskblade and At Home in the Shadows, the early rogue introduction.", hub = "Thendal Grove", level = 2, questId = 92483, action = "manual", class = "ROGUE", x = 43.6, y = 24.2 },
    { id = "class-shaman", title = "Shaman: first training", text = "Visit Windshaper Boro for Embracing the Elements. Watch for the later Call of Earth and Call of Fire chains.", hub = "Thendal Grove", level = 2, questId = 92484, action = "manual", class = "SHAMAN", x = 42.8, y = 23.6 },
    { id = "class-druid", title = "Druid: first training", text = "Visit Xyton Silverwind for A Student of Nature; your later spirit training continues from Valanaar.", hub = "Thendal Grove", level = 2, questId = 92485, action = "manual", class = "DRUID", x = 41.6, y = 23.4 },
    { id = "class-warrior", title = "Warrior: first training", text = "Find Blademaster Ren for The Warrior's Path before you push farther across the island.", hub = "Thendal Grove", level = 2, questId = 92532, action = "manual", class = "WARRIOR", x = 43.6, y = 24.2 },
    { id = "glide-accept", title = "Learn Falling With Style", text = "Pick up Falling With Style from Myriaal Mistwake and put Walk on Air on your action bar.", hub = "Thendal Village", level = 2, questId = 92474, action = "accept", x = 43.7, y = 24.1 },
    { id = "glide-complete", title = "Glide from the watchtower", text = "Climb the watchtower, jump, and activate Walk on Air during the fall. Return to Rorian to hand in.", hub = "Thendal Watchtower", level = 2, questId = 92474, action = "turnin", x = 42.1, y = 23.5 },
    { id = "anchors-accept", title = "Help stabilize the island", text = "Take The Anchors of Zephras from Halaan Hawk-Eye and inspect the pylon-related objectives shown in your log.", hub = "Thendal Village", level = 3, questId = 94414, action = "accept", x = 43.8, y = 24.1 },
    { id = "anchors-done", title = "Finish the anchor work", text = "Complete The Anchors of Zephras and turn it in. Check the quest log for any remaining scrying targets.", hub = "Thendal Standing Stones", level = 3, questId = 94414, action = "turnin", x = 43.8, y = 24.1 },
    { id = "racial-alliance", title = "High Order: read the leylines", text = "Complete Reading the Ley Lines in Thendal. Your faction racial is useful near a leyline when resting.", hub = "Thendal Grove", level = 3, questId = 92597, action = "turnin", faction = "Alliance" },
    { id = "racial-horde", title = "Windshapers: learn Skysight", text = "Follow The Gift of Skysight. Use your racial near an elemental convergence as the quest directs.", hub = "Thendal Grove", level = 3, questId = 92598, action = "turnin", faction = "Horde", x = 42.6, y = 24.4 },
    { id = "thendal-cleanup", title = "Thendal: optional task loop", text = "Pick up nearby optional quests before leaving for Shen'dar Village. Finish relevant objectives and return to their quest givers.", hub = "Thendal Grove", level = 4, action = "manual", x = 43.4, y = 24.8 },
    { id = "queen-accept", title = "Pick up The Cirrusfly Queen", text = "Return to Elatrell Featherlight to start the cirrusfly queen task.", hub = "Thendal Village", level = 4, questId = 92463, action = "accept" },
    { id = "queen-objective", title = "Defeat the Cirrusfly Queen", text = "Head into the infestation area and defeat the queen. Spawn point is an approximate hunting area.", hub = "Thendal Grove", level = 4, questId = 92463, action = "objective" },
    { id = "matriarch-objective", title = "Investigate the Foul Matriarch", text = "Work on the Foul Matriarch objective if you have the quest. The pin is a reported search location.", hub = "Thendal Grove", level = 4, questId = 92470, action = "objective" },
    { id = "encroachment-objective", title = "Clear Aggressive Encroachment", text = "Finish Aggressive Encroachment before continuing toward the village. Follow your quest log for individual targets.", hub = "Thendal Grove", level = 4, questId = 92473, action = "objective" },
    { id = "village-arrival", title = "Travel to Shen'dar Village", text = "Work south via Windsong Lake. Follow Welcome to Shen'dar Village and collect the next hub's available tasks.", hub = "Shen'dar Village", level = 5, questIds = { Alliance = 93461, Horde = 92514 }, action = "turnin", x = 45.6, y = 45.4 },
    { id = "camp-outdoors", title = "Learn camp basics", text = "Talk to Raan Wildwind for The Great Outdoors. Optional Camping 101 profession tasks can be picked up here too.", hub = "Shen'dar Village", level = 6, questId = 96101, action = "turnin", x = 41.6, y = 44.8 },
    { id = "class-mid-druid", title = "Druid: train at Shen'dar", text = "Find Naeluna Swiftmend for intermediate druid training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "DRUID", x = 45.2, y = 44.2 },
    { id = "class-mid-hunter", title = "Hunter: train at Shen'dar", text = "Find Elayaa Easewind for intermediate hunter training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "HUNTER", x = 45.2, y = 44.2 },
    { id = "class-mid-mage", title = "Mage: train at Shen'dar", text = "Find Shenaan Spellwind for intermediate mage training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "MAGE", x = 45.0, y = 45.8 },
    { id = "class-mid-rogue", title = "Rogue: train at Shen'dar", text = "Find Miriaan Mistblade for intermediate rogue training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "ROGUE", x = 43.2, y = 43.2 },
    { id = "class-mid-shaman", title = "Shaman: train at Shen'dar", text = "Find Aarnor Galestrike for intermediate shaman training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "SHAMAN", x = 43.6, y = 44.8 },
    { id = "class-mid-warrior", title = "Warrior: train at Shen'dar", text = "Find Corsan Earthrazer for intermediate warrior training while visiting Shen'dar Village.", hub = "Shen'dar Village", level = 6, action = "manual", class = "WARRIOR", x = 44.8, y = 45.2 },
    { id = "shendar-highorder", title = "Meet the High Order", text = "Follow The High Order and speak with the faction envoys. Check your quest log for the village trouble chain.", hub = "Shen'dar Village", level = 6, questId = 92596, action = "turnin", faction = "Alliance" },
    { id = "shendar-windshaper", title = "Meet the Windshapers", text = "Follow The Windshapers and speak with the faction envoys. Pick up the nearby village tasks before heading out.", hub = "Shen'dar Village", level = 6, questId = 92595, action = "turnin", faction = "Horde" },
    { id = "bandits-accept", title = "Pick up The Criminal Element", text = "Accept Constable Aonda's task before heading into the highlands.", hub = "Shen'dar Village", level = 6, questId = 92517, action = "accept" },
    { id = "bandits", title = "Deal with Shen'dar's bandits", text = "Find the bandit leader for The Criminal Element after accepting Constable Aonda's quest. The marker is an approximate encounter area.", hub = "Shen'dar Highlands", level = 6, questId = 92517, action = "objective" },
    { id = "cult-infiltration", title = "Complete Infiltrating the Cult", text = "After investigating Falaath, return to Sania Silverstream in Shen'dar Village to finish the quest.", hub = "Shen'dar Village", level = 7, questId = 93036, action = "turnin" },
    { id = "west-watch", title = "Check the western watch", text = "Complete The Western Watch while passing the West Pylon Watchtower. Gather the nearby turn-ins before moving east.", hub = "West Pylon Watchtower", level = 8, questId = 93926, action = "turnin" },
    { id = "orchard", title = "Visit Windfield Orchard", text = "Sweep the orchard tasks, including Blood Tithe if offered. Return to the road toward Valanaar once the local errands are done.", hub = "Windfield Orchard", level = 8, questId = 92679, action = "turnin" },
    { id = "valanaar", title = "Make Valanaar your base", text = "Enter Valanaar, collect the quest hub's tasks and find the local inn. Your faction branch begins here.", hub = "Valanaar", level = 9, action = "manual", coordsByFaction = { Alliance = {66.6, 79.9}, Horde = {59.1, 79.8} } },
    { id = "alliance-leader", title = "High Order: Supreme Magister", text = "Report for The Supreme Magister at the High Order side of Valanaar. Review your faction-specific follow-ups.", hub = "Valanaar", level = 9, questId = 92699, action = "turnin", faction = "Alliance" },
    { id = "horde-leader", title = "Windshapers: Grand Skyseer", text = "Report for The Grand Skyseer at the Windshaper side of Valanaar. Review your faction-specific follow-ups.", hub = "Valanaar", level = 9, questId = 92700, action = "turnin", faction = "Horde" },
    { id = "advanced-hunter", title = "Hunter: pet training", text = "Find Quel'ana Quickgale in Valanaar for Taming the Beast, then complete Training the Beast as your class quests unlock.", hub = "Valanaar", level = 10, action = "manual", class = "HUNTER", x = 59.6, y = 72.6 },
    { id = "advanced-druid", title = "Druid: spirit training", text = "Ask Lotheluum Starbreeze in Valanaar about The Great Ursera Spirit and follow the trail toward Urs'endris.", hub = "Valanaar", level = 10, action = "manual", class = "DRUID", x = 64.0, y = 75.0 },
    { id = "advanced-shaman", title = "Shaman: Call of Fire", text = "Follow Sessaria Skystride's Call of Fire chain when available, then seek Olariaan Swiftburn near the Shrine of Flames.", hub = "Valanaar", level = 10, action = "manual", class = "SHAMAN", x = 58.2, y = 78.6 },
    { id = "advanced-mage", title = "Mage: Valanaar training", text = "Find Anathamaas Aetherwind for advanced mage training when in Valanaar.", hub = "Valanaar", level = 10, action = "manual", class = "MAGE", x = 65.8, y = 80.4 },
    { id = "advanced-rogue", title = "Rogue: Valanaar training", text = "Find Eltheen Nightbreeze for advanced rogue training when in Valanaar.", hub = "Valanaar", level = 10, action = "manual", class = "ROGUE", x = 59.8, y = 72.6 },
    { id = "advanced-warrior", title = "Warrior: Valanaar training", text = "Find Seena Skybreaker for advanced warrior training when in Valanaar.", hub = "Valanaar", level = 10, action = "manual", class = "WARRIOR", x = 59.8, y = 72.8 },
    { id = "alliance-investigation", title = "Alliance: investigate the missing scholar", text = "Begin the three linked quests for The Missing Scholar, starting with Dondallion Whisperwind. These are separate quests with different NPCs and destinations.", hub = "Valanaar", level = 10, action = "manual", faction = "Alliance", x = 66.3, y = 79.8 },
    { id = "scholar-92727-accept", title = "The Missing Scholar: start the search", text = "Accept The Missing Scholar from Dondallion Whisperwind in Valanaar.", hub = "Valanaar", level = 10, questId = 92727, action = "accept", faction = "Alliance" },
    { id = "scholar-92727-turnin", title = "Find the bloodstained satchel", text = "Find the bloodstained satchel and complete the first Missing Scholar quest.", hub = "West of Valanaar", level = 10, questId = 92727, action = "turnin", faction = "Alliance" },
    { id = "scholar-92849-accept", title = "The Missing Scholar: search the trail", text = "Accept the next part of The Missing Scholar at the bloodstained satchel.", hub = "West of Valanaar", level = 10, questId = 92849, action = "accept", faction = "Alliance" },
    { id = "scholar-92849-objective", title = "Find and rescue Fillion", text = "Find Fillion in the shriekling den, carry him outside and place him on the bedroll. Follow the live quest marker for the rescue.", hub = "Shriekling Den", level = 10, questId = 92849, action = "objective", faction = "Alliance" },
    { id = "scholar-92849-turnin", title = "Find Fillion Flamebreeze", text = "Find Fillion Flamebreeze and complete the second Missing Scholar quest.", hub = "Shriekling Den", level = 10, questId = 92849, action = "turnin", faction = "Alliance" },
    { id = "scholar-92850-accept", title = "The Missing Scholar: final search", text = "Accept The Missing Scholar (92850) from Fillion Flamebreeze.", hub = "Shriekling Den", level = 10, questId = 92850, action = "accept", faction = "Alliance" },
    { id = "scholar-92850-entrance", title = "Enter the Shriekling Den", text = "Go to the cave entrance around 51.44, 68.99. The marker is the entrance, not the cliff above. Press Done once inside.", hub = "Shriekling Den", level = 10, questId = 92850, action = "manual", locationRole = "entrance", faction = "Alliance" },
    { id = "scholar-92850-objective", title = "Defeat the Shriekling Matriarch", text = "Follow the cave passages to the Shriekling Matriarch. The pin marks the documented encounter area; check your quest objectives.", hub = "Shriekling Den", level = 10, questId = 92850, action = "objective", faction = "Alliance" },
    { id = "scholar-92850-turnin", title = "Report The Missing Scholar", text = "Return to Fillion Flamebreeze in Valanaar and hand in quest 92850.", hub = "Valanaar", level = 10, questId = 92850, action = "turnin", faction = "Alliance" },
    { id = "horde-construct", title = "Windshapers: rebuild defenses", text = "Start The Broken Construct quests with Grand Skyseer Ayessa Dawnsinger.", hub = "Valanaar", level = 10, action = "manual", faction = "Horde", x = 59.1, y = 79.8 },
    { id = "construct-93735-accept", title = "The Broken Construct: first task", text = "Accept the first Broken Construct quest from Grand Skyseer Ayessa.", hub = "Valanaar", level = 10, questId = 93735, action = "accept", faction = "Horde" },
    { id = "construct-93735-turnin", title = "Visit Riaani Nightwind", text = "Report to Riaani Nightwind north of Valanaar.", hub = "Valanaar Highlands", level = 10, questId = 93735, action = "turnin", faction = "Horde" },
    { id = "construct-93737-accept", title = "The Broken Construct: gather parts", text = "Accept the parts collection task from Riaani. Use the game quest markers for each part.", hub = "Valanaar Highlands", level = 10, questId = 93737, action = "accept", faction = "Horde" },
    { id = "construct-93738-accept", title = "The Broken Construct: report back", text = "Follow Riaani's concluding instructions and accept the final report quest.", hub = "Valanaar Highlands", level = 10, questId = 93738, action = "accept", faction = "Horde" },
    { id = "construct-93738-turnin", title = "Return to Grand Skyseer Ayessa", text = "Return to Ayessa in Valanaar with the construct findings.", hub = "Valanaar", level = 10, questId = 93738, action = "turnin", faction = "Horde" },
    { id = "firm-response-93746-accept", title = "Prepare A Firm Response", text = "Take A Firm Response from Grand Skyseer Ayessa.", hub = "Valanaar", level = 10, questId = 93746, action = "accept", faction = "Horde" },
    { id = "firm-response-93746-objective", title = "A Firm Response: highlands target", text = "Travel toward the reported enemy area and complete A Firm Response. The pin is an approximate objective area.", hub = "Valanaar Highlands", level = 10, questId = 93746, action = "objective", faction = "Horde" },
    { id = "east-pylon", title = "Secure the eastern watchtower", text = "Complete Tower Defense and report to Yorana Windyreed at East Pylon Watchtower. Check your quest log for related tasks.", hub = "East Pylon Watchtower", level = 10, questId = 93320, action = "turnin" },
    { id = "turncoat", title = "Uncover the cult's plans", text = "Begin the Turncoat and Cult's True Plans chain by reaching the dead cultist. Follow the quest log before the final assault.", hub = "Valanaar Highlands", level = 11, questId = 92643, action = "turnin" },
    { id = "unfortunate-news-92644-accept", title = "Accept Unfortunate News", text = "Accept Unfortunate News at the dead cultist's location.", hub = "Valanaar Highlands", level = 11, questId = 92644, action = "accept" },
    { id = "unfortunate-news-92644-turnin", title = "Report Unfortunate News", text = "Return to Talaanis Shadowsong in Valanaar.", hub = "Valanaar", level = 11, questId = 92644, action = "turnin" },
    { id = "cult-94568-turnin", title = "Finish The Cult's True Plans", text = "Complete The Cult's True Plans and report to Talaanis Shadowsong.", hub = "Valanaar", level = 11, questId = 94568, action = "turnin" },
    { id = "shrine", title = "Push toward the Shrine of Akir", text = "Complete the combat goals in Making Our Move near the shrine. The marker is an approximate target area.", hub = "Shrine of Akir", level = 12, questId = 92947, action = "objective" },
    { id = "shrine-92947-turnin", title = "Making Our Move: report", text = "Report to Hyusaa Quickbreeze after completing the assault.", hub = "Shrine of Akir", level = 12, questId = 92947, action = "turnin" },
    { id = "shrine-93958-accept", title = "Begin The Inner Sanctum", text = "Pick up The Inner Sanctum from Hyusaa Quickbreeze.", hub = "Shrine of Akir", level = 12, questId = 93958, action = "accept" },
    { id = "shrine-93958-turnin", title = "Complete The Inner Sanctum", text = "Complete the objective and report to Valennia Stormfist.", hub = "Shrine of Akir", level = 12, questId = 93958, action = "turnin" },
    { id = "fate", title = "Resolve The Fate of Zephras", text = "Finish the main finale, The Fate of Zephras, and report to the quest's indicated NPC. This is the island's story climax.", hub = "Rohashi Spires", level = 12, questIds = { Alliance = 94369, Horde = 93836 }, action = "turnin" },
    { id = "next", title = "Plan what comes next", text = "Complete What Comes Next and return to your order's leader in Valanaar to prepare for departure.", hub = "Valanaar", level = 13, questIds = { Alliance = 93089, Horde = 93090 }, action = "turnin" },
    { id = "leave-alliance-accept", title = "Dalaran departure order", text = "Accept The Magical City of Dalaran from Elaadrin and head to the Alliance skycutter.", hub = "Valanaar", level = 13, questId = 94946, action = "accept", faction = "Alliance" },
    { id = "leave-alliance", title = "Alliance: depart for Dalaran", text = "Follow The Magical City of Dalaran to the skycutter at the Valanaar skydocks, then use the Skyborne route toward Stormwind.", hub = "Valanaar Skydocks", level = 13, action = "manual", faction = "Alliance", x = 65.9, y = 83.5 },
    { id = "leave-horde-accept", title = "Earthen Ring departure order", text = "Accept The Earthen Ring from Ayessa Dawnsinger and travel to the Horde skycutter.", hub = "Valanaar", level = 13, questId = 95349, action = "accept", faction = "Horde" },
    { id = "leave-horde", title = "Horde: depart for Mulgore", text = "Follow The Earthen Ring to the skycutter at Valanaar. After landing in Mulgore, continue your faction introduction toward Orgrimmar.", hub = "Valanaar Skydocks", level = 13, action = "manual", faction = "Horde", x = 57.9, y = 80.9 },
}

-- Source-backed prerequisite/pickup recovery for characters joining mid-route.
-- Factual quest relationships and NPC pins were cross-checked against Forever
-- quest catalogs; only the live client can confirm what a player can accept.
-- Insert before existing stable-ID steps so saved currentStepId bookmarks survive.
local additions = {
    ["alliance-leader"] = {
        { id="supreme-92699-accept", title="Pick up The Supreme Magister", text="Speak with Valennia Stormfist upstairs in Valanaar and accept The Supreme Magister.", hub="Valanaar", level=9, questId=92699, action="accept", faction="Alliance", x=66.2, y=76.7 },
        { id="skyseer-92700-accept", title="Pick up The Grand Skyseer", text="Speak with Valennia Stormfist upstairs in Valanaar and accept The Grand Skyseer.", hub="Valanaar", level=9, questId=92700, action="accept", faction="Horde", x=66.2, y=76.7 },
    },
    ["horde-construct"] = {
        { id="fillion-99260-accept", title="Pick up Fillion's Mission", text="Speak with Fillion Flamebreeze in Valanaar and accept Fillion's Mission.", hub="Valanaar", level=10, questId=99260, action="accept", faction="Alliance", requires={92850}, x=66.2, y=79.9 },
        { id="fillion-99260-turnin", title="Report Fillion's Mission", text="Hand Fillion's Mission to Elaadrin Evengale in Valanaar.", hub="Valanaar", level=10, questId=99260, action="turnin", faction="Alliance", x=66.6, y=79.9 },
        { id="wind-92840-accept", title="Pick up Catching Wind", text="Accept Catching Wind from Elaadrin Evengale in Valanaar after Fillion's Mission.", hub="Valanaar", level=10, questId=92840, action="accept", faction="Alliance", requires={99260}, x=66.6, y=80.0 },
        { id="wind-92840-objective", title="Catching Wind: collect readings", text="Use the Index Esoteria beside Windstone Formations at the Overlook Standing Stones. Follow live quest objectives.", hub="Windfield Orchard", level=10, questId=92840, action="objective", faction="Alliance", x=47.6, y=68.8 },
        { id="wind-92840-turnin", title="Hand in Catching Wind", text="Return to Elaadrin Evengale in Valanaar to hand in Catching Wind.", hub="Valanaar", level=10, questId=92840, action="turnin", faction="Alliance", x=66.6, y=79.9 },
        { id="service-92860-accept", title="Pick up In Service of Zephras", text="Accept In Service of Zephras from Elaadrin Evengale after Catching Wind.", hub="Valanaar", level=10, questId=92860, action="accept", faction="Alliance", requires={92840}, x=66.6, y=79.9 },
        { id="service-92860-turnin", title="Report to Valennia Stormfist", text="Tell Valennia Stormfist that the High Order will support the fight against the cult.", hub="Valanaar", level=10, questId=92860, action="turnin", faction="Alliance", x=66.1, y=76.7 },
    },
    ["east-pylon"] = {
        { id="service-92871-accept", title="Pick up In Service of Zephras", text="Accept In Service of Zephras from Ayessa Dawnsinger after A Firm Response.", hub="Valanaar", level=10, questId=92871, action="accept", faction="Horde", requires={93746}, x=59.1, y=79.8 },
        { id="service-92871-turnin", title="Report to Valennia Stormfist", text="Tell Valennia Stormfist that the Windshapers will support the defense of Zephras.", hub="Valanaar", level=10, questId=92871, action="turnin", faction="Horde", x=66.1, y=76.7 },
        { id="tower-93320-accept", title="Pick up Tower Defense", text="Accept Tower Defense from Valennia Stormfist in Valanaar.", hub="Valanaar", level=10, questId=93320, action="accept", x=66.1, y=76.7 },
    },
    ["turncoat"] = {
        { id="breaker-92645-accept", title="Pick up Breaking the Breaker", text="Speak with Yorana Windyreed at East Pylon Watchtower to accept Breaking the Breaker.", hub="East Pylon Watchtower", level=10, questId=92645, action="accept", requires={93320}, x=69.6, y=67.1 },
        { id="breaker-92645-objective", title="Defeat Commander Belguilos", text="Find Commander Belguilos in a house in the Gustberry Lowlands. She is upstairs.", hub="Gustberry Lowlands", level=10, questId=92645, action="objective", x=65.8, y=65.5 },
        { id="breaker-92645-turnin", title="Report Breaking the Breaker", text="Return to Yorana Windyreed at East Pylon Watchtower.", hub="East Pylon Watchtower", level=10, questId=92645, action="turnin", x=69.6, y=67.1 },
        { id="logistics-92642-accept", title="Pick up Disrupting Logistics", text="Accept Disrupting Logistics from Yorana Windyreed after Tower Defense.", hub="East Pylon Watchtower", level=10, questId=92642, action="accept", requires={93320}, x=69.6, y=67.1 },
        { id="logistics-92642-objective", title="Disrupt the cult's logistics", text="Defeat the Al'Aketh Healers and Brawlers listed in the quest log.", hub="Gustberry Lowlands", level=10, questId=92642, action="objective", x=65.7, y=65.6 },
        { id="logistics-92642-turnin", title="Report Disrupting Logistics", text="Return to Yorana Windyreed at East Pylon Watchtower.", hub="East Pylon Watchtower", level=10, questId=92642, action="turnin", x=69.6, y=67.1 },
        { id="return-92880-accept", title="Pick up Return to Valanaar", text="Accept Return to Valanaar from Yorana Windyreed after Breaking the Breaker and Disrupting Logistics.", hub="East Pylon Watchtower", level=10, questId=92880, action="accept", requires={92645,92642}, x=69.6, y=67.1 },
        { id="return-92880-turnin", title="Return to Valanaar", text="Take Yorana's report to Valennia Stormfist in Valanaar.", hub="Valanaar", level=10, questId=92880, action="turnin", x=66.2, y=76.7 },
        { id="elder-92881-accept", title="Pick up The High Elder's Request", text="Accept The High Elder's Request from Valennia Stormfist after Return to Valanaar.", hub="Valanaar", level=10, questId=92881, action="accept", requires={92880}, x=66.2, y=76.7 },
        { id="elder-92881-turnin", title="Talk to High Elder Shadowsong", text="Turn in The High Elder's Request to Talaanis Shadowsong in Valanaar.", hub="Valanaar", level=10, questId=92881, action="turnin", x=66.2, y=76.5 },
        { id="turncoat-92643-accept", title="Pick up The Turncoat", text="Accept The Turncoat from Talaanis Shadowsong after The High Elder's Request.", hub="Valanaar", level=11, questId=92643, action="accept", requires={92881}, x=66.2, y=76.5 },
        { id="turncoat-92643-objective", title="Find the cultist turncoat", text="Go to the secluded house northwest of Valanaar and follow the quest objective.", hub="Overlook Standing Stones", level=11, questId=92643, action="objective", x=56.1, y=60.3 },
    },
    ["cult-94568-turnin"] = {
        { id="cult-94568-accept", title="Pick up The Cult's True Plans", text="Accept The Cult's True Plans from Talaanis Shadowsong after handing in Unfortunate News.", hub="Valanaar", level=11, questId=94568, action="accept", requires={92644}, x=66.2, y=76.5 },
    },
    ["shrine"] = {
        { id="desperate-92640-accept", title="Pick up Desperate Times", text="Talk to Talaanis Shadowsong to accept Desperate Times.", hub="Valanaar", level=11, questId=92640, action="accept", requires={94568}, x=66.2, y=76.5 },
        { id="desperate-92640-turnin", title="Report Desperate Times", text="Speak with Valennia Stormfist in Valanaar and follow her instructions.", hub="Valanaar", level=11, questId=92640, action="turnin", x=66.1, y=76.7 },
        { id="prepare-93065-accept", title="Pick up Prepare for Battle", text="Accept Prepare for Battle from Valennia Stormfist after Desperate Times.", hub="Valanaar", level=12, questId=93065, action="accept", requires={92640}, x=66.1, y=76.7 },
        { id="prepare-93065-turnin", title="Meet Valennia at the road", text="Report to Valennia Stormfist in the Gustberry Lowlands to complete Prepare for Battle.", hub="Gustberry Lowlands", level=12, questId=93065, action="turnin", x=61.1, y=70.9 },
        { id="shrine-92947-accept", title="Pick up Making Our Move", text="Follow Valennia's instructions and accept Making Our Move after Prepare for Battle.", hub="Gustberry Lowlands", level=12, questId=92947, action="accept", requires={93065}, x=61.1, y=70.9 },
    },
}

local original = allSteps
allSteps = {}
for _, step in ipairs(original) do
    for _, extra in ipairs(additions[step.id] or {}) do allSteps[#allSteps+1] = extra end
    allSteps[#allSteps+1] = step
end
local amendments = {
    ["alliance-leader"]={x=66.6,y=79.9},
    ["horde-leader"]={x=59.1,y=79.8},
    ["scholar-92727-accept"]={requires={92699},x=66.3,y=79.8},
    ["scholar-92727-turnin"]={x=53.3,y=72.1},
    ["scholar-92849-accept"]={requires={92727},x=53.3,y=72.1},
    ["scholar-92849-turnin"]={x=52.1,y=69.4},
    ["scholar-92850-accept"]={requires={92849},x=52.1,y=69.4},
    ["scholar-92850-turnin"]={x=66.2,y=79.9},
    ["east-pylon"]={x=69.6,y=67.1},
    ["turncoat"]={title="Hand in The Turncoat",text="Hand in The Turncoat to the dead cultist at the secluded house. If you do not have this quest, first pick it up from Talaanis Shadowsong in Valanaar.",requires={92881},x=56.0,y=58.8},
    ["unfortunate-news-92644-accept"]={requires={92643},x=56.0,y=58.8},
    ["unfortunate-news-92644-turnin"]={x=66.2,y=76.5},
    ["cult-94568-turnin"]={x=66.2,y=76.5},
    ["shrine"]={requires={93065}},
    ["shrine-93958-accept"]={requires={92947}},
}
for _, step in ipairs(allSteps) do
    for name, value in pairs(amendments[step.id] or {}) do step[name] = value end
end

-- Attach the verified zone map to every Skyborne guide step without altering stable step IDs.
for _, step in ipairs(allSteps) do step.mapId = 2521 end

ns.starterGuides[#ns.starterGuides + 1] = {
    id = "zephras-alliance", title = "Skyborne: Zephras Isle (Alliance)",
    description = "High Order leveling route, roughly levels 1-13. Confirm optional quests in your live quest log.",
    faction = "Alliance", steps = allSteps,
}
ns.starterGuides[#ns.starterGuides + 1] = {
    id = "zephras-horde", title = "Skyborne: Zephras Isle (Horde)",
    description = "Windshaper leveling route, roughly levels 1-13. Confirm optional quests in your live quest log.",
    faction = "Horde", steps = allSteps,
}
