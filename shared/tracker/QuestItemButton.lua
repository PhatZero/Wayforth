-- Native quest items, used only by a real click on a secure item action.
local _, ns = ...
local Item = {}
ns:RegisterModule("QuestItemButton", Item)
local theme = ns.Modules.Theme

local function public(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return nil end
    end
    return value
end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return public(a), public(b), public(c), public(d) end
end
local function number(value)
    value = public(value)
    if type(value) == "number" and value == value and value > -math.huge and value < math.huge then return value end
end
local function positive(value)
    value = number(value)
    if value and value > 0 and value == math.floor(value) then return value end
end
local function combat()
    return call(InCombatLockdown) == true
end
local function questAPI()
    return type(C_QuestLog) == "table" and C_QuestLog or {}
end
local function same(a, b)
    return a and b and a.questID == b.questID and a.itemID == b.itemID
end

function Item:Read(step)
    if not step or (step.action ~= "objective" and step.action ~= "turnin") then return nil end
    local questID = positive(step.questId)
    if not questID then return nil end
    local api = questAPI()
    local index = positive(call(api.GetLogIndexForQuestID, questID))
        or positive(call(GetQuestLogIndexByID, questID))
    if not index then return nil end
    -- A log index is transient. Never bind the action or tooltip to that index.
    local actualID = call(api.GetQuestIDForLogIndex, index)
    if actualID ~= nil and actualID ~= questID then return nil end
    if call(api.IsFailed, questID) == true then return nil end
    local link, texture, charges, showWhenComplete = call(GetQuestLogSpecialItemInfo, index)
    if type(link) ~= "string" then return nil end
    local itemID = positive(tonumber(link:match("item:(%d+)")))
    if not itemID then return nil end
    local ready = call(api.ReadyForTurnIn, questID) == true or call(api.IsComplete, questID) == true
    if ready and showWhenComplete ~= true and showWhenComplete ~= 1 then return nil end
    local itemAPI = type(C_Item) == "table" and C_Item or {}
    local count = number(call(itemAPI.GetItemCount, itemID, false, false))
    if count == nil then count = number(call(GetItemCount, itemID, false, false)) end
    charges = number(charges)
    -- Exclude bank-only items and items already consumed. Native charges are
    -- a fallback only on clients without a readable inventory-count API.
    if count ~= nil then
        if count <= 0 then return nil end
    elseif not charges or charges <= 0 then return nil end
    if type(texture) ~= "string" and not number(texture) then texture = "Interface\\Icons\\INV_Misc_QuestionMark" end
    return {questID = questID, itemID = itemID, index = index, link = link, texture = texture,
        count = math.max(0, math.floor(charges or count or 1)), title = step.title or "Quest item"}
end

function Item:Initialize(tracker)
    self.tracker = tracker or self.tracker
    if self.events then return end
    local events = CreateFrame("Frame")
    self.events = events
    for _, event in ipairs({"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "BAG_UPDATE_COOLDOWN",
        "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "QUEST_LOG_UPDATE", "QUEST_REMOVED", "QUEST_TURNED_IN"}) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function(_, event)
        if event == "BAG_UPDATE_COOLDOWN" then self:UpdateCooldown()
        else
            local hadItem = self.desired ~= nil
            self:Refresh()
            if hadItem ~= (self.desired ~= nil) and self.tracker and self.tracker.Layout then self.tracker:Layout() end
            self:Position()
        end
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        if not self.bound and not self.desired then return end
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.05 then return end
        self.elapsed = 0
        self:Position()
    end)
end

function Item:MakeButton()
    if self.button or combat() then return end
    -- No parent or anchor relationship with the movable tracker: a protected
    -- descendant would also restrict its ancestors' movement/hiding in combat.
    local button = CreateFrame("Button", "WayForthQuestItemButton", UIParent, "SecureActionButtonTemplate")
    button:SetSize(34, 34)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(self.tracker.frame:GetFrameLevel() + 5)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("useOnKeyDown", false)
    theme:Panel(button, theme.panel, theme.gold)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(.08, .92, .08, .92)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    local count = theme:Text(button, "", 10, theme.ivory)
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    self.button, self.icon, self.cooldown, self.count = button, icon, cooldown, count
    button:SetScript("OnEnter", function() self:Tooltip(button, false) end)
    button:SetScript("OnLeave", function() self:HideTooltip() end)
    button:SetScript("OnHide", function() self:HideTooltip() end)
    button:Hide()
end

function Item:MakeBlocker()
    if self.blocker then return end
    -- This ordinary sibling consumes mouse input while a secure binding is
    -- frozen. It never reparents, hides, disables or rebinds the secure button.
    local blocker = CreateFrame("Button", nil, UIParent)
    blocker:SetSize(34, 34)
    blocker:SetFrameStrata("DIALOG")
    theme:Panel(blocker, theme.navy, theme.gold)
    local caption = theme:Text(blocker, "WAIT", 9, theme.gold)
    caption:SetPoint("CENTER", blocker, "CENTER")
    blocker:SetScript("OnEnter", function() self:Tooltip(blocker, true) end)
    blocker:SetScript("OnLeave", function() self:HideTooltip() end)
    blocker:SetScript("OnHide", function() self:HideTooltip() end)
    blocker:SetScript("OnClick", function() ns:Print("Quest item button updates after combat.") end)
    blocker:Hide()
    self.blocker = blocker
end

function Item:HideTooltip()
    if GameTooltip and ((self.button and GameTooltip:IsOwned(self.button))
        or (self.blocker and GameTooltip:IsOwned(self.blocker))) then GameTooltip:Hide() end
end

function Item:Tooltip(owner, blocked)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if blocked then
        GameTooltip:SetText("Quest item updates after combat", unpack(theme.gold))
        GameTooltip:AddLine("The guide or tracker changed. This button will update when combat ends.",
            theme.ivory[1], theme.ivory[2], theme.ivory[3], true)
    elseif self.bound then
        local ok = GameTooltip.SetHyperlink and pcall(GameTooltip.SetHyperlink, GameTooltip, self.bound.link)
        if not ok then GameTooltip:SetText("Quest item", unpack(theme.gold)) end
        GameTooltip:AddLine("Left-click to use.", theme.teal[1], theme.teal[2], theme.teal[3], true)
    end
    GameTooltip:Show()
end

function Item:Coordinates()
    local tracker = self.tracker
    if not tracker or not tracker.objectiveCard then return nil end
    local card = tracker.objectiveCard
    local right, top = card:GetRight(), card:GetTop()
    if not right or not top then return nil end
    local scale = card:GetEffectiveScale() / UIParent:GetEffectiveScale()
    -- Match the tracker scale without anchoring to any of its frames.
    return (right - 90) * scale, (top - 7) * scale, scale
end

local function place(frame, x, y, scale)
    frame:SetScale(scale)
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

function Item:Position()
    local x, y, scale = self:Coordinates()
    local positioned = x ~= nil
    if not x and combat() then x, y, scale = self.x, self.y, self.scale end
    if not x then return end
    if combat() then
        local visible = self.button and self.button:IsShown()
        local located = positioned and self.x and math.abs(x - self.x) < .5 and math.abs(y - self.y) < .5 and scale == self.scale
        local blocked = visible and (not same(self.bound, self.desired) or not located)
            or (not visible and self.desired ~= nil)
        if blocked then
            self:MakeBlocker()
            if not self.blocker:IsShown() then self:HideTooltip() end
            place(self.blocker, visible and self.x or x, visible and self.y or y, visible and self.scale or scale)
            self.blocker:Show()
        elseif self.blocker then self.blocker:Hide() end
        return
    end
    if self.blocker then self.blocker:Hide() end
    if self.button and same(self.bound, self.desired) then
        if self.x ~= x or self.y ~= y or self.scale ~= scale then
            place(self.button, x, y, scale)
            self.x, self.y, self.scale = x, y, scale
        end
        self.button:Show()
    end
end

function Item:UpdateCooldown()
    if not self.bound or not self.cooldown then return end
    local current = self:Read({questId = self.bound.questID, action = "objective"})
    local start, duration, enabled
    if same(current, self.bound) then
        start, duration, enabled = call(GetQuestLogSpecialItemCooldown, current.index)
    end
    start, duration = number(start), number(duration)
    if start and duration and duration > 0 and enabled ~= 0 and enabled ~= false then
        self.cooldown:SetCooldown(start, duration)
    else self.cooldown:SetCooldown(0, 0) end
end

function Item:Refresh(tracker)
    self:Initialize(tracker)
    tracker = self.tracker
    local visible = tracker and tracker.frame and tracker.frame:IsShown()
        and not (ns.char and ns.char.trackerMinimized)
    self.desired = visible and self:Read(tracker.displayStep) or nil
    if combat() then
        -- Keep the old icon truthful until both binding and visibility may
        -- change. The normal overlay blocks clicks if its context is stale.
        if same(self.bound, self.desired) then
            self.count:SetText(self.desired.count > 1 and self.desired.count or "")
        end
        self:UpdateCooldown()
        self:Position()
        return self.desired ~= nil
    end
    if not same(self.bound, self.desired) then self:HideTooltip() end
    if not self.desired then
        if self.button then
            self.button:SetAttribute("type1", nil)
            self.button:SetAttribute("item1", nil)
            self.button:Hide()
        end
        self.bound = nil
        if self.blocker then self.blocker:Hide() end
        return false
    end
    self:MakeButton()
    self.button:SetAttribute("type1", nil)
    self.button:SetAttribute("item1", "item:" .. self.desired.itemID)
    self.button:SetAttribute("type1", "item")
    self.bound = self.desired
    self.icon:SetTexture(self.bound.texture)
    self.count:SetText(self.bound.count > 1 and self.bound.count or "")
    self:UpdateCooldown()
    self:Position()
    return true
end
