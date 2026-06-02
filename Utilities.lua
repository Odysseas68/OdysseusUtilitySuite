-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Utilities.lua
-- Version : 2026.06.02
-- Desc    : Utility commands — rare announcer (/ous_rare), auto repair
-- ============================================================

local addonName, OUS = ...

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

    -- TomTom support
    if TomTom then
        TomTom:AddWaypoint(mapID, pos.x, pos.y, { title = "Rare: " .. mobName })
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

    -- TODO: switch to General for live use
    -- local index = GetGeneralChannelIndex()
    -- if index then C_ChatInfo.SendChatMessage(msg, "CHANNEL", nil, index) end
    C_ChatInfo.SendChatMessage(msg, "GUILD")
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
