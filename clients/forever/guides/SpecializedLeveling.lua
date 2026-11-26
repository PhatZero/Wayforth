-- Original opt-in Mage practice routes. No third-party route text or spawn
-- coordinates. Spell IDs are classic-family candidates; Forever live QA pending.
local _,ns=...
local function mage(faction,zone,id,base,low,high)
    local source
    for _,guide in ipairs(ns.starterGuides or {}) do
        if guide.id==base then source=guide;break end
    end
    if not source then return end
    local steps={
        {id=id.."-level14",action="checkpoint",class="MAGE",title="Prepare for frost control",
            text="Reach level 14 through normal questing. Use single-target combat until you have reliable control spells.",
            checkpoint={level=14},level=14},
        {id=id.."-frostnova",action="checkpoint",class="MAGE",title="Learn Frost Nova",
            text="Visit a Mage trainer and learn Frost Nova if available. Confirm the spell is in your spellbook.",
            checkpoint={kind="spell",spellId=122,name="Frost Nova"},level=14},
        {id=id.."-restock",action="checkpoint",class="MAGE",title="Prepare supplies",
            text="Repair your gear, clear bag space and obtain suitable food and water. Confirm when ready.",
            checkpoint={kind="vendor"},level=14},
        {id=id.."-level20",action="checkpoint",class="MAGE",title="Reach level 20",
            text="Continue normal questing in "..zone..". Practice controlling small groups only when safe; do not assume every enemy can be rooted.",
            checkpoint={level=20},level=20},
        {id=id.."-blizzard",action="checkpoint",class="MAGE",title="Learn Blizzard",
            text="Check the Mage trainer for Blizzard and place the spell on your action bar.",
            checkpoint={kind="spell",spellId=10,name="Blizzard"},level=20},
        {id=id.."-practice",action="manual",class="MAGE",title="Practice controlled AoE",
            text="Choose a safe open area with suitable non-elite melee enemies and a clear escape path. Start with small pulls. Root, create distance and use Blizzard if learned. Stop if control breaks or mana is low.",
            level=20},
        {id=id.."-finish",action="manual",class="MAGE",title="Continue your leveling journey",
            text="Return to the standard "..zone.." guide for verified quest destinations. This practice module does not prescribe a farming location or guarantee XP yield.",level=20},
    }
    ns.starterGuides[#ns.starterGuides+1]={
        id=id,title=faction..": Mage AoE preparation ("..zone..")",faction=faction,
        class="MAGE",isOptional=true,isSpecialized=true,zone=zone,levelMin=low,levelMax=high,
        routeStyle="class-practice",description="Optional Mage training and AoE practice checkpoints; use standard zone guides for quests.",
        contentStatus="Original practice module; Forever spell availability and live verification pending",steps=steps,
    }
end
mage("Alliance","Darkshore","alliance-mage-aoe-prep","alliance-darkshore",14,20)
mage("Horde","The Barrens","horde-mage-aoe-prep","horde-the-barrens",14,24)
