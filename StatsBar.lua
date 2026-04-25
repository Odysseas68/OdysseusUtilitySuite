-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: STATS BAR ENGINE
-- ==========================================
local addonName, OUS = ...

OUS.StatsBar = {}
local SB = OUS.StatsBar

-- Restriction state — true during combat, M+, encounter, PvP match
local isRestricted = false

-- Cached stat strings — updated only when not restricted
local cache = {
    ilvl     = "—",
    str      = "—", agi  = "—", int  = "—", stam = "—",
    crit     = "—", haste = "—", mast = "—", vers = "—",
    critr    = "—", haster = "—", mastr = "—", versr = "—",
    leech    = "—", avoid = "—", speed = "—",
    armor    = "—", dodge = "—", parry = "—", block = "—",
    spec     = "—",
}

-- ==========================================
-- 2. HELPERS
-- ==========================================

-- Returns the current spec ID or nil.
local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID
end

-- Returns the stat priority list for the current spec.
local function GetSpecPriority()
    local specID = GetCurrentSpecID()
    local entry = specID and OUS.StatsBarSpecPriority and OUS.StatsBarSpecPriority[specID]
    return entry and entry.default or {"Crit", "Haste", "Mastery", "Vers"}
end

-- Formats a float to one decimal place.
local function Fmt1(n)
    return string.format("%.1f", n or 0)
end

-- Formats a number with thousands separator.
local function FmtNum(n)
    return tostring(math.floor(n or 0))
end

-- Returns a color code string for a stat name.
local statColors = {
    Crit    = "|cFFE85655",
    Haste   = "|cFF57C55A",
    Mastery = "|cFFC5C53D",
    Vers    = "|cFF517AC5",
}
-- Display labels for stat names in the table view.
local statLabels = {
    Crit    = "Crit Strike",
    Haste   = "Haste",
    Mastery = "Mastery",
    Vers    = "Versatility",
}

-- Primary stat name from spec info.
local function GetPrimaryStatName()
    local specIndex = GetSpecialization()
    if not specIndex then return "Strength" end
    local _, _, _, _, _, primaryStat = GetSpecializationInfo(specIndex)
    if primaryStat == 1 then return "Strength"
    elseif primaryStat == 2 then return "Agility"
    elseif primaryStat == 3 then return "Stamina"
    elseif primaryStat == 4 then return "Intellect"
    else return "Strength" end
end

-- Primary stat value from spec.
local function GetPrimaryStatValue()
    local specIndex = GetSpecialization()
    if not specIndex then return cache.str end
    local _, _, _, _, _, primaryStat = GetSpecializationInfo(specIndex)
    if primaryStat == 1 then return cache.str
    elseif primaryStat == 2 then return cache.agi
    elseif primaryStat == 3 then return cache.stam
    elseif primaryStat == 4 then return cache.int
    else return cache.str end
end

local function StatColor(statName, text)
    local c = statColors[statName] or "|cFFFFFFFF"
    return c .. text .. "|r"
end

-- ==========================================
-- 3. CACHE REFRESH
-- ==========================================

-- Forward declaration so RefreshCache can call UpdateTable.
local UpdateTable

-- Reads all stats and formats them to strings. Never called while restricted.
local function RefreshCache()
    if isRestricted then return end

    local db = OdysseusCharDB and OdysseusCharDB.statsBar

    -- Item level
    local ilvl = C_PaperDollInfo.GetInspectItemLevel("player")
    cache.ilvl = ilvl and string.format("%.1f", ilvl) or "—"

    -- Primary stats
    local str  = UnitStat("player", 1) or 0
    local agi  = UnitStat("player", 2) or 0
    local stam = UnitStat("player", 3) or 0
    local int  = UnitStat("player", 4) or 0
    cache.str  = FmtNum(str)
    cache.agi  = FmtNum(agi)
    cache.stam = FmtNum(stam)
    cache.int  = FmtNum(int)

    -- Secondary stats — ratings and percentages
    local critR  = GetCombatRating(CR_CRIT_MELEE)   or 0
    local hasteR = GetCombatRating(CR_HASTE_MELEE)  or 0
    local mastR  = GetCombatRating(CR_MASTERY)       or 0
    local versR  = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0

    local critP  = GetCritChance()    or 0
    local hasteP = GetHaste()         or 0
    local mastP  = GetMasteryEffect() or 0
    local versP  = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0)
                 + (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)  or 0)

    cache.critr  = FmtNum(critR)
    cache.haster = FmtNum(hasteR)
    cache.mastr  = FmtNum(mastR)
    cache.versr  = FmtNum(versR)
    cache.crit   = Fmt1(critP)  .. "%"
    cache.haste  = Fmt1(hasteP) .. "%"
    cache.mast   = Fmt1(mastP)  .. "%"
    cache.vers   = Fmt1(versP)  .. "%"

    -- Tertiary stats
    cache.leech = Fmt1(GetLifesteal()  or 0) .. "%"
    cache.avoid = Fmt1(GetAvoidance()  or 0) .. "%"
    cache.speed = Fmt1(GetSpeed()      or 0) .. "%"

    -- Defensive stats
    cache.dodge = Fmt1(GetDodgeChance() or 0) .. "%"
    cache.parry = Fmt1(GetParryChance() or 0) .. "%"
    cache.block = Fmt1(GetBlockChance() or 0) .. "%"
    local _, effectiveArmor = UnitArmor("player")
    cache.armor = FmtNum(effectiveArmor or 0)

    -- Spec priority display
    local priority = GetSpecPriority()
    local statValues = {
        Crit    = critP,
        Haste   = hasteP,
        Mastery = mastP,
        Vers    = versP,
    }
    local parts = {}
    for _, statName in ipairs(priority) do
        local val = Fmt1(statValues[statName] or 0) .. "%"
        table.insert(parts, StatColor(statName, statName .. " " .. val))
    end
    cache.spec = table.concat(parts, " ")

    SB.UpdateDisplay()
    UpdateTable()
end

-- ==========================================
-- 4. DISPLAY
-- ==========================================

local sbFrame = CreateFrame("Frame", "OdysseusStatsBarFrame", UIParent)
sbFrame:SetSize(300, 20)
sbFrame:SetPoint("CENTER")
sbFrame:SetFrameStrata("MEDIUM")
sbFrame:SetMovable(true)
sbFrame:EnableMouse(false)
sbFrame:RegisterForDrag("LeftButton")
sbFrame:SetScript("OnDragStart", sbFrame.StartMoving)
sbFrame:SetScript("OnDragStop", function()
    sbFrame:StopMovingOrSizing()
    if OdysseusCharDB and OdysseusCharDB.statsBar then
        local point, _, relPoint, x, y = sbFrame:GetPoint(1)
        OdysseusCharDB.statsBar.x = x
        OdysseusCharDB.statsBar.y = y
        OdysseusCharDB.statsBar.point = point
        OdysseusCharDB.statsBar.relPoint = relPoint
    end
end)
sbFrame:Hide()
-- ==========================================
-- TABLE FRAME
-- ==========================================
local stFrame = CreateFrame("Frame", "OdysseusStatsTableFrame", UIParent)
stFrame:SetSize(180, 120)
stFrame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
stFrame:SetFrameStrata("MEDIUM")
stFrame:SetMovable(true)
stFrame:EnableMouse(false)
stFrame:RegisterForDrag("LeftButton")
stFrame:SetScript("OnDragStart", stFrame.StartMoving)
stFrame:SetScript("OnDragStop", function()
    stFrame:StopMovingOrSizing()
    if OdysseusCharDB and OdysseusCharDB.statsBar then
        local point, _, relPoint, x, y = stFrame:GetPoint(1)
        OdysseusCharDB.statsBar.tableX = x
        OdysseusCharDB.statsBar.tableY = y
        OdysseusCharDB.statsBar.tablePoint = point
        OdysseusCharDB.statsBar.tableRelPoint = relPoint
    end
end)
stFrame:Hide()

-- Left column — labels
local stLabels = stFrame:CreateFontString(nil, "OVERLAY")
stLabels:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stLabels:SetPoint("TOPLEFT", stFrame, "TOPLEFT", 0, 0)
stLabels:SetJustifyH("LEFT")
stLabels:SetJustifyV("TOP")
stLabels:SetTextColor(0.8, 0.8, 0.8, 1)

-- Right column — values
local stValues = stFrame:CreateFontString(nil, "OVERLAY")
stValues:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stValues:SetPoint("TOPRIGHT", stFrame, "TOPRIGHT", 0, 0)
stValues:SetJustifyH("RIGHT")
stValues:SetJustifyV("TOP")
stValues:SetTextColor(1, 1, 1, 1)

-- Split table sections for tighter separator control
local stLabelsTop = stFrame:CreateFontString(nil, "OVERLAY")
stLabelsTop:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stLabelsTop:SetJustifyH("LEFT")
stLabelsTop:SetJustifyV("TOP")
stLabelsTop:SetTextColor(0.8, 0.8, 0.8, 1)

local stValuesTop = stFrame:CreateFontString(nil, "OVERLAY")
stValuesTop:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stValuesTop:SetJustifyH("RIGHT")
stValuesTop:SetJustifyV("TOP")
stValuesTop:SetTextColor(1, 1, 1, 1)

local stLabelsMid = stFrame:CreateFontString(nil, "OVERLAY")
stLabelsMid:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stLabelsMid:SetJustifyH("LEFT")
stLabelsMid:SetJustifyV("TOP")
stLabelsMid:SetTextColor(0.8, 0.8, 0.8, 1)

local stValuesMid = stFrame:CreateFontString(nil, "OVERLAY")
stValuesMid:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stValuesMid:SetJustifyH("RIGHT")
stValuesMid:SetJustifyV("TOP")
stValuesMid:SetTextColor(1, 1, 1, 1)

local stLabelsBot = stFrame:CreateFontString(nil, "OVERLAY")
stLabelsBot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stLabelsBot:SetJustifyH("LEFT")
stLabelsBot:SetJustifyV("TOP")
stLabelsBot:SetTextColor(0.8, 0.8, 0.8, 1)

local stValuesBot = stFrame:CreateFontString(nil, "OVERLAY")
stValuesBot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
stValuesBot:SetJustifyH("RIGHT")
stValuesBot:SetJustifyV("TOP")
stValuesBot:SetTextColor(1, 1, 1, 1)

-- Separator lines (textures — not ASCII)
local sep1 = stFrame:CreateTexture(nil, "OVERLAY")
sep1:SetColorTexture(0.4, 0.4, 0.4, 0.8)
sep1:SetHeight(1)

local sep2 = stFrame:CreateTexture(nil, "OVERLAY")
sep2:SetColorTexture(0.4, 0.4, 0.4, 0.8)
sep2:SetHeight(1)

-- Builds and renders the table frame content.
UpdateTable = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.statsBar then
        stFrame:Hide()
        return
    end
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB or not charDB.tableEnabled then
        stFrame:Hide()
        return
    end

        local fontSize = charDB.fontSize or 12
    local lineHeight = fontSize + 2
    local frameWidth = (OdysseusCharDB and OdysseusCharDB.statsBar and OdysseusCharDB.statsBar.tableWidth) or 150
    local gap = 2

    -- Hide old multiline columns in table mode
    stLabels:SetText("")
    stValues:SetText("")

    stLabelsTop:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stValuesTop:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stLabelsMid:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stValuesMid:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stLabelsBot:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stValuesBot:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")

    local priority = GetSpecPriority()
    local primaryName = GetPrimaryStatName()
    local primaryVal  = GetPrimaryStatValue()

    local secValues = {
        Crit    = cache.crit,
        Haste   = cache.haste,
        Mastery = cache.mast,
        Vers    = cache.vers,
    }

    local secLabelLines = {}
    local secValueLines = {}
    for _, statName in ipairs(priority) do
        local label = statLabels[statName] or statName
        local val   = secValues[statName] or "—"
        local c     = statColors[statName] or "|cFFFFFFFF"
        table.insert(secLabelLines, c .. label .. "|r")
        table.insert(secValueLines, c .. val   .. "|r")
    end

    stLabelsTop:SetText("|cFFFFD100iLvl|r")
    stValuesTop:SetText("|cFFFFD100" .. cache.ilvl .. "|r")

    stLabelsMid:SetText("|cFF00CCFF" .. primaryName .. "|r")
    stValuesMid:SetText("|cFF00CCFF" .. primaryVal .. "|r")

    stLabelsBot:SetText(table.concat(secLabelLines, "\n"))
    stValuesBot:SetText(table.concat(secValueLines, "\n"))

    local leftWidth  = frameWidth * 0.55
    local rightWidth = frameWidth * 0.45

    stLabelsTop:SetWidth(leftWidth)
    stValuesTop:SetWidth(rightWidth)
    stLabelsMid:SetWidth(leftWidth)
    stValuesMid:SetWidth(rightWidth)
    stLabelsBot:SetWidth(leftWidth)
    stValuesBot:SetWidth(rightWidth)

    stLabelsTop:ClearAllPoints()
    stLabelsTop:SetPoint("TOPLEFT", stFrame, "TOPLEFT", 0, 0)

    stValuesTop:ClearAllPoints()
    stValuesTop:SetPoint("TOPRIGHT", stFrame, "TOPRIGHT", 0, 0)

    sep1:SetHeight(2)
    sep1:SetWidth(frameWidth)
    sep1:ClearAllPoints()
    sep1:SetPoint("TOPLEFT", stFrame, "TOPLEFT", 0, -lineHeight - gap + 1)

    stLabelsMid:ClearAllPoints()
    stLabelsMid:SetPoint("TOPLEFT", sep1, "BOTTOMLEFT", 0, -gap)

    stValuesMid:ClearAllPoints()
    stValuesMid:SetPoint("TOPRIGHT", sep1, "BOTTOMRIGHT", 0, -gap)

    sep2:SetHeight(2)
    sep2:SetWidth(frameWidth)
    sep2:ClearAllPoints()
    sep2:SetPoint("TOPLEFT", stLabelsMid, "BOTTOMLEFT", 0, -gap + 1)

    stLabelsBot:ClearAllPoints()
    stLabelsBot:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -gap)

    stValuesBot:ClearAllPoints()
    stValuesBot:SetPoint("TOPRIGHT", sep2, "BOTTOMRIGHT", 0, -gap)

    local secondaryLines = #priority
    local totalHeight =
        lineHeight +          -- ilvl
        gap + 1 + gap +       -- sep1 block
        lineHeight +          -- primary
        gap + 1 + gap +       -- sep2 block
        (secondaryLines * lineHeight)

    stFrame:SetWidth(frameWidth)
    stFrame:SetHeight(totalHeight + 2)
    stFrame:Show()
end

-- Positions the table frame from saved DB values.
local function ApplyTablePosition()
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB then return end
    stFrame:ClearAllPoints()
    stFrame:SetPoint(
        charDB.tablePoint    or "CENTER",
        UIParent,
        charDB.tableRelPoint or "CENTER",
        charDB.tableX        or 200,
        charDB.tableY        or 0
    )
    stFrame:EnableMouse(not charDB.tableLocked)
end

-- Enables or disables mouse on the table frame for dragging.
function SB.SetTableLocked(locked)
    stFrame:EnableMouse(not locked)
end
local sbText = sbFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sbText:SetAllPoints(sbFrame)
sbText:SetJustifyH("CENTER")
sbText:SetJustifyV("MIDDLE")

-- Parses a template string and returns the rendered text.
local function ParseTemplate(template)
    if not template or template == "" then return "" end
    return (template:gsub("{(%w+)}", function(token)
        return cache[token] or ""
    end))
end

-- Expose UpdateTable publicly so Config.lua can call it.
function SB.UpdateTable()
    UpdateTable()
end

-- Updates the visible text from the current template and cache.
function SB.UpdateDisplay()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.statsBar then
        sbFrame:Hide()
        return
    end
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB or not charDB.enabled or charDB.tableEnabled then
        sbFrame:Hide()
        return
    end

    local template = charDB.template or "{ilvl} | {spec}"
    local rendered = ParseTemplate(template)
    sbText:SetText(rendered)
    sbText:SetFont(sbText:GetFont(), charDB.fontSize or 12)
    sbFrame:SetWidth(sbText:GetStringWidth() + 10)
    sbFrame:Show()
end

-- Positions the frame from saved character DB values.
local function ApplyPosition()
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB then return end
    sbFrame:ClearAllPoints()
    sbFrame:SetPoint(
        charDB.point    or "CENTER",
        UIParent,
        charDB.relPoint or "CENTER",
        charDB.x        or 0,
        charDB.y        or 0
    )
end

-- Enables or disables mouse interaction for dragging.
function SB.SetLocked(locked)
    sbFrame:EnableMouse(not locked)
end

-- ==========================================
-- 5. EVENT HANDLER
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_STATS")
frame:RegisterEvent("COMBAT_RATING_UPDATE")
frame:RegisterEvent("MASTERY_UPDATE")
frame:RegisterEvent("AVOIDANCE_UPDATE")
frame:RegisterEvent("LIFESTEAL_UPDATE")
frame:RegisterEvent("SPEED_UPDATE")
frame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ApplyPosition()
        ApplyTablePosition()
        SB.SetLocked(OdysseusCharDB.statsBar and OdysseusCharDB.statsBar.locked or false)
        SB.SetTableLocked(OdysseusCharDB.statsBar and OdysseusCharDB.statsBar.tableLocked or false)
        RefreshCache()

    elseif event == "PLAYER_REGEN_DISABLED" then
        if not isRestricted then
            isRestricted = true
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        isRestricted = false
        C_Timer.After(0.1, RefreshCache)

    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        -- restrictionType 2 = stat restrictions (M+, encounter, PvP match)
        local restrictionType = unit
        local restrictionState = select(1, ...)
        if restrictionType == 2 then
            isRestricted = (restrictionState ~= 0)
            if not isRestricted then
                C_Timer.After(0.1, RefreshCache)
            end
        end

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        C_Timer.After(0.2, RefreshCache)

    elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE" then
        C_Timer.After(0.1, RefreshCache)

    elseif not unit or unit == "player" then
        RefreshCache()
    end
end)

-- ==========================================
-- 6. SLASH COMMAND HANDLER
-- ==========================================

-- Prints current StatsBar configuration.
local function PrintStatus()
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB then return end
    print("|cFF00CCFFOdysseus StatsBar Status:|r")
    print("  Enabled: " .. (charDB.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Template: " .. (charDB.template or "{ilvl} | {spec}"))
    print("  Font Size: " .. tostring(charDB.fontSize or 12))
    print("  Locked: " .. (charDB.locked and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
end

function SB.SlashHandler(msg)
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if not charDB then return end

    local command, arg = msg:match("^(%S+)%s*(.*)$")
    if not command then command = "help" end
    command = command:lower()

    if command == "toggle" then
        charDB.enabled = not charDB.enabled
        SB.UpdateDisplay()
        print("|cFF00CCFFOdysseus StatsBar:|r " .. (charDB.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))

    elseif command == "enable" then
        charDB.enabled = true
        SB.UpdateDisplay()
        print("|cFF00CCFFOdysseus StatsBar:|r |cFF00FF00Enabled|r")

    elseif command == "disable" then
        charDB.enabled = false
        SB.UpdateDisplay()
        print("|cFF00CCFFOdysseus StatsBar:|r |cFFFF0000Disabled|r")

    elseif command == "template" then
        if arg == "" then
            print("|cFF00CCFFOdysseus StatsBar:|r Current template: " .. (charDB.template or "{ilvl} | {spec}"))
            return
        end
        charDB.template = arg
        RefreshCache()
        print("|cFF00CCFFOdysseus StatsBar:|r Template set to: " .. arg)

    elseif command == "size" then
        local size = tonumber(arg)
        if size and size >= 8 and size <= 24 then
            charDB.fontSize = size
            SB.UpdateDisplay()
            UpdateTable()
            print("|cFF00CCFFOdysseus StatsBar:|r Font size set to " .. size)
        else
            print("|cFFFF0000[StatsBar]|r Usage: /sb size <8-24>")
        end

    elseif command == "lock" then
        charDB.locked = true
        SB.SetLocked(true)
        print("|cFF00CCFFOdysseus StatsBar:|r |cFF00FF00Locked|r")

    elseif command == "unlock" then
        charDB.locked = false
        SB.SetLocked(false)
        print("|cFF00CCFFOdysseus StatsBar:|r |cFFFF0000Unlocked — drag to reposition|r")

    elseif command == "table" then
        charDB.tableEnabled = not charDB.tableEnabled
        if charDB.tableEnabled then
            stFrame:EnableMouse(not charDB.tableLocked)
        end
        SB.UpdateDisplay()
        UpdateTable()
        print("|cFF00CCFFOdysseus StatsBar:|r Table " .. (charDB.tableEnabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))

    elseif command == "tlock" then
        charDB.tableLocked = true
        SB.SetTableLocked(true)
        print("|cFF00CCFFOdysseus StatsBar:|r Table |cFF00FF00Locked|r")

    elseif command == "tunlock" then
        charDB.tableLocked = false
        SB.SetTableLocked(false)
        print("|cFF00CCFFOdysseus StatsBar:|r Table |cFFFF0000Unlocked — drag to reposition|r")

    elseif command == "reset" then
        charDB.template      = "{ilvl} | {spec}"
        charDB.fontSize      = 12
        charDB.locked        = false
        charDB.x, charDB.y  = 0, 0
        charDB.point, charDB.relPoint = "CENTER", "CENTER"
        charDB.tableEnabled  = false
        charDB.tableX        = 200
        charDB.tableY        = 0
        charDB.tablePoint, charDB.tableRelPoint = "CENTER", "CENTER"
        charDB.tableLocked   = false
        ApplyPosition()
        ApplyTablePosition()
        SB.SetLocked(false)
        SB.SetTableLocked(false)
        RefreshCache()
        print("|cFF00CCFFOdysseus StatsBar:|r Reset to defaults.")

    elseif command == "tokens" then
        print("|cFF00CCFFOdysseus StatsBar Tokens:|r")
        print("  {ilvl} — equipped item level")
        print("  {str} {agi} {int} {stam} — primary stats")
        print("  {crit} {haste} {mast} {vers} — secondary %")
        print("  {critr} {haster} {mastr} {versr} — secondary ratings")
        print("  {leech} {avoid} {speed} — tertiary %")
        print("  {armor} {dodge} {parry} {block} — defensive")
        print("  {spec} — secondaries in spec priority order")

    elseif command == "status" then
        PrintStatus()

    elseif command == "help" then
        print("|cFF00CCFFOdysseus StatsBar Commands:|r")
        print("  /sb toggle — Toggle on/off")
        print("  /sb enable / disable — Explicit on/off")
        print("  /sb template <text> — Set display template")
        print("  /sb size <8-24> — Set font size")
        print("  /sb lock / unlock — Lock/unlock position")
        print("  /sb reset — Reset to defaults")
        print("  /sb tokens — Show all available tokens")
        print("  /sb table — Toggle table view on/off")
        print("  /sb tlock / tunlock — Lock/unlock table position")
        print("  /sb status — Show current settings")

    else
        print("|cFFFF0000[StatsBar]|r Unknown command: " .. command .. ". Type /sb help.")
    end
end