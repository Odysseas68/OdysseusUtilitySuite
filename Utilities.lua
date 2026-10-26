-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Utilities.lua
-- Version : 2026.10.26
-- Desc    : Utility commands, merchant tools, and Blizzard action artwork control
-- ============================================================

-- luacheck: globals GetGuildBankWithdrawMoney

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
        detailedSaleReport = false,
        limitTo12 = true,
        animation = "goblin",
        nativeGoblin = false,
        nativeGoblinDistance = 1.2,
        nativeGoblinSize = 96,
        blacklist = {},
    },
}

-- Keep action guards consistent without changing stored feature preferences.
local function IsUtilitiesEnabled()
    return OdysseusDB and OdysseusDB.modules and OdysseusDB.modules.utilities
end

local artworkHiddenByUtilities = {}
local artworkApplyPending = false
local extraActionHooked = false
local zoneAbilityHooked = false

-- Restore only artwork OUS hid, then relinquish it while the module is disabled.
local function ApplyArtworkVisibility(artwork, enabled, hideArtwork)
    if not artwork then return end
    if not enabled and not artworkHiddenByUtilities[artwork] then return end
    artwork:SetAlpha(hideArtwork and 0 or 1)
    if hideArtwork then
        artworkHiddenByUtilities[artwork] = true
        artwork:Hide()
    else
        artworkHiddenByUtilities[artwork] = nil
        artwork:Show()
    end
end

-- Applies the effective artwork preference, deferring all changes during combat.
function OUS.ApplyExtraActionArtworkSetting()
    if InCombatLockdown() then
        artworkApplyPending = true
        return
    end

    artworkApplyPending = false
    local enabled = IsUtilitiesEnabled()
    local hideArtwork = enabled and OdysseusDB.utilities
        and OdysseusDB.utilities.hideExtraActionArtwork == true
    local extraButton = _G.ExtraActionButton1
    ApplyArtworkVisibility(extraButton and extraButton.style, enabled, hideArtwork)
    local zoneFrame = _G.ZoneAbilityFrame
    ApplyArtworkVisibility(zoneFrame and zoneFrame.Style, enabled, hideArtwork)
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

-- Formats the pre-repair guild allowance observation without assigning funding semantics.
local function FormatObservedGuildAllowance(amount, repairCost)
    if type(amount) ~= "number" or amount < 0 then
        return "|cffFF6666unavailable|r"
    end
    if amount > repairCost then
        return "|cff00FF00above repair bill|r"
    end
    return FormatCost(amount)
end

-- Passes exact OUS-owned merchant amounts to Session Stats without coupling Utilities to its runtime state.
local function RecordSessionMerchantTransaction(transactionType, amount, details)
    if OUS.SessionStats and OUS.SessionStats.RecordKnownMerchantTransaction then
        OUS.SessionStats.RecordKnownMerchantTransaction(transactionType, amount, details)
    end
end

local function DoRepair()
    if not IsUtilitiesEnabled() then return end
    local db = OdysseusDB.utilities
    if not db or not db.repairEnabled then return end
    if not CanMerchantRepair() then return end

    local cost = GetRepairAllCost()
    if not cost or cost == 0 then return end

    local inGuild = db.guildRepair and IsInGuild()
    local canGuildRepair = inGuild and CanGuildBankRepair()

    if canGuildRepair then
        if OUS.SessionStats and OUS.SessionStats.MarkRepairFundingIndeterminate then
            OUS.SessionStats.MarkRepairFundingIndeterminate()
        end
    elseif GetMoney() < cost then
        print("|cffA78BFA[OUS]:|r Not enough gold to repair.")
        return
    end

    RecordSessionMerchantTransaction("REPAIR_COST", cost, {
        fundingType = canGuildRepair and "indeterminate" or "personal",
        walletEffectKnown = not canGuildRepair,
    })

    local observedGuildAllowance
    if canGuildRepair then
        observedGuildAllowance = GetGuildBankWithdrawMoney()
        RepairAllItems(true)
    else
        RepairAllItems()
    end

    if db.announceRepair then
        if canGuildRepair then
            print(string.format(
                "|cffA78BFA[OUS]:|r |cffFBBF24Guild-first|r repair requested: %s (observed guild allowance: %s)",
                FormatCost(cost),
                FormatObservedGuildAllowance(observedGuildAllowance, cost)
            ))
        else
            print(string.format("|cffA78BFA[OUS]:|r Repair cost: %s using |cffFBBF24Own funds|r", FormatCost(cost)))
        end
    end

    OUS.LogDebug("Utilities", canGuildRepair
        and "Guild-first repair requested for " .. cost .. " copper (funding indeterminate)"
        or "Repaired for " .. cost .. " copper (own)")
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
local junkSaleGeneration = 0
local junkBatchWaiting = false
local junkSaleActive = false -- distinguishes running work from manual/batch confirmation
local junkSaleScheduled = false -- excludes the initial delay from animation playback
local EnsureJunkSellPresentation
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

local batchSold     = 0   -- bag entries sold in current batch
local batchQuantity = 0   -- physical item quantity sold in current batch
local batchCopper   = 0   -- copper earned in current batch
local batchLimit    = 12  -- bag entries per batch

local junkAnimationFrame
local junkNativeFrame
local junkAnimationModes = {
    goblin = {file = "GoblinCounting.tga", columns = 8, rows = 4, frames = 32, duration = 1.6, size = 28},
    coin = {file = "CoinSpin.tga", columns = 4, rows = 4, frames = 16, duration = 1.2, size = 16},
}

-- Keep old or malformed saved camera values within the calibrated positive range.
local function JunkGoblinDistance(value)
    value = tonumber(value)
    if not value or value ~= value then return 1.2 end
    return math.max(1, math.min(2, value))
end

-- Accept only the three native viewport sizes without changing camera preferences.
local function JunkGoblinSize(value)
    return (value == 32 or value == 64) and value or 96
end

-- Share the approved cosmetic renderer between merchant artwork and an isolated OUS2 preview.
function OUS.CreateJunkGoblinRenderer(parent, repeatAnimation, onStatus)
    if InCombatLockdown() then return nil, "3D preview unavailable during combat." end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(96, 96)
    frame:SetClipsChildren(true)
    frame:EnableMouse(false)
    frame:Hide()
    frame.distance = 1.2
    frame.viewportSize = 96
    local pieces = {}

    -- Supply the same Midnight backing that the probe window provided behind its counter.
    local backing = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    backing:SetAllPoints()
    backing:SetColorTexture(0.035, 0.025, 0.06, 0.98)

    -- Preserve Merchant Counter v2's normalized geometry and native BACKGROUND layers.
    local function Piece(x, y, width, height, color, gradient, layer)
        local texture = frame:CreateTexture(nil, "BACKGROUND", nil, layer or 0)
        texture:SetColorTexture(unpack(color))
        if gradient then texture:SetGradient("HORIZONTAL", gradient[1], gradient[2]) end
        texture:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x * 96, y * 96)
        texture:SetSize(width * 96, height * 96)
        pieces[#pieces + 1] = { texture = texture, x = x, y = y, width = width, height = height }
    end
    local edge = CreateColor(0.15, 0.07, 0.24, 0)
    local glow = CreateColor(0.15, 0.07, 0.24, 0.1)
    Piece(0.04, 0.04, 0.46, 0.62, { 1, 1, 1, 1 }, { edge, glow })
    Piece(0.5, 0.04, 0.46, 0.62, { 1, 1, 1, 1 }, { glow, edge })
    Piece(0.08, 0.01, 0.84, 0.025, { 0.025, 0.012, 0.035, 0.35 })
    Piece(0.08, 0.035, 0.84, 0.11, { 1, 1, 1, 1 }, {
        CreateColor(0.12, 0.055, 0.075, 0.72), CreateColor(0.23, 0.12, 0.13, 0.72),
    }, 1)
    Piece(0.05, 0.145, 0.9, 0.018, { 0.23, 0.12, 0.13, 0.8 }, nil, 2)
    Piece(0.08, 0.163, 0.84, 0.018, { 0.32, 0.19, 0.17, 0.7 }, nil, 2)
    Piece(0.11, 0.181, 0.78, 0.018, { 0.4, 0.25, 0.2, 0.6 }, nil, 2)
    Piece(0.11, 0.197, 0.78, 0.012, { 0.62, 0.43, 0.23, 0.45 }, nil, 3)
    Piece(0.05, 0.14, 0.9, 0.012, { 0.5, 0.32, 0.16, 0.5 }, nil, 3)
    for _, x in ipairs({ 0.29, 0.5, 0.71 }) do
        Piece(x, 0.045, 0.008, 0.085, { 0.04, 0.018, 0.035, 0.45 }, nil, 2)
    end
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(0.75, 0.6, 1, 1)
    border:EnableMouse(false)
    border:Hide()

    local model
    -- Catch individual optional display calls only; failures never enter the transaction path.
    local function Fail(message)
        frame.failed = true
        frame:Hide()
        OUS.LogDebug("Utilities", "Native Goblin: " .. message)
        if onStatus then onStatus(message, true) end
        return false
    end
    local function Call(method, ...)
        if InCombatLockdown() then return false end
        if not model or type(model[method]) ~= "function" then return Fail(method .. " unavailable.") end
        local ok, result = pcall(model[method], model, ...)
        if not ok then return Fail(method .. ": " .. tostring(result)) end
        return true, result
    end

    -- Reloading the verified display restores natural idle after a selling/test sequence.
    function frame:Load()
        if InCombatLockdown() or not self:IsShown() or self.failed then return false end
        self.ready, self.loading, self.playing = false, false, false
        if not Call("ClearModel") then return false end
        self.loading = true
        if onStatus then onStatus("Loading display 6882...") end
        return Call("SetDisplayInfo", 6882)
    end

    -- Native completion can repeat only cosmetic animation, never selling or inventory work.
    local function RequestAnimation()
        if not frame.ready or not frame.active or not frame:IsShown() or frame.failed then return end
        if InCombatLockdown() then frame:Hide(); return end
        frame.playing, frame.requesting = true, true
        local ok = Call("SetAnimation", 50, 0)
        frame.requesting = false
        if not ok then frame.playing = false end
    end

    -- Resize native model bounds and normalized decoration together, deferring combat writes.
    function frame:SetViewportSize(value)
        local size = JunkGoblinSize(value)
        if InCombatLockdown() then return false end
        if self.viewportSize == size then return true end
        self.viewportSize = size
        self:SetSize(size, size)
        for _, piece in ipairs(pieces) do
            piece.texture:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", piece.x * size, piece.y * size)
            piece.texture:SetSize(piece.width * size, piece.height * size)
        end
        if self.ready and self:IsShown() then
            return Call("RefreshCamera") and Call("SetPortraitZoom", 0)
                and Call("SetCamDistanceScale", self.distance)
        end
        return true
    end

    -- Read the saved camera distance without resetting the native pose or animation.
    function frame:SetDistance(value)
        value = JunkGoblinDistance(value)
        if self.distance == value then return end
        self.distance = value
        if self.ready and self:IsShown() then Call("SetCamDistanceScale", value) end
    end

    -- Accept only presentation intent; preview and merchant callers own separate instances.
    function frame:SetActive(active)
        if InCombatLockdown() then self:Hide(); return false end
        if self.failed then return false end
        self.active = active == true
        if not self.ready then
            if not self.loading then self:Load() end
        elseif self.active and not self.playing then
            if Call("SetPaused", false) then RequestAnimation() end
        elseif not self.active and self.playing then
            self:Load()
        end
        return not self.failed
    end

    frame:SetScript("OnShow", function() border:Show() end)
    frame:SetScript("OnHide", function(self)
        self.ready, self.loading, self.active, self.playing, self.requesting = false, false, false, false, false
        border:Hide()
        -- No native model writes during combat; a later show always reloads before playback.
        if model and not InCombatLockdown() then
            if type(model.SetPaused) == "function" then pcall(model.SetPaused, model, true) end
            if type(model.ClearModel) == "function" then pcall(model.ClearModel, model) end
        end
    end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:SetScript("OnEvent", function(self) self:Hide() end)

    local ok, result = pcall(CreateFrame, "PlayerModel", nil, frame)
    if not ok then Fail("PlayerModel unavailable: " .. tostring(result)); return frame end
    model = result
    model:SetAllPoints(frame)
    model:SetFrameLevel(frame:GetFrameLevel() + 1)
    model:EnableMouse(false)
    Call("SetScript", "OnModelLoaded", function()
        if not frame.loading or frame.failed or not frame:IsShown() then return end
        frame.loading = false
        if InCombatLockdown() then frame:Hide(); return end
        if not Call("RefreshCamera") or not Call("SetPortraitZoom", 0)
            or not Call("SetCamDistanceScale", frame.distance) or not Call("SetPosition", 0, 0, 0)
            or not Call("SetFacing", 0) or not Call("SetModelScale", 1)
            or not Call("SetPaused", false) then return end
        local queried, available = Call("HasAnimation", 50)
        if not queried then return end
        if available ~= true then Fail("Animation 50 unavailable; use 2D artwork."); return end
        frame.ready = true
        if onStatus then onStatus("Display loaded. Test playback is cosmetic only.") end
        frame:SetActive(frame.active)
    end)
    Call("SetScript", "OnAnimFinished", function()
        if not frame.active or not frame.playing or not frame.ready or not frame:IsShown() then return end
        if InCombatLockdown() then frame:Hide(); return end
        if frame.requesting then Fail("Reentrant animation completion; playback stopped."); return end
        if repeatAnimation then
            RequestAnimation()
        else
            frame.active = false
            frame:Load()
        end
    end)
    return frame
end

-- Reset only presentation; animation cleanup must never authorize a transaction.
local function ResetJunkSellAnimation()
    if not junkAnimationFrame then return end
    junkAnimationFrame.animation:Stop()
    local mode = junkAnimationModes[junkAnimationFrame.mode] or junkAnimationModes.goblin
    junkAnimationFrame.texture:SetTexCoord(0, 1 / mode.columns, 0, 1 / mode.rows)
end

-- Keep merchant artwork independent of the manual/batch button's visibility.
function OUS.UpdateJunkSellAnimation()
    if not junkAnimationFrame then return end
    local merchant = _G.MerchantFrame
    local db = OdysseusDB and OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not merchant or not IsUtilitiesEnabled() or not db or not db.enabled
        or not (isMerchantOpen or merchant:IsShown()) then
        if junkNativeFrame then junkNativeFrame:Hide() end
        ResetJunkSellAnimation()
        junkAnimationFrame:Hide()
        return
    end

    local active = isMerchantOpen and merchant:IsShown() and junkSaleActive
        and not junkSaleScheduled and not junkBatchWaiting and #junkPending > 0
        and not InCombatLockdown()
        and (not db.limitTo12 or batchSold < batchLimit)
    if db.nativeGoblin == true and not InCombatLockdown() then
        if not junkNativeFrame then
            junkNativeFrame = OUS.CreateJunkGoblinRenderer(merchant, true, function(_, failed)
                if failed and junkNativeFrame then OUS.UpdateJunkSellAnimation() end
            end)
            if junkNativeFrame then
                -- Grow below the merchant, leaving the approved button and vendor controls untouched.
                junkNativeFrame:SetPoint("TOPRIGHT", junkSellBtn, "TOPLEFT", -6, 0)
            end
        end
        if junkNativeFrame and not junkNativeFrame.failed then
            junkNativeFrame:SetViewportSize(db.nativeGoblinSize)
            junkNativeFrame:Show()
            junkNativeFrame:SetDistance(db.nativeGoblinDistance)
            if junkNativeFrame:SetActive(active) then
                ResetJunkSellAnimation()
                junkAnimationFrame:Hide()
                return
            end
        end
    end
    if junkNativeFrame then junkNativeFrame:Hide() end

    local key = db.animation == "coin" and "coin" or "goblin"
    local mode = junkAnimationModes[key]
    if junkAnimationFrame.mode ~= key then
        ResetJunkSellAnimation()
        junkAnimationFrame.mode = key
        junkAnimationFrame.texture:SetTexture("Interface\\AddOns\\OdysseusUtilitySuite\\media\\Textures\\" .. mode.file)
        junkAnimationFrame.texture:SetSize(mode.size, mode.size)
        local flipbook = junkAnimationFrame.flipbook
        flipbook:SetFlipBookRows(mode.rows)
        flipbook:SetFlipBookColumns(mode.columns)
        flipbook:SetFlipBookFrames(mode.frames)
        flipbook:SetDuration(mode.duration)
        junkAnimationFrame.texture:SetTexCoord(0, 1 / mode.columns, 0, 1 / mode.rows)
    end
    junkAnimationFrame:Show()

    if active then
        if not junkAnimationFrame.animation:IsPlaying() then
            junkAnimationFrame.texture:SetTexCoord(0, 1, 0, 1)
            junkAnimationFrame.animation:Play()
        end
    else
        ResetJunkSellAnimation()
    end
end

-- Visual preferences never run the settings path that can resume a waiting sale queue.
function OUS.ApplyJunkSellVisualSettings()
    if junkNativeFrame then junkNativeFrame.failed = false end
    OUS.UpdateJunkSellAnimation()
end

-- Reuse the proven probe FlipBook on an OUS-owned, noninteractive merchant child.
local function CreateJunkSellAnimation()
    if junkAnimationFrame then return end
    junkAnimationFrame = CreateFrame("Frame", nil, _G.MerchantFrame)
    junkAnimationFrame:SetSize(36, 38)
    junkAnimationFrame:SetPoint("RIGHT", junkSellBtn, "LEFT", -6, 0)
    junkAnimationFrame:SetFrameStrata(junkSellBtn:GetFrameStrata())
    junkAnimationFrame:EnableMouse(false)
    junkAnimationFrame:Hide()

    -- Frame the sprite without clipping its motion or changing its display size.
    local backing = junkAnimationFrame:CreateTexture(nil, "BACKGROUND")
    backing:SetAllPoints()
    backing:SetColorTexture(0.035, 0.025, 0.06, 0.98)
    local inset = junkAnimationFrame:CreateTexture(nil, "BORDER")
    inset:SetPoint("TOPLEFT", 2, -2)
    inset:SetPoint("BOTTOMRIGHT", -2, 2)
    inset:SetColorTexture(0.075, 0.055, 0.11, 1)
    for i, points in ipairs({
        {"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
        {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"},
    }) do
        local border = junkAnimationFrame:CreateTexture(nil, "OVERLAY")
        border:SetPoint(points[1])
        border:SetPoint(points[2])
        if i <= 2 then border:SetHeight(1) else border:SetWidth(1) end
        border:SetColorTexture(0.5, 0.3, 0.7, 0.9)
    end

    local texture = junkAnimationFrame:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("CENTER")
    junkAnimationFrame.texture = texture
    junkAnimationFrame.animation = texture:CreateAnimationGroup()
    junkAnimationFrame.animation:SetLooping("REPEAT")
    local flipbook = junkAnimationFrame.animation:CreateAnimation("FlipBook")
    flipbook:SetOrder(1)
    flipbook:SetSmoothing("NONE")
    flipbook:SetFlipBookFrameWidth(0)
    flipbook:SetFlipBookFrameHeight(0)
    junkAnimationFrame.flipbook = flipbook
    junkAnimationFrame:SetScript("OnHide", ResetJunkSellAnimation)
    junkAnimationFrame:SetScript("OnShow", OUS.UpdateJunkSellAnimation)
end

-- Match the FlightMaster tooltip palette without changing merchant geometry or actions.
local function StyleJunkSellButton(button)
    local media = LibStub and LibStub("LibSharedMedia-3.0", true)
    local texture = media and media:Fetch("statusbar", "Blizzard") or "Interface\\TargetingFrame\\UI-StatusBar"
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.05, 0.1, 1)

    local function CreateFace(r, g, b)
        local face = button:CreateTexture(nil, "ARTWORK")
        face:SetPoint("TOPLEFT", 1, -1)
        face:SetPoint("BOTTOMRIGHT", -1, 1)
        face:SetTexture(texture)
        face:SetVertexColor(r, g, b)
        return face
    end
    button:SetNormalTexture(CreateFace(0.18, 0.15, 0.25))
    button:SetPushedTexture(CreateFace(0.09, 0.07, 0.14))
    button:SetDisabledTexture(CreateFace(0.10, 0.10, 0.12))
    local highlight = CreateFace(0.45, 0.30, 0.65)
    highlight:SetAlpha(0.3)
    button:SetHighlightTexture(highlight, "ADD")

    for i, points in ipairs({
        {"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
        {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"},
    }) do
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetPoint(points[1])
        border:SetPoint(points[2])
        if i <= 2 then border:SetHeight(1) else border:SetWidth(1) end
        border:SetColorTexture(0.5, 0.3, 0.7, 1)
    end

    button.actionText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.actionText:SetPoint("TOPLEFT", 6, -5)
    button.actionText:SetPoint("TOPRIGHT", -6, -5)
    button.actionText:SetHeight(14)
    button.actionText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    button.actionText:SetJustifyH("CENTER")
    button.actionText:SetWordWrap(false)
    button.countText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.countText:SetPoint("TOPLEFT", button.actionText, "BOTTOMLEFT", 0, -1)
    button.countText:SetPoint("TOPRIGHT", button.actionText, "BOTTOMRIGHT", 0, -1)
    button.countText:SetHeight(12)
    button.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    button.countText:SetJustifyH("CENTER")
    button.countText:SetWordWrap(false)

    local function SetEnabledColors()
        button.actionText:SetTextColor(0.94, 0.90, 1)
        button.countText:SetTextColor(0.72, 0.68, 0.82)
    end
    button:SetScript("OnEnable", SetEnabledColors)
    button:SetScript("OnDisable", function()
        button.actionText:SetTextColor(0.48, 0.47, 0.53)
        button.countText:SetTextColor(0.40, 0.39, 0.45)
    end)
    SetEnabledColors()
end

-- Keep the merchant action available only for configured manual/batched selling.
function OUS.UpdateJunkSellButton()
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not junkSellBtn and IsUtilitiesEnabled() and db and db.enabled
        and _G.MerchantFrame and _G.MerchantFrame:IsShown() then
        EnsureJunkSellPresentation()
    end
    OUS.UpdateJunkSellAnimation()
    if not junkSellBtn then return end
    if not isMerchantOpen or not IsUtilitiesEnabled() or not db or not db.enabled
        or #junkPending == 0 or not (db.limitTo12 or db.requireShift) then
        junkSellBtn:Hide()
        return
    end
    junkSellBtn.actionText:SetText(junkSaleActive and "Selling..." or (db.limitTo12 and "Sell Next 12" or "Sell All Junk"))
    junkSellBtn.countText:SetText(string.format("(%d left)", #junkPending))
    junkSellBtn:Show()
end

-- Invalidate timer ownership without changing merchant transactions or preferences.
local function CancelJunkSelling()
    junkSaleGeneration = junkSaleGeneration + 1
    junkBatchWaiting = false
    junkSaleActive = false
    junkSaleScheduled = false
    isMerchantOpen = false
    junkPending = {}
    if junkSellBtn then junkSellBtn:Hide() end
    if junkAnimationFrame then
        ResetJunkSellAnimation()
        junkAnimationFrame:Hide()
    end
    if junkNativeFrame then
        junkNativeFrame:Hide()
        junkNativeFrame.failed = false
    end
end

-- Apply master-toggle changes immediately; artwork retains its combat deferral.
function OUS.ApplyUtilitiesModuleSetting()
    if not IsUtilitiesEnabled() then CancelJunkSelling() end
    OUS.UpdateJunkSellButton()
    OUS.ApplyExtraActionArtworkSetting()
end

--- Sells one item from junkPending then schedules the next via timer.
local function SellNextItem(generation)
    if generation ~= junkSaleGeneration then return end
    local settings = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not IsUtilitiesEnabled() or not settings or not settings.enabled then
        CancelJunkSelling()
        return
    end
    if not isMerchantOpen then return end
    if InCombatLockdown() or not MerchantFrame:IsShown() then
        junkSaleActive = false
        OUS.UpdateJunkSellButton()
        return
    end
    if #junkPending == 0 then
        -- All done — announce and keep the merchant action available
        local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
        if db and batchSold > 0 and db.announceJunk then
            print(string.format("|cffA78BFA[OUS]:|r Sold %d junk item(s) for %s",
                batchQuantity, FormatCost(batchCopper)))
        end
        junkSaleActive = false
        OUS.UpdateJunkSellButton()
        batchSold     = 0
        batchQuantity = 0
        batchCopper   = 0
        return
    end

    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return end

    -- Batch limit reached — announce and show button for remainder
    if db.limitTo12 and batchSold >= batchLimit then
        if db.announceJunk and batchSold > 0 then
            print(string.format("|cffA78BFA[OUS]:|r Sold %d junk item(s) for %s",
                batchQuantity, FormatCost(batchCopper)))
        end
        junkBatchWaiting = true
        junkSaleActive = false
        OUS.UpdateJunkSellButton()
        batchSold     = 0
        batchQuantity = 0
        batchCopper   = 0
        return
    end

    -- Price the current bag instance rather than the queued ItemID template.
    -- Blacklist already applied in CollectJunkItems, no rescan needed
    local item = table.remove(junkPending, 1)
    if item then
        local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
        local sellPrice = info and info.itemID == item.itemID and info.hyperlink
            and select(11, C_Item.GetItemInfo(info.hyperlink))
        if sellPrice and sellPrice > 0 then
            local stackCount = (info and info.stackCount) or 1
            local proceeds = sellPrice * stackCount
            local itemIDSellPrice, bagTooltipPrice, bagTooltipMaxPrice
            -- Retain the old price and whole-stack tooltip value for post-fix A/B diagnostics.
            if OUS.IsDebugModeOn() then
                itemIDSellPrice = select(11, C_Item.GetItemInfo(item.itemID))
                local tooltipData = C_TooltipInfo.GetBagItem(item.bag, item.slot)
                for _, line in ipairs(tooltipData and tooltipData.lines or {}) do
                    if line.type == Enum.TooltipDataLineType.SellPrice then
                        bagTooltipPrice = line.price
                        bagTooltipMaxPrice = line.maxPrice
                        break
                    end
                end
            end
            -- Pair this observed wallet with the notification snapshot to diagnose sale-call ordering.
            local walletBeforeSale = GetMoney()
            C_Container.UseContainerItem(item.bag, item.slot)
            batchSold = batchSold + 1
            batchQuantity = batchQuantity + stackCount
            batchCopper = batchCopper + proceeds
            RecordSessionMerchantTransaction("VENDOR_INCOME", proceeds, {
                itemCount = 1,
                stackCount = stackCount,
                itemID = item.itemID,
                walletBeforeSale = walletBeforeSale,
                itemLink = info and info.hyperlink,
                itemIDSellPrice = itemIDSellPrice,
                linkSellPrice = sellPrice,
                bagTooltipPrice = bagTooltipPrice,
                bagTooltipMaxPrice = bagTooltipMaxPrice,
            })
            if db.detailedSaleReport and isMerchantOpen then
                print(string.format("|cffA78BFA[OUS]:|r %s x%d = %s",
                    info.hyperlink, stackCount, FormatCost(proceeds)))
            end
        else
            OUS.LogDebug("Utilities", "Skipped junk slot with changed item or unavailable positive bag-link price: " .. item.bag .. ":" .. item.slot)
        end
    end

    OUS.UpdateJunkSellButton()

    -- Schedule next item after 0.2s delay
    C_Timer.After(0.2, function() SellNextItem(generation) end)
end

--- Starts selling the current batch — entry point.
local function SellNextBatch()
    if not IsUtilitiesEnabled() then CancelJunkSelling(); return end
    if not isMerchantOpen then return end
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db or not db.enabled then CancelJunkSelling(); return end
    if InCombatLockdown() or (db.requireShift and not IsShiftKeyDown()) then
        OUS.UpdateJunkSellButton()
        return
    end
    junkBatchWaiting = false
    junkSaleActive = true
    junkSaleScheduled = false
    batchSold     = 0
    batchQuantity = 0
    batchCopper   = 0
    junkSaleGeneration = junkSaleGeneration + 1
    SellNextItem(junkSaleGeneration)
end

-- Also allow idle artwork when the seller is enabled after a merchant opens.
EnsureJunkSellPresentation = function()
    if not junkSellBtn then
        junkSellBtn = CreateFrame("Button", "OUSJunkSellBtn", MerchantFrame)
        junkSellBtn:SetSize(120, 38)
        junkSellBtn:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", -1, 1)
        StyleJunkSellButton(junkSellBtn)
        junkSellBtn:SetScript("OnClick", SellNextBatch)
    end
    CreateJunkSellAnimation()
end

-- Start a waiting queue only when its confirmation requirement has been removed.
function OUS.ApplyJunkSellSettings()
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not IsUtilitiesEnabled() or not db or not db.enabled then CancelJunkSelling() end
    OUS.UpdateJunkSellButton()
    if isMerchantOpen and #junkPending > 0 and not junkSaleActive and db and not db.requireShift
        and (not junkBatchWaiting or not db.limitTo12) then
        SellNextBatch()
    end
end

--- Entry point called on MERCHANT_SHOW.
local function OnMerchantShow()
    CancelJunkSelling()
    if not IsUtilitiesEnabled() then return end
    local db = OdysseusDB.utilities and OdysseusDB.utilities.junkSell
    if not db then return end
    if not db.enabled then return end
    isMerchantOpen = true
    junkPending = CollectJunkItems()

    EnsureJunkSellPresentation()
    OUS.UpdateJunkSellButton()

    -- Auto-sell unless Shift is required
    if db.requireShift and not IsShiftKeyDown() then
        return
    end

    local generation = junkSaleGeneration
    junkSaleActive = true
    junkSaleScheduled = true
    OUS.UpdateJunkSellButton()
    C_Timer.After(0.3, function()
        if generation == junkSaleGeneration then
            junkSaleActive = false
            junkSaleScheduled = false
            SellNextBatch()
        end
    end)
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
junkFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
junkFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
junkFrame:SetScript("OnEvent", function(_, event, _, msg)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "MERCHANT_CLOSED" then
        CancelJunkSelling()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        OUS.UpdateJunkSellAnimation()
    elseif event == "UI_ERROR_MESSAGE" then
        -- Stop selling if vendor refuses or gold cap reached
        if msg == ERR_VENDOR_DOESNT_BUY or msg == ERR_TOO_MUCH_GOLD then
            CancelJunkSelling()
        end
    end
end)
