-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Fasterloot.lua
-- Version : 2026.05.29
-- Desc    : Auto-loot module
-- ============================================================

-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: FASTER LOOT
-- ==========================================
local addonName, OUS = ...
local f = CreateFrame("Frame")

-- ==========================================
-- 2. THE INVISIBLE GARAGE (FRAME HIJACKING)
-- ==========================================
local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

local isHidden = true
local lootTicker = nil

-- The Magic Hook: Stop Blizzard's Edit Mode from stealing our hidden frame!
if LootFrame then
    LootFrame:SetParent(hiddenFrame)
    if LootFrame.UpdateShownState then
        hooksecurefunc(LootFrame, "UpdateShownState", function(self)
            if isHidden and not self.isInEditMode then
                self:SetParent(hiddenFrame)
            end
        end)
    end
end

local function ShowLootFrame()
    isHidden = false
    if LootFrame then
        LootFrame:SetParent(UIParent)
        LootFrame:SetFrameStrata("HIGH")
    end
end

local function HideLootFrame()
    isHidden = true
    if LootFrame then
        LootFrame:SetParent(hiddenFrame)
    end
end

-- ==========================================
-- 3. THE LOOT ENGINE (EVENT HANDLER)
-- ==========================================
f:RegisterEvent("LOOT_READY")
f:RegisterEvent("LOOT_CLOSED")
f:RegisterEvent("UI_ERROR_MESSAGE")

f:SetScript("OnEvent", function(self, event, ...)
    -- 1. MODULE CHECK: Is FasterLoot enabled?
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fasterLoot then
        ShowLootFrame()
        return
    end

    -- 2. CLEANUP: Hide the window for the NEXT kill
    if event == "LOOT_CLOSED" then
        if lootTicker then
            lootTicker:Cancel()
            lootTicker = nil
        end
        HideLootFrame()
        if OUS.LogDebug then
            OUS.LogDebug("FasterLoot", "Corpse closed. Hidden frame reset.")
        end
        return
    end

    -- 3. ERROR DETECTION: Reveal window if bags are full
    if event == "UI_ERROR_MESSAGE" then
        local errorType, msg = ...
        if msg == ERR_INV_FULL or msg == ERR_ITEM_MAX_COUNT then
            if lootTicker then
                lootTicker:Cancel()
                lootTicker = nil
            end
            if OUS.LogDebug then
                OUS.LogDebug("FasterLoot", "Inventory Full or Max Count reached! Yielding UI.")
            end
            ShowLootFrame()
        end
        return
    end

    -- 4. THE CORE LOOT LOGIC
    if event == "LOOT_READY" then
        local autoLootTriggeredByGame = ...

        -- SUITE COMMUNICATION: Yield to the Fishing Tracker!
        if IsFishingLoot and IsFishingLoot() then
            if OUS.LogDebug then
                OUS.LogDebug("FasterLoot", "Bobber detected. Yielding to Fishing Tracker.")
            end
            ShowLootFrame()
            return
        end

        local isModifierDown = IsModifiedClick("AUTOLOOTTOGGLE")
        local isAutoLootOn = C_CVar.GetCVarBool("autoLootDefault") or GetCVarBool("autoLootDefault")

        -- Fast loot if the game already triggered autoloot, or if the player's current modifier/CVar state resolves to autoloot.
        local shouldFastLoot = autoLootTriggeredByGame or (isAutoLootOn ~= isModifierDown)

        if not shouldFastLoot then
            -- The player intentionally DOES NOT want to auto-loot.
            if OUS.LogDebug then
                OUS.LogDebug("FasterLoot", "Manual loot requested. Revealing window.")
            end
            ShowLootFrame()
            return
        end

        local numItems = GetNumLootItems()
        if numItems == 0 then return end

        local inGroup = IsInGroup() or IsInRaid()
        local lootMethod = GetLootMethod and GetLootMethod() or "personal"
        local lootThreshold = GetLootThreshold and GetLootThreshold() or 2
        local itemsLeftBehind = false

        if lootTicker then
            lootTicker:Cancel()
            lootTicker = nil
        end

        -- Ensure it stays locked in the invisible frame while processing
        HideLootFrame()
        if OUS.LogDebug then
            OUS.LogDebug("FasterLoot", string.format("Processing %d items invisibly...", numItems))
        end

        -- Server Throttling Ticker (0.033 seconds per item)
        local currentSlot = numItems
        lootTicker = C_Timer.NewTicker(0.033, function()
            if currentSlot >= 1 then
                local slotType = GetLootSlotType(currentSlot)
                local canLoot = true

                -- Check standard items for locks and group rules
                if slotType == 1 then
                    local _, _, _, _, quality, locked = GetLootSlotInfo(currentSlot)

                    if locked then
                        canLoot = false
                        if OUS.LogDebug then
                            OUS.LogDebug("FasterLoot", "Locked item detected in slot " .. currentSlot)
                        end
                    end

                    if inGroup and quality and quality >= lootThreshold then
                        if lootMethod == "master" or lootMethod == "group" or lootMethod == "needbeforegreed" then
                            canLoot = false
                            if OUS.LogDebug then
                                OUS.LogDebug("FasterLoot", "Group roll required for slot " .. currentSlot)
                            end
                        end
                    end
                end

                -- Prevent trying to loot empty slots
                if slotType == 0 then
                    canLoot = false
                end

                -- Execute Loot or Flag as left behind
                if canLoot then
                    LootSlot(currentSlot)
                else
                    itemsLeftBehind = true
                end

                currentSlot = currentSlot - 1
            else
                -- Ticker finished: Check if anything was left behind
                if itemsLeftBehind or GetNumLootItems() > 0 then
                    if OUS.LogDebug then
                        OUS.LogDebug("FasterLoot", "Items left behind (Roll/Locked/Full). Revealing window.")
                    end
                    ShowLootFrame()
                else
                    CloseLoot()
                end

                if lootTicker then
                    lootTicker:Cancel()
                    lootTicker = nil
                end
            end
        end, numItems + 1)
    end
end)