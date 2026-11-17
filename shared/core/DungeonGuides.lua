-- Live dungeon checklist, read-only with respect to saved quest completion.
-- A quest absent from the log is Unknown, never assumed to be offered.
local _,ns=...
local Dungeon={}
ns:RegisterModule("DungeonGuides",Dungeon)

local function completed(id)
    if ns.char and ns.char.turnedInQuests and ns.char.turnedInQuests[id]==true then return true end
    for _,fn in ipairs({C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or false,
                        IsQuestFlaggedCompleted or false}) do
        if type(fn)=="function" then
            local ok,yes=pcall(fn,id)
            if ok and yes==true then return true end
        end
    end
    return false
end
local function factionAllowed(quest)
    if not quest.faction then return true end
    if type(UnitFactionGroup)~="function" then return nil end
    local ok,faction=pcall(UnitFactionGroup,"player")
    if not ok or not faction then return nil end
    return faction==quest.faction
end
function Dungeon:QuestStatus(quest)
    local allowed=factionAllowed(quest)
    if allowed==false then return "Not eligible" end
    if completed(quest.id) then return "Completed" end
    local progress=ns.Modules.QuestProgress
    local snapshot=progress and progress:Get(quest.id)
    if snapshot then
        if snapshot.state=="turnedIn" then return "Completed" end
        if snapshot.state=="ready" then return "Ready to turn in" end
        if snapshot.state=="active" or snapshot.state=="unavailable" then return "In progress" end
        if snapshot.state=="loading" then return "Accepted" end
    end
    local requirements=(ns.foreverQuestRequirements or {})[quest.id]
    for _,required in ipairs(requirements and requirements.requires or {}) do
        if not completed(required) then return "Locked" end
    end
    -- Unknown is intentional: neither no quest log entry nor sufficient level
    -- guarantees an NPC is presently offering a quest to this character.
    return "Unknown"
end
function Dungeon:Overview(id)
    local manifest=(ns.dungeonManifests or {})[id]
    if not manifest then return nil end
    local overview={known=0,eligible=0,collected=0,completed=0,locked=0,unknown=0,
        missingPickup=0,rows={},coverage=manifest.coverage}
    for _,quest in ipairs(manifest.quests) do
        local status=self:QuestStatus(quest)
        local row={id=quest.id,name=quest.name,status=status,source=quest.url,
            pickup=quest.pickup,turnin=quest.turnin,pickupUnverified=quest.pickupUnverified==true}
        overview.rows[#overview.rows+1]=row
        overview.known=overview.known+1
        if status~="Not eligible" then
            overview.eligible=overview.eligible+1
            if status=="Completed" then
                overview.completed=overview.completed+1
                overview.collected=overview.collected+1
            elseif status=="In progress" or status=="Ready to turn in" or status=="Accepted" then
                overview.collected=overview.collected+1
            elseif status=="Locked" then overview.locked=overview.locked+1
            else overview.unknown=overview.unknown+1 end
            if not quest.pickup then overview.missingPickup=overview.missingPickup+1 end
        end
    end
    return overview
end
function Dungeon:Summary(id)
    local summary=self:Overview(id)
    if not summary then return "Dungeon quest data unavailable." end
    return "Quests collected "..summary.collected.."/"..summary.eligible..
        "  |  Completed "..summary.completed.."/"..summary.eligible..
        "  |  Pickup unverified "..summary.missingPickup
end
