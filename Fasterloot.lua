local addonName, OUS = ...
local f = CreateFrame("Frame")

f:RegisterEvent("LOOT_READY")
f:SetScript("OnEvent", function(self, event, autoLootTriggeredByGame)
    -- 1. GATEKEEPER: Check if the module is enabled in the General tab
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.fasterLoot then return end

    -- 2. SUITE COMMUNICATION: Yield to the Fishing Tracker!
    if IsFishingLoot and IsFishingLoot() then return end

    -- 3. Determine if the player WANTS to auto-loot right now
    local isModifierDown = IsModifiedClick("AUTOLOOTTOGGLE")
    local isAutoLootOn = C_CVar.GetCVarBool("autoLootDefault") or GetCVarBool("autoLootDefault")
    
    local shouldFastLoot = autoLootTriggeredByGame or (isAutoLootOn ~= isModifierDown)

    if shouldFastLoot then
        local numItems = GetNumLootItems()
        if numItems == 0 then return end

        -- NEW: Check for general-purpose bag space (ignoring specialized/reagent bags)
        local freeSlots = 0
        local getFreeSlots = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
        if getFreeSlots then
            -- Bags 0-4 are the standard inventory bags
            for b = 0, 4 do
                local free, bagFamily = getFreeSlots(b)
                -- bagFamily == 0 ensures we only count universal slots, ignoring reagent/profession bags!
                if free and (not bagFamily or bagFamily == 0) then
                    freeSlots = freeSlots + free
                end
            end
        end

        local inGroup = IsInGroup() or IsInRaid()
        local lootMethod = GetLootMethod and GetLootMethod() or "personal"
        local lootThreshold = GetLootThreshold and GetLootThreshold() or 2
        
        -- THE FIX: Leave window open if we have 1 or fewer GENERAL free slots!
        local itemsLeftBehind = (freeSlots <= 1)

        -- Loop backwards to prevent slot-shifting bugs when items are removed
        for i = numItems, 1, -1 do
            local slotType = GetLootSlotType(i)
            local canLoot = true

            -- If it is a standard item, we must run the Group/Raid checks
            if slotType == 1 then -- 1 translates to LOOT_SLOT_ITEM
                local _, _, _, _, quality, locked = GetLootSlotInfo(i)
                
                -- Rule A: Cannot auto-loot locked items
                if locked then
                    canLoot = false
                end
                
                -- Rule B: Respect Group/Raid Loot Rules and Thresholds
                if inGroup and quality and quality >= lootThreshold then
                    if lootMethod == "master" or lootMethod == "group" or lootMethod == "needbeforegreed" then
                        canLoot = false
                    end
                end
            end

            -- If it passed the checks, grab it instantly!
            if canLoot and (slotType == 1 or slotType == 2) then -- 2 is LOOT_SLOT_MONEY
                LootSlot(i)
            else
                -- Flag that an item was skipped so the window stays open
                itemsLeftBehind = true
            end
        end
        
        -- Aggressively hide the visual loot frame ONLY if we safely looted everything
        if not itemsLeftBehind and LootFrame and LootFrame:IsShown() then
            LootFrame:Hide()
        end
    end
end)