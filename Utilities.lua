-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Utilities.lua
-- Version : 2026.06.03
-- Desc    : Utility commands — rare announcer (/ous_rare), auto repair
-- ============================================================

local _, OUS = ...

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
