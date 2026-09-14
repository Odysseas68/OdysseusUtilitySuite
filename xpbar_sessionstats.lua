-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : xpbar_sessionstats.lua
-- Version : 2026.09.14
-- Desc    : Runtime XPBar session statistics tracking and display
-- ============================================================
-- luacheck: globals COPPER_AMOUNT_TEXTURE C_CurrencyInfo CanMerchantRepair CreateScrollBoxLinearView GOLD_AMOUNT_TEXTURE GetGuildBankMoney GetGuildBankWithdrawMoney GetMoney GetRepairAllCost RepairAllItems SILVER_AMOUNT_TEXTURE ScrollUtil hooksecurefunc

local addonName, OUS = ...
local Session = OUS.XPBarSession
local SessionStats = OUS.SessionStats or {}
OUS.SessionStats = SessionStats

local eventFrame = CreateFrame("Frame")

local BUILT_IN_RESOURCES = {
    { type = "CURRENCY", id = 3442, key = "adventurer", label = "Adventurer", configLabel = "Adventurer Mistcrest", category = "Midnight Season 2", defaultTracked = true },
    { type = "CURRENCY", id = 3443, key = "veteran", label = "Veteran", configLabel = "Veteran Mistcrest", category = "Midnight Season 2", defaultTracked = true },
    { type = "CURRENCY", id = 3444, key = "champion", label = "Champion", configLabel = "Champion Mistcrest", category = "Midnight Season 2", defaultTracked = true },
    { type = "CURRENCY", id = 3445, key = "hero", label = "Hero", configLabel = "Hero Mistcrest", category = "Midnight Season 2", defaultTracked = true },
    { type = "CURRENCY", id = 3446, key = "myth", label = "Myth", configLabel = "Myth Mistcrest", category = "Midnight Season 2", defaultTracked = true },
}
SessionStats.BuiltInResources = BUILT_IN_RESOURCES

Session.sessionGoldGained = Session.sessionGoldGained or 0
Session.sessionGoldSpent = Session.sessionGoldSpent or 0
Session.sessionRepairSpent = Session.sessionRepairSpent or 0
Session.crestStats = Session.crestStats or {}

-- Normalizes every nested Session Stats setting for existing SavedVariables.
function SessionStats.GetSettings()
    OdysseusDB = OdysseusDB or {}
    OdysseusDB.xpBar = OdysseusDB.xpBar or {}

    local defaults = OUS.defaults and OUS.defaults.sessionStats or {}
    local settings = OdysseusDB.xpBar.sessionStats
    if type(settings) ~= "table" then
        settings = OUS.DeepCopyTable(defaults)
        OdysseusDB.xpBar.sessionStats = settings
    end

    if type(settings.sections) ~= "table" then
        settings.sections = OUS.DeepCopyTable(defaults.sections or {})
    else
        for key, defaultValue in pairs(defaults.sections or {}) do
            if settings.sections[key] == nil then
                settings.sections[key] = defaultValue
            end
        end
    end

    if type(settings.currencyOverrides) ~= "table" then
        settings.currencyOverrides = {}
    end

    return settings
end

-- Resolves a sparse user override before falling back to the catalog default.
function SessionStats.IsResourceEnabled(resource)
    local settings = SessionStats.GetSettings()
    local override = settings.currencyOverrides[resource.id]
    if override ~= nil then
        return override
    end
    return resource.defaultTracked == true
end

-- Updates each player-facing crest from one currency while counting only positive owned-quantity deltas.
local function UpdateSessionCrests(countSessionGain)
    if not C_CurrencyInfo then return end

    for _, resource in ipairs(BUILT_IN_RESOURCES) do
        local crestState = Session.crestStats[resource.key] or {
            sessionGained = 0,
            current = 0,
            seasonEarned = 0,
        }
        Session.crestStats[resource.key] = crestState

        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(resource.id)
        if currencyInfo then
            local current = currencyInfo.quantity or 0
            local previous = crestState.lastQuantity

            if countSessionGain and previous ~= nil and current > previous then
                crestState.sessionGained = crestState.sessionGained + (current - previous)
            end

            crestState.name = currencyInfo.name
            crestState.iconFileID = currencyInfo.iconFileID
            crestState.lastQuantity = current
            crestState.current = current
            crestState.seasonEarned = currencyInfo.totalEarned or 0
            crestState.seasonMaximum = currencyInfo.maxQuantity and currencyInfo.maxQuantity > 0
                and currencyInfo.maxQuantity or nil
        end
    end
end

-- Reads the repair bill without changing merchant or cursor state.
local function ReadRepairCost()
    if not CanMerchantRepair or not CanMerchantRepair() then return nil end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair then return 0 end
    return cost or 0
end

-- Limits repair-bill comparisons to the active merchant interaction.
local function GetCurrentRepairCost()
    if not Session.repairMerchantOpen then return nil end
    return ReadRepairCost()
end

-- A secure post-hook observes Repair All calls without replacing or modifying the repair API.
if RepairAllItems and hooksecurefunc then
    hooksecurefunc("RepairAllItems", function(useGuildBank)
        local currentCost = ReadRepairCost() or Session.lastRepairCost or 0

        if useGuildBank then
            local guildWithdrawal = GetGuildBankWithdrawMoney() or 0
            local guildMoney = GetGuildBankMoney() or 0
            local guildAvailable = guildWithdrawal == -1 and guildMoney or math.min(guildWithdrawal, guildMoney)
            Session.pendingRepairCost = math.max(0, currentCost - guildAvailable)
            Session.ignoreNextRepairReduction = Session.pendingRepairCost == 0
            return
        end

        Session.ignoreNextRepairReduction = false
        Session.pendingRepairCost = math.max(Session.pendingRepairCost or 0, Session.lastRepairCost or 0, currentCost)
    end)
end

-- Tracks gross money movement while retaining repairs as a subset of total spending.
local function HandlePlayerMoney()
    local currentMoney = GetMoney()
    if Session.lastMoney == nil then
        Session.lastMoney = currentMoney
        return
    end

    local delta = currentMoney - Session.lastMoney
    local currentRepairCost = GetCurrentRepairCost()

    if delta > 0 then
        Session.sessionGoldGained = Session.sessionGoldGained + delta
    elseif delta < 0 then
        local spent = -delta
        Session.sessionGoldSpent = Session.sessionGoldSpent + spent

        local repairSpent = 0
        if Session.ignoreNextRepairReduction then
            Session.ignoreNextRepairReduction = false
        elseif (Session.pendingRepairCost or 0) > 0 then
            repairSpent = math.min(spent, Session.pendingRepairCost)
            Session.pendingRepairCost = 0
        elseif currentRepairCost and Session.lastRepairCost and currentRepairCost < Session.lastRepairCost then
            repairSpent = math.min(spent, Session.lastRepairCost - currentRepairCost)
        end

        Session.sessionRepairSpent = Session.sessionRepairSpent + repairSpent
    end

    Session.lastMoney = currentMoney
    if currentRepairCost ~= nil then
        Session.lastRepairCost = currentRepairCost
    end

    SessionStats.Refresh()
end

-- Starts and ends the bounded repair-cost observation window at repair merchants.
local function HandleMerchantEvent(event)
    if event == "MERCHANT_SHOW" then
        Session.repairMerchantOpen = true
        Session.lastRepairCost = GetCurrentRepairCost()
        Session.pendingRepairCost = 0
        Session.ignoreNextRepairReduction = false
    else
        Session.repairMerchantOpen = false
        Session.lastRepairCost = nil
        Session.pendingRepairCost = 0
        Session.ignoreNextRepairReduction = false
    end
end

-- Initializes runtime-only counters while the first currency update establishes crest baselines.
local function InitializeSessionStats()
    Session.sessionGoldGained = 0
    Session.sessionGoldSpent = 0
    Session.sessionRepairSpent = 0
    Session.crestStats = {}
    Session.lastMoney = GetMoney()
    Session.repairMerchantOpen = false
    Session.lastRepairCost = nil
    Session.pendingRepairCost = 0
    Session.ignoreNextRepairReduction = false
end

-- Session Stats Frame
OUS.statsFrame = CreateFrame("Frame", "OdysseusStatsFrame", UIParent, "BackdropTemplate")
local stats = OUS.statsFrame
stats:SetSize(380, 470)
stats:SetPoint("CENTER")
stats:SetFrameStrata("DIALOG")
tinsert(UISpecialFrames, stats:GetName())

stats:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
stats:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
stats:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
stats:Hide()

stats:SetMovable(true)
stats:SetClampedToScreen(true)
stats:EnableMouse(true)

stats:RegisterForDrag("LeftButton")
stats:SetScript("OnDragStart", stats.StartMoving)
stats:SetScript("OnDragStop", stats.StopMovingOrSizing)

stats.headerBg = stats:CreateTexture(nil, "BACKGROUND", nil, 2)
stats.headerBg:SetPoint("TOPLEFT", 4, -4)
stats.headerBg:SetPoint("TOPRIGHT", -4, -4)
stats.headerBg:SetHeight(30)
stats.headerBg:SetColorTexture(1, 1, 1, 1)
stats.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

local statsClose = CreateFrame("Button", nil, stats, "UIPanelCloseButton")
statsClose:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -2, -2)

local statsTitle = stats:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statsTitle:SetPoint("TOP", 0, -10)
statsTitle:SetText("Odysseus Session Stats")
statsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

stats.scrollBox = CreateFrame("Frame", nil, stats, "WowScrollBox")
stats.scrollBox:SetPoint("TOPLEFT", 20, -50)
stats.scrollBox:SetPoint("BOTTOMRIGHT", -36, 20)

stats.scrollBar = CreateFrame("EventFrame", nil, stats, "MinimalScrollBar")
stats.scrollBar:SetWidth(8)
stats.scrollBar:SetPoint("TOPLEFT", stats.scrollBox, "TOPRIGHT", 2, 0)
stats.scrollBar:SetPoint("BOTTOMLEFT", stats.scrollBox, "BOTTOMRIGHT", 2, 0)

stats.scrollChild = CreateFrame("Frame", nil, stats.scrollBox)
stats.scrollChild:SetWidth(324)
stats.scrollChild:SetHeight(1)
stats.scrollChild.scrollable = true

local statsScrollView = CreateScrollBoxLinearView()
statsScrollView:SetPanExtent(20)
ScrollUtil.InitScrollBoxWithScrollBar(stats.scrollBox, stats.scrollBar, statsScrollView)
stats.scrollBar:SetHideIfUnscrollable(true)

-- Creates consistent text regions for the dynamically positioned session sections.
local function CreateStatsText(template, width, justify)
    local text = stats.scrollChild:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    text:SetWidth(width or 324)
    text:SetJustifyH(justify or "LEFT")
    text:SetJustifyV("TOP")
    return text
end

stats.experienceHeader = CreateStatsText()
stats.experienceValue = CreateStatsText()
stats.reputationHeader = CreateStatsText()
stats.reputationText = CreateStatsText()
stats.goldHeader = CreateStatsText()
stats.crestHeader = CreateStatsText()

stats.goldRows = {}
for _, label in ipairs({ "Gold Gained:", "Gold Spent:", "Repairs:" }) do
    local row = {
        label = CreateStatsText("GameFontHighlight", 94, "LEFT"),
        value = CreateStatsText("GameFontHighlight", 224, "LEFT"),
    }
    row.label:SetText(label)
    stats.goldRows[#stats.goldRows + 1] = row
end

stats.crestColumns = {
    CreateStatsText("GameFontNormalSmall", 135, "LEFT"),
    CreateStatsText("GameFontNormalSmall", 54, "CENTER"),
    CreateStatsText("GameFontNormalSmall", 54, "CENTER"),
    CreateStatsText("GameFontNormalSmall", 81, "CENTER"),
}
stats.crestColumns[1]:SetText("")
stats.crestColumns[2]:SetText("Session")
stats.crestColumns[3]:SetText("Current")
stats.crestColumns[4]:SetText("Season")

stats.crestRows = {}
for _, resource in ipairs(BUILT_IN_RESOURCES) do
    stats.crestRows[#stats.crestRows + 1] = {
        definition = resource,
        name = CreateStatsText("GameFontHighlight", 135, "LEFT"),
        session = CreateStatsText("GameFontHighlight", 54, "CENTER"),
        current = CreateStatsText("GameFontHighlight", 54, "CENTER"),
        season = CreateStatsText("GameFontHighlight", 81, "CENTER"),
    }
end

-- Uses Blizzard's standard coin markup while keeping every denomination visible.
local function FormatSessionMoney(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100
    return string.format(GOLD_AMOUNT_TEXTURE, gold, 0, 0) .. " "
        .. string.format(SILVER_AMOUNT_TEXTURE, silver, 0, 0) .. " "
        .. string.format(COPPER_AMOUNT_TEXTURE, copperOnly, 0, 0)
end

local function PositionStatsText(text, x, y)
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", x, y)
end

-- Positions each section from the measured reputation height so later content never overlaps it.
function stats:UpdateData()
    local settings = SessionStats.GetSettings()
    local sections = settings.sections
    local reputationLines = {}
    local hasRep = false

    for faction, amount in pairs(Session.sessionRep) do
        hasRep = true
        reputationLines[#reputationLines + 1] = "• " .. faction .. ": |cFF00FF00+" .. amount .. "|r"
    end

    if not hasRep then
        reputationLines[1] = "|cFF888888No reputation gained yet this session.|r"
    end

    self.experienceHeader:SetText("|cFF00FFFFExperience Gained:|r")
    self.experienceValue:SetText(OUS.FormatLargeNumber(Session.sessionXP) .. " XP")
    self.reputationHeader:SetText("|cFF00FFFFReputation Breakdown:|r")
    self.reputationText:SetText(table.concat(reputationLines, "\n"))
    self.goldHeader:SetText("|cFF00FFFFGold:|r")
    self.goldRows[1].value:SetText(FormatSessionMoney(Session.sessionGoldGained))
    self.goldRows[2].value:SetText(FormatSessionMoney(Session.sessionGoldSpent))
    self.goldRows[3].value:SetText(FormatSessionMoney(Session.sessionRepairSpent))
    self.crestHeader:SetText("|cFF00FFFFCrests:|r")

    self.experienceHeader:Hide()
    self.experienceValue:Hide()
    self.reputationHeader:Hide()
    self.reputationText:Hide()
    self.goldHeader:Hide()
    self.crestHeader:Hide()
    for _, row in ipairs(self.goldRows) do
        row.label:Hide()
        row.value:Hide()
    end
    for _, column in ipairs(self.crestColumns) do
        column:Hide()
    end
    for _, row in ipairs(self.crestRows) do
        row.name:Hide()
        row.session:Hide()
        row.current:Hide()
        row.season:Hide()
    end

    local y = 0
    if sections.experience then
        self.experienceHeader:Show()
        self.experienceValue:Show()
        PositionStatsText(self.experienceHeader, 0, y)
        y = y - 18
        PositionStatsText(self.experienceValue, 0, y)
        y = y - 32
    end

    if sections.reputation then
        self.reputationHeader:Show()
        self.reputationText:Show()
        PositionStatsText(self.reputationHeader, 0, y)
        y = y - 18
        PositionStatsText(self.reputationText, 0, y)
        y = y - math.max(14, self.reputationText:GetStringHeight()) - 14
    end

    if sections.gold or sections.repairs then
        self.goldHeader:Show()
        PositionStatsText(self.goldHeader, 0, y)
        y = y - 20

        local lastGoldRow = sections.repairs and 3 or 2
        local firstGoldRow = sections.gold and 1 or 3
        for index = firstGoldRow, lastGoldRow do
            local row = self.goldRows[index]
            row.label:Show()
            row.value:Show()
            PositionStatsText(row.label, 0, y)
            PositionStatsText(row.value, 100, y)
            y = y - 18
        end
    end

    local crestColumnX = { 0, 135, 189, 243 }
    if sections.currencies then
        local hasEnabledCurrency = false
        for _, row in ipairs(self.crestRows) do
            if SessionStats.IsResourceEnabled(row.definition) then
                hasEnabledCurrency = true
                break
            end
        end

        if hasEnabledCurrency then
            if y < 0 then
                y = y - 8
            end
            self.crestHeader:Show()
            PositionStatsText(self.crestHeader, 0, y)
            y = y - 20

            for index, column in ipairs(self.crestColumns) do
                column:Show()
                PositionStatsText(column, crestColumnX[index], y)
            end
            y = y - 18

            for _, row in ipairs(self.crestRows) do
                if SessionStats.IsResourceEnabled(row.definition) then
                    local crestState = Session.crestStats[row.definition.key] or {}
                    local icon = crestState.iconFileID and string.format("|T%d:16:16:0:0|t ", crestState.iconFileID) or ""
                    row.name:SetText(icon .. row.definition.label)
                    row.session:SetText(tostring(math.floor(crestState.sessionGained or 0)))
                    row.current:SetText(tostring(math.floor(crestState.current or 0)))

                    if crestState.seasonMaximum and crestState.seasonMaximum > 0 then
                        row.season:SetText(string.format("%d / %d", crestState.seasonEarned or 0, crestState.seasonMaximum))
                    else
                        row.season:SetText("Unavailable")
                    end

                    row.name:Show()
                    row.session:Show()
                    row.current:Show()
                    row.season:Show()
                    PositionStatsText(row.name, crestColumnX[1], y)
                    PositionStatsText(row.session, crestColumnX[2], y)
                    PositionStatsText(row.current, crestColumnX[3], y)
                    PositionStatsText(row.season, crestColumnX[4], y)
                    y = y - 20
                end
            end
        end
    end

    self.scrollChild:SetHeight(math.max(1, -y + 8))
end

-- Refreshes the informational session window only while the player is viewing it.
function SessionStats.Refresh()
    if stats:IsShown() then
        stats:UpdateData()
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            SessionStats.GetSettings()
            InitializeSessionStats()
        end
        return
    end

    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end

    if event == "PLAYER_MONEY" then
        HandlePlayerMoney()
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_CLOSED" then
        HandleMerchantEvent(event)
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        UpdateSessionCrests(true)
        SessionStats.Refresh()
    end
end)

SLASH_XPSTATS1 = "/xpstats"
SlashCmdList["XPSTATS"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    if stats:IsShown() then
        stats:Hide()
    else
        stats:Show()
        stats:UpdateData()
        stats.scrollBox:ScrollToBegin()
    end
end
