-- ==========================================
-- ODYSSEUS UTILITY SUITE: OPENABLES MODULE
-- ==========================================
local addonName, OUS = ...

OUS.Openables = {}
local OP = OUS.Openables

-- Session blacklist — cleared on reload, not persisted
local sessionBlacklist = {}

-- Currently displayed item: { itemID, bag, slot, icon, count }
local currentItem = nil

-- Debounce timer for bag scans
local scanPending = false

-- Lock state
local isLocked = false

-- Forward reference — defined in section 4
local pendingItemLoad = {}

-- ==========================================
-- COLLECTION FILTER CACHE
-- ==========================================

local function IsPetCollected(itemID)
    local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID))
    if not speciesID then return false end
    return C_PetJournal.GetNumCollectedInfo(speciesID) > 0
end

-- Returns true if item should be skipped due to collection state
-- Tracks itemIDs where GetMountFromItem returned nil — retried after item load
local pendingMountCheck = {}

local function IsAlreadyCollected(itemID, category, bag, slot)
    if category == "mount" then
        local mountID = C_MountJournal.GetMountFromItem(itemID)
        if not mountID then
            if not pendingMountCheck[itemID] then
                pendingMountCheck[itemID] = true
                local item = Item:CreateFromItemID(itemID)
                item:ContinueOnItemLoad(function()
                    pendingMountCheck[itemID] = nil
                    OP.Refresh()
                end)
            end
            return false
        end
        local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
        return isCollected == true
    elseif category == "pet" then
        return IsPetCollected(itemID)
    elseif category == "toy" then
        return PlayerHasToy(itemID)
    elseif category == "recipe" then
        -- First try TradeSkillUI — only trust it for non-generic spells
        local _, spellID = C_Item.GetItemSpell(itemID)
        if spellID then
            local recipeInfo = C_TradeSkillUI.GetRecipeInfo(spellID)
            if recipeInfo and recipeInfo.name and recipeInfo.name ~= "Learning" then
                return recipeInfo.learned == true
            end
        end
        -- Fallback: tooltip scan for "Already Known" line
        if bag and slot then
            local data = C_TooltipInfo.GetBagItem(bag, slot)
            if data and data.lines then
                for _, line in ipairs(data.lines) do
                    if line.leftText == ITEM_SPELL_KNOWN then
                        return true
                    end
                end
                return false
            end
            -- Tooltip not ready yet — schedule rescan and show for now
            if not pendingMountCheck[itemID] then
                pendingMountCheck[itemID] = true
                C_Timer.After(2, function()
                    pendingMountCheck[itemID] = nil
                    OP.Refresh()
                end)
            end
        end
        return false
    end
    return false
end

-- ==========================================
-- CATEGORY SYSTEM
-- ==========================================
local CATEGORY_COLORS = {
    mount     = {0.75, 0.20, 1.00},  -- purple
    pet       = {0.20, 0.60, 1.00},  -- blue
    toy       = {0.20, 1.00, 0.20},  -- green
    cache     = {1.00, 0.82, 0.00},  -- gold
    knowledge = {1.00, 0.50, 0.10},  -- orange
    currency  = {0.60, 0.60, 0.60},  -- grey
    recipe    = {1.00, 0.40, 0.40},  -- pink-red
    generic   = {1.00, 0.82, 0.00},  -- gold (same as cache, no badge)
}

local CATEGORY_BADGES = {
    mount     = "M",
    pet       = "P",
    toy       = "T",
    cache     = nil,   -- no badge
    knowledge = "K",
    currency  = "G",
    recipe    = "R",
    generic   = nil,   -- no badge
}

-- Explicit category overrides for known itemIDs
-- Format: [itemID] = "category"
local CATEGORY_OVERRIDES = {
    -- Pets
    [ 82800] = "pet",    -- Pet Cage
    [118697] = "cache",  -- Pet Supplies
    [122535] = "cache",  -- Traveler's Pet Supplies
    [142447] = "cache",  -- Torn Sack of Pet Supplies
    [221495] = "cache",  -- TWW pet cage (opens to reveal pet, no learn spell)
}

-- Category sets by itemID range / known sets
local MOUNT_ITEMS = {}   -- populated below if needed; mostly handled by spell check later
local PET_ITEMS   = {}  -- dynamic via C_PetJournal.GetPetInfoByItemID
local TOY_ITEMS   = {}
local KNOWLEDGE_ITEMS = {
    [224982]=true,  -- Delver's Dirigible Schematic
    [263467]=true,  -- Avid Learner's Supply Pack
    -- DF profession knowledge
    [198614]=true,[198675]=true,[198689]=true,[198694]=true,
    [198799]=true,[198800]=true,[198798]=true,[210234]=true,[210231]=true,
    [200939]=true,[200940]=true,[200941]=true,[200942]=true,[200943]=true,
    [200944]=true,[200945]=true,[200946]=true,[200947]=true,
    [201356]=true,[201357]=true,[201358]=true,[201359]=true,
    -- TWW knowledge
    [217707]=true,[226258]=true,
}
local CURRENCY_ITEMS = {
    -- Crest pouches TWW 11.0
    [221268]=true,[221373]=true,[220767]=true,[221375]=true,[220773]=true,[220776]=true,
    -- Crest pouches TWW 11.1
    [231153]=true,[231270]=true,[231154]=true,[231269]=true,[231264]=true,[231267]=true,
    -- Sparks
    [211297]=true,[230905]=true,[231757]=true,
    -- Gallybux (tier currency)
    [228802]=true,[228806]=true,[228810]=true,[228814]=true,[228818]=true,
    -- TWW 11.2 tier tokens
    [237592]=true,[237588]=true,[237596]=true,[237584]=true,[237600]=true,
    -- TWW 11.0 tier tokens
    [225617]=true,[225621]=true,[225625]=true,[225629]=true,[225633]=true,
}

local function GetItemCategory(itemID)
    if CATEGORY_OVERRIDES[itemID] then
        return CATEGORY_OVERRIDES[itemID]
    end
    if PET_ITEMS[itemID] then return "pet" end
    if TOY_ITEMS[itemID] then return "toy" end
    if KNOWLEDGE_ITEMS[itemID] then return "knowledge" end
    if CURRENCY_ITEMS[itemID] then return "currency" end
    -- Check mount journal
    if C_MountJournal.GetMountFromItem(itemID) then return "mount" end
    -- Check toy collection
    if C_ToyBox.GetToyInfo(itemID) then return "toy" end
    -- Check pet journal
    if C_PetJournal.GetPetInfoByItemID(itemID) then return "pet" end
    -- Check recipe class (classID 9) — no DB needed
    -- Return positions: name,link,quality,iLevel,reqLevel,class,subclass,maxStack,equipSlot,icon,vendorPrice,classID
    local _, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(itemID)
    if classID == Enum.ItemClass.Recipe then return "recipe" end
    if classID == nil and not pendingItemLoad[itemID] then
        pendingItemLoad[itemID] = true
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            pendingItemLoad[itemID] = nil
            OP.Refresh()
        end)
    end
    -- User-added or generic cache
    return "cache"
end

-- ==========================================
-- 1. DATABASE HELPERS
-- ==========================================

-- Returns true if itemID is in any blacklist.
local function IsBlacklisted(itemID)
    if sessionBlacklist[itemID] then return true end
    local db = OdysseusDB and OdysseusDB.openables
    if db and db.blacklist and db.blacklist[itemID] then return true end
    return false
end

-- Returns minQuantity for itemID from DB or custom list, or nil if not openable.
local function GetOpenableMinQty(itemID)
    if not itemID then return nil end
    -- Check custom user list first
    local db = OdysseusDB and OdysseusDB.openables
    if db and db.customItems and db.customItems[itemID] then
        return db.customItems[itemID]
    end
    -- Check built-in DB
    if OUS.OpenablesDB and OUS.OpenablesDB[itemID] then
        return OUS.OpenablesDB[itemID]
    end
    return nil
end

-- ==========================================
-- 2. BAG SCANNER
-- ==========================================

-- Scans all bags and returns the first valid openable item found.
local function FindOpenableItem()
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemID = info.itemID
                if not IsBlacklisted(itemID) then
                    local cat = GetItemCategory(itemID)
                    local minQty = GetOpenableMinQty(itemID)
                    -- Recipes bypass minQty (not in DB) — all others need DB entry
                    if (minQty and info.stackCount >= minQty) or cat == "recipe" then
                        if C_PlayerInfo.CanUseItem(itemID) then
                            if not IsAlreadyCollected(itemID, cat, bag, slot) then
                                return {
                                    itemID   = itemID,
                                    bag      = bag,
                                    slot     = slot,
                                    icon     = info.iconFileID,
                                    count    = info.stackCount,
                                    category = cat,
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ==========================================
-- 3. BUTTON
-- ==========================================

-- opContainer: the draggable parent — invisible, 64x64 to fit the border
-- opBtn: the clickable button — 40x40, centered inside the container
-- Border textures live on the container so they never clip against the button

local opContainer = CreateFrame("Frame", "OdysseusOpenablesContainer", UIParent, "BackdropTemplate")
opContainer:SetSize(64, 64)
opContainer:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
opContainer:SetFrameStrata("MEDIUM")
opContainer:SetMovable(true)
opContainer:EnableMouse(false)  -- transparent to mouse — opBtn handles everything
opContainer:Hide()

-- Clickable button — 40x40 centered, mouse-passthrough for drag events
local opBtn = CreateFrame("Button", "OdysseusOpenablesButton", opContainer, "SecureActionButtonTemplate,BackdropTemplate")
opBtn:SetNormalTexture("")
opBtn:SetPushedTexture("")
opBtn:SetHighlightTexture("")
opBtn:SetDisabledTexture("")
opBtn:SetSize(40, 40)
opBtn:SetPoint("CENTER", opContainer, "CENTER", 0, 0)
opBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown", "RightButtonUp")
opBtn:EnableMouse(true)

-- Border on the button
opBtn:SetBackdrop({
    bgFile   = nil,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileEdge = true,
    edgeSize = 16,
    insets   = { left = -6, right = -6, top = -6, bottom = -6 }
})
opBtn:SetBackdropBorderColor(1, 0.82, 0, 1)

-- Icon inset so corners sit inside the border
local opIcon = opBtn:CreateTexture(nil, "BACKGROUND")
opIcon:SetPoint("TOPLEFT", opBtn, "TOPLEFT", 2, -2)
opIcon:SetPoint("BOTTOMRIGHT", opBtn, "BOTTOMRIGHT", -2, 2)
opIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Count text
local opCount = opBtn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
opCount:SetPoint("BOTTOMRIGHT", opBtn, "BOTTOMRIGHT", -2, 2)

-- Category badge — lower left, hidden for generic/cache
local opBadge = opBtn:CreateFontString(nil, "OVERLAY")
opBadge:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
opBadge:SetPoint("BOTTOMLEFT", opBtn, "BOTTOMLEFT", 2, 2)
opBadge:Hide()

-- Cooldown frame on button
local opCooldown = CreateFrame("Cooldown", nil, opBtn, "CooldownFrameTemplate")
opCooldown:SetAllPoints()
opCooldown:SetDrawEdge(false)
opCooldown:SetDrawBling(false)

-- Drag handle — shown when unlocked, replaces the button
local dragHandle = CreateFrame("Frame", "OdysseusOpenablesDragHandle", opContainer, "BackdropTemplate")
dragHandle:SetPoint("CENTER", opContainer, "CENTER", 0, 0)
dragHandle:SetSize(40, 40)
dragHandle:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
dragHandle:SetBackdropColor(0.1, 0.1, 0.3, 0.9)
dragHandle:SetBackdropBorderColor(0.5, 0.5, 1, 1)

local dragIcon = dragHandle:CreateTexture(nil, "ARTWORK")
dragIcon:SetSize(24, 24)
dragIcon:SetPoint("CENTER", dragHandle, "CENTER", 0, 6)
dragIcon:SetTexture("Interface\\Cursor\\UI-Cursor-Move")

local dragLabel = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragLabel:SetPoint("CENTER", dragHandle, "CENTER", 0, -10)
dragLabel:SetText("drag")
dragLabel:SetTextColor(0.7, 0.7, 1)
dragHandle:Hide()

-- Drag on container — active only when unlocked
local dragOffsetX, dragOffsetY = 0, 0
opContainer:SetScript("OnDragStart", function(self)
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local bx, by = self:GetCenter()
    dragOffsetX = bx - cx
    dragOffsetY = by - cy
    self:SetScript("OnUpdate", function()
        local s = UIParent:GetEffectiveScale()
        local mx, my = GetCursorPosition()
        mx, my = mx / s, my / s
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mx + dragOffsetX, my + dragOffsetY)
    end)
end)
opContainer:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    local point, _, relPoint, x, y = self:GetPoint(1)
    if OdysseusDB and OdysseusDB.openables then
        OdysseusDB.openables.x = x
        OdysseusDB.openables.y = y
        OdysseusDB.openables.point = point
        OdysseusDB.openables.relPoint = relPoint
    end
end)

opBtn:HookScript("OnEnter", function() opBtn:SetBackdropBorderColor(1, 1, 0.7, 1) end)
opBtn:HookScript("OnLeave", function() opBtn:SetBackdropBorderColor(1, 0.82, 0, 1) end)

opBtn:SetScript("OnEnter", function(self)
    if not currentItem then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(currentItem.bag, currentItem.slot)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Open/Use", 0, 1, 0)
    GameTooltip:AddLine("Right-click: Skip (session)", 0, 1, 0)
    GameTooltip:AddLine("Shift+Right-click: Blacklist permanently", 1, 0.5, 0)
    GameTooltip:Show()
end)
opBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

opBtn:SetScript("PostClick", function(self, button)
    if not currentItem then return end
    if InCombatLockdown() then return end
    if button == "RightButton" then
        if IsShiftKeyDown() then
            local db = OdysseusDB and OdysseusDB.openables
            if db then
                db.blacklist[currentItem.itemID] = true
                local name = C_Item.GetItemNameByID(currentItem.itemID) or tostring(currentItem.itemID)
                print("|cFF00CCFFOdysseus Openables:|r |cFFFF8800" .. name .. "|r permanently blacklisted. Use /op list to manage.")
            end
        else
            sessionBlacklist[currentItem.itemID] = true
            local name = C_Item.GetItemNameByID(currentItem.itemID) or tostring(currentItem.itemID)
            print("|cFF00CCFFOdysseus Openables:|r |cFFFFFF00" .. name .. "|r skipped for this session.")
        end
        currentItem = nil
        OP.Refresh()
    end
end)

-- Updates the button display from currentItem.
local function UpdateButton()
    if not currentItem then
        opContainer:Hide()
        opBtn:Hide()
        opBtn:SetBackdropBorderColor(1, 0.82, 0, 1)  -- restore default gold
        opBadge:Hide()
        return
    end
    if InCombatLockdown() then
        opContainer:Hide()
        opBtn:Hide()
        return
    end
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.openables then
        opContainer:Hide()
        return
    end
    opBtn:Show()

    opIcon:SetTexture(currentItem.icon)
    opCount:SetText(currentItem.count > 1 and currentItem.count or "")
    opBtn:SetAttribute("type", "macro")
    opBtn:SetAttribute("macrotext", string.format("/use item:%d", currentItem.itemID))

    -- Category border color and badge
    local cat = currentItem.category or "generic"
    local col = CATEGORY_COLORS[cat] or CATEGORY_COLORS.generic
    opBtn:SetBackdropBorderColor(col[1], col[2], col[3], 1)

    local badge = CATEGORY_BADGES[cat]
    if badge then
        opBadge:SetText(badge)
        opBadge:SetTextColor(col[1], col[2], col[3], 1)
        opBadge:Show()
    else
        opBadge:Hide()
    end

    local start, duration = C_Container.GetContainerItemCooldown(currentItem.bag, currentItem.slot)
    if start and start > 0 then
        opCooldown:SetCooldown(start, duration)
    else
        opCooldown:SetCooldown(0, 0)
    end

    opContainer:Show()
end

-- Restores saved position.
local function ApplyPosition()
    local db = OdysseusDB and OdysseusDB.openables
    if not db then return end
    opContainer:ClearAllPoints()
    opContainer:SetPoint(
        db.point    or "CENTER",
        UIParent,
        db.relPoint or "CENTER",
        db.x        or 300,
        db.y        or 0
    )
    local s = db.scale or 1.0
    opContainer:SetSize(64 * s, 64 * s)
    opBtn:SetSize(40 * s, 40 * s)
    dragHandle:SetSize(40 * s, 40 * s)
    isLocked = db.locked or false
    if isLocked then
        opContainer:SetMovable(false)
        opContainer:EnableMouse(false)
        opContainer:RegisterForDrag()
        dragHandle:Hide()
    else
        opContainer:SetMovable(true)
        opContainer:EnableMouse(true)
        opContainer:RegisterForDrag("LeftButton")
        opBtn:Hide()
        dragHandle:Show()
        opContainer:Show()
    end
end

local function SetLocked(state)
    isLocked = state
    if OdysseusDB and OdysseusDB.openables then
        OdysseusDB.openables.locked = state
    end
    if state then
        opContainer:SetMovable(false)
        opContainer:EnableMouse(false)
        opContainer:RegisterForDrag()
        dragHandle:Hide()
        opBtn:Show()
        if not currentItem then opContainer:Hide() end
        print("|cFF00CCFFOdysseus Openables:|r Button |cFFFF8800locked|r.")
    else
        opContainer:SetMovable(true)
        opContainer:EnableMouse(true)
        opContainer:RegisterForDrag("LeftButton")
        opBtn:Hide()
        dragHandle:Show()
        opContainer:Show()
        print("|cFF00CCFFOdysseus Openables:|r Button |cFF00FF00unlocked|r — drag to reposition, /op lock when done.")
    end
end

-- ==========================================
-- 4. REFRESH LOGIC
-- ==========================================

-- Rescans bags and updates button. Called after bag events.
function OP.Refresh()
    if InCombatLockdown() then return end
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.openables then
        opContainer:Hide()
        return
    end

    currentItem = FindOpenableItem()
    UpdateButton()

    -- Auto-open if enabled and item found
    local db = OdysseusDB and OdysseusDB.openables
    if db and db.autoOpen and currentItem then
        C_Timer.After(0.3, function()
            if currentItem and not InCombatLockdown() then
                C_Container.UseContainerItem(currentItem.bag, currentItem.slot)
            end
        end)
    end
end

-- Debounced refresh — avoids spamming scans on BAG_UPDATE.
local function DebouncedRefresh()
    if scanPending then return end
    scanPending = true
    C_Timer.After(1.5, function()
        scanPending = false
        OP.Refresh()
    end)
end

-- ==========================================
-- 5. EVENT HANDLER
-- ==========================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ITEM_LOCK_CHANGED")
frame:RegisterEvent("NEW_MOUNT_ADDED")
frame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize DB
        OdysseusDB.openables = OdysseusDB.openables or {
            autoOpen  = false,
            blacklist = {},
            customItems = {},
            x         = 300,
            y         = 0,
            point     = "CENTER",
            relPoint  = "CENTER",
            locked    = false,
            scale     = 1.0,
        }
        ApplyPosition()

    elseif event == "PLAYER_ENTERING_WORLD" then
        ApplyPosition()
        C_Timer.After(4, function()
            OP.Refresh()
        end)

    elseif event == "BAG_UPDATE_DELAYED" then
        DebouncedRefresh()

    elseif event == "PLAYER_REGEN_DISABLED" then
        opContainer:Hide()
        opBtn:Hide()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Rescan after combat
        C_Timer.After(0.5, OP.Refresh)

    elseif event == "ITEM_LOCK_CHANGED" then
        C_Timer.After(1, OP.Refresh)

    elseif event == "NEW_MOUNT_ADDED"
        or event == "MOUNT_JOURNAL_USABILITY_CHANGED"
        or event == "PET_JOURNAL_LIST_UPDATE" then
        wipe(pendingMountCheck)
        OP.Refresh()
    end
end)

-- ==========================================
-- 6. SLASH COMMANDS
-- ==========================================

-- Opens the blacklist management frame.
local blFrame
local function OpenBlacklistFrame()
    if blFrame then
        if blFrame:IsShown() then blFrame:Hide() else blFrame:Show() end
        return
    end

    blFrame = CreateFrame("Frame", "OdysseusOpenablesListFrame", UIParent, "BackdropTemplate")
    blFrame:SetSize(300, 350)
    blFrame:SetPoint("CENTER")
    blFrame:SetFrameStrata("DIALOG")
    blFrame:SetMovable(true)
    blFrame:EnableMouse(true)
    blFrame:RegisterForDrag("LeftButton")
    blFrame:SetScript("OnDragStart", blFrame.StartMoving)
    blFrame:SetScript("OnDragStop", blFrame.StopMovingOrSizing)
    blFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    blFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
    blFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

    local title = blFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cFF00FFFFOpenables Blacklist|r")

    local closeBtn = CreateFrame("Button", nil, blFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() blFrame:Hide() end)

    -- ScrollFrame for entries
    local scrollFrame = CreateFrame("ScrollFrame", nil, blFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(260, 1)
    scrollFrame:SetScrollChild(content)

    -- Clear All button
    local clearBtn = CreateFrame("Button", nil, blFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 24)
    clearBtn:SetPoint("BOTTOMLEFT", 10, 12)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_CLEAR_OPENABLES_BL")
    end)

    StaticPopupDialogs["ODYSSEUS_CONFIRM_CLEAR_OPENABLES_BL"] = {
        text = "Clear the entire Openables permanent blacklist?",
        button1 = "Clear",
        button2 = "Cancel",
        OnAccept = function()
            local db = OdysseusDB and OdysseusDB.openables
            if db then
                db.blacklist = {}
                blFrame:Hide()
                print("|cFF00CCFFOdysseus Openables:|r Blacklist cleared.")
                OP.Refresh()
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    -- Populate rows
    local rows = {}
    local function PopulateList()
        -- Hide all rows
        for _, row in ipairs(rows) do row:Hide() end
        local db = OdysseusDB and OdysseusDB.openables
        if not db or not db.blacklist then return end

        -- Pre-load all item names, then rebuild
        -- Pre-request uncached items, retry after 1s
        local needsRetry = false
        for itemID in pairs(db.blacklist) do
            if not C_Item.GetItemNameByID(itemID) then
                needsRetry = true
                Item:CreateFromItemID(itemID)
            end
        end
        if needsRetry then
            C_Timer.After(1, function()
                if blFrame:IsShown() then PopulateList() end
            end)
            return
        end

        local y = 0
        for itemID in pairs(db.blacklist) do
            local row = rows[#rows + 1] or CreateFrame("Frame", nil, content)
            rows[#rows] = row
            row:SetSize(255, 24)
            row:SetPoint("TOPLEFT", 0, -y)
            row:Show()

            -- Item name
            if not row.label then
                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.label:SetPoint("LEFT", 4, 0)
                row.label:SetWidth(180)
                row.label:SetJustifyH("LEFT")
            end
            local name = C_Item.GetItemNameByID(itemID) or ("ID: " .. itemID)
            row.label:SetText(name)

            -- Remove button
            if not row.removeBtn then
                row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.removeBtn:SetSize(60, 20)
                row.removeBtn:SetPoint("RIGHT", -2, 0)
                row.removeBtn:SetText("Remove")
            end
            local id = itemID
            row.removeBtn:SetScript("OnClick", function()
                db.blacklist[id] = nil
                PopulateList()
                OP.Refresh()
            end)

            y = y + 26
        end
        content:SetHeight(math.max(y, 1))
    end

    blFrame:SetScript("OnShow", function()
        PopulateList()
        C_Timer.After(0.5, function()
            if blFrame:IsShown() then PopulateList() end
        end)
    end)
    blFrame:Show()
end

-- Opens the custom items management frame.
local clFrame
local function OpenCustomListFrame()
    if clFrame then
        if clFrame:IsShown() then clFrame:Hide() else clFrame:Show() end
        return
    end

    clFrame = CreateFrame("Frame", "OdysseusOpenablesCustomListFrame", UIParent, "BackdropTemplate")
    clFrame:SetSize(320, 350)
    clFrame:SetPoint("CENTER")
    clFrame:SetFrameStrata("DIALOG")
    clFrame:SetMovable(true)
    clFrame:EnableMouse(true)
    clFrame:RegisterForDrag("LeftButton")
    clFrame:SetScript("OnDragStart", clFrame.StartMoving)
    clFrame:SetScript("OnDragStop", clFrame.StopMovingOrSizing)
    clFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    clFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
    clFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

    local title = clFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cFF00FFFFOpenables Custom List|r")

    local closeBtn = CreateFrame("Button", nil, clFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() clFrame:Hide() end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, clFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(275, 1)
    scrollFrame:SetScrollChild(content)

    local clearBtn = CreateFrame("Button", nil, clFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 24)
    clearBtn:SetPoint("BOTTOMLEFT", 10, 12)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_CLEAR_OPENABLES_CL")
    end)

    StaticPopupDialogs["ODYSSEUS_CONFIRM_CLEAR_OPENABLES_CL"] = {
        text = "Clear the entire Openables custom list?",
        button1 = "Clear",
        button2 = "Cancel",
        OnAccept = function()
            local db = OdysseusDB and OdysseusDB.openables
            if db then
                db.customItems = {}
                clFrame:Hide()
                print("|cFF00CCFFOdysseus Openables:|r Custom list cleared.")
                OP.Refresh()
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    local rows = {}
    local function PopulateCustomList()
        for _, row in ipairs(rows) do row:Hide() end
        local db = OdysseusDB and OdysseusDB.openables
        if not db or not db.customItems then return end

        -- Pre-request uncached items, retry after 1s
        local needsRetry = false
        for itemID in pairs(db.customItems) do
            if not C_Item.GetItemNameByID(itemID) then
                needsRetry = true
                Item:CreateFromItemID(itemID)  -- triggers cache load
            end
        end
        if needsRetry then
            C_Timer.After(1, function()
                if clFrame:IsShown() then PopulateCustomList() end
            end)
            return
        end

        local y = 0
        local i = 0
        for itemID, qty in pairs(db.customItems) do
            i = i + 1
            if not rows[i] then
                rows[i] = CreateFrame("Frame", nil, content)
            end
            local row = rows[i]
            row:SetSize(270, 24)
            row:SetPoint("TOPLEFT", 0, -y)
            row:Show()

            if not row.label then
                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.label:SetPoint("LEFT", 4, 0)
                row.label:SetWidth(155)
                row.label:SetJustifyH("LEFT")
                row.label:SetWordWrap(false)
            end
            local name = C_Item.GetItemNameByID(itemID) or ("ID: " .. itemID)
            row.label:SetText(name)

            -- Remove button

            if not row.qty then
                row.qty = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                row.qty:SetPoint("LEFT", row.label, "RIGHT", 4, 0)
                row.qty:SetWidth(30)
                row.qty:SetJustifyH("CENTER")
                row.qty:SetTextColor(1, 0.82, 0)
            end
            row.qty:SetText("x" .. qty)

            if not row.removeBtn then
                row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.removeBtn:SetSize(60, 20)
                row.removeBtn:SetPoint("RIGHT", -2, 0)
                row.removeBtn:SetText("Remove")
            end
            local id = itemID
            row.removeBtn:SetScript("OnClick", function()
                db.customItems[id] = nil
                PopulateCustomList()
                OP.Refresh()
            end)

            y = y + 26
        end
        content:SetHeight(math.max(y, 1))
    end

    clFrame:SetScript("OnShow", PopulateCustomList)
    clFrame:Show()
end

-- Main slash handler
function OP.SlashHandler(msg)
    local db = OdysseusDB and OdysseusDB.openables
    if not db then return end

    local command, arg1, arg2 = msg:match("^(%S+)%s*(%S*)%s*(.*)$")
    if not command then command = "help" end
    command = command:lower()

    if command == "add" then
        local itemID = tonumber(arg1)
        local minQty = tonumber(arg2) or 1
        if not itemID then
            print("|cFFFF0000[Openables]|r Usage: /op add <itemID> [minQuantity]")
            return
        end
        db.customItems[itemID] = minQty
        local name = C_Item.GetItemNameByID(itemID) or tostring(itemID)
        print("|cFF00CCFFOdysseus Openables:|r Added |cFFFFD100" .. name .. "|r (min qty: " .. minQty .. ")")
        OP.Refresh()

    elseif command == "remove" then
        local itemID = tonumber(arg1)
        if not itemID then
            print("|cFFFF0000[Openables]|r Usage: /op remove <itemID>")
            return
        end
        if db.customItems[itemID] then
            db.customItems[itemID] = nil
            local name = C_Item.GetItemNameByID(itemID) or tostring(itemID)
            print("|cFF00CCFFOdysseus Openables:|r Removed |cFFFFD100" .. name .. "|r from custom list.")
            OP.Refresh()
        else
            print("|cFFFF0000[Openables]|r ItemID " .. itemID .. " not found in custom list.")
        end

    elseif command == "list" then
        OpenBlacklistFrame()

    elseif command == "clist" then
        OpenCustomListFrame()

    elseif command == "madd" then
        OP.OpenMassAddFrame()

    elseif command == "lock" then
        SetLocked(true)

    elseif command == "unlock" then
        SetLocked(false)

    elseif command == "auto" then
        db.autoOpen = not db.autoOpen
        print("|cFF00CCFFOdysseus Openables:|r Auto-open " .. (db.autoOpen and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
        if db.autoOpen then OP.Refresh() end

    elseif command == "unblacklist" then
        local itemID = tonumber(arg1)
        if not itemID then
            print("|cFFFF0000[Openables]|r Usage: /op unblacklist <itemID>")
            return
        end
        if db.blacklist[itemID] then
            db.blacklist[itemID] = nil
            local name = C_Item.GetItemNameByID(itemID) or tostring(itemID)
            print("|cFF00CCFFOdysseus Openables:|r |cFFFFD100" .. name .. "|r removed from blacklist.")
            OP.Refresh()
        else
            print("|cFFFF0000[Openables]|r ItemID " .. itemID .. " not in permanent blacklist.")
        end

    elseif command == "status" then
        print("|cFF00CCFFOdysseus Openables Status:|r")
        print("  Enabled: " .. (OdysseusDB.modules.openables and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
        print("  Auto-open: " .. (db.autoOpen and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
        local customCount = 0
        for _ in pairs(db.customItems) do customCount = customCount + 1 end
        local blCount = 0
        for _ in pairs(db.blacklist) do blCount = blCount + 1 end
        print("  Custom items: " .. customCount)
        print("  Blacklisted: " .. blCount)
        if currentItem then
            local name = C_Item.GetItemNameByID(currentItem.itemID) or tostring(currentItem.itemID)
            print("  Current item: " .. name)
        else
            print("  Current item: None")
        end

    elseif command == "help" then
        print("|cFF00CCFFOdysseus Openables Commands:|r")
        print("  /op add <itemID> [qty] — Add item to custom list")
        print("  /op remove <itemID> — Remove from custom list")
        print("  /op unblacklist <itemID> — Remove from permanent blacklist")
        print("  /op list — Open blacklist management frame")
        print("  /op clist — Open custom items management frame")
        print("  /op madd — Open drag-and-drop item add frame")
        print("  /op auto — Toggle auto-open")
        print("  /op lock / unlock — Lock/unlock button position")
        print("  /op status — Show current settings")

    else
        print("|cFFFF0000[Openables]|r Unknown command. Type /op help.")
    end
end

-- ==========================================
-- 7. MASS ADD FRAME (/op madd)
-- ==========================================

local maddFrame
function OP.OpenMassAddFrame()
    if maddFrame then
        if maddFrame:IsShown() then maddFrame:Hide() else maddFrame:Show() end
        return
    end

    -- Queued items: array of { itemID, qty, name, icon }
    local queue = {}
    -- Row widget pool
    local rows = {}

    maddFrame = CreateFrame("Frame", "OdysseusOpenablesMaddFrame", UIParent, "BackdropTemplate")
    maddFrame:SetSize(300, 420)
    maddFrame:SetPoint("CENTER")
    maddFrame:SetFrameStrata("DIALOG")
    maddFrame:SetMovable(true)
    maddFrame:EnableMouse(true)
    maddFrame:RegisterForDrag("LeftButton")
    maddFrame:SetScript("OnDragStart", maddFrame.StartMoving)
    maddFrame:SetScript("OnDragStop", maddFrame.StopMovingOrSizing)
    maddFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    maddFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
    maddFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

    -- Title
    local title = maddFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cFF00FFFFAdd Openable Items|r")

    local closeBtn = CreateFrame("Button", nil, maddFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() maddFrame:Hide() end)

    -- ----------------------------------------
    -- DROP ZONE (top, self-contained frame)
    -- ----------------------------------------
    local dropZone = CreateFrame("Frame", nil, maddFrame, "BackdropTemplate")
    dropZone:SetSize(268, 50)
    dropZone:SetPoint("TOPLEFT", 10, -30)
    dropZone:EnableMouse(true)
    dropZone:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropZone:SetBackdropColor(0.08, 0.08, 0.18, 0.9)
    dropZone:SetBackdropBorderColor(0.3, 0.3, 0.6, 1)

    local dzText = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dzText:SetPoint("CENTER")
    dzText:SetTextColor(0.5, 0.5, 0.7)
    dzText:SetText("Drop item here to add to queue")

    -- ----------------------------------------
    -- SCROLL LIST (middle)
    -- ----------------------------------------
    local listLabel = maddFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listLabel:SetPoint("TOPLEFT", 12, -88)
    listLabel:SetTextColor(0.7, 0.5, 1)
    listLabel:SetText("QUEUED ITEMS")

    local scrollFrame = CreateFrame("ScrollFrame", nil, maddFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -102)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 46)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(255)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    -- ----------------------------------------
    -- ROW BUILDER
    -- ----------------------------------------
    local function RebuildRows()
        -- Hide all pooled rows
        for _, row in ipairs(rows) do row:Hide() end

        local y = 0
        for i, entry in ipairs(queue) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Frame", nil, content, "BackdropTemplate")
                row:SetSize(252, 30)
                row:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    tile = false, edgeSize = 1,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 }
                })
                row:SetBackdropColor(0.18, 0.10, 0.28, 0.85)
                row:SetBackdropBorderColor(0.35, 0.20, 0.50, 0.8)

                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(22, 22)
                row.icon:SetPoint("LEFT", 4, 0)
                row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
                row.label:SetWidth(120)
                row.label:SetJustifyH("LEFT")
                row.label:SetWordWrap(false)

                row.qtyBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                row.qtyBox:SetSize(36, 18)
                row.qtyBox:SetPoint("RIGHT", -36, 0)
                row.qtyBox:SetAutoFocus(false)
                row.qtyBox:SetNumeric(true)
                row.qtyBox:SetMaxLetters(4)

                row.removeBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
                row.removeBtn:SetSize(18, 18)
                row.removeBtn:SetPoint("RIGHT", -2, 0)

                rows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row.icon:SetTexture(entry.icon)
            row.label:SetText(entry.name)
            row.qtyBox:SetText(tostring(entry.qty))

            -- qty box saves back into queue entry
            local idx = i
            row.qtyBox:SetScript("OnEditFocusLost", function(self)
                queue[idx].qty = tonumber(self:GetText()) or 1
            end)
            row.qtyBox:SetScript("OnEnterPressed", function(self)
                queue[idx].qty = tonumber(self:GetText()) or 1
                self:ClearFocus()
            end)

            row.removeBtn:SetScript("OnClick", function()
                table.remove(queue, idx)
                RebuildRows()
            end)

            row:Show()
            y = y + 32
        end

        content:SetHeight(math.max(y, 1))

        -- Update Add All button state
        if maddFrame.addAllBtn then
            maddFrame.addAllBtn:SetEnabled(#queue > 0)
        end
    end

    -- ----------------------------------------
    -- ENQUEUE ITEM
    -- ----------------------------------------
    local function EnqueueItem(itemID)
        -- Don't add duplicates
        for _, entry in ipairs(queue) do
            if entry.itemID == itemID then
                print("|cFF00CCFFOdysseus Openables:|r Item already in queue.")
                return
            end
        end

        local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
        if not name then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                EnqueueItem(itemID)
            end)
            return
        end

        -- Check if already in custom or built-in DB
        local db = OdysseusDB and OdysseusDB.openables
        local existingQty = 1
        if db and db.customItems and db.customItems[itemID] then
            existingQty = db.customItems[itemID]
        elseif OUS.OpenablesDB and OUS.OpenablesDB[itemID] then
            existingQty = OUS.OpenablesDB[itemID]
        end

        table.insert(queue, { itemID = itemID, qty = existingQty, name = name, icon = icon })
        RebuildRows()
    end

    -- ----------------------------------------
    -- DROP HANDLERS
    -- ----------------------------------------
    dropZone:SetScript("OnReceiveDrag", function()
        local infoType, itemID = GetCursorInfo()
        if infoType == "item" and itemID then
            ClearCursor()
            EnqueueItem(itemID)
        end
    end)
    dropZone:SetScript("OnMouseDown", function()
        local infoType, itemID = GetCursorInfo()
        if infoType == "item" and itemID then
            ClearCursor()
            EnqueueItem(itemID)
        end
    end)

    -- ----------------------------------------
    -- BOTTOM BUTTONS
    -- ----------------------------------------
    local addAllBtn = CreateFrame("Button", nil, maddFrame, "UIPanelButtonTemplate")
    addAllBtn:SetSize(100, 24)
    addAllBtn:SetPoint("BOTTOMLEFT", 14, 12)
    addAllBtn:SetText("Add All")
    addAllBtn:SetEnabled(false)
    maddFrame.addAllBtn = addAllBtn

    addAllBtn:SetScript("OnClick", function()
        local db = OdysseusDB and OdysseusDB.openables
        if not db then return end
        local count = 0
        for _, entry in ipairs(queue) do
            -- Commit qty from editbox in case focus wasn't lost
            local row = rows[count + 1]
            if row then
                entry.qty = tonumber(row.qtyBox:GetText()) or entry.qty
            end
            db.customItems[entry.itemID] = entry.qty
            count = count + 1
        end
        print("|cFF00CCFFOdysseus Openables:|r Added |cFFFFD100" .. count .. "|r item(s) to custom list.")
        queue = {}
        RebuildRows()
        OP.Refresh()
    end)

    local clearQueueBtn = CreateFrame("Button", nil, maddFrame, "UIPanelButtonTemplate")
    clearQueueBtn:SetSize(80, 24)
    clearQueueBtn:SetPoint("LEFT", addAllBtn, "RIGHT", 6, 0)
    clearQueueBtn:SetText("Clear")
    clearQueueBtn:SetScript("OnClick", function()
        queue = {}
        RebuildRows()
    end)

    local cancelBtn = CreateFrame("Button", nil, maddFrame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(70, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    cancelBtn:SetText("Close")
    cancelBtn:SetScript("OnClick", function() maddFrame:Hide() end)

    maddFrame:Show()
end

-- ==========================================
-- 8. PUBLIC API (for Config.lua)
-- ==========================================

-- Exposes refresh for config toggles.
function OUS.Openables.UpdateDisplay()
    OP.Refresh()
end
