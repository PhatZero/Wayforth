-- Run from repository root with Lua 5.1.
local ns={Modules={},char={guideProgress={}},state={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
local toc=assert(io.open("clients/forever/manifest/WayForth.toc"))
for line in toc:lines() do
    local data=line:match("^Data/(.+%.lua)$")
    if data then assert(loadfile("clients/forever/guides/"..data))("WayForth",ns) end
end
toc:close()
local inventory=assert(ns.hordeProgression,"Missing Horde progression inventory")
local ids={}
for _,g in ipairs(ns.starterGuides) do
    assert(not ids[g.id],"Duplicate guide "..g.id)
    ids[g.id]=g
end
for _,id in ipairs({"horde-durotar","horde-mulgore","horde-tirisfal-glades","zephras-horde"}) do
    assert(ids[id],"Missing Horde starter "..id)
    local included=false
    for _,chapterId in ipairs(inventory.chapters) do
        local chapter=ids[chapterId]
        if chapterId==id or chapter.parentGuideId==id then included=true end
    end
    assert(included,"Starter excluded from Horde progression: "..id)
end
local count,quests=0,{}
for _,id in ipairs(inventory.chapters) do
    local g=assert(ids[id])
    assert(g.faction=="Horde" and not g.isDungeon and not g.isProfession)
    assert(#g.steps>0)
    count=count+1
    local keys,circuits={},{}
    for _,s in ipairs(g.steps) do
        if s.questId then quests[s.questId]=true end
        if s.id then assert(not keys[s.id],"Duplicate step "..g.id.."/"..s.id);keys[s.id]=true end
        if g.generatedChapter then
            local key=assert(s.routeCircuitId)
            circuits[key]=circuits[key] or {}
            local phases=circuits[key]
            phases[s.questId]=phases[s.questId] or {}
            phases[s.questId][s.action]=true
        end
    end
    for _,c in pairs(circuits) do
        for _,phases in pairs(c) do assert(phases.accept and phases.turnin,"Split quest circuit") end
    end
end
local unique=0
for _ in pairs(quests) do unique=unique+1 end
print("Horde progression: "..count.." chapters, "..unique.." unique quest IDs")
for level=1,60 do print("Level "..level..": "..(inventory.coverage[level] or 0).." candidate chapters") end
assert(#inventory.gaps==0,"Uncovered levels: "..table.concat(inventory.gaps,", "))
print("Horde nominal level coverage passed; live eligibility and XP not verified")
