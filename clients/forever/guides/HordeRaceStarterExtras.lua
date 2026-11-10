-- Explicit race-restricted source quest entries for Horde starters.
-- AllTheThings Forever snapshot b2d15612a1319d450ffe844ee6b9ef708aa9d2c9.
-- Kept separate from generic zone candidates so Undead and Tauren intros
-- are not silently omitted or incorrectly shown to Orc/Troll players.
local _, ns = ...
local additions={
 { guide="horde-mulgore", zone="Mulgore", rows={
 {98427,"Ceasing Operations",5,54.4,60.4,98424,{"UNDEAD","TAUREN"}},
 {748,"Poison Water",4,48.5,60.4,nil,{"TAUREN"}},
 {98430,"The Longwalkers",1,33,65.8,nil,{"UNDEAD","TAUREN"}},
 {758,"Thunderhorn Cleansing",4,48.5,60.4,756,{"TAUREN"}},
 {756,"Thunderhorn Totem",4,48.5,60.4,754,{"TAUREN"}},
 {98435,"Thunderhorn's Report",4,48.5,60.4,760,{"UNDEAD","TAUREN"}},
 {760,"Wildmane Cleansing",4,48.5,60.4,759,{"TAUREN"}},
 {759,"Wildmane Totem",4,48.5,60.4,758,{"TAUREN"}},
 {754,"Winterhoof Cleansing",4,48.5,60.4,748,{"TAUREN"}},
 }},
 { guide="horde-tirisfal-glades", zone="Tirisfal Glades", rows={
 {363,"Rude Awakening",1,30.2,71.6,nil,{"UNDEAD"}},
 {96896,"A Righteous Cause",10,22,44.8,96899,{"UNDEAD"}},
 {99152,"As Above, So Below",10,22,47.2,96896,{"UNDEAD"}},
 {96899,"Bandarion Keep",10,65.8,61,nil,{"ORC","UNDEAD"}},
 {97558,"Hides for the Forsaken",6,65.4,60,nil,{"ORC","UNDEAD"}},
 {98545,"Leonid's Letter",10,22,44.8,96896,{"UNDEAD"}},
 {99156,"Rear Guard Patrol (2/2)",6,65.4,60.2,356,{"ORC","UNDEAD"}},
 {96898,"Remnants of War",10,65.8,61,nil,{"ORC","UNDEAD","TROLL"}},
 {99144,"Seeking Refuge",5,32,46.2,nil,{"UNDEAD"}},
 {96897,"The Cult of the Damned",10,65.8,61,nil,{"ORC","UNDEAD","TROLL"}},
 {99153,"The One That Got Away",10,20.2,46.4,96896,{"UNDEAD"}},
 {99142,"Tomb Weed",5,57.5,49,5482,{"UNDEAD"}},
 }},
}
local byId={}
for _,guide in ipairs(ns.starterGuides or {}) do byId[guide.id]=guide end
for _,set in ipairs(additions) do
 local guide=byId[set.guide]
 if guide then
  local known={}
  for _,step in ipairs(guide.steps) do
   if step.questId then known[step.questId]=true end
  end
  for _,row in ipairs(set.rows) do known[row[1]]=true end
  for _,row in ipairs(set.rows) do
   local id,title,lvl,x,y,required,races=row[1],row[2],row[3],row[4],row[5],row[6],row[7]
   local req=required and known[required] and {required} or nil
   local prefix="att-race-"..id
   local accept={id=prefix.."-accept",questId=id,title="Pick up: "..title,
    zone=set.zone,level=lvl,action="accept",x=x,y=y,requires=req,races=races,
    text="Accept "..title.." on an eligible race. Verify NPC availability in your game.",
    sourceStatus="ATT Forever race-specific quest candidate; verify"}
   local turnin={id=prefix.."-turnin",questId=id,title="Complete: "..title,
    zone=set.zone,level=lvl,action="turnin",requires=req,races=races,
    text="Finish "..title.." and return to the live quest giver or turn-in NPC.",
    sourceStatus="ATT Forever race-specific quest candidate; verify"}
   if id==363 then
    table.insert(guide.steps,1,turnin)
    table.insert(guide.steps,1,accept)
   else
    guide.steps[#guide.steps+1]=accept
    guide.steps[#guide.steps+1]=turnin
   end
  end
 end
end
