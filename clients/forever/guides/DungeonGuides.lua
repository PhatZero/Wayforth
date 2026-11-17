-- Dungeon quest preparation: source-observed Forever records only.
-- First usable dungeon: Hall of Thanes. No other dungeon is advertised as complete.
local _, ns = ...
ns.starterGuides = ns.starterGuides or {}
local source="ForeverDB 1.60.1.70938, observed in WoW Forever"
local hall={
    id="dungeon-hall-of-thanes", name="Hall of Thanes", mapID=3065,
    entrance="Under Ironforge, down the old halls",
    entrancePoint={mapId=1455,x=77.1,y=51.3},
    levelMin=13,levelMax=20,
    coverage="Partial", verifiedQuests=4, source="https://foreverdb.net/dungeon/3065-the-hall-of-thanes",
    quests={
        {id=96393,name="Old Ironforge Incursion",faction="Alliance",
            pickup={name="Earthseer Farsen",zone="Dun Morogh",mapId=1426,x=64.8,y=58.4},
            turnin={name="King Magni Bronzebeard",zone="Ironforge",mapId=1455,x=39.3,y=56.0},
            objective="Defeat Durgen Dirgehammer and collect his head.",
            url="https://foreverdb.net/quest/96393-old-ironforge-incursion"},
        {id=96394,name="The Restless Dead",faction="Alliance",
            pickup={name="Afadra Dunwall",zone="Ironforge",mapId=1455,x=33.3,y=48.0},
            turnin={name="Afadra Dunwall",zone="Ironforge",mapId=1455,x=33.3,y=47.8},
            objective="Kill 15 Enraged Apparitions and 10 Tormented Souls; put Anvilmar's spirit to rest.",
            url="https://foreverdb.net/quest/96394-the-restless-dead"},
        {id=96403,name="Important Heirlooms",
            pickup={name="Thom Filch",zone="Ironforge",mapId=1455,x=32.4,y=44.7},
            turnin={name="Thom Filch",zone="Ironforge",mapId=1455,x=32.2,y=44.8},
            objective="Collect 8 Dwarven Heirlooms inside the Hall of Thanes.",
            url="https://foreverdb.net/quest/96403-important-heirlooms"},
        {id=96395,name="An Ancient Grudge",
            pickupUnverified=true,turninUnverified=true,
            objective="Put Faldrim Anvilmar's spirit to rest; return to the Ghostly Attendant in the Hall of Thanes.",
            url="https://foreverdb.net/quest/96395-an-ancient-grudge"},
    },
}
ns.dungeonManifests={ [hall.id]=hall }
local steps={}
local function add(quest,phase,title,text,point)
    local step={id="dungeon-"..quest.id.."-"..phase,questId=quest.id,
        faction=quest.faction,action=phase=="pickup" and "accept" or phase=="work" and "objective" or "turnin",
        title=title,text=text,locationRole=phase=="pickup" and "pickup" or phase=="work" and "objective" or "turnin",
        sourceStatus="forever-observed",level=hall.levelMin}
    if point then
        step.mapId,step.x,step.y=point.mapId,point.x,point.y
        step.zone,step.hub=point.zone,point.name
        step.locationSource=source
    end
    steps[#steps+1]=step
end
-- Gather every source-confirmed outside pickup before entering.
for _,quest in ipairs(hall.quests) do
    if quest.pickup then
        local p=quest.pickup
        add(quest,"pickup","Collect: "..quest.name,
            "Before entering, accept quest #"..quest.id.." from "..p.name.." in "..p.zone..
            ". Quest association observed in Forever; confirm eligibility in-game.",p)
    else
        add(quest,"pickup","Check pickup: "..quest.name,
            "Quest #"..quest.id.." is observed in Forever, but its giver and pickup location have not been verified. Check your quest log and nearby NPCs. No fabricated map pin.")
    end
end
steps[#steps+1]={id="dungeon-hall-entrance",action="manual",title="Enter the Hall of Thanes",
    text="First collect eligible quests from outside. The entrance is below Ironforge; follow the old halls to the instance portal. You may skip this manual checkpoint if already inside.",
    mapId=hall.entrancePoint.mapId,x=hall.entrancePoint.x,y=hall.entrancePoint.y,
    zone="Ironforge",hub=hall.entrance,locationSource=source}
-- In-instance coordinates are intentionally absent: no guessed map pins.
for _,quest in ipairs(hall.quests) do
    add(quest,"work","Inside: "..quest.name,quest.objective..
        " Follow live quest counters and your party's path; internal waypoint not verified.")
end
-- Ancient Grudge's observed objective returns to a named NPC inside.
add(hall.quests[4],"finish","Inside turn-in: An Ancient Grudge",
    "Return to the Ghostly Attendant in the Hall of Thanes if this quest is ready. Exact coordinates unverified.")
for _,quest in ipairs(hall.quests) do
    if quest.turnin then
        local p=quest.turnin
        add(quest,"finish","After run: "..quest.name,
            "After leaving the instance, turn in quest #"..quest.id.." to "..p.name.." in "..p.zone..".",p)
    end
end
ns.starterGuides[#ns.starterGuides+1]={
    id=hall.id,title="Dungeon: "..hall.name,zone="Ironforge",continent="Dungeons",
    isDungeon=true,isOptional=true,testingOnly=true,limitedData=true,
    contentStatus="Partial quest verification; in-game walkthrough QA pending",
    description="4 observed Forever quests, pre-run pickup checklist, live quest phases and post-run turn-ins. Faction eligibility and instance paths require in-game confirmation.",
    levelMin=hall.levelMin,levelMax=hall.levelMax,steps=steps,
}
