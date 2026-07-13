-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Utilities.lua
-- Version : 2026.07.11
-- Desc    : Utility commands, merchant tools, and Blizzard action artwork control
-- ============================================================

local _, OUS = ...

OUS.utilitiesDefaults = {
    rareEnabled = true,
    repairEnabled = true,
    guildRepair = true,
    announceRepair = true,
    hideExtraActionArtwork = false,
    junkSell = {
        enabled = true,
        requireShift = false,
        announceJunk = true,
        limitTo12 = true,
        blacklist = {},
    },
}

local artworkApplyPending = false
local extraActionHooked = false
local zoneAbilityHooked = false

-- Applies only the configured visibility of Blizzard's decorative ability artwork.
function OUS.ApplyExtraActionArtworkSetting()
    if InCombatLockdown() then
        artworkApplyPending = true
        return
    end

    artworkApplyPending = false
    local hideArtwork = OdysseusDB
        and OdysseusDB.utilities
        and OdysseusDB.utilities.hideExtraActionArtwork == true
    local alpha = hideArtwork and 0 or 1

    local extraButton = _G.ExtraActionButton1
    local extraArtwork = extraButton and extraButton.style
    if extraArtwork then
        extraArtwork:SetAlpha(alpha)
        if hideArtwork then extraArtwork:Hide() else extraArtwork:Show() end
    end

    local zoneFrame = _G.ZoneAbilityFrame
    local zoneArtwork = zoneFrame and zoneFrame.Style
    if zoneArtwork then
        zoneArtwork:SetAlpha(alpha)
        if hideArtwork then zoneArtwork:Hide() else zoneArtwork:Show() end
    end
end

-- Hooks Blizzard's frame-level refreshes without touching protected or pooled buttons.
local function InstallExtraActionArtworkHooks()
    if not extraActionHooked and _G.ExtraActionBar_Update then
        _G.hooksecurefunc("ExtraActionBar_Update", OUS.ApplyExtraActionArtworkSetting)
        extraActionHooked = true
    end
    local zoneMixin = _G.ZoneAbilityFrameMixin
    if not zoneAbilityHooked and zoneMixin and zoneMixin.UpdateDisplayedZoneAbilities then
        _G.hooksecurefunc(zoneMixin, "UpdateDisplayedZoneAbilities", OUS.ApplyExtraActionArtworkSetting)
        zoneAbilityHooked = true
    end
end

local artworkEventFrame = CreateFrame("Frame")
artworkEventFrame:RegisterEvent("PLAYER_LOGIN")
artworkEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
artworkEventFrame:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
artworkEventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
artworkEventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
artworkEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
artworkEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
artworkEventFrame:RegisterEvent("ADDON_LOADED")
artworkEventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Blizzard_ZoneAbility" then return end
    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
        InstallExtraActionArtworkHooks()
    end
    if event ~= "PLAYER_REGEN_ENABLED" or artworkApplyPending then
        OUS.ApplyExtraActionArtworkSetting()
    end
end)

-- ============================================================
-- Localized General channel names (from Leatrix Plus pattern)
-- ============================================================

local GENERAL_CHANNEL = {
    deDE = "Allgemein",
    esMX = "General",
    esES = "General",
    frFR = "Général",
    itIT = "Generale",
    ptBR = "Geral",
    ruRU = "Общий",
    koKR = "공개",
    zhCN = "综合",
    zhTW = "綜合",
}

local function GetGeneralChannelIndex()
    local name = GENERAL_CHANNEL[GetLocale()] or "General"
    local index = GetChannelName(name)
    return (index and index > 0) and index or nil
end

-- ============================================================
-- Rare Announcer
-- ============================================================

--- Announces the targeted rare mob with a waypoint link to Guild chat (test) or General.
local function AnnounceRare()
    local db = OdysseusDB.utilities
    if not db or not db.rareEnabled then return end
    if not UnitExists("target") then return end

    -- Open world only
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType ~= "none" then return end

    local classification = UnitClassification("target")
    local mobName = UnitName("target")
    if not mobName then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    if not C_Map.CanSetUserWaypointOnMap(mapID) then
        OUS.LogDebug("Utilities", "Cannot set waypoint on this map")
        return
    end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos or pos.x == 0 or pos.y == 0 then
        OUS.LogDebug("Utilities", "Invalid player position")
        return
    end

    -- Store existing waypoint to restore after
    local currentPin = C_Map.GetUserWaypointHyperlink()

    -- Set temporary waypoint to get the hyperlink
    local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)
    if not mapPoint then return end
    C_Map.SetUserWaypoint(mapPoint)
    local waypointLink = C_Map.GetUserWaypointHyperlink()

    -- Restore old waypoint after short delay
    if currentPin then
        C_Timer.After(0.1, function()
            local oldPin = C_Map.GetUserWaypointFromHyperlink(currentPin)
            if oldPin then C_Map.SetUserWaypoint(oldPin) end
        end)
    else
        C_Map.ClearUserWaypoint()
    end

    if not waypointLink then
        OUS.LogDebug("Utilities", "Failed to get waypoint hyperlink")
        return
    end

    -- Color codes for local display only — stripped for chat (blocked in 12.0+)
    local TAGS_CHAT = {
        rare      = "[Rare]",
        rareelite = "[Rare Elite]",
        elite     = "[Elite]",
        worldboss = "[World Boss]",
    }
    local tag = TAGS_CHAT[classification] or "[Normal]"
    local msg = tag .. " " .. mobName .. " " .. waypointLink

    local index = GetGeneralChannelIndex()
    if index then C_ChatInfo.SendChatMessage(msg, "CHANNEL", nil, index --[[@as string]]) end
    -- TomTom after chat send — avoids conflict with temporary native waypoint
    if TomTom then
        TomTom:AddWaypoint(mapID, pos.x, pos.y, {
            title  = "Rare: " .. mobName,
            source = "OUS",
            crazy  = true,   -- activate the crazy arrow automatically
        })
    end
    OUS.LogDebug("Utilities", "Rare announced: " .. mobName)
end

-- ============================================================
-- Auto Repair
-- ============================================================

local ICON_GOLD   = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local ICON_SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
local ICON_COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

--- Formats copper amount as WoW-style gold/silver/copper with coin icons.
local function FormatCost(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("%d%s %d%s %d%s", g, ICON_GOLD, s, ICON_SILVER, c, ICON_COPPER)
end

local function DoRepair()
    local db = OdysseusDB.utilities
    if not db or not db.repairEnabled then return end
    if not CanMerchantRepair() then return end

    local cost = GetRepairAllCost()
    if not cost or cost == 0 then return end

    local usedGuild = false

    -- Try guild repair first
    if db.guildRepair and IsInGuild() then
        local guildMoney = GetGuildBankWithdrawMoney()
        if guildMoney and guildMoney >= cost then
            RepairAllItems(true)
            usedGuild = true
        end
    end

    -- Fallback to own gold
    if not usedGuild then
        if GetMoney() >= cost then
            RepairAllItems()
        else
            print("|cffA78BFA[OUS]:|r Not enough gold to repair.")
            return
        end
    end

    if db.announceRepair then
        local source = usedGuild
            and " using |cff4ADE80Guild funds|r"
            or  " using |cffFBBF24Own funds|r"
        print(string.format("|cffA78BFA[OUS]:|r Repair cost: %s%s", FormatCost(cost), source))
    end

    OUS.LogDebug("Utilities", "Repaired for " .. cost .. " copper" .. (usedGuild and " (guild)" or " (own)"))
end

-- ============================================================
-- Events
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        DoRepair()
    end
end)

-- ============================================================
-- Slash command
-- ============================================================

SLASH_OUSRARE1 = "/ous_rare"
SlashCmdList["OUSRARE"] = function()
    if not OdysseusDB.modules.utilities then return end
    AnnounceRare()
end

-- ============================================================
-- Junk Seller
-- ============================================================

local junkPending    = {}   -- { {bag, slot}, ... } remaining items to sell
local junkSellBtn    = nil  -- "Sell Next 12" floating button
local isMerchantOpen = false

--- Collects all grey quality non-blacklisted bag items into a list.
local function CollectJunkItems()
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return {} end
    local blacklist = db.blacklist or {}
    local items = {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local quality = select(3, C_Item.GetItemInfo(info.itemID))
                if quality == 0 and not blacklist[info.itemID] then
                    items[#items + 1] = { bag = bag, slot = slot, itemID = info.itemID }
                end
            end
        end
    end
    return items
end

local batchSold   = 0   -- items sold in current batch
local batchCopper = 0   -- copper earned in current batch
local batchLimit  = 12  -- items per batch

--- Sells one item from junkPending then schedules the next via timer.
local function SellNextItem()
    if not isMerchantOpen then return end
    if InCombatLockdown() then return end
    if not MerchantFrame:IsShown() then return end
    if #junkPending == 0 then
        -- All done — announce and hide button
        local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
        if db and batchSold > 0 and db.announceJunk then
            print(string.format("|cffA78BFA[OUS]:|r Sold %d junk item(s) for %s",
                batchSold, FormatCost(batchCopper)))
        end
        if junkSellBtn then junkSellBtn:Hide() end
        batchSold   = 0
        batchCopper = 0
        return
    end

    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return end

    -- Batch limit reached — announce and show button for remainder
    if db.limitTo12 and batchSold >= batchLimit then
        if db.announceJunk and batchSold > 0 then
            print(string.format("|cffA78BFA[OUS]:|r Sold %d junk item(s) for %s",
                batchSold, FormatCost(batchCopper)))
        end
        if junkSellBtn then
            junkSellBtn:SetText("Sell Next 12 (" .. #junkPending .. " left)")
            junkSellBtn:Show()
        end
        batchSold   = 0
        batchCopper = 0
        return
    end

    -- Sell directly from pending list — slots stable during vendor session
    -- Blacklist already applied in CollectJunkItems, no rescan needed
    local item = table.remove(junkPending, 1)
    if item then
        local _, sellPrice = select(10, C_Item.GetItemInfo(item.itemID))
        C_Container.UseContainerItem(item.bag, item.slot)
        batchSold = batchSold + 1
        if sellPrice then
            local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
            local stackCount = (info and info.stackCount) or 1
            batchCopper = batchCopper + (sellPrice * stackCount)
        end
    end

    -- Schedule next item after 0.2s delay
    C_Timer.After(0.2, SellNextItem)
end

--- Starts selling the current batch — entry point.
local function SellNextBatch()
    if not isMerchantOpen then return end
    if InCombatLockdown() then return end
    batchSold   = 0
    batchCopper = 0
    SellNextItem()
end

--- Entry point called on MERCHANT_SHOW.
local function OnMerchantShow()
    if InCombatLockdown() then return end
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return end
    if not db.enabled then return end
    isMerchantOpen = true
    junkPending = CollectJunkItems()

    if #junkPending == 0 then return end

    if not junkSellBtn then
        junkSellBtn = CreateFrame("Button", "OUSJunkSellBtn", MerchantFrame, "UIPanelButtonTemplate")
        junkSellBtn:SetSize(160, 22)
        junkSellBtn:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -160, 4)
        junkSellBtn:SetScript("OnClick", SellNextBatch)
    end
    local btnLabel = db.limitTo12
        and ("Sell Junk (" .. #junkPending .. ")")
        or  ("Sell All Junk (" .. #junkPending .. ")")
    junkSellBtn:SetText(btnLabel)
    junkSellBtn:Show()

    -- Auto-sell unless Shift is required
    if db.requireShift and not IsShiftKeyDown() then
        return
    end

    C_Timer.After(0.3, SellNextBatch)
end

-- ============================================================
-- Junk Seller Blacklist Frame
-- ============================================================

local junkBLFrame  = nil  -- main blacklist frame
local junkAddQueue = {}   -- pending items to add { [itemID] = { name, icon, ilvl } }

--- Refreshes the right panel list of currently blacklisted items.
local function RefreshBlacklist()
    if not junkBLFrame or not junkBLFrame.rightScrollChild then return end
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return end

    local scrollChild = junkBLFrame.rightScrollChild
    -- Clear existing rows
    for _, child in ipairs({ scrollChild:GetChildren() }) do child:Hide() end

    local yOff = -8
    local ROW_H = 28
    local sorted = {}
    for itemID, data in pairs(db.blacklist or {}) do
        sorted[#sorted + 1] = { itemID = itemID, name = data.name or tostring(itemID), icon = data.icon }
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sorted) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(220, ROW_H)
        row:SetPoint("TOPLEFT", 0, yOff)

        -- Icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 2, 0)
        if entry.icon then icon:SetTexture(entry.icon) end

        -- Name
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        lbl:SetWidth(160)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(entry.name)

        -- X button
        local removeBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        removeBtn:SetSize(20, 20)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        removeBtn:SetScript("OnClick", function()
            db.blacklist[entry.itemID] = nil
            RefreshBlacklist()
        end)

        yOff = yOff - ROW_H
    end
    scrollChild:SetHeight(math.max(300, math.abs(yOff) + 10))
end

--- Refreshes the left panel queue of pending items to add.
local function RefreshAddQueue()
    if not junkBLFrame or not junkBLFrame.leftScrollChild then return end
    local scrollChild = junkBLFrame.leftScrollChild
    -- (guard valid — leftScrollChild set on container)

    for _, child in ipairs({ scrollChild:GetChildren() }) do child:Hide() end

    local yOff = -8
    local ROW_H = 28
    local sorted = {}
    for itemID, data in pairs(junkAddQueue) do
        sorted[#sorted + 1] = { itemID = itemID, name = data.name, icon = data.icon }
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sorted) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(220, ROW_H)
        row:SetPoint("TOPLEFT", 0, yOff)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 2, 0)
        if entry.icon then icon:SetTexture(entry.icon) end

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        lbl:SetWidth(160)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(entry.name)

        local removeBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        removeBtn:SetSize(20, 20)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        removeBtn:SetScript("OnClick", function()
            junkAddQueue[entry.itemID] = nil
            RefreshAddQueue()
        end)

        yOff = yOff - ROW_H
    end
    scrollChild:SetHeight(math.max(300, math.abs(yOff) + 10))
end

--- Builds the blacklist frame (lazy — created once on first open).
local function BuildJunkBlacklistFrame()
    local FRAME_W  = 260
    local FRAME_H  = 420
    local FRAME_GAP = 8

    -- Invisible container — handles drag for both panels
    local container = CreateFrame("Frame", "OUSJunkBLContainer", UIParent)
    container:SetSize(FRAME_W * 2 + FRAME_GAP, FRAME_H)
    container:SetPoint("CENTER")
    container:SetFrameStrata("DIALOG")
    container:SetMovable(true)
    container:EnableMouse(false)   -- children handle mouse

    local function StartDrag() container:StartMoving() end
    local function StopDrag()  container:StopMovingOrSizing() end

    -- ── LEFT FRAME (Add Items) ───────────────────────────────
    local lf = CreateFrame("Frame", "OUSJunkBLAdd", container, "BackdropTemplate")
    lf:SetSize(FRAME_W, FRAME_H)
    lf:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    lf:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    lf:SetBackdropColor(0.08, 0.06, 0.14, 0.97)
    lf:SetBackdropBorderColor(0.4, 0.3, 0.6, 1)
    lf:SetMovable(true)
    lf:EnableMouse(true)
    lf:RegisterForDrag("LeftButton")
    lf:SetScript("OnDragStart", StartDrag)
    lf:SetScript("OnDragStop",  StopDrag)

    -- Left title
    local lTitle = lf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lTitle:SetPoint("TOP", 0, -10)
    lTitle:SetTextColor(1, 0.82, 0)
    lTitle:SetText("Add Items")

    -- Left separator
    local lSep = lf:CreateTexture(nil, "ARTWORK")
    lSep:SetHeight(1)
    lSep:SetPoint("TOPLEFT", 8, -26)
    lSep:SetPoint("TOPRIGHT", -8, -26)
    lSep:SetColorTexture(0.4, 0.3, 0.6, 0.8)

    -- Close button (closes both)
    local closeBtn = CreateFrame("Button", nil, lf, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() container:Hide() end)

    -- Drop zone
    local dropZone = CreateFrame("Frame", nil, lf, "BackdropTemplate")
    dropZone:SetSize(FRAME_W - 20, 52)
    dropZone:SetPoint("TOP", 0, -34)
    dropZone:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    dropZone:SetBackdropColor(0.10, 0.08, 0.18, 0.9)
    dropZone:SetBackdropBorderColor(0.55, 0.35, 0.85, 0.9)
    dropZone:EnableMouse(true)

    local dropLabel = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropLabel:SetAllPoints()
    dropLabel:SetJustifyH("CENTER")
    dropLabel:SetTextColor(0.5, 0.4, 0.7)
    dropLabel:SetText("Drag an item here\nto add to blacklist")

    local function TryAddItem()
        local cursorType, itemID = GetCursorInfo()
        if cursorType == "item" and itemID then
            local name, _, _, ilvl, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
            if name then
                junkAddQueue[itemID] = { name = name, icon = icon, ilvl = ilvl or 0 }
                ClearCursor()
                RefreshAddQueue()
            end
        end
    end
    dropZone:SetScript("OnMouseDown", TryAddItem)
    dropZone:SetScript("OnReceiveDrag", TryAddItem)

    -- Pending header
    local pendingHdr = lf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pendingHdr:SetPoint("TOPLEFT", 10, -94)
    pendingHdr:SetTextColor(1, 0.82, 0)
    pendingHdr:SetText("Pending:")

    -- Left scroll — stops above Cancel/Add buttons (buttons at bottom 38px)
    local SCROLL_TOP    = -110
    local BUTTON_AREA   = 44   -- buttons 22px + 14px margin top + 8px bottom
    local SCROLL_H      = FRAME_H + SCROLL_TOP - BUTTON_AREA

    local leftScroll = CreateFrame("ScrollFrame", nil, lf, "UIPanelScrollFrameTemplate")
    leftScroll:SetSize(FRAME_W - 30, SCROLL_H)
    leftScroll:SetPoint("TOPLEFT", 4, SCROLL_TOP)

    local leftScrollChild = CreateFrame("Frame", nil, leftScroll)
    leftScrollChild:SetSize(FRAME_W - 46, SCROLL_H)
    leftScroll:SetScrollChild(leftScrollChild)

    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, lf, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 22)
    cancelBtn:SetPoint("BOTTOMLEFT", 10, 10)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        wipe(junkAddQueue)
        RefreshAddQueue()
    end)

    -- Add button
    local addBtn = CreateFrame("Button", nil, lf, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 22)
    addBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
        if not db then return end
        db.blacklist = db.blacklist or {}
        for itemID, data in pairs(junkAddQueue) do
            db.blacklist[itemID] = { name = data.name, icon = data.icon }
        end
        wipe(junkAddQueue)
        RefreshAddQueue()
        RefreshBlacklist()
    end)

    -- Esc handled by Cancel button — OnKeyDown removed to avoid blocking game keybinds

    -- ── RIGHT FRAME (Blacklist Items) ────────────────────────
    local rf = CreateFrame("Frame", "OUSJunkBLList", container, "BackdropTemplate")
    rf:SetSize(FRAME_W, FRAME_H)
    rf:SetPoint("TOPLEFT", lf, "TOPRIGHT", FRAME_GAP, 0)
    rf:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    rf:SetBackdropColor(0.08, 0.06, 0.14, 0.97)
    rf:SetBackdropBorderColor(0.4, 0.3, 0.6, 1)
    rf:SetMovable(true)
    rf:EnableMouse(true)
    rf:RegisterForDrag("LeftButton")
    rf:SetScript("OnDragStart", StartDrag)
    rf:SetScript("OnDragStop",  StopDrag)

    -- Right title
    local rTitle = rf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rTitle:SetPoint("TOP", 0, -10)
    rTitle:SetTextColor(1, 0.82, 0)
    rTitle:SetText("Blacklisted Items")

    -- Right separator
    local rSep = rf:CreateTexture(nil, "ARTWORK")
    rSep:SetHeight(1)
    rSep:SetPoint("TOPLEFT", 8, -26)
    rSep:SetPoint("TOPRIGHT", -8, -26)
    rSep:SetColorTexture(0.4, 0.3, 0.6, 0.8)

    -- Right scroll
    local rightScroll = CreateFrame("ScrollFrame", nil, rf, "UIPanelScrollFrameTemplate")
    rightScroll:SetSize(FRAME_W - 30, FRAME_H - 70)
    rightScroll:SetPoint("TOPLEFT", 4, -34)

    local rightScrollChild = CreateFrame("Frame", nil, rightScroll)
    rightScrollChild:SetSize(FRAME_W - 46, FRAME_H - 70)
    rightScroll:SetScrollChild(rightScrollChild)

    -- Wipe button
    local wipeBtn = CreateFrame("Button", nil, rf, "UIPanelButtonTemplate")
    wipeBtn:SetSize(140, 22)
    wipeBtn:SetPoint("BOTTOM", 0, 10)
    wipeBtn:SetText("|cffFF6666Wipe Blacklist|r")
    wipeBtn:SetScript("OnClick", function()
        StaticPopupDialogs["OUS_JUNK_WIPE_BL"] = {
            text      = "Wipe the entire junk seller blacklist? This cannot be undone.",
            button1   = "Wipe",
            button2   = "Cancel",
            OnAccept  = function()
                local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
                if db then db.blacklist = {} end
                RefreshBlacklist()
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("OUS_JUNK_WIPE_BL")
    end)

    -- Wire scroll children to module-level refs
    container.leftScrollChild  = leftScrollChild
    container.rightScrollChild = rightScrollChild
    container.rightScroll      = rightScroll

    container:SetScript("OnShow", function()
        wipe(junkAddQueue)
        RefreshAddQueue()
        RefreshBlacklist()
    end)

    container:Hide()
    return container
end

--- Toggles the junk blacklist frame — called from Config and /js command.
function OUS.ToggleJunkBlacklist()
    if not junkBLFrame then
        junkBLFrame = BuildJunkBlacklistFrame()
    end
    if junkBLFrame:IsShown() then
        junkBLFrame:Hide()
    else
        junkBLFrame:Show()
    end
end

-- Slash command
SLASH_JSSELLER1 = "/js"
SlashCmdList["JSSELLER"] = function()
    OUS.ToggleJunkBlacklist()
end

-- Register merchant events
local junkFrame = CreateFrame("Frame")
junkFrame:RegisterEvent("MERCHANT_SHOW")
junkFrame:RegisterEvent("MERCHANT_CLOSED")
junkFrame:RegisterEvent("UI_ERROR_MESSAGE")
junkFrame:SetScript("OnEvent", function(_, event, _, msg)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "MERCHANT_CLOSED" then
        isMerchantOpen = false
        junkPending = {}
        if junkSellBtn then junkSellBtn:Hide() end
    elseif event == "UI_ERROR_MESSAGE" then
        -- Stop selling if vendor refuses or gold cap reached
        if msg == ERR_VENDOR_DOESNT_BUY or msg == ERR_TOO_MUCH_GOLD then
            isMerchantOpen = false
            junkPending = {}
            if junkSellBtn then junkSellBtn:Hide() end
        end
    end
end)
