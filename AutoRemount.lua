-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: AUTO REMOUNT ENGINE
-- ==========================================
local addonName, OUS = ...

OUS.AutoRemount = {}
local AR = OUS.AutoRemount

-- Module state
local isGathering = false
local isTryingToMount = false
local lootWindowOpened = false
local noLootTimer = nil
local pendingSpySpellID = nil  -- tracks last unknown spell waiting for loot confirmation

-- ==========================================
-- 2. HELPERS
-- ==========================================

-- Strips WoW link formatting from a mount name dragged into chat.
local function CleanMountName(name)
    if not name then return nil end
    local linkName = name:match("|h%[(.+)%]|h")
    name = linkName or name
    name = name
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|H.-|h", "")
        :gsub("[%[%]]", "")
        :match("^%s*(.-)%s*$")
    return name
end

-- Finds a collected mount ID by exact name match.
local function FindMountIDByName(searchName)
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local name, _, _, _, _, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and name == searchName then
            return mountID, name
        end
    end
    return nil
end

-- Returns true if the player is in a dungeon or raid (not delves).
local function IsInRestrictedInstance()
    local _, instanceType = IsInInstance()
    return instanceType == "party" or instanceType == "raid"
end

-- Returns true if spellID is in the master spell list.
local function IsKnownGatherSpell(spellID)
    return spellID and OUS.AutoRemountSpells and OUS.AutoRemountSpells[spellID] or false
end

-- Returns true if spellID is in the custom spell list.
local function IsInCustomSpells(spellID)
    local custom = OdysseusDB.autoRemount.customSpells
    if not custom then return false end
    for _, id in ipairs(custom) do
        if id == spellID then return true end
    end
    return false
end

-- Returns true if spellID is in either known or custom list.
local function IsGatherSpell(spellID)
    return IsKnownGatherSpell(spellID) or IsInCustomSpells(spellID)
end

-- Returns true if spellID is in the permanent exclude list.
local function IsExcludedSpell(spellID)
    return spellID and OUS.AutoRemountExcludeSpells and OUS.AutoRemountExcludeSpells[spellID] or false
end

-- Returns true if spellID is already in the discovered spy list.
local function IsInDiscoveredSpells(spellID)
    local discovered = OdysseusDB.autoRemount.discoveredSpells
    if not discovered then return false end
    for _, entry in ipairs(discovered) do
        if entry.id == spellID then return true end
    end
    return false
end

-- Returns true if spellID is in the persisted spy filter blacklist.
local function IsSpyBlacklisted(spellID)
    local filter = OdysseusDB.autoRemount.spyFilter
    if not filter then return false end
    for _, id in ipairs(filter) do
        if id == spellID then return true end
    end
    return false
end

-- Returns true if the player currently has a profession crafting UI open.
local function IsProfessionCraftingContext()
    if ProfessionsFrame and ProfessionsFrame:IsShown() then return true end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then return true end
    return false
end

-- Returns true if all safety conditions allow remounting.
local function CanRemount()
    local db = OdysseusDB.autoRemount
    if not db.enabled then return false end
    if IsMounted() then return false end
    if IsFlying() then return false end
    if InCombatLockdown() then return false end
    if UnitIsDeadOrGhost("player") then return false end
    if IsInRestrictedInstance() then return false end
    if IsProfessionCraftingContext() then
        OUS.LogDebug("AutoRemount", "Remount skipped — profession crafting context detected.")
        return false
    end

    -- Skip druids in any shapeshift form (Travel Form etc.)
    if db.skipDruid then
        local _, class = UnitClass("player")
        if class == "DRUID" and GetShapeshiftForm() ~= 0 then
            return false
        end
    end

    return true
end

-- ==========================================
-- 3. MOUNT LOGIC
-- ==========================================

-- Resolves mount ID: character override → account → favourite (0).
local function GetMountID()
    local charDB = OdysseusCharDB.autoRemountChar
    local db = OdysseusDB.autoRemount
    return charDB.mountID or db.accountMountID or 0
end

local function TryRemount()
    if not CanRemount() then
        OUS.LogDebug("AutoRemount", "Remount skipped — safety check failed.")
        return
    end

    local mountID = GetMountID()
    OUS.LogDebug("AutoRemount", "Attempting remount. mountID: " .. tostring(mountID))

    isTryingToMount = true
    C_MountJournal.SummonByID(mountID)

    -- Clear flag after 2s whether or not an error fired.
    C_Timer.After(2, function()
        isTryingToMount = false
    end)
end

-- Cancels the no-loot fallback timer if it's running.
local function CancelNoLootTimer()
    if noLootTimer then
        noLootTimer:Cancel()
        noLootTimer = nil
    end
end

-- Confirms a pending spy spell after loot trigger — prints to chat and adds to spy frame.
local function ConfirmSpySpell()
    if not pendingSpySpellID then return end
    if not OdysseusDB.autoRemount.spyMode then return end

    local spellID = pendingSpySpellID
    pendingSpySpellID = nil

    -- Silently ignore excluded spells.
    if IsExcludedSpell(spellID) then return end

    -- Also ignore if already in custom list.
    if IsInCustomSpells(spellID) then return end

    local spellName = C_Spell.GetSpellName(spellID) or "Unknown"

    -- Add to spy frame discovered list if not already there.
    if not IsInDiscoveredSpells(spellID) then
        if not OdysseusDB.autoRemount.discoveredSpells then
            OdysseusDB.autoRemount.discoveredSpells = {}
        end
        table.insert(OdysseusDB.autoRemount.discoveredSpells, {
            id   = spellID,
            name = spellName,
        })
        if OUS.AutoRemount and OUS.AutoRemount.RefreshSpyFrame then
            OUS.AutoRemount.RefreshSpyFrame()
        end
    end

    -- Print to chat.
    print("|cFF00CCFFOdysseus AutoRemount Spy:|r Loot-confirmed: "
        .. spellName .. " (" .. tostring(spellID) .. ") — /ar add "
        .. tostring(spellID) .. " to track | /ar spyfilter add "
        .. tostring(spellID) .. " to exclude")
end

-- Starts the no-loot fallback timer after a gather spell with no loot window.
local function StartNoLootTimer()
    CancelNoLootTimer()
    local delay = OdysseusDB.autoRemount.delay or 0.5
    noLootTimer = C_Timer.NewTimer(1.5 + delay, function()
        noLootTimer = nil
        if not lootWindowOpened and isGathering then
            OUS.LogDebug("AutoRemount", "No loot window detected — remounting via fallback.")
            -- Confirm spy spell via no-loot path (e.g. trap disarm)
            isGathering = false
            TryRemount()
        end
    end)
end

-- ==========================================
-- 4. SPY FRAME
-- ==========================================
local spyFrame = CreateFrame("Frame", "OdysseusAutoRemountSpyFrame", UIParent, "BackdropTemplate")
spyFrame:SetSize(420, 300)
spyFrame:SetPoint("CENTER")
spyFrame:SetFrameStrata("DIALOG")
spyFrame:Hide()
spyFrame:SetMovable(true)
spyFrame:EnableMouse(true)
spyFrame:RegisterForDrag("LeftButton")
spyFrame:SetScript("OnDragStart", spyFrame.StartMoving)
spyFrame:SetScript("OnDragStop", spyFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, spyFrame:GetName())

spyFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
spyFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
spyFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

-- Header bar
local spyHeaderBg = spyFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
spyHeaderBg:SetPoint("TOPLEFT", 4, -4)
spyHeaderBg:SetPoint("TOPRIGHT", -4, -4)
spyHeaderBg:SetHeight(28)
spyHeaderBg:SetColorTexture(1, 1, 1, 1)
spyHeaderBg:SetGradient("HORIZONTAL",
    CreateColor(0.3, 0.1, 0.5, 0.8),
    CreateColor(0.07, 0.05, 0.1, 0.8)
)

local spyTitle = spyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
spyTitle:SetPoint("TOP", spyFrame, "TOP", 0, -12)
spyTitle:SetText("|cFF00FFFFOdysseus AutoRemount|r — Custom Spell List")
spyTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

local spyCloseBtn = CreateFrame("Button", nil, spyFrame, "UIPanelCloseButton")
spyCloseBtn:SetPoint("TOPRIGHT", spyFrame, "TOPRIGHT", -2, -2)
spyCloseBtn:SetScript("OnClick", function() spyFrame:Hide() end)

-- ScrollingMessageFrame for clean list display
local spyMsgFrame = CreateFrame("ScrollingMessageFrame", nil, spyFrame)
spyMsgFrame:SetPoint("TOPLEFT", 10, -38)
spyMsgFrame:SetPoint("BOTTOMRIGHT", -10, 44)
spyMsgFrame:SetFontObject(GameFontNormalSmall)
spyMsgFrame:SetJustifyH("LEFT")
spyMsgFrame:SetFading(false)
spyMsgFrame:SetMaxLines(200)

-- Copy overlay
local spyCopyOverlay = CreateFrame("ScrollFrame", nil, spyFrame, "UIPanelScrollFrameTemplate")
spyCopyOverlay:SetPoint("TOPLEFT", 10, -38)
spyCopyOverlay:SetPoint("BOTTOMRIGHT", -30, 44)
spyCopyOverlay:Hide()

local spyCopyEditBox = CreateFrame("EditBox", nil, spyCopyOverlay)
spyCopyEditBox:SetMultiLine(true)
spyCopyEditBox:SetFontObject(GameFontNormalSmall)
spyCopyEditBox:SetWidth(360)
spyCopyEditBox:SetAutoFocus(false)
spyCopyOverlay:SetScrollChild(spyCopyEditBox)

-- Bottom buttons
local spyCopyBtn = CreateFrame("Button", nil, spyFrame, "UIPanelButtonTemplate")
spyCopyBtn:SetSize(100, 22)
spyCopyBtn:SetPoint("BOTTOMLEFT", 10, 12)
spyCopyBtn:SetText("Copy All")

local spyClearBtn = CreateFrame("Button", nil, spyFrame, "UIPanelButtonTemplate")
spyClearBtn:SetSize(80, 22)
spyClearBtn:SetPoint("LEFT", spyCopyBtn, "RIGHT", 8, 0)
spyClearBtn:SetText("Clear")

local spyCountText = spyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
spyCountText:SetPoint("BOTTOMRIGHT", spyFrame, "BOTTOMRIGHT", -14, 16)
spyCountText:SetTextColor(0.6, 0.6, 0.6)

StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE_SPY"] = {
    text = "Are you sure you want to clear all discovered spy spells? This cannot be undone.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        OdysseusDB.autoRemount.discoveredSpells = {}
        AR.RefreshSpyFrame()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Rebuilds the spy frame from persisted DB.
function AR.RefreshSpyFrame()
    spyCopyOverlay:Hide()
    spyMsgFrame:Show()
    spyCopyBtn:SetText("Copy All")
    spyMsgFrame:Clear()

    local discovered = OdysseusDB.autoRemount.discoveredSpells or {}
    for _, entry in ipairs(discovered) do
        spyMsgFrame:AddMessage(
            string.format("|cFFFFD100%-12s|r -- %s", entry.id .. ",", entry.name)
        )
    end

    local count = #discovered
    spyCountText:SetText(count .. " spell" .. (count == 1 and "" or "s") .. " discovered")
end

spyCopyBtn:SetScript("OnClick", function()
    if spyCopyOverlay:IsShown() then
        spyCopyOverlay:Hide()
        spyMsgFrame:Show()
        spyCopyBtn:SetText("Copy All")
    else
        local discovered = OdysseusDB.autoRemount.discoveredSpells or {}
        if #discovered == 0 then
            print("|cFF00CCFFOdysseus AutoRemount:|r No discovered spells to copy.")
            return
        end
        local lines = {}
        for _, entry in ipairs(discovered) do
            table.insert(lines, string.format("%-12s -- %s", entry.id .. ",", entry.name))
        end
        spyMsgFrame:Hide()
        spyCopyEditBox:SetText(table.concat(lines, "\n"))
        spyCopyOverlay:Show()
        spyCopyEditBox:HighlightText()
        spyCopyEditBox:SetFocus()
        spyCopyBtn:SetText("Back to List")
    end
end)

spyClearBtn:SetScript("OnClick", function()
    StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_SPY")
end)

-- ==========================================
-- 5. EVENT HANDLER
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" then return end

        if IsExcludedSpell(spellID) then
            pendingSpySpellID = nil  -- Clear any pending spy spell to prevent false confirmations
            OUS.LogDebug("AutoRemount", "Excluded spell ignored: " .. tostring(spellID))
        elseif IsGatherSpell(spellID) then
            -- Known gather spell — trigger remount path.
            isGathering = true
            lootWindowOpened = false
            pendingSpySpellID = nil
            OUS.LogDebug("AutoRemount", "Gather spell detected: " .. tostring(spellID))
            StartNoLootTimer()
        elseif OdysseusDB.autoRemount.spyMode and not IsSpyBlacklisted(spellID) then
            -- Spy mode: track unknown spell as pending but do NOT set isGathering.
            -- Only records if LOOT_CLOSED fires — no remount triggered.
            -- Blacklisted spellIDs are silently ignored.
            pendingSpySpellID = spellID
            OUS.LogDebug("AutoRemount", "Spy: watching unknown spell " .. tostring(spellID))
        end

    elseif event == "LOOT_OPENED" then
        if not isGathering then return end
        lootWindowOpened = true
        CancelNoLootTimer()
        OUS.LogDebug("AutoRemount", "Loot window opened — waiting for LOOT_CLOSED.")

    elseif event == "LOOT_CLOSED" then
        if pendingSpySpellID then
            ConfirmSpySpell()
        end

        if not isGathering then
            return
        end

        isGathering = false
        lootWindowOpened = false
        CancelNoLootTimer()

        local delay = OdysseusDB.autoRemount.delay or 0.5
        OUS.LogDebug("AutoRemount", "Loot closed after gather. Remounting in " .. delay .. "s.")
        C_Timer.After(delay, TryRemount)

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended — discard any pending spy spell to prevent
        -- combat spells being confirmed by subsequent loot windows.
        if pendingSpySpellID then
            OUS.LogDebug("AutoRemount", "Combat ended — discarding pending spy spell " .. tostring(pendingSpySpellID))
            pendingSpySpellID = nil
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if not isTryingToMount then return end
        local _, message = ...
        isTryingToMount = false
        if not OdysseusDB.autoRemount.silent then
            print("|cFF00CCFFOdysseus AutoRemount:|r " .. tostring(message))
        end
        OUS.LogDebug("AutoRemount", "Mount error: " .. tostring(message))
    end
end)

-- ==========================================
-- 6. SLASH COMMAND HANDLER
-- ==========================================

local function PrintStatus()
    local db = OdysseusDB.autoRemount
    local charDB = OdysseusCharDB.autoRemountChar

    local charMount = "|cFF888888None|r"
    if charDB.mountID then
        local name = C_MountJournal.GetMountInfoByID(charDB.mountID)
        charMount = name or "|cFFFF0000Unknown|r"
    end

    local acctMount = "|cFF888888None|r"
    if db.accountMountID then
        local name = C_MountJournal.GetMountInfoByID(db.accountMountID)
        acctMount = name or "|cFFFF0000Unknown|r"
    end

    local customCount = db.customSpells and #db.customSpells or 0
    local discoveredCount = db.discoveredSpells and #db.discoveredSpells or 0

    print("|cFF00CCFFOdysseus AutoRemount Status:|r")
    print("  Enabled: " .. (db.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Delay: " .. tostring(db.delay) .. "s")
    print("  Skip Druid: " .. (db.skipDruid and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Silent: " .. (db.silent and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Spy Mode: " .. (db.spyMode and "|cFFFFAA00ON|r" or "|cFF888888Off|r"))
    print("  Character Mount: " .. charMount)
    print("  Account Mount: " .. acctMount)
    print("  Fallback: |cFF888888Favourite mount (ID 0)|r")
    print("  Custom Spells: " .. customCount .. " added")
    print("  Discovered Spells: " .. discoveredCount .. " found")
end

function AR.SlashHandler(msg)
    local db = OdysseusDB.autoRemount
    local charDB = OdysseusCharDB.autoRemountChar
    local command, arg = msg:match("^(%S+)%s*(.*)$")
    if not command then command = "help" end
    command = command:lower()

    if command == "mount" then
        if arg == "" then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar mount <name>")
            return
        end
        local cleanName = CleanMountName(arg)
        local mountID, mountName = FindMountIDByName(cleanName)
        if mountID then
            charDB.mountID = mountID
            print("|cFF00CCFFOdysseus AutoRemount:|r Character mount set to " .. mountName)
        else
            print("|cFFFF0000[AutoRemount]|r Mount not found: " .. cleanName)
        end

    elseif command == "account" then
        if arg == "" then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar account <name>")
            return
        end
        local cleanName = CleanMountName(arg)
        local mountID, mountName = FindMountIDByName(cleanName)
        if mountID then
            db.accountMountID = mountID
            print("|cFF00CCFFOdysseus AutoRemount:|r Account mount set to " .. mountName)
        else
            print("|cFFFF0000[AutoRemount]|r Mount not found: " .. cleanName)
        end

    elseif command == "reset" then
        if arg:lower():match("^account") then
            db.accountMountID = nil
            print("|cFF00CCFFOdysseus AutoRemount:|r Account mount reset to favourite.")
        else
            charDB.mountID = nil
            print("|cFF00CCFFOdysseus AutoRemount:|r Character mount reset to account setting.")
        end

    elseif command == "toggle" then
        db.enabled = not db.enabled
        print("|cFF00CCFFOdysseus AutoRemount:|r " .. (db.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))

    elseif command == "enable" then
        db.enabled = true
        print("|cFF00CCFFOdysseus AutoRemount:|r |cFF00FF00Enabled|r")

    elseif command == "disable" then
        db.enabled = false
        print("|cFF00CCFFOdysseus AutoRemount:|r |cFFFF0000Disabled|r")

    elseif command == "druid" then
        db.skipDruid = not db.skipDruid
        print("|cFF00CCFFOdysseus AutoRemount:|r Druid skip " .. (db.skipDruid and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))

    elseif command == "delay" then
        local seconds = tonumber(arg)
        if seconds and seconds >= 0.1 and seconds <= 5.0 then
            db.delay = seconds
            print("|cFF00CCFFOdysseus AutoRemount:|r Delay set to " .. seconds .. "s")
        else
            print("|cFFFF0000[AutoRemount]|r Usage: /ar delay <0.1 - 5.0>")
        end

    elseif command == "silent" then
        db.silent = not db.silent
        print("|cFF00CCFFOdysseus AutoRemount:|r Error notifications " .. (db.silent and "|cFFFF0000suppressed|r" or "|cFF00FF00enabled|r"))

    elseif command == "debug" then
        db.debug = not db.debug
        OUS.Session.isDebugOn = db.debug
        print("|cFF00CCFFOdysseus AutoRemount:|r Debug " .. (db.debug and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))

    elseif command == "spy" then
        db.spyMode = not db.spyMode
        if db.spyMode then
            AR.RefreshSpyFrame()
            spyFrame:Show()
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy mode |cFFFFAA00ON|r — loot-confirmed spells will be printed to chat.")
        else
            pendingSpySpellID = nil
            spyFrame:Hide()
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy mode |cFF888888Off|r")
        end

    elseif command == "add" then
        local spellID = tonumber(arg)
        if not spellID then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar add <spellID>")
            return
        end
        if IsInCustomSpells(spellID) then
            print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " is already in your custom list.")
            return
        end
        if not db.customSpells then db.customSpells = {} end
        table.insert(db.customSpells, spellID)
        print("|cFF00CCFFOdysseus AutoRemount:|r Added spellID " .. spellID .. " to custom list.")

    elseif command == "remove" then
        local spellID = tonumber(arg)
        if not spellID then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar remove <spellID>")
            return
        end
        local custom = db.customSpells
        if not custom then
            print("|cFFFF0000[AutoRemount]|r Custom spell list is empty.")
            return
        end
        for i, id in ipairs(custom) do
            if id == spellID then
                table.remove(custom, i)
                print("|cFF00CCFFOdysseus AutoRemount:|r Removed spellID " .. spellID .. " from custom list.")
                return
            end
        end
        print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " not found in custom list.")

    elseif command == "export" then
        local custom = db.customSpells
        if not custom or #custom == 0 then
            print("|cFFFF0000[AutoRemount]|r Custom spell list is empty — nothing to export.")
            return
        end
        print("|cFF00CCFFOdysseus AutoRemount Custom SpellIDs:|r")
        print(table.concat(custom, ", "))

    elseif command == "spyfilter" then
        local sub, subarg = arg:match("^(%S+)%s*(.*)$")
        if not sub then
            -- Show current filter list
            local filter = db.spyFilter or {}
            if #filter == 0 then
                print("|cFF00CCFFOdysseus AutoRemount:|r Spy filter is empty.")
            else
                print("|cFF00CCFFOdysseus AutoRemount Spy Filter:|r")
                for _, id in ipairs(filter) do
                    local name = C_Spell.GetSpellName(id) or "Unknown"
                    print("  " .. id .. " — " .. name)
                end
            end
            return
        end
        sub = sub:lower()
        if sub == "add" then
            local spellID = tonumber(subarg)
            if not spellID then
                print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter add <spellID>")
                return
            end
            if not db.spyFilter then db.spyFilter = {} end
            for _, id in ipairs(db.spyFilter) do
                if id == spellID then
                    print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " is already in the spy filter.")
                    return
                end
            end
            table.insert(db.spyFilter, spellID)
            local name = C_Spell.GetSpellName(spellID) or "Unknown"
            print("|cFF00CCFFOdysseus AutoRemount:|r Added " .. name .. " (" .. spellID .. ") to spy filter.")
        elseif sub == "remove" then
            local spellID = tonumber(subarg)
            if not spellID then
                print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter remove <spellID>")
                return
            end
            local filter = db.spyFilter
            if not filter then
                print("|cFFFF0000[AutoRemount]|r Spy filter is empty.")
                return
            end
            for i, id in ipairs(filter) do
                if id == spellID then
                    local name = C_Spell.GetSpellName(spellID) or "Unknown"
                    table.remove(filter, i)
                    print("|cFF00CCFFOdysseus AutoRemount:|r Removed " .. name .. " (" .. spellID .. ") from spy filter.")
                    return
                end
            end
            print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " not found in spy filter.")
        elseif sub == "clear" then
            db.spyFilter = {}
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy filter cleared.")
        else
            print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter [add|remove|clear] <spellID>")
        end

    elseif command == "wipe" then
        db.customSpells = {}
        print("|cFF00CCFFOdysseus AutoRemount:|r Custom spell list cleared.")

    elseif command == "status" then
        PrintStatus()

    elseif command == "help" then
        print("|cFF00CCFFOdysseus AutoRemount Commands:|r")
        print("  /ar mount <name> — Set character mount")
        print("  /ar account <name> — Set account-wide mount")
        print("  /ar reset — Clear character mount override")
        print("  /ar reset account — Clear account mount override")
        print("  /ar toggle — Toggle on/off")
        print("  /ar enable / disable — Explicit on/off")
        print("  /ar druid — Toggle druid form skip")
        print("  /ar delay <sec> — Set remount delay (0.1-5.0)")
        print("  /ar silent — Toggle error notifications")
        print("  /ar spy — Toggle spy mode (prints loot-confirmed spells to chat)")
        print("  /ar spyfilter — Show spy filter list")
        print("  /ar spyfilter add <id> — Add spellID to spy filter (never recorded)")
        print("  /ar spyfilter remove <id> — Remove spellID from spy filter")
        print("  /ar spyfilter clear — Clear entire spy filter")
        print("  /ar add <id> — Add custom spellID")
        print("  /ar remove <id> — Remove custom spellID")
        print("  /ar export — Print custom spellIDs for copy/paste")
        print("  /ar wipe — Clear all custom spellIDs")
        print("  /ar debug — Toggle debug mode")
        print("  /ar status — Show current settings")

    else
        print("|cFFFF0000[AutoRemount]|r Unknown command: " .. command .. ". Type /ar help.")
    end
end