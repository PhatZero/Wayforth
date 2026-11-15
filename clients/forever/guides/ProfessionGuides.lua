-- Profession routes for WoW: Forever. Skill and recipe availability are read live in game.
local _, ns = ...
local profiles = {
    {id="alchemy", name="Alchemy", skillLine=171, pairing="Herbalism", materials="Herbs, vials and recipes learned from trainers, vendors, quests or drops.", method="Prefer orange recipes. Check current reagent costs before crafting in bulk.", camp="Camp benefit: mana regeneration.", focus="Potions, elixirs, transmutes and dyes; healing potions use First Aid."},
    {id="blacksmithing", name="Blacksmithing", skillLine=164, pairing="Mining", materials="Metal bars, stone, flux and plans. Check the recipe window for exact quantities before smelting or buying ore.", method="Use known orange-only plans and save bars needed for the next recipe.", camp="Camp benefit: a combat-stat buff from the Sharpening Wheel; check its live tooltip.", focus="Weapons, armor and metal goods. Use an anvil and revisit your trainer at each rank."},
    {id="cooking", name="Cooking", skillLine=185, pairing="Fishing", materials="Vendor ingredients, meat and fish. The recipe window shows which ingredients are missing.", method="Learn recipes from trainers and vendors; use orange-only dishes for skill-ups.", camp="Camp benefit: stamina food; some Forever foods also grant experience.", focus="Food buffs and camp recipes; some foods also grant experience."},
    {id="enchanting", name="Enchanting", skillLine=333, pairing="Tailoring", materials="Dust, essences and shards from disenchanting suitable magic items. Keep unneeded greens for materials before vendoring them.", method="Learn trainer enchants and compare their current skill color. Disenchant items only after checking whether you or another character still needs the gear.", camp="Camp benefit: armor, stats and resistance buffs.", focus="Enchants, oils and curios. Enchants are applied to gear."},
    {id="engineering", name="Engineering", skillLine=202, pairing="Mining", materials="Bars, stone, cloth and vendor components. Check recipes before smelting; engineering uses several different material types.", method="Work from recipes you know and craft the orange-only option with the best materials on hand. Keep a reserve of metal for the next trainer recipe.", camp="Camp benefit: an engineer can provide a campsite vendor.", focus="Gadgets, explosives and utility items; some plans come from other sources."},
    {id="first-aid", name="First Aid", skillLine=129, pairing="Tailoring or cloth from humanoid enemies", materials="Cloth dropped by humanoid enemies, plus any recipe-specific supplies.", method="Train each bandage as soon as it becomes available. Use the highest bandage you can make and gather the next cloth type before the current one stops granting skill.", camp="Camp benefit: stamina.", focus="Bandages, poultices and healing potions, which moved here from Alchemy."},
    {id="fishing", name="Fishing", skillLine=356, pairing="Cooking", materials="A fishing pole, bait or lures when available, and time at water. Catch quality depends on the water and your skill.", method="Fish at accessible waters and use a lure if you have one. Move to water with fish appropriate to your current skill when catches stop granting points.", camp="Camp benefit: increased stats while the profession camp effect is active.", focus="Fish for cooking and quests. Forever adds Fishing campsite recipes and blueprints."},
    {id="herbalism", name="Herbalism", skillLine=182, pairing="Alchemy", materials="Herbs gathered in the world. Node availability depends on the region, character access and gathering skill.", method="Track herbs on the minimap; move zones when available nodes stop granting skill.", camp="Camp benefit: increased Intellect.", focus="Gather herbs for Alchemy or sale. Forever adds campsite growing tools."},
    {id="leatherworking", name="Leatherworking", skillLine=165, pairing="Skinning", materials="Leather, hides, thread and recipe-specific vendor goods.", method="Skin while questing, save several leather grades, and use orange-only recipes.", camp="Camp benefit: a tent that can provide rested experience.", focus="Leather armor, kits and bags. Save rare hides for recipes that need them."},
    {id="mining", name="Mining", skillLine=186, pairing="Blacksmithing or Engineering", materials="Mining pick and ore nodes that match your skill. Smelting options depend on learned recipes and available ore.", method="Enable Find Minerals on the minimap. Gather nodes that grant skill and smelt only when the recipe window shows a skill-up opportunity or you need the bars.", camp="Camp benefit: increased melee attack power.", focus="Supplies metalworking. Forever adds campsite smelting and recipes."},
    {id="skinning", name="Skinning", skillLine=393, pairing="Leatherworking", materials="A skinning knife and skinnable beasts near your character's level.", method="Skin beasts as you quest. If a corpse is too difficult to skin, raise your skill or find lower-level beasts; move on when the current area stops granting points.", camp="Camp benefit: increased critical strike.", focus="Supplies Leatherworking. Forever adds skinning campsite recipes and objects."},
    {id="tailoring", name="Tailoring", skillLine=197, pairing="Enchanting", materials="Cloth from humanoid enemies, thread and recipe-specific vendor components.", method="Collect cloth while questing; compare recipe skill colors and materials before crafting.", camp="Camp benefit: increased Spirit.", focus="Cloth armor, bags and reagent storage. First Aid also uses cloth."},
}

-- Rank acquisition differs for secondary professions in Forever.
-- Source: Wowhead Forever profession overviews. No inferred coordinates.
local rankNotes={
    cooking={
        expert="Expert Cooking comes from the Expert Cookbook, not a trainer. Alliance: Shandrina in Ashenvale. Horde: Wulan in Desolace. The book is tradeable.",
        artisan="Artisan Cooking comes from the Clamlette Surprise quest given by Dirge Quikcleave in Gadgetzan, Tanaris, at Cooking 225 and character level 35. Bring 12 Giant Eggs, 10 Zesty Clam Meat, and 20 Alterac Swiss."},
    ["first-aid"]={
        expert="Expert First Aid comes from Expert First Aid - Under Wraps, not a trainer. Alliance: Deneb Walker in Arathi Highlands. Horde: Balai Lok'Wein in Dustwallow Marsh. Buy the Heavy Silk and Mageweave bandage manuals too.",
        artisan="Artisan First Aid comes from Triage, not a trainer, at First Aid 225 and character level 35. Alliance: Doctor Gustaf VanHowzen in Theramore. Horde: Doctor Gregory Victor in Hammerfall."},
    fishing={
        expert="Expert Fishing comes from the book Expert Fishing - The Bass and You, sold by Old Man Heming in Stranglethorn Vale. Check the item and required skill before purchasing.",
        artisan="Artisan Fishing comes from Nat Pagle, Angler Extreme, started with Nat Pagle in Dustwallow Marsh at Fishing 225 and character level 35."},
}

for _, profile in ipairs(profiles) do
    local steps = {
        {id="profession-"..profile.id.."-start", title="Learn "..profile.name, action="manual", trainer=true, skillComplete=1,
            text="Visit a trainer and learn "..profile.name..". Then open its profession window and use WayForth's Next Skill-Up recommendation. Make one recommended craft at a time and check the guide again after each skill-up so you do not craft extra items after a recipe turns green or gray. "..profile.pairing.." is a common pairing."},
        {id="profession-"..profile.id.."-camp", title="Check your profession campsite at skill 20", action="manual", skillComplete=20,
            text="At skill 20, check the profession trainer and campsite for this profession's camp item or recipe. Some camp benefits require a quest, purchase or blueprint. Then keep using one-at-a-time skill-up recommendations."},
        {id="profession-"..profile.id.."-journeyman", title="Train Journeyman before the 75 cap", action="manual", trainer=true, rankCap=75,
            text="Train Journeyman as soon as the live trainer allows it, before reaching the Apprentice cap of 75. Check the trainer's character-level and location requirements. Once the learned cap rises, follow the Next Skill-Up recommendation toward the new cap."},
        {id="profession-"..profile.id.."-expert", title="Train Expert before the 150 cap", action="manual", trainer=true, rankCap=150,
            text="Train Expert as soon as the live trainer allows it, before reaching the Journeyman cap of 150. Check the trainer's character-level, location and any profession-specific quest requirements. Then follow the Next Skill-Up recommendation toward the new cap."},
        {id="profession-"..profile.id.."-artisan", title="Train Artisan before the 225 cap", action="manual", trainer=true, rankCap=225,
            text="Train Artisan as soon as the live trainer allows it, before reaching the Expert cap of 225. Character-level requirements can differ between crafting, gathering and secondary skills, so use the live trainer as the authority. Then follow the Next Skill-Up recommendation to 300."},
        {id="profession-"..profile.id.."-finish", title="Reach skill 300", action="manual", skillComplete=300,
            text="Continue one skill-up at a time until you reach 300. The recommendation is recalculated after your skill changes, so it can switch recipes when the current one stops being an efficient source of points. Gather only the materials shown for the next recommended craft."},
    }
    -- Fill the dynamic profession name into the first step after constructing shared milestones.
    local rank=rankNotes[profile.id]
    if rank then
        steps[4].text=rank.expert.." Your profession cap must actually increase before the tracker advances."
        steps[5].text=rank.artisan.." Your profession cap must actually increase before the tracker advances."
    end
    steps[1].text=steps[1].text.." WayForth uses a verified offline orange-only route when available; collect the full verified shopping list first. Where records are incomplete, it shows only the next live orange recipe."
    for _, step in ipairs(steps) do step.professionId=profile.id end
    ns.starterGuides[#ns.starterGuides+1] = {
        id="profession-"..profile.id, title=profile.name.." Profession Guide", zone=profile.name,
        description=profile.focus.." "..profile.materials.." "..profile.camp,
        professionId=profile.id, isProfession=true, isOptional=true, contentStatus=true,
        levelMin=1,levelMax=60,steps=steps,
    }
end
ns.professionProfiles = profiles
