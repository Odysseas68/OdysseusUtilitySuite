-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : xpbar_sessionstats.lua
-- Version : 2026.09.19
-- Desc    : Runtime XPBar session statistics tracking and display
-- ============================================================
-- luacheck: globals COPPER_AMOUNT_TEXTURE C_CurrencyInfo CanMerchantRepair ChatFontNormal CreateScrollBoxLinearView GOLD_AMOUNT_TEXTURE GameTooltip GetMoney GetRepairAllCost RepairAllItems SILVER_AMOUNT_TEXTURE ScrollUtil StaticPopupDialogs StaticPopup_Show UnitXP UnitXPMax hooksecurefunc

local addonName, OUS = ...
local Session = OUS.XPBarSession
local SessionStats = OUS.SessionStats or {}
OUS.SessionStats = SessionStats

-- Publishes only authoritative junk-counter changes, independently of window visibility.
SessionStats.JunkCallbacks = {}
local junkCallbacks = LibStub("CallbackHandler-1.0"):New(SessionStats.JunkCallbacks)

local eventFrame = CreateFrame("Frame")
local repairFundingIndeterminate = false

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
Session.sessionJunkItems = Session.sessionJunkItems or 0
Session.sessionJunkGold = Session.sessionJunkGold or 0
Session.crestStats = Session.crestStats or {}
Session.pendingKnownWalletMovements = Session.pendingKnownWalletMovements or {}

local diagnosticRecords = {}
local diagnosticSequence = 0
local diagnosticsEnabled = false
local diagnosticFrame
local diagnosticEditBox

local function DiagnosticValue(value)
    if value == nil then return "nil" end
    return tostring(value)
end

-- Formats raw copper with a plain-text denomination equivalent for copyable diagnostics.
local function FormatDiagnosticMoney(copper, showPositiveSign)
    if copper == nil then return "nil" end

    copper = math.floor(tonumber(copper) or 0)
    local absoluteCopper = math.abs(copper)
    local gold = math.floor(absoluteCopper / 10000)
    local silver = math.floor((absoluteCopper % 10000) / 100)
    local copperOnly = absoluteCopper % 100
    local sign = copper < 0 and "-" or (showPositiveSign and copper > 0 and "+" or "")
    local raw = sign == "+" and ("+" .. copper) or tostring(copper)

    return string.format("%s copper (%s%dg %02ds %02dc)", raw, sign, gold, silver, copperOnly)
end

-- Builds one canonical copyable report without exposing diagnostic edits to accounting state.
local function BuildDiagnosticText()
    local lines = {
        "OUS Session Stats Gold Diagnostics",
        "",
        "Current Wallet: " .. FormatDiagnosticMoney(GetMoney()),
        "lastMoney: " .. FormatDiagnosticMoney(Session.lastMoney),
        "Gold Gained: " .. FormatDiagnosticMoney(Session.sessionGoldGained),
        "Gold Spent: " .. FormatDiagnosticMoney(Session.sessionGoldSpent),
        "Repairs: " .. FormatDiagnosticMoney(Session.sessionRepairSpent),
        "Junk Items: " .. DiagnosticValue(Session.sessionJunkItems),
        "Junk Gold: " .. FormatDiagnosticMoney(Session.sessionJunkGold),
        "Pending Repair Cost: " .. FormatDiagnosticMoney(Session.pendingRepairCost),
        "Last Repair Cost: " .. FormatDiagnosticMoney(Session.lastRepairCost),
    }

    if not diagnosticsEnabled then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Gold diagnostics are disabled."
        return table.concat(lines, "\n")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "--- EVENT TIMELINE ---"
    lines[#lines + 1] = ""

    for _, record in ipairs(diagnosticRecords) do
        lines[#lines + 1] = record
        lines[#lines + 1] = ""
    end

    return table.concat(lines, "\n")
end

-- Appends runtime-only records in exact observation order for merchant accounting diagnostics.
local function AppendDiagnosticRecord(eventName, fields)
    if not diagnosticsEnabled then return end

    diagnosticSequence = diagnosticSequence + 1
    local lines = { string.format("#%03d %s", diagnosticSequence, eventName) }
    for _, field in ipairs(fields or {}) do
        lines[#lines + 1] = field
    end
    diagnosticRecords[#diagnosticRecords + 1] = table.concat(lines, "\n")

    if diagnosticFrame and diagnosticFrame:IsShown() and diagnosticEditBox then
        diagnosticEditBox:SetText(BuildDiagnosticText())
    end
end

-- Summarizes the runtime-only known movement queue without changing its order.
local function GetPendingKnownMovementState()
    local positive = 0
    local negative = 0
    local values = {}

    for _, movement in ipairs(Session.pendingKnownWalletMovements) do
        if movement > 0 then
            positive = positive + movement
        else
            negative = negative - movement
        end
        values[#values + 1] = FormatDiagnosticMoney(movement, true)
    end

    return positive, negative, #values > 0 and table.concat(values, ", ") or "empty"
end

-- Reconciles exact ordered batches first, then consumes only same-sign pending movement with partial support.
local function ReconcilePendingKnownMovement(rawDelta)
    if rawDelta == 0 then return 0, 0 end

    local queue = Session.pendingKnownWalletMovements
    local prefixTotal = 0
    for index, movement in ipairs(queue) do
        prefixTotal = prefixTotal + movement
        if prefixTotal == rawDelta then
            for _ = 1, index do
                table.remove(queue, 1)
            end
            AppendDiagnosticRecord("KNOWN_MOVEMENT_RECONCILIATION", {
                "Raw delta: " .. FormatDiagnosticMoney(rawDelta, true),
                "Mode: exact ordered prefix",
                "Prefix entries removed: " .. index,
            })
            return rawDelta, 0
        end
    end

    local direction = rawDelta > 0 and 1 or -1
    local remaining = math.abs(rawDelta)
    local reconciled = 0
    local index = 1
    local consumption = diagnosticsEnabled and {} or nil

    while index <= #queue and remaining > 0 do
        local movement = queue[index]
        if (movement > 0 and direction > 0) or (movement < 0 and direction < 0) then
            local consumed = math.min(math.abs(movement), remaining)
            if consumption then
                consumption[#consumption + 1] = "Entry value " .. FormatDiagnosticMoney(movement, true)
                    .. "; consumed " .. FormatDiagnosticMoney(direction * consumed, true)
                    .. "; remainder " .. FormatDiagnosticMoney(movement - direction * consumed, true)
            end
            remaining = remaining - consumed
            reconciled = reconciled + (direction * consumed)
            movement = movement - (direction * consumed)

            if movement == 0 then
                table.remove(queue, index)
            else
                queue[index] = movement
                index = index + 1
            end
        else
            index = index + 1
        end
    end

    AppendDiagnosticRecord("KNOWN_MOVEMENT_RECONCILIATION", {
        "Raw delta: " .. FormatDiagnosticMoney(rawDelta, true),
        "Mode: same-sign consumption in queue order",
        "Consumption steps: " .. (consumption and #consumption > 0 and table.concat(consumption, " | ") or "none"),
        "Unexplained remainder: " .. FormatDiagnosticMoney(direction * remaining, true),
    })
    return reconciled, direction * remaining
end

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

-- Records exact OUS merchant transactions while queuing their wallet effects for later observed reconciliation.
function SessionStats.RecordKnownMerchantTransaction(transactionType, amount, details)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount == 0 then return end

    details = details or {}
    local currentMoney = GetMoney()
    local lastMoneyBefore = Session.lastMoney
    local gainedBefore = Session.sessionGoldGained
    local spentBefore = Session.sessionGoldSpent
    local repairsBefore = Session.sessionRepairSpent
    local junkItemsBefore = Session.sessionJunkItems
    local junkGoldBefore = Session.sessionJunkGold
    local pendingBefore = Session.pendingRepairCost
    local lastRepairBefore = Session.lastRepairCost
    local knownPositiveBefore, knownNegativeBefore, knownQueueBefore = GetPendingKnownMovementState()

    local walletDelta = 0
    if transactionType == "VENDOR_INCOME" then
        Session.sessionGoldGained = Session.sessionGoldGained + amount
        Session.sessionJunkItems = Session.sessionJunkItems
            + math.max(0, math.floor(tonumber(details.stackCount) or 0))
        Session.sessionJunkGold = Session.sessionJunkGold + amount
        walletDelta = amount
    elseif transactionType == "REPAIR_COST" then
        Session.sessionRepairSpent = Session.sessionRepairSpent + amount
        if details.walletEffectKnown then
            Session.sessionGoldSpent = Session.sessionGoldSpent + amount
            walletDelta = -amount
        end
    else
        return
    end

    if walletDelta ~= 0 then
        Session.pendingKnownWalletMovements[#Session.pendingKnownWalletMovements + 1] = walletDelta
    end

    if transactionType == "REPAIR_COST" then
        Session.lastRepairCost = 0
        Session.pendingRepairCost = 0
    end

    local knownPositiveAfter, knownNegativeAfter, knownQueueAfter = GetPendingKnownMovementState()

    local eventName = transactionType == "VENDOR_INCOME" and "KNOWN_JUNK_SALE" or "KNOWN_REPAIR"
    AppendDiagnosticRecord(eventName, {
        "Transaction Type: " .. transactionType,
        "Funding Type: " .. DiagnosticValue(details.fundingType),
        "Item Entries: " .. DiagnosticValue(details.itemCount),
        "Stack Count: " .. DiagnosticValue(details.stackCount),
        "Item ID: " .. DiagnosticValue(details.itemID),
        "Amount: " .. FormatDiagnosticMoney(amount),
        "GetMoney before vendor call: " .. FormatDiagnosticMoney(details.walletBeforeSale),
        "Bag item link: " .. DiagnosticValue(details.itemLink),
        "ItemID sellPrice (raw): " .. FormatDiagnosticMoney(details.itemIDSellPrice),
        "Bag-link sellPrice (raw): " .. FormatDiagnosticMoney(details.linkSellPrice),
        "Bag-tooltip SellPrice (raw): " .. FormatDiagnosticMoney(details.bagTooltipPrice),
        "Bag-tooltip maxPrice (raw): " .. FormatDiagnosticMoney(details.bagTooltipMaxPrice),
        "GetMoney at notify: " .. FormatDiagnosticMoney(currentMoney),
        "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
        "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
        "Pending Known Positive before: " .. FormatDiagnosticMoney(knownPositiveBefore),
        "Pending Known Positive after: " .. FormatDiagnosticMoney(knownPositiveAfter),
        "Pending Known Negative before: " .. FormatDiagnosticMoney(knownNegativeBefore),
        "Pending Known Negative after: " .. FormatDiagnosticMoney(knownNegativeAfter),
        "Pending Known Queue before: " .. knownQueueBefore,
        "Pending Known Queue after: " .. knownQueueAfter,
        "Gold Gained before: " .. FormatDiagnosticMoney(gainedBefore),
        "Gold Gained after: " .. FormatDiagnosticMoney(Session.sessionGoldGained),
        "Gold Spent before: " .. FormatDiagnosticMoney(spentBefore),
        "Gold Spent after: " .. FormatDiagnosticMoney(Session.sessionGoldSpent),
        "Repairs before: " .. FormatDiagnosticMoney(repairsBefore),
        "Repairs after: " .. FormatDiagnosticMoney(Session.sessionRepairSpent),
        "Junk Items before: " .. DiagnosticValue(junkItemsBefore),
        "Junk Items after: " .. DiagnosticValue(Session.sessionJunkItems),
        "Junk Gold before: " .. FormatDiagnosticMoney(junkGoldBefore),
        "Junk Gold after: " .. FormatDiagnosticMoney(Session.sessionJunkGold),
        "Pending Repair Cost before: " .. FormatDiagnosticMoney(pendingBefore),
        "Pending Repair Cost after: " .. FormatDiagnosticMoney(Session.pendingRepairCost),
        "Last Repair Cost before: " .. FormatDiagnosticMoney(lastRepairBefore),
        "Last Repair Cost after: " .. FormatDiagnosticMoney(Session.lastRepairCost),
    })

    if transactionType == "VENDOR_INCOME" then
        junkCallbacks:Fire("JunkChanged")
    end
    SessionStats.Refresh()
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

-- Protect the whole merchant interaction because native guild-first funding is not attributable.
function SessionStats.MarkRepairFundingIndeterminate()
    repairFundingIndeterminate = true
    Session.pendingRepairCost = 0
end

-- A secure post-hook observes Repair All calls without replacing or modifying the repair API.
if RepairAllItems and hooksecurefunc then
    hooksecurefunc("RepairAllItems", function(useGuildBank)
        local currentCost = ReadRepairCost() or Session.lastRepairCost or 0
        -- Observe post-call state after Utilities records the known OUS repair transaction.
        if diagnosticsEnabled then
            local _, _, knownQueue = GetPendingKnownMovementState()
            AppendDiagnosticRecord("REPAIR_ALL_POST_HOOK", {
                "Use Guild Bank: " .. DiagnosticValue(useGuildBank),
                "GetMoney: " .. FormatDiagnosticMoney(GetMoney()),
                "lastMoney: " .. FormatDiagnosticMoney(Session.lastMoney),
                "Current Repair Cost: " .. FormatDiagnosticMoney(currentCost),
                "Pending Known Queue: " .. knownQueue,
            })
        end

        if repairFundingIndeterminate or useGuildBank then return end

        Session.pendingRepairCost = math.max(Session.pendingRepairCost or 0, Session.lastRepairCost or 0, currentCost)
    end)
end

-- Tracks gross wallet movement while keeping fallback repair attribution separate from explicit OUS repair bills.
local function HandlePlayerMoney()
    local currentMoney = GetMoney()
    local lastMoneyBefore = Session.lastMoney
    local gainedBefore = Session.sessionGoldGained
    local spentBefore = Session.sessionGoldSpent
    local repairsBefore = Session.sessionRepairSpent
    local pendingBefore = Session.pendingRepairCost
    local lastRepairBefore = Session.lastRepairCost
    local knownPositiveBefore, knownNegativeBefore, knownQueueBefore = GetPendingKnownMovementState()
    if Session.lastMoney == nil then
        Session.lastMoney = currentMoney
        AppendDiagnosticRecord("PLAYER_MONEY", {
            "GetMoney: " .. FormatDiagnosticMoney(currentMoney),
            "lastMoney before: nil",
            "Raw delta: unavailable",
            "Action: baseline established",
            "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
            "Pending Known Queue unchanged: " .. knownQueueBefore,
        })
        return
    end

    local rawDelta = currentMoney - Session.lastMoney
    local reconciledKnown, unexplainedDelta = ReconcilePendingKnownMovement(rawDelta)
    local currentRepairCost = GetCurrentRepairCost()

    if unexplainedDelta > 0 then
        Session.sessionGoldGained = Session.sessionGoldGained + unexplainedDelta
    elseif unexplainedDelta < 0 then
        local spent = -unexplainedDelta
        Session.sessionGoldSpent = Session.sessionGoldSpent + spent

        local repairSpent = 0
        if not repairFundingIndeterminate then
            if (Session.pendingRepairCost or 0) > 0 then
                repairSpent = math.min(spent, Session.pendingRepairCost)
                Session.pendingRepairCost = 0
            elseif currentRepairCost and Session.lastRepairCost and currentRepairCost < Session.lastRepairCost then
                repairSpent = math.min(spent, Session.lastRepairCost - currentRepairCost)
            end
        end

        Session.sessionRepairSpent = Session.sessionRepairSpent + repairSpent
    end

    Session.lastMoney = currentMoney
    if currentRepairCost ~= nil then
        Session.lastRepairCost = currentRepairCost
    end

    local knownPositiveAfter, knownNegativeAfter, knownQueueAfter = GetPendingKnownMovementState()

    AppendDiagnosticRecord("PLAYER_MONEY", {
        "GetMoney: " .. FormatDiagnosticMoney(currentMoney),
        "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
        "Raw delta: " .. FormatDiagnosticMoney(rawDelta, true),
        "Pending Known Positive before: " .. FormatDiagnosticMoney(knownPositiveBefore),
        "Pending Known Positive after: " .. FormatDiagnosticMoney(knownPositiveAfter),
        "Pending Known Negative before: " .. FormatDiagnosticMoney(knownNegativeBefore),
        "Pending Known Negative after: " .. FormatDiagnosticMoney(knownNegativeAfter),
        "Pending Known Queue before: " .. knownQueueBefore,
        "Pending Known Queue after: " .. knownQueueAfter,
        "Reconciled Known Movement: " .. FormatDiagnosticMoney(reconciledKnown, true),
        "Unexplained Remainder: " .. FormatDiagnosticMoney(unexplainedDelta, true),
        "Pending Repair Cost before: " .. FormatDiagnosticMoney(pendingBefore),
        "Pending Repair Cost after: " .. FormatDiagnosticMoney(Session.pendingRepairCost),
        "Current Repair Cost: " .. FormatDiagnosticMoney(currentRepairCost),
        "Last Repair Cost before: " .. FormatDiagnosticMoney(lastRepairBefore),
        "Last Repair Cost after: " .. FormatDiagnosticMoney(Session.lastRepairCost),
        "Classified Gold Gained: " .. FormatDiagnosticMoney(Session.sessionGoldGained - gainedBefore),
        "Classified Gold Spent: " .. FormatDiagnosticMoney(Session.sessionGoldSpent - spentBefore),
        "Repair Attribution: " .. FormatDiagnosticMoney(Session.sessionRepairSpent - repairsBefore),
        "Gold Gained before: " .. FormatDiagnosticMoney(gainedBefore),
        "Gold Gained after: " .. FormatDiagnosticMoney(Session.sessionGoldGained),
        "Gold Spent before: " .. FormatDiagnosticMoney(spentBefore),
        "Gold Spent after: " .. FormatDiagnosticMoney(Session.sessionGoldSpent),
        "Repairs before: " .. FormatDiagnosticMoney(repairsBefore),
        "Repairs after: " .. FormatDiagnosticMoney(Session.sessionRepairSpent),
        "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
    })

    SessionStats.Refresh()
end

-- Starts and ends the bounded repair-cost observation window at repair merchants.
local function HandleMerchantEvent(event)
    local lastMoneyBefore = Session.lastMoney
    local _, _, knownQueue = GetPendingKnownMovementState()
    if event == "MERCHANT_SHOW" then
        Session.repairMerchantOpen = true
        Session.lastRepairCost = GetCurrentRepairCost()
        Session.pendingRepairCost = 0
    else
        Session.repairMerchantOpen = false
        Session.lastRepairCost = nil
        Session.pendingRepairCost = 0
    end

    AppendDiagnosticRecord(event, {
        "GetMoney: " .. FormatDiagnosticMoney(GetMoney()),
        "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
        "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
        "Repair Merchant Open: " .. DiagnosticValue(Session.repairMerchantOpen),
        "Last Repair Cost: " .. FormatDiagnosticMoney(Session.lastRepairCost),
        "Pending Repair Cost: " .. FormatDiagnosticMoney(Session.pendingRepairCost),
        "Pending Known Queue unchanged: " .. knownQueue,
    })
end

-- Initializes runtime-only counters while later lifecycle events establish money and crest baselines.
local function InitializeSessionStats()
    repairFundingIndeterminate = false
    Session.sessionGoldGained = 0
    Session.sessionGoldSpent = 0
    Session.sessionRepairSpent = 0
    Session.sessionJunkItems = 0
    Session.sessionJunkGold = 0
    Session.crestStats = {}
    Session.pendingKnownWalletMovements = {}
    Session.lastMoney = nil
    Session.repairMerchantOpen = false
    Session.lastRepairCost = nil
    Session.pendingRepairCost = 0
end

-- Resets only runtime Session Stats and establishes fresh observable baselines for subsequent events.
function SessionStats.ResetCounters()
    -- Funding protection survives counter resets until this merchant interaction closes.
    local walletBefore = GetMoney()
    local lastMoneyBefore = Session.lastMoney
    local knownPositiveBefore, knownNegativeBefore, knownQueueBefore = GetPendingKnownMovementState()

    Session.sessionXP = 0
    Session.lastXPGain = 0
    Session.lastXP = UnitXP("player")
    Session.lastMaxXP = UnitXPMax("player")
    Session.sessionRep = {}

    Session.sessionGoldGained = 0
    Session.sessionGoldSpent = 0
    Session.sessionRepairSpent = 0
    Session.sessionJunkItems = 0
    Session.sessionJunkGold = 0
    Session.lastMoney = walletBefore
    Session.pendingKnownWalletMovements = {}
    Session.pendingRepairCost = 0
    Session.lastRepairCost = Session.repairMerchantOpen and GetCurrentRepairCost() or nil

    for _, resource in ipairs(BUILT_IN_RESOURCES) do
        local crestState = Session.crestStats[resource.key] or {}
        Session.crestStats[resource.key] = crestState
        crestState.sessionGained = 0
        crestState.lastQuantity = nil
    end
    UpdateSessionCrests(false)

    local knownPositiveAfter, knownNegativeAfter, knownQueueAfter = GetPendingKnownMovementState()
    AppendDiagnosticRecord("SESSION_STATS_RESET", {
        "GetMoney: " .. FormatDiagnosticMoney(walletBefore),
        "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
        "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
        "Pending Known Positive before: " .. FormatDiagnosticMoney(knownPositiveBefore),
        "Pending Known Positive after: " .. FormatDiagnosticMoney(knownPositiveAfter),
        "Pending Known Negative before: " .. FormatDiagnosticMoney(knownNegativeBefore),
        "Pending Known Negative after: " .. FormatDiagnosticMoney(knownNegativeAfter),
        "Pending Known Queue before: " .. knownQueueBefore,
        "Pending Known Queue after: " .. knownQueueAfter,
        "Experience baseline: " .. DiagnosticValue(Session.lastXP),
        "Experience maximum baseline: " .. DiagnosticValue(Session.lastMaxXP),
        "Gold Gained after: " .. FormatDiagnosticMoney(Session.sessionGoldGained),
        "Gold Spent after: " .. FormatDiagnosticMoney(Session.sessionGoldSpent),
        "Repairs after: " .. FormatDiagnosticMoney(Session.sessionRepairSpent),
        "Junk Items after: " .. DiagnosticValue(Session.sessionJunkItems),
        "Junk Gold after: " .. FormatDiagnosticMoney(Session.sessionJunkGold),
        "Pending Repair Cost after: " .. FormatDiagnosticMoney(Session.pendingRepairCost),
        "Last Repair Cost after: " .. FormatDiagnosticMoney(Session.lastRepairCost),
        "Mistcrest session gains reset and quantities re-baselined: true",
    })

    junkCallbacks:Fire("JunkChanged")
    SessionStats.Refresh()
end

StaticPopupDialogs["OUS_CONFIRM_RESET_SESSION_STATS"] = {
    text = "Reset Session Stats? Current-session counters will be cleared and re-baselined.",
    button1 = "Reset Counters",
    button2 = "Cancel",
    OnAccept = function()
        SessionStats.ResetCounters()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

local GOLD_DEBUG_HELP_TEXT = [[
|cffA78BFASUMMARY FIELDS|r

|cffFBBF24Current Wallet:|r Current character wallet returned by GetMoney() when the report is refreshed.
|cffFBBF24lastMoney:|r Last wallet value actually observed and accepted by Session Stats. It is never a predicted future value.
|cffFBBF24Gold Gained / Gold Spent:|r Gross personal-wallet income and spending this session, including personal repairs. Known OUS transactions count immediately; unexplained wallet gains or spending count through PLAYER_MONEY.
|cffFBBF24Repairs:|r Total known cost of repairs initiated by OUS this session, regardless of whether Blizzard uses personal funds, guild funds, or both. Personal wallet spending remains tracked separately in Gold Spent.
|cffFBBF24Junk Items:|r Physical item quantity sold automatically by OUS, using each sold stack count.
|cffFBBF24Junk Gold:|r Exact gross proceeds from OUS automatic junk sales. It is an informational subset of Gold Gained.
|cffFBBF24Pending Repair Cost:|r Repair amount awaiting attribution by the fallback repair observer.
|cffFBBF24Last Repair Cost:|r Previous merchant repair bill used to detect a repair-cost reduction.
|cffFBBF24Repair Merchant Open:|r Whether Session Stats is currently inside its bounded merchant repair-observation window.

|cffA78BFARECONCILIATION FIELDS|r

|cffFBBF24Raw delta:|r Current GetMoney() minus lastMoney before reconciliation. Positive is an observed wallet gain; negative is an observed wallet loss.
|cffFBBF24Pending Known Positive before / after:|r Expected positive personal-wallet movement from OUS transactions, normally junk sales, still awaiting observed wallet reconciliation.
|cffFBBF24Pending Known Negative before / after:|r Expected negative personal-wallet movement, normally personal-funded repairs. Indeterminate guild-first repairs add no expected wallet movement.
|cffFBBF24Pending Known Queue before / after:|r Ordered known wallet movements awaiting reconciliation. Positive entries are gains; negative entries are losses. Matching first looks for an exact cumulative total from the front of the queue. Otherwise, same-sign entries are consumed in queue order, skipping opposite-sign entries and allowing partial consumption.
|cffFBBF24Reconciled Known Movement:|r Portion of Raw delta matched to OUS transactions already counted explicitly, preventing duplicate accounting.
|cffFBBF24Unexplained Remainder:|r Observed wallet movement not matched to a known OUS transaction. Positive remainder adds Gold Gained; negative remainder adds Gold Spent.
|cffFBBF24Classified Gold Gained / Classified Gold Spent:|r Additional ordinary gain or spending assigned from the current PLAYER_MONEY remainder.
|cffFBBF24Repair Attribution:|r Portion of additional spending assigned to Repairs by the fallback repair observer during this PLAYER_MONEY event.

|cffA78BFAKNOWN TRANSACTION FIELDS|r

|cffFBBF24Transaction Type:|r VENDOR_INCOME or REPAIR_COST.
|cffFBBF24Funding Type:|r personal for personal repairs, indeterminate for guild-first repairs, and nil for junk sales.
|cffFBBF24Item Entries:|r Number of bag-slot sale entries represented by the notification. Current junk notifications represent one entry.
|cffFBBF24Stack Count:|r Physical item quantity represented by the current junk sale transaction.
|cffFBBF24Item ID:|r Blizzard item ID for the known junk transaction.
|cffFBBF24Amount:|r Exact known transaction value in copper and plain-text gold, silver, and copper.
|cffFBBF24GetMoney at notify:|r Observable wallet value when Utilities reports the known transaction.
|cffFBBF24Gold Gained before / after, Gold Spent before / after, Repairs before / after:|r Session accumulator values surrounding the record.
|cffFBBF24Junk Items before / after and Junk Gold before / after:|r Junk breakdown accumulators surrounding the known transaction.
|cffFBBF24Current Repair Cost:|r Current merchant repair bill when available.
Fields ending in before or after show state immediately before or after the named event processing.

|cffA78BFAJUNK PRICE DIAGNOSTICS|r

|cffFBBF24Bag item link:|r Actual current bag hyperlink used to price the sold stack.
|cffFBBF24Bag-link sellPrice (raw):|r Production per-unit sellPrice from C_Item.GetItemInfo(bag hyperlink). Amount for a junk sale is this price multiplied by Stack Count.
|cffFBBF24ItemID sellPrice (raw):|r ItemID-only price probe for comparison, not production accounting.
|cffFBBF24Bag-tooltip SellPrice (raw) / Bag-tooltip maxPrice (raw):|r Optional bag-tooltip comparison values, not production accounting. These and the ItemID probe can be nil even when production bag-link pricing succeeds; comparison probes run only with OUS debug mode enabled.
|cffFBBF24GetMoney before vendor call / GetMoney at notify:|r Actual wallet observations surrounding the sale call, not predicted proceeds.

|cffA78BFAEVENTS|r

#001, #002, and later numbers preserve exact diagnostic observation order.
|cffFBBF24DIAGNOSTICS_ENABLED:|r Logging was enabled and captures the current wallet, baseline, and pending queue.
|cffFBBF24ADDON_LOADED:|r Runtime counters are initialized. Addon names the loaded addon and Action describes initialization. The cold-login money baseline is intentionally left nil until PLAYER_ENTERING_WORLD.
|cffFBBF24PLAYER_ENTERING_WORLD:|r Establishes or refreshes the observed wallet baseline on login/reload, with isInitialLogin, isReloadingUi, and Baseline initialized/reset fields.
|cffFBBF24PLAYER_MONEY:|r Reconciles an observed wallet change, then records known movement, unexplained remainder, accumulator changes, and the accepted lastMoney value. Action describes the nil-baseline fallback when applicable.
|cffFBBF24MERCHANT_SHOW / MERCHANT_CLOSED:|r Merchant lifecycle boundaries with wallet, repair-open, and repair-cost state.
|cffFBBF24KNOWN_JUNK_SALE:|r Records the bag-link-priced gross amount, one bag-slot entry, and physical stack quantity when OUS issues the sale. It is a known OUS transaction, not a separate wallet confirmation.
|cffFBBF24KNOWN_REPAIR:|r Records the full known OUS repair bill once. Personal repairs also record their expected wallet effect; guild-first repairs leave wallet attribution to normal reconciliation.
|cffFBBF24REPAIR_ALL_POST_HOOK:|r Observes wallet and repair state after a Repair All call; OUS records its known repair transaction before invoking the API.
|cffFBBF24KNOWN_MOVEMENT_RECONCILIATION:|r Reports the matching mode. Prefix entries removed counts an exact ordered match; Consumption steps shows same-sign amounts consumed and any partial entry left pending.
|cffFBBF24SESSION_STATS_RESET:|r Clears session XP and reputation gains, Gold Gained, Gold Spent, Repairs, Junk Items, Junk Gold, and Mistcrest Session gains. XP, wallet, and crest quantities are rebaselined; the known queue and pending repair state are cleared, and the current repair bill is reread if the merchant is open. Guild-first attribution protection survives until merchant close. Current/Season crest values are refreshed, not zeroed. Lifetime/Overall Stats and SavedVariables are untouched. Existing diagnostic records remain; an enabled timeline records the reset.

All monetary fields show both raw copper and a plain-text g/s/c equivalent. Booleans, IDs, quantities, event names, and sequence numbers are not money-formatted.
]]

local goldDebugHelpFrame

-- Opens a scrollable reference that matches the diagnostic fields emitted by this file.
local function ShowGoldDebugHelp()
    if not goldDebugHelpFrame then
        goldDebugHelpFrame = CreateFrame("Frame", "OUSSessionStatsGoldDebugHelp", UIParent, "BackdropTemplate")
        goldDebugHelpFrame:SetSize(580, 520)
        goldDebugHelpFrame:SetPoint("CENTER", UIParent, "CENTER", 80, 20)
        goldDebugHelpFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        goldDebugHelpFrame:SetMovable(true)
        goldDebugHelpFrame:SetClampedToScreen(true)
        goldDebugHelpFrame:EnableMouse(true)
        goldDebugHelpFrame:RegisterForDrag("LeftButton")
        goldDebugHelpFrame:SetScript("OnDragStart", goldDebugHelpFrame.StartMoving)
        goldDebugHelpFrame:SetScript("OnDragStop", goldDebugHelpFrame.StopMovingOrSizing)
        goldDebugHelpFrame:Hide()
        tinsert(UISpecialFrames, goldDebugHelpFrame:GetName())

        goldDebugHelpFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        goldDebugHelpFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
        goldDebugHelpFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

        local title = goldDebugHelpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", goldDebugHelpFrame, "TOP", 0, -14)
        title:SetText("Gold Debug Help")
        title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

        local closeButton = CreateFrame("Button", nil, goldDebugHelpFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", goldDebugHelpFrame, "TOPRIGHT", -2, -2)

        local scrollFrame = CreateFrame("ScrollFrame", nil, goldDebugHelpFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", goldDebugHelpFrame, "TOPLEFT", 20, -44)
        scrollFrame:SetPoint("BOTTOMRIGHT", goldDebugHelpFrame, "BOTTOMRIGHT", -36, 18)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(512)
        scrollFrame:SetScrollChild(scrollChild)

        local helpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        helpText:SetPoint("TOPLEFT")
        helpText:SetWidth(512)
        helpText:SetJustifyH("LEFT")
        helpText:SetJustifyV("TOP")
        helpText:SetText(GOLD_DEBUG_HELP_TEXT)
        scrollChild:SetHeight(helpText:GetStringHeight() + 20)
    end

    goldDebugHelpFrame:Show()
end

-- Creates the temporary copyable gold-accounting timeline only when requested.
local function ShowGoldDiagnostics()
    if not diagnosticFrame then
        diagnosticFrame = CreateFrame("Frame", "OUSSessionStatsGoldDiagnostics", UIParent, "BackdropTemplate")
        diagnosticFrame:SetSize(680, 520)
        diagnosticFrame:SetPoint("CENTER")
        diagnosticFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        diagnosticFrame:SetMovable(true)
        diagnosticFrame:SetClampedToScreen(true)
        diagnosticFrame:EnableMouse(true)
        diagnosticFrame:RegisterForDrag("LeftButton")
        diagnosticFrame:SetScript("OnDragStart", diagnosticFrame.StartMoving)
        diagnosticFrame:SetScript("OnDragStop", diagnosticFrame.StopMovingOrSizing)
        diagnosticFrame:Hide()
        tinsert(UISpecialFrames, diagnosticFrame:GetName())

        diagnosticFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        diagnosticFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
        diagnosticFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

        local title = diagnosticFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", diagnosticFrame, "TOP", 0, -14)
        title:SetText("OUS Session Stats Gold Diagnostics")
        title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

        local closeButton = CreateFrame("Button", nil, diagnosticFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", diagnosticFrame, "TOPRIGHT", -2, -2)

        local helpButton = CreateFrame("Button", nil, diagnosticFrame, "UIPanelButtonTemplate")
        helpButton:SetSize(22, 22)
        helpButton:SetPoint("TOPRIGHT", diagnosticFrame, "TOPRIGHT", -34, -6)
        helpButton:SetText("?")
        helpButton:SetScript("OnClick", ShowGoldDebugHelp)

        local enableCheckButton = CreateFrame("CheckButton", nil, diagnosticFrame, "UICheckButtonTemplate")
        enableCheckButton:SetSize(24, 24)
        enableCheckButton:SetPoint("TOPLEFT", diagnosticFrame, "TOPLEFT", 18, -38)
        enableCheckButton:SetChecked(diagnosticsEnabled)
        diagnosticFrame.enableCheckButton = enableCheckButton

        local enableLabel = diagnosticFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        enableLabel:SetPoint("LEFT", enableCheckButton, "RIGHT", 2, 0)
        enableLabel:SetText("Enable Gold Diagnostics")

        enableCheckButton:SetScript("OnClick", function(self)
            diagnosticsEnabled = self:GetChecked() == true
            if diagnosticsEnabled then
                AppendDiagnosticRecord("DIAGNOSTICS_ENABLED", {
                    "GetMoney: " .. FormatDiagnosticMoney(GetMoney()),
                    "lastMoney: " .. FormatDiagnosticMoney(Session.lastMoney),
                    "Pending Known Queue: " .. select(3, GetPendingKnownMovementState()),
                })
            end
            diagnosticEditBox:SetText(BuildDiagnosticText())
            diagnosticEditBox:SetCursorPosition(0)
        end)

        local scrollFrame = CreateFrame("ScrollFrame", nil, diagnosticFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", diagnosticFrame, "TOPLEFT", 18, -70)
        scrollFrame:SetPoint("BOTTOMRIGHT", diagnosticFrame, "BOTTOMRIGHT", -34, 48)
        diagnosticFrame.scrollFrame = scrollFrame

        diagnosticEditBox = CreateFrame("EditBox", nil, scrollFrame)
        diagnosticEditBox:SetMultiLine(true)
        diagnosticEditBox:SetAutoFocus(false)
        diagnosticEditBox:SetFontObject(ChatFontNormal)
        diagnosticEditBox:SetWidth(618)
        diagnosticEditBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        scrollFrame:SetScrollChild(diagnosticEditBox)

        local clearButton = CreateFrame("Button", nil, diagnosticFrame, "UIPanelButtonTemplate")
        clearButton:SetSize(100, 24)
        clearButton:SetPoint("BOTTOMLEFT", diagnosticFrame, "BOTTOMLEFT", 18, 14)
        clearButton:SetText("Clear Log")
        clearButton:SetScript("OnClick", function()
            diagnosticRecords = {}
            diagnosticSequence = 0
            diagnosticEditBox:SetText(BuildDiagnosticText())
            diagnosticEditBox:SetCursorPosition(0)
            scrollFrame:SetVerticalScroll(0)
        end)

        local copyHelp = diagnosticFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        copyHelp:SetPoint("BOTTOMRIGHT", diagnosticFrame, "BOTTOMRIGHT", -18, 20)
        copyHelp:SetText("Click text, then press Ctrl+A and Ctrl+C")
    end

    diagnosticFrame.enableCheckButton:SetChecked(diagnosticsEnabled)
    diagnosticEditBox:SetText(BuildDiagnosticText())
    diagnosticEditBox:SetCursorPosition(0)
    diagnosticFrame.scrollFrame:SetVerticalScroll(0)
    diagnosticFrame:Show()
end

-- Lets broker clicks reuse the existing show-only diagnostic construction and refresh path.
SessionStats.ShowGoldDiagnostics = ShowGoldDiagnostics

local diagnosticsButton = CreateFrame("Button", nil, stats, "UIPanelButtonTemplate")
diagnosticsButton:SetSize(88, 20)
diagnosticsButton:SetPoint("TOPLEFT", stats, "TOPLEFT", 8, -8)
diagnosticsButton:SetText("Gold Debug")
diagnosticsButton:SetScript("OnClick", ShowGoldDiagnostics)
diagnosticsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Gold Debug")
    GameTooltip:AddLine("Opens detailed diagnostic information for Session Stats gold accounting.", 1, 1, 1, true)
    GameTooltip:AddLine("Intended for troubleshooting money, junk-sale, and repair tracking.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)
diagnosticsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local resetCountersButton = CreateFrame("Button", nil, stats, "UIPanelButtonTemplate")
resetCountersButton:SetSize(118, 22)
resetCountersButton:SetPoint("BOTTOM", stats, "BOTTOM", 0, 10)
resetCountersButton:SetText("Reset Counters")
resetCountersButton:SetScript("OnClick", function()
    StaticPopup_Show("OUS_CONFIRM_RESET_SESSION_STATS")
end)

stats.scrollBox = CreateFrame("Frame", nil, stats, "WowScrollBox")
stats.scrollBox:SetPoint("TOPLEFT", 20, -50)
stats.scrollBox:SetPoint("BOTTOMRIGHT", -36, 42)

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
for _, label in ipairs({ "Gold Gained:", "Gold Spent:", "Repairs (Own + Guild):", "Junk:" }) do
    local row = {
        label = CreateStatsText("GameFontHighlight", 144, "LEFT"),
        value = CreateStatsText("GameFontHighlight", 174, "LEFT"),
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
    self.goldRows[4].value:SetText(string.format("%d items / %s",
        Session.sessionJunkItems, FormatSessionMoney(Session.sessionJunkGold)))
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

        local visibleGoldRows = {
            sections.gold,
            sections.gold,
            sections.repairs,
            sections.gold,
        }
        for index, isVisible in ipairs(visibleGoldRows) do
            local row = self.goldRows[index]
            if isVisible then
                row.label:Show()
                row.value:Show()
                PositionStatsText(row.label, 0, y)
                PositionStatsText(row.value, 150, y)
                y = y - 18
            end
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
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    -- Clear interaction protection even when XPBar tracking has been disabled meanwhile.
    if event == "MERCHANT_CLOSED" then
        repairFundingIndeterminate = false
    end
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            local currentMoney = GetMoney()
            local lastMoneyBefore = Session.lastMoney
            SessionStats.GetSettings()
            InitializeSessionStats()
            junkCallbacks:Fire("JunkChanged")
            AppendDiagnosticRecord("ADDON_LOADED", {
                "Addon: " .. DiagnosticValue(arg1),
                "GetMoney: " .. FormatDiagnosticMoney(currentMoney),
                "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
                "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
                "Action: runtime counters reset; money baseline left uninitialized",
            })
        end
        return
    end

    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end

    if event == "PLAYER_ENTERING_WORLD" then
        local currentMoney = GetMoney()
        local lastMoneyBefore = Session.lastMoney
        local _, _, knownQueue = GetPendingKnownMovementState()
        local baselineReset = arg1 or arg2 or Session.lastMoney == nil
        if baselineReset then
            Session.lastMoney = currentMoney
        end
        AppendDiagnosticRecord("PLAYER_ENTERING_WORLD", {
            "isInitialLogin: " .. DiagnosticValue(arg1),
            "isReloadingUi: " .. DiagnosticValue(arg2),
            "GetMoney: " .. FormatDiagnosticMoney(currentMoney),
            "lastMoney before: " .. FormatDiagnosticMoney(lastMoneyBefore),
            "lastMoney after: " .. FormatDiagnosticMoney(Session.lastMoney),
            "Baseline initialized/reset: " .. DiagnosticValue(baselineReset),
            "Pending Known Queue unchanged: " .. knownQueue,
        })
    elseif event == "PLAYER_MONEY" then
        HandlePlayerMoney()
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_CLOSED" then
        HandleMerchantEvent(event)
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        UpdateSessionCrests(true)
        SessionStats.Refresh()
    end
end)

-- Opens the existing session window without toggling it closed for broker clicks.
function SessionStats.Show()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    stats:Show()
    stats:UpdateData()
    stats.scrollBox:ScrollToBegin()
end

SLASH_XPSTATS1 = "/xpstats"
SlashCmdList["XPSTATS"] = function()
    if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then return end
    if stats:IsShown() then
        stats:Hide()
    else
        SessionStats.Show()
    end
end
