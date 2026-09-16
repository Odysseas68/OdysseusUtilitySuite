-- Addon   : OdysseusUtilitySuite
-- File    : JunkBroker.lua
-- Version : 2026.09.16
-- Desc    : Read-only bag junk and session sale data for broker displays
-- ================================================
-- luacheck: globals C_Container C_Item C_Timer Enum NUM_TOTAL_EQUIPPED_BAG_SLOTS
-- luacheck: globals GOLD_AMOUNT_TEXTURE_STRING SILVER_AMOUNT_TEXTURE COPPER_AMOUNT_TEXTURE FormatLargeNumber

local addonName, OUS = ...
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then return end

local eventFrame = CreateFrame("Frame")
local bagCache = {}
local dirtyBags = {}
local itemRetryPending = false
local bagQuantity, bagValue = 0, 0
local unresolved = true
local shownTooltip, tooltipOwner

-- Keeps broker text compact without changing private merchant/session formatters.
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local copperOnly = copper % 100
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = "|cffFFFF00" .. string.format(GOLD_AMOUNT_TEXTURE_STRING, FormatLargeNumber(gold), 0, 0) .. "|r"
    end
    if silver > 0 then
        parts[#parts + 1] = "|cffCCCCCC" .. string.format(SILVER_AMOUNT_TEXTURE, silver, 0, 0) .. "|r"
    end
    if copperOnly > 0 or #parts == 0 then
        parts[#parts + 1] = "|cffFF6600" .. string.format(COPPER_AMOUNT_TEXTURE, copperOnly, 0, 0) .. "|r"
    end
    return table.concat(parts, " ")
end

-- Reads session totals directly; the inventory cache never contributes to accounting.
local function FillTooltip(tooltip)
    local session = OUS.XPBarSession
    tooltip:ClearLines()
    tooltip:AddLine("Odysseus Junk", 0.65, 0.55, 0.98)
    tooltip:AddLine(" ")
    tooltip:AddLine("In Bags", 1, 0.82, 0)
    tooltip:AddDoubleLine("Items:", tostring(bagQuantity), 1, 1, 1, 1, 1, 1)
    tooltip:AddDoubleLine("Vendor Value:", FormatMoney(bagValue), 1, 1, 1, 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine("This Session", 1, 0.82, 0)
    tooltip:AddDoubleLine("Items Sold:", tostring(session.sessionJunkItems), 1, 1, 1, 1, 1, 1)
    tooltip:AddDoubleLine("Junk Gold:", FormatMoney(session.sessionJunkGold), 1, 1, 1, 1, 1, 1)
    if unresolved then
        tooltip:AddLine(" ")
        tooltip:AddLine("Some junk values are still loading.", 0.85, 0.85, 0.85)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine("|cffB3A6D9Left Click:|r Open Session Stats", 0.85, 0.85, 0.85)
    tooltip:AddLine("|cffB3A6D9Right Click:|r Open Gold Diagnostics", 0.85, 0.85, 0.85)
end

-- Does not overwrite a shared host tooltip after it has moved to another button.
local function RefreshVisibleTooltip()
    if shownTooltip and tooltipOwner and shownTooltip:IsShown()
        and shownTooltip:GetOwner() == tooltipOwner then
        FillTooltip(shownTooltip)
        shownTooltip:Show()
    end
end

local broker = ldb:NewDataObject("OUSJunkBroker", {
    type = "data source",
    label = "OUS Junk",
    tocname = addonName,
    icon = "Interface\\AddOns\\OdysseusUtilitySuite\\media\\Textures\\Trashcan.tga",
    text = FormatMoney(0) .. "*",
    OnClick = function(_, button)
        if button == "LeftButton" then
            OUS.SessionStats.Show()
        elseif button == "RightButton" then
            OUS.SessionStats.ShowGoldDiagnostics()
        end
    end,
    OnTooltipShow = function(tooltip)
        shownTooltip = tooltip
        tooltipOwner = tooltip:GetOwner()
        FillTooltip(tooltip)
    end,
})
if not broker then return end

-- Prices fresh bag instances, including blacklisted junk, without touching the sale queue.
local function ScanBag(bag)
    local cached = { quantity = 0, value = 0, pending = {}, unresolved = false }
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and (info.quality == Enum.ItemQuality.Poor or info.quality == nil) then
            local quality, price
            if info.hyperlink then
                local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(info.hyperlink)
                quality, price = itemQuality, sellPrice
            end
            quality = info.quality or quality
            if quality == Enum.ItemQuality.Poor then
                cached.quantity = cached.quantity + info.stackCount
                if price ~= nil then
                    cached.value = cached.value + math.max(0, price) * info.stackCount
                else
                    cached.unresolved = true
                end
            elseif quality == nil then
                cached.unresolved = true
            end
            if quality == nil or (quality == Enum.ItemQuality.Poor and price == nil) then
                if info.itemID then
                    cached.pending[info.itemID] = true
                end
            end
        end
    end
    bagCache[bag] = cached
end

-- Coalesces dirty bags and publishes known totals; unresolved prices remain visibly partial.
local function UpdateInventory()
    for bag in pairs(dirtyBags) do
        dirtyBags[bag] = nil
        ScanBag(bag)
    end
    bagQuantity, bagValue, unresolved = 0, 0, false
    for _, cached in pairs(bagCache) do
        bagQuantity = bagQuantity + cached.quantity
        bagValue = bagValue + cached.value
        unresolved = unresolved or cached.unresolved
    end
    local text = FormatMoney(bagValue) .. (unresolved and "*" or "")
    if broker.text ~= text then
        broker.text = text
    end
    RefreshVisibleTooltip()
end

-- Publishes after startup event handlers finish and coalesces pending item-info retries.
local function QueueInventoryUpdate()
    if itemRetryPending then return end
    itemRetryPending = true
    C_Timer.After(0, function()
        itemRetryPending = false
        UpdateInventory()
    end)
end

-- Restricts scanning to backpack and equipped carried bags, including the reagent bag.
local function MarkAllBagsDirty()
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        dirtyBags[bag] = true
    end
end

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:SetScript("OnEvent", function(_, event, itemID, success)
    if event == "PLAYER_ENTERING_WORLD" then
        MarkAllBagsDirty()
        QueueInventoryUpdate()
    elseif event == "BAG_UPDATE" then
        local bag = itemID
        if bag >= 0 and bag <= NUM_TOTAL_EQUIPPED_BAG_SLOTS then
            dirtyBags[bag] = true
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        if next(dirtyBags) then UpdateInventory() end
    elseif event == "GET_ITEM_INFO_RECEIVED" and success then
        for bag, cached in pairs(bagCache) do
            if cached.pending[itemID] then dirtyBags[bag] = true end
        end
        if next(dirtyBags) then
            QueueInventoryUpdate()
        end
    end
end)

OUS.SessionStats.JunkCallbacks.RegisterCallback(eventFrame, "JunkChanged", RefreshVisibleTooltip)
