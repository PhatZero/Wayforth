# WoW: Forever profession guides

WayForth includes 12 per-character skill guides: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Fishing, Herbalism, Leatherworking, Mining, Skinning and Tailoring.

The in-game **Professions** page now gives a step-by-step leveling loop. It reads the character's skill and current cap, then uses the open profession window to inspect learned recipes, their live skill-up color, reagent quantities and bag counts. For crafting professions, it recommends one orange recipe at a time, preferring the option with fewer missing reagents and then fewer total reagents. When no orange recipe is available, it considers yellow recipes. It recalculates after each skill-up so the character does not keep making a recipe after it stops being a good source of points.

The route then walks the character through these checkpoints:

- Learn the profession and use the next-skill-up recommendation.
- Check the profession's campsite options at skill 20.
- Train Journeyman before reaching the 75 cap.
- Train Expert before reaching the 150 cap.
- Train Artisan before reaching the 225 cap.
- Continue using one-skill-up recommendations until 300.

The page targets the character's detected skill cap and prompts for the next rank before the cap is reached. Trainers can impose character-level, location, quest or profession-specific requirements; follow the live trainer if those differ. The recipe scorer minimizes in-game reagent amounts and missing bag supplies among learned orange recipes, then uses yellow recipes when needed. It does not know auction prices, travel time, undiscovered recipes or exact yellow skill-up odds, so it cannot claim a globally cheapest route. For gathering professions it gives a next action from the profession's live skill and notes; the client does not expose a complete node-by-node route.

Forever adds profession camp utilities, including a campsite vendor for Engineering and rested experience from the Leatherworking tent. Other examples include gathering buffs and Cooking, Fishing, and First Aid camp benefits. Tooltip wording, recipes and blueprint availability should be checked in the live client.

Sources consulted:

- [Wowhead: Professions Overview in WoW: Forever](https://www.wowhead.com/forever/guide/professions/overview), updated November 7, 2026; profession ranks, rank thresholds and campsite benefits.
- [Blizzard: Gather Around the Campfire in World of Warcraft: Forever](https://worldofwarcraft.blizzard.com/en-gb/news/24301516); campsite system and skill-20 profession items.
- [Blizzard: New Player's Starter Guide](https://worldofwarcraft.blizzard.com/en-us/news/24315280); profession limits, trainer access and current Professions window.
- [WoW-Professions: Forever](https://www.wow-professions.com/forever); profession guide coverage and note that the routes were based on beta and should be corrected from live feedback.

No fixed recipe table or long shopping list is bundled; recipes and material counts are read from the character's live window. All guide state is saved per character. Quest completion and profession synchronization remain separate.
