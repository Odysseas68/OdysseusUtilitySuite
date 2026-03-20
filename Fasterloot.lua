local addonName, OUS = ...
local f = CreateFrame("Frame")

-- SPEEDY'S SECRET: The Invisible Garage
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

f:RegisterEvent("LOOT_READY")
f:RegisterEvent("LOOT_CLOSED")
f:RegisterEvent("UI_ERROR_MESSAGE")

f:SetScript("OnEvent", function(self, event, ...)
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fasterLoot then
        ShowLootFrame()
        return
    end

    -- Cleanup and hide the window for the NEXT kill
    if event == "LOOT_CLOSED" then
        if lootTicker then
            lootTicker:Cancel()
            lootTicker = nil
        end
        HideLootFrame()
        return
    end

    -- ERROR DETECTION: Immediately reveal window if bags are full
    if event == "UI_ERROR_MESSAGE" then
        local errorType, msg = ...
        if msg == ERR_INV_FULL or msg == ERR_ITEM_MAX_COUNT then
            ShowLootFrame()
        end
        return
    end

    if event == "LOOT_READY" then
        local autoLootTriggeredByGame = ...
        
        -- SUITE COMMUNICATION: Yield to the Fishing Tracker!
        if IsFishingLoot and IsFishingLoot() then 
            ShowLootFrame()
            return 
        end

        local isModifierDown = IsModifiedClick("AUTOLOOTTOGGLE")
        local isAutoLootOn = C_CVar.GetCVarBool("autoLootDefault") or GetCVarBool("autoLootDefault")
        local shouldFastLoot = autoLootTriggeredByGame or (isAutoLootOn ~= isModifierDown)

        if not shouldFastLoot then
            -- If the player intentionally DOES NOT want to auto-loot, show the window!
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
        end

        -- Ensure it stays locked in the invisible frame while processing
        HideLootFrame()

        -- Server Throttling Ticker (0.033 seconds per item)
        local currentSlot = numItems
        lootTicker = C_Timer.NewTicker(0.033, function()
            if currentSlot >= 1 then
                local slotType = GetLootSlotType(currentSlot)
                local canLoot = true

                -- If slot is a standard item, check group rules
                if slotType == 1 then
                    local _, _, _, _, quality, locked = GetLootSlotInfo(currentSlot)
                    if locked then canLoot = false end
                    if inGroup and quality and quality >= lootThreshold then
                        if lootMethod == "master" or lootMethod == "group" or lootMethod == "needbeforegreed" then
                            canLoot = false
                        end
                    end
                end

                -- Prevent trying to loot empty slots
                if slotType == 0 then
                    canLoot = false
                end

                if canLoot then
                    LootSlot(currentSlot)
                else
                    itemsLeftBehind = true
                end

                currentSlot = currentSlot - 1
            else
                -- Ticker finished: Check if anything was left behind
                if itemsLeftBehind or GetNumLootItems() > 0 then
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