-- Regression for the browser's canonical chapter inventory and saved progress.
local ns={Modules={},char={activeGuide="first-steps",guideProgress={},recentGuides={}},state={}}
function ns:RegisterModule(name,module) self.Modules[name]=module end
UnitFactionGroup=function() return "Alliance" end
UnitClass=function() return "Hunter","HUNTER" end
UnitRace=function() return "Human","HUMAN" end
UnitLevel=function() return 12 end
local function guide(id,zone,lo,hi,extra)
    local g={id=id,title=id,zone=zone,continent="Kalimdor",faction="Alliance",
        levelMin=lo,levelMax=hi,steps={{id=id.."-step",action="manual",title="Test"}}}
    for k,v in pairs(extra or {}) do g[k]=v end
    return g
end
local parent=guide("parent","Zone A",1,20)
local child=guide("chapter-11","Zone A",11,15,{generatedChapter=true,parentGuideId="parent"})
local another=guide("chapter-16","Zone A",16,20,{generatedChapter=true,parentGuideId="parent"})
local other=guide("other","Zone B",10,15)
local empty=guide("unusable","Zone C",10,15,{class="MAGE"})
local old=guide("duplicate","Old",1,10)
local canonical=guide("duplicate","New",1,10)
local prof=guide("profession","Trades",1,60,{isProfession=true})
local starter=guide("first-steps","Starter",1,1)
ns.starterGuides={starter,parent,child,another,other,empty,old,canonical,prof}
assert(loadfile("shared/core/Guides.lua"))("WayForth",ns)
assert(loadfile("shared/core/SmartRoutes.lua"))("WayForth",ns)
local guides,routes=ns.Modules.Guides,ns.Modules.SmartRoutes
local function index(list)
    local result={}
    for _,g in ipairs(list) do assert(not result[g.id],"Duplicate guide "..g.id);result[g.id]=g end
    return result
end
assert(index(guides:List()).duplicate==canonical)
for _,kind in ipairs({"all","leveling"}) do
    local found=index(routes:ListGuides(kind))
    assert(found[child.id] and found[another.id] and not found[parent.id])
    assert(found.profession==(kind=="all" and prof or nil))
end
assert(index(routes:ListGuides("all",true)).parent==parent)
assert(index(routes:ListGuides("professions")).profession==prof)
assert(guides:SetActive(parent.id))
local saved=guides:GetProgress(parent.id)
saved.completed["parent-step"]=true
assert(not guides:SetActive(empty.id))
assert(ns.char.activeGuide==parent.id and ns.char.recentGuides[1]==parent.id)
assert(guides:GetProgress(parent.id)==saved and saved.completed["parent-step"])
local zones={}
for _,entry in ipairs(routes:ZoneSuggestions(20)) do
    assert(not zones[entry.title],"Repeated zone suggestion")
    zones[entry.title]=entry.id
end
assert(zones["Zone A"]==child.id and zones["Zone B"]==other.id)
print("Guide library consolidation, duplicate registrations, progress and unique suggestions passed")
