-- Run from QuestieDB at c6745129ef9ea5e6dd1cdcd77224090f71bda880.
-- Arguments: WayForth checkout, destination Lua file.
local revision=assert(io.popen('git rev-parse HEAD'))
local sha=revision:read('*l');revision:close()
assert(sha=='c6745129ef9ea5e6dd1cdcd77224090f71bda880','Use the pinned QuestieDB revision')
local root, output=assert(arg[1]),assert(arg[2])
local ns={starterGuides={}}
for line in io.lines(root..'/clients/forever/manifest/WayForth.toc') do
    local file=line:match('^Data/(.+%.lua)$')
    if file and file~='ForeverQuestRequirements.lua' and file~='ForeverQuestLocationUpdates.lua' then
        assert(loadfile(root..'/clients/forever/guides/'..file))('WayForth',ns)
    end
end
local wanted={}
for _,guide in ipairs(ns.starterGuides) do
    for _,step in ipairs(guide.steps) do
        if step.questId then wanted[step.questId]=true end
        for _,id in pairs(step.questIds or {}) do wanted[id]=true end
    end
end
local loaded=dofile('tools/export/inline.lua').loadForever(true)
local rows=loaded.Quest.entities
local ids={};for id in pairs(wanted) do ids[#ids+1]=id end;table.sort(ids)
local function list(values)
    if type(values)~='table' or #values==0 then return nil end
    local out={}
    -- Negative/zero IDs use special semantics: never reinterpret as completion gates.
    for _,id in ipairs(values) do if type(id)~='number' or id<=0 then return nil end;out[#out+1]=id end
    return '{'..table.concat(out,',')..'}'
end
local f=assert(io.open(output,'w'))
f:write('-- Generated factual requirements; QuestieDB c6745129ef9ea5e6dd1cdcd77224090f71bda880.\nlocal _,ns=...\nns.foreverQuestRequirements={\n')
local count=0
for _,id in ipairs(ids) do
    local row=rows[id]
    if row then
        local fields={}
        if type(row[4])=='number' and row[4]>0 then fields[#fields+1]='minLevel='..row[4] end
        local group,single=list(row[12]),list(row[13])
        -- A combined group/single rule needs source-specific semantics; retain authored rules.
        if group and (not row[13] or #row[13]==0) then fields[#fields+1]='requires='..group end
        if single and (not row[12] or #row[12]==0) then fields[#fields+1]='requiresAny='..single end
        if #fields>0 then f:write('    [',id,']={',table.concat(fields,','),'},\n');count=count+1 end
    end
end
f:write('}\n');f:close();print('Exported requirements for '..count..' bundled quest IDs')
