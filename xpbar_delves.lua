-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : xpbar_delves.lua
-- Version : 2026.08.05
-- Desc    : Delves companion tracking and session detection for XP/rep bar
-- ============================================================

-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP DELVES ENGINE
-- ==========================================
local _, OUS = ...
local Session = OUS.XPBarSession
local delveBar = OUS.delveBarFrame

-- Alt+Left-click either bar to print delve debug info to chat.
local function DelveBarClickHandler(_, button)
    if button == "LeftButton" and IsAltKeyDown() then
        local _, _, _, _, _, _, _, iID = GetInstanceInfo()
        local uiMap = C_Map.GetBestMapForUnit("player")
        print(string.format("|cFF00CCFFOdysseus Delve Debug:|r iID: %s | uiMap: %s | companion: %s",
            tostring(iID), tostring(uiMap), tostring(Session.activeDelveCompanion)))
    end
end

Session.isTestingDelve = false
Session.isDelveBarUnlocked = false
Session.isMovingDelveBar = false

-- Position saving remains shared by mouse release, explicit locking, and combat interruption.
local function SaveDelveBarPosition()
    local db = OdysseusDB and OdysseusDB.xpBar
    if not db then return end

    local point, _, relativePoint, x, y = delveBar:GetPoint()
    if not point then return end

    db.delveBarPos = { p = point, rP = relativePoint, x = x, y = y }
end

-- Movement always terminates before the temporary edit state is cleared.
local function StopDelveBarMovement(savePosition)
    delveBar:StopMovingOrSizing()
    if savePosition then
        SaveDelveBarPosition()
    end
    Session.isMovingDelveBar = false
end

local function StartDelveBarMovement()
    if not Session.isDelveBarUnlocked or InCombatLockdown() then return end

    Session.isMovingDelveBar = true
    delveBar:StartMoving()
end

local function FinishDelveBarMovement()
    if not Session.isMovingDelveBar then return end
    StopDelveBarMovement(true)
end

-- All visible Delves bar layers share the same guarded drag behavior.
local function ConfigureDelveDragTarget(target)
    target:EnableMouse(true)
    target:RegisterForDrag("LeftButton")
    target:SetScript("OnDragStart", StartDelveBarMovement)
    target:SetScript("OnDragStop", FinishDelveBarMovement)
end

ConfigureDelveDragTarget(delveBar)
ConfigureDelveDragTarget(delveBar.compBar)
ConfigureDelveDragTarget(delveBar.jourBar)
delveBar.compBar:SetScript("OnMouseUp", DelveBarClickHandler)
delveBar.jourBar:SetScript("OnMouseUp", DelveBarClickHandler)

-- ==========================================
-- 2. DELVES HELPERS
-- ==========================================

-- Midnight-expansion delves that use Valeera Sanguinar as companion.
local VALEERA_INSTANCE_IDS = {
    [2933] = true, -- Collegiate Calamity
    [2952] = true, -- The Shadow Enclave
    [2953] = true, -- Parhelion Plaza
    [2961] = true, -- Twilight Crypts
    [2962] = true, -- Atal'Aman
    [2963] = true, -- The Grudge Pit
    [2964] = true, -- The Gulf of Memory
    [2965] = true, -- Sunkiller Sanctum
    [2966] = true, -- Torment's Rise
    [2979] = true, -- Shadowguard Point
    [3003] = true, -- The Darkway
    [3038] = true, -- Gnarldor Isle
    [3077] = true, -- The Ring of Glory
}
local VALEERA_MAP_IDS = {
    [2933] = true, -- Collegiate Calamity
    [2952] = true, -- The Shadow Enclave
    [2953] = true, -- Parhelion Plaza
    [2961] = true, -- Twilight Crypts
    [2962] = true, -- Atal'Aman
    [2963] = true, -- The Grudge Pit
    [2964] = true, -- The Gulf of Memory
    [2965] = true, -- Sunkiller Sanctum
    [2966] = true, -- Torment's Rise
    [2979] = true, -- Shadowguard Point
    [3003] = true, -- The Darkway
    [2635] = true, -- Gnarldor Isle
    [2633] = true, -- The Ring of Glory
}

-- Delves that fall above the Valeera thresholds but actually use Brann.
local BRANN_EXCEPTION_INSTANCE_IDS = { [2951]=true }
local BRANN_EXCEPTION_MAP_IDS      = { [2484]=true }
-- Instances that match delve heuristics but are NOT delves (e.g. PvP scenarios).
local NON_DELVE_INSTANCE_IDS = {
    [3022] = true, -- Decor Duel
    [3074] = true, -- Eversong Woods Ritual Site
    [3018] = true, -- Broken throne Ritual Site
    [2987] = true, -- The Tidebound Grotto
}
local NON_DELVE_MAP_IDS = {
    [2537] = true, -- Decor Duel
    [2594] = true, -- Eversong Woods Ritual Site
    [2585] = true, -- Broken throne Ritual Site
    [2632] = true, -- The Tidebound Grotto
}

local function IsPlayerReallyInDelve()
    local _, instanceType = IsInInstance()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0

    -- Explicit exclusions: non-delve scenarios that match delve heuristics.
    if NON_DELVE_INSTANCE_IDS[instanceID] or NON_DELVE_MAP_IDS[uiMapID] then
        return false
    end

    -- Primary signal
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
        return true
    end

    -- Fallback: still physically inside a delve scenario even after the boss
    -- has died and Blizzard has already ended the "in progress" flag.
    if instanceType == "scenario" then
        -- Delves currently report difficulty 208 in your test and use delve maps/instances.
        if difficultyID == 208 then
            return true
        end

        -- Extra safety if Blizzard changes one side but not the other.
        if (instanceID and instanceID >= 2800) or (uiMapID and uiMapID >= 2350) then
            return true
        end
    end

    return false
end

local function IsPlayerInDelve()
    return Session.isTestingDelve or IsPlayerReallyInDelve()
end

-- Temporary edit mode reuses the existing test renderer only outside a real Delve.
local function SetDelveBarUnlocked(unlocked, bypassCombatCheck)
    unlocked = unlocked == true
    if not bypassCombatCheck and InCombatLockdown() then
        return false
    end
    if unlocked and (not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar) then
        return false
    end

    if unlocked then
        Session.isDelveBarUnlocked = true
        delveBar:SetMovable(true)
    else
        StopDelveBarMovement(true)
        Session.isDelveBarUnlocked = false
        Session.isTestingDelve = false
        delveBar:SetMovable(false)
    end

    if OUS.UpdateDelveBar then
        OUS.UpdateDelveBar()
    end
    return true
end

-- Reports the temporary Delves positioning state to configuration controls.
function OUS.IsDelveBarUnlocked()
    return Session.isDelveBarUnlocked == true
end

-- Toggles temporary Delves positioning only while out of combat.
function OUS.SetDelveBarUnlocked(unlocked)
    return SetDelveBarUnlocked(unlocked, false)
end

local delveCombatFrame = CreateFrame("Frame")
delveCombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
delveCombatFrame:SetScript("OnEvent", function()
    if Session.isDelveBarUnlocked then
        SetDelveBarUnlocked(false, true)
    end
end)

local function GetActiveDelveCompanion()
    if not OdysseusDB then
        return "Companion", 2640
    end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0

    -- Brann exceptions take priority over any whitelist check.
    if BRANN_EXCEPTION_INSTANCE_IDS[instanceID] or BRANN_EXCEPTION_MAP_IDS[uiMapID] then
        Session.activeDelveCompanion = "brann"
        return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640
    end

    if VALEERA_INSTANCE_IDS[instanceID] or VALEERA_MAP_IDS[uiMapID] then
        Session.activeDelveCompanion = "valeera"
        return "Valeera Sanguinar", OdysseusDB.xpBar.delveValeeraID or 2744
    end

    -- Sticky fallback: Blizzard may swap instance IDs after the final boss dies;
    -- reuse the last known companion so the bar doesn't flip mid-delve.
    if IsPlayerInDelve() then
        if Session.activeDelveCompanion == "valeera" then
            return "Valeera Sanguinar", OdysseusDB.xpBar.delveValeeraID or 2744
        end
        if Session.activeDelveCompanion == "brann" then
            return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640
        end
    end

    Session.activeDelveCompanion = "brann"
    return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640
end

-- ==========================================
-- 3. DELVES RENDERING
-- ==========================================
function OUS.UpdateDelveBar()
    if not OdysseusDB or not OdysseusDB.xpBar or not delveBar then return end
    local db = OdysseusDB.xpBar
    local isRealDelve = IsPlayerReallyInDelve()
    Session.isTestingDelve = Session.isDelveBarUnlocked == true and not isRealDelve

    if isRealDelve or Session.isTestingDelve then
        local compName, compFactionID = GetActiveDelveCompanion()

        local compMaxLevel = 60
        if compName == "Brann Bronzebeard" then
            compMaxLevel = 100
        elseif compName == "Valeera Sanguinar" then
            compMaxLevel = 60
        end

        local cXP, cMax, cLvl, isMaxed = 0, 1, 1, false

        if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
            local repInfo = C_GossipInfo.GetFriendshipReputation(compFactionID)
            if repInfo and repInfo.friendshipFactionID > 0 then
                local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(compFactionID)
                if rankInfo and rankInfo.currentLevel then
                    cLvl = rankInfo.currentLevel
                    if rankInfo.currentLevel >= rankInfo.maxLevel then
                        isMaxed = true
                        cMax = 1
                        cXP = 1
                    else
                        cXP = repInfo.standing - repInfo.reactionThreshold
                        cMax = repInfo.nextThreshold - repInfo.reactionThreshold
                    end
                end
            end
        end

        local jRep, jMax, jLvl, jNextLvl = 0, 1, "?", "?"

        if C_DelvesUI and C_DelvesUI.GetDelvesFactionForSeason and C_MajorFactions and C_MajorFactions.GetMajorFactionRenownInfo then
            -- Resolve Delves seasonal Journey (Renown-based progression)
            local journeyFactionID = C_DelvesUI.GetDelvesFactionForSeason()
            if journeyFactionID then
                local renownInfo = C_MajorFactions.GetMajorFactionRenownInfo(journeyFactionID)
                if renownInfo then
                    jLvl = renownInfo.renownLevel or "?" ---@diagnostic disable-line: cast-local-type

                    local level     = renownInfo.renownLevel or 0
                    local earned    = renownInfo.renownReputationEarned or 0
                    local threshold = renownInfo.renownLevelThreshold or 0

                    -- At max renown Blizzard returns earned=0 with threshold>0 and level>0
                    local isJourneyMaxed = (level > 0) and (earned == 0) and (threshold > 0)

                    if isJourneyMaxed then
                        jRep     = threshold
                        jMax     = threshold
                        jNextLvl = "Max"
                    else
                        jRep  = earned
                        jMax  = threshold > 0 and threshold or 1
                        jNextLvl = level + 1 ---@diagnostic disable-line: cast-local-type
                    end
                end
            end
        end

        if Session.isTestingDelve then
            cXP, cMax, cLvl = 25000, 83000, 15
            jRep, jMax = 1200, 5000
            jLvl, jNextLvl = 4, 5 ---@diagnostic disable-line: cast-local-type
            isMaxed = false
        end

        delveBar.compBar:SetMinMaxValues(0, cMax)
        delveBar.compBar:SetValue(cXP)
        delveBar.compBar:SetStatusBarColor(db.delveCompColor.r, db.delveCompColor.g, db.delveCompColor.b, 1)
        delveBar.compText:SetText(
            OUS.ParseXPText(db.delveCompTemplate, cXP, cMax, 0, cLvl, compMaxLevel, "?", isMaxed, compName)
        )

        delveBar.jourBar:SetMinMaxValues(0, jMax)
        delveBar.jourBar:SetValue(jRep)
        delveBar.jourBar:SetStatusBarColor(db.delveJourColor.r, db.delveJourColor.g, db.delveJourColor.b, 1)
        if jNextLvl == "Max" then
            delveBar.jourText:SetText(string.format("Journey: (Lvl: %s) :: |cFFFFD100MAX|r", tostring(jLvl)))
        else
            delveBar.jourText:SetText(OUS.ParseRepText(db.delveJourTemplate, "Journey", "Active", jRep, jMax, false, jLvl, jNextLvl))
        end

        delveBar:Show()
    else
        Session.activeDelveCompanion = nil
        delveBar:Hide()
    end
end

function OUS.TriggerAggressiveDelveCheck()
    if Session.delveCheckTicker then Session.delveCheckTicker:Cancel() end
    local checks = 0
    Session.delveCheckTicker = C_Timer.NewTicker(1, function()
        checks = checks + 1
        if IsPlayerInDelve() or checks >= 10 then
            OUS.WakeBars()
            OUS.UpdateBar()
            OUS.SleepBars()
            if Session.delveCheckTicker then Session.delveCheckTicker:Cancel() end
        end
    end)
end
