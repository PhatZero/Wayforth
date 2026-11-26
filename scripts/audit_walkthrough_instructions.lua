-- Run from the repository root. Avoid double counting generated chapter copies.
local audit=dofile("scripts/audit_quest_locations.lua")
local ns,guides=audit.ns,audit.guides
local seen={}
local totals={pickup=0,objective=0,turnin=0,missingLocations=0,missingObjectives=0}
for _,g in ipairs(guides:List()) do
    if not g.generatedChapter and not g.isDungeon and not g.isProfession and
        (g.faction=="Alliance" or g.faction=="Horde") then
        local races,classes={HUMAN=true,ORC=true},{HUNTER=true}
        for _,s in ipairs(g.steps) do
            for _,r in ipairs(s.races or {}) do races[r]=true end
            if s.class then classes[s.class]=true end
        end
        for race in pairs(races) do for class in pairs(classes) do
            UnitRace=function() return race,race end
            UnitClass=function() return class,class end
            for _,s in ipairs(guides:GetSteps(g.id)) do
                local role=s.action=="accept" and "pickup" or s.action
                local key=g.faction..":"..tostring(s.questId)..":"..tostring(role)
                if s.questId and totals[role]~=nil and not seen[key] then
                    seen[key]=true
                    totals[role]=totals[role]+1
                    if not (s.mapId and s.x and s.y) then
                        totals.missingLocations=totals.missingLocations+1
                        print("LOCATION GAP",g.faction,g.id,s.questId,role)
                    end
                    if role=="objective" and (s.instructionNeedsObjectives or s.useLiveInstructions and not s.objectiveSource) then
                        totals.missingObjectives=totals.missingObjectives+1
                        print("OBJECTIVE GAP",g.faction,g.id,s.questId)
                    end
                end
            end
        end end
    end
end
for k,v in pairs(totals) do print(k,v) end
print("Static metadata audit only; live objective and route correctness require in-game QA.")
