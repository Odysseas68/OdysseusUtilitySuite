-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP DELVES ENGINE
-- ==========================================
local addonName, OUS = ...
local Session = OUS.XPBarSession
local delveBar = OUS.delveBarFrame

-- ==========================================
-- 2. DELVES HELPERS
-- ==========================================
local function GetActiveDelveCompanion()
    if not OdysseusDB then return "Companion", 2640 end
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0

    if (instanceID and instanceID >= 2800) or (uiMapID >= 2350) then
        return "Valeera Sanguinar", OdysseusDB.xpBar.delveValeeraID or 2744
    else
        return "Brann Bronzebeard", OdysseusDB.xpBar.delveBrannID or 2640
    end
end

local function IsPlayerInDelve()
    if Session.isTestingDelve then
        return true
    end

    local inInstance, instanceType = IsInInstance()
    local name, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player") or 0

    -- Primary signal
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
        return true
    end

    -- Fallback: still physically inside a delve scenario even after the boss
    -- has died and Blizzard has already ended the "in progress" flag.
    if inInstance and instanceType == "scenario" then
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

-- ==========================================
-- 3. DELVES RENDERING
-- ==========================================
function OUS.UpdateDelveBar()
    if not OdysseusDB or not OdysseusDB.xpBar or not delveBar then return end
    local db = OdysseusDB.xpBar

    if IsPlayerInDelve() then
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
                    jRep = renownInfo.renownReputationEarned or 0
                    jMax = renownInfo.renownLevelThreshold or 1
                    jLvl = renownInfo.renownLevel or "?"

                    if jMax == 0 then jMax = 1 end

                    if jRep < jMax then
                        jNextLvl = (renownInfo.renownLevel or 0) + 1
                    else
                        jNextLvl = "Max"
                    end
                end
            end
        end

        if Session.isTestingDelve and cMax <= 1 and jMax <= 1 then
            cXP, cMax, cLvl = 25000, 83000, 15
            jRep, jMax = 1200, 5000
            jLvl, jNextLvl = 4, 5
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
        delveBar.jourText:SetText(OUS.ParseRepText(db.delveJourTemplate, "Journey", "Active", jRep, jMax, false, jLvl, jNextLvl))

        delveBar:Show()
    else
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