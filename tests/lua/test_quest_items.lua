-- Forever quest special items: API fallback, charge metadata and ready-state.
local ns={Modules={}}
function ns:RegisterModule(name, module) self.Modules[name]=module end
local ready, showAfterComplete, calls=false,false,0
C_QuestLog={
    GetLogIndexForQuestID=function(id) if id==100 then return 4 end end,
    ReadyForTurnIn=function(id) return ready and id==100 end,
}
GetQuestLogSpecialItemInfo=function(index)
    calls=calls+1
    if index==4 then return "|cffffffff|Hitem:12345::::::::|h[Test quest item]|h|r", 134400, 3, showAfterComplete end
end
assert(loadfile("shared/ui/QuestItems.lua"))("WayForth",ns)
local items=ns.Modules.QuestItems
assert(items:Find(99)==nil and calls==0,"No API query for quests absent from the log")
local data=items:Find(100)
assert(data and data.link:find("item:12345",1,true) and data.icon==134400 and data.charges==3)
ready=true
assert(items:Find(100)==nil,"Hide special item once ready unless Blizzard says to keep it")
showAfterComplete=true
assert(items:Find(100)~=nil,"Respect show-item-when-complete metadata")
C_QuestLog.GetLogIndexForQuestID=nil
GetQuestLogIndexByID=function(id) return id==100 and 8 or 0 end
GetQuestLogSpecialItemInfo=function(index)
    if index==8 then return "item:12345",133729,0,true end
end
assert(items:Find(100) and items:Find(100).icon==133729,"Legacy log-index fallback works")
GetQuestLogSpecialItemInfo=function() error("Client API unavailable") end
assert(items:Find(100)==nil,"Client API exceptions do not break tracker")
GetQuestLogSpecialItemInfo=nil
assert(items:Find(100)==nil,"Unsupported clients simply omit the action button")
print("WayForth special quest-item lookup tests passed")
