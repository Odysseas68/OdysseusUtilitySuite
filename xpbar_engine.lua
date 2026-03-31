-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP & REP ENGINE
-- ==========================================
local addonName, OUS = ...
local f = CreateFrame("Frame")
local Session = OUS.XPBarSession
local xpBar = OUS.xpBarFrame
local delveBar = OUS.delveBarFrame
local toast = OUS.toastFrame

function OUS.ApplyXPBarBorders()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    local bName = db.barBorderName or "None"
    local bPath = LibStub("LibSharedMedia-3.0"):Fetch("border", bName)
    local bSize = db.barBorderSize or 16
    local bColor = db.barBorderColor or {r=1, g=1, b=1}

    local function ApplyToFrame(barFrame)
        local borderFrame = barFrame.borderFrame
        if not borderFrame then return end

        if bPath and bName ~= "None" then
            borderFrame:SetBackdrop({ edgeFile = bPath, edgeSize = bSize })
            borderFrame:SetBackdropBorderColor(bColor.r, bColor.g, bColor.b, 1)
            local offset = math.floor(bSize / 3)
            borderFrame:ClearAllPoints()
            borderFrame:SetPoint("TOPLEFT", barFrame, "TOPLEFT", -offset, offset)
            borderFrame:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", offset, -offset)
        else
            borderFrame:SetBackdrop(nil)
            borderFrame:ClearAllPoints()
            borderFrame:SetAllPoints(barFrame)
        end
    end

    ApplyToFrame(xpBar)
    ApplyToFrame(delveBar)
end

-- ==========================================
-- 2. CORE VISUAL HELPERS
-- ==========================================
function OUS.ApplyFonts()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    
    if LSM then 
        fontPath = LSM:Fetch("font", OdysseusDB.xpBar.xpFont) or fontPath 
    end
    
    local size = OdysseusDB.xpBar.xpFontSize or 12
    xpBar.text:SetFont(fontPath, size, "OUTLINE")
    delveBar.compText:SetFont(fontPath, math.max(8, size - 2), "OUTLINE")
    delveBar.jourText:SetFont(fontPath, math.max(8, size - 2), "OUTLINE")
end

function OUS.ApplyDimensions()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    
    xpBar:SetSize(db.xpBarWidth or 400, db.xpBarHeight or 24)
    xpBar:SetScale(db.xpBarScale or 1.0)
    
    delveBar:SetSize(db.delveBarWidth or 300, db.delveBarHeight or 40)
    delveBar:SetScale(db.delveBarScale or 1.0)
    
    local innerHeight = ((db.delveBarHeight or 40) - 2) / 2
    delveBar.compBar:SetSize((db.delveBarWidth or 300) - 2, innerHeight)
    delveBar.jourBar:SetSize((db.delveBarWidth or 300) - 2, innerHeight)
end

function OUS.FadeBarsTo(targetAlpha)
    if Session.fadeTicker then Session.fadeTicker:Cancel() end
    
    local currentAlpha = xpBar:GetAlpha()
    local step = (targetAlpha - currentAlpha) / 10
    if step == 0 then return end
    
    local count = 0
    Session.fadeTicker = C_Timer.NewTicker(0.02, function()
        count = count + 1
        local newAlpha = currentAlpha + (step * count)
        xpBar:SetAlpha(newAlpha)
        delveBar:SetAlpha(newAlpha)
        
        if count >= 10 then 
            xpBar:SetAlpha(targetAlpha)
            delveBar:SetAlpha(targetAlpha) 
        end
    end, 10)
end

function OUS.WakeBars()
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then 
        OUS.FadeBarsTo((OdysseusDB and OdysseusDB.xpBar.activeAlpha or 100) / 100)
        return 
    end
    
    if Session.sleepTimer then 
        Session.sleepTimer:Cancel()
        Session.sleepTimer = nil 
    end
    
    OUS.FadeBarsTo(OdysseusDB.xpBar.activeAlpha / 100)
end

function OUS.SleepBars()
    if not OdysseusDB or not OdysseusDB.xpBar.autoHide then return end
    if UnitAffectingCombat("player") or xpBar:IsMouseOver() or delveBar:IsMouseOver() or Session.forceRepDisplay or (OUS.favHoverFrame and OUS.favHoverFrame:IsMouseOver()) then return end
    
    if Session.sleepTimer then Session.sleepTimer:Cancel() end
    
    Session.sleepTimer = C_Timer.NewTimer(OdysseusDB.xpBar.fadeDelay, function()
        if not UnitAffectingCombat("player") and not xpBar:IsMouseOver() and not delveBar:IsMouseOver() and not Session.forceRepDisplay and not (OUS.favHoverFrame and OUS.favHoverFrame:IsMouseOver()) then 
            OUS.FadeBarsTo(OdysseusDB.xpBar.fadedAlpha / 100) 
        end
    end)
end

-- Small helper to refresh bars consistently
-- Convenience wrapper for common wake → update → sleep flow
local function RefreshBars()
    OUS.WakeBars()
    OUS.UpdateBar()
    OUS.SleepBars()
end

delveBar:HookScript("OnEnter", OUS.WakeBars)
delveBar:HookScript("OnLeave", OUS.SleepBars)

-- ==========================================
-- 3. WAYPOINT ASSISTANT (TOAST CLICK)
-- ==========================================
toast:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() and self.factionID then
        local data = OUS.FactionData and OUS.FactionData[self.factionID]
        if data and data.rewardNPC and data.rewardNPC.mapID and data.rewardNPC.mapID > 0 then
            local npc = data.rewardNPC
            
            if TomTom and TomTom.AddWaypoint then
                TomTom:AddWaypoint(npc.mapID, npc.x/100, npc.y/100, { title = "Quartermaster (" .. data.name .. ")", persistent = false, minimap = true, world = true })
            end
            
            if C_Map.CanSetUserWaypointOnMap(npc.mapID) then
                C_Map.ClearUserWaypoint()
                local pt = UiMapPoint.CreateFromCoordinates(npc.mapID, npc.x/100, npc.y/100)
                C_Map.SetUserWaypoint(pt)
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_WIDGET_CLICK)
                print("|cFF00FF00Odysseus:|r Waypoint set for " .. data.name .. " Quartermaster!")
                OUS.LogDebug("XPBar", "Map Waypoint created for Quartermaster.")
            else
                print("|cFFFF0000Odysseus:|r Blizzard API blocked the pin. Map ID " .. npc.mapID .. " might not support waypoints yet.")
            end
            toast:Hide()
        else
            print("|cFF00FFFFOdysseus:|r No Quartermaster location data saved for this faction yet.")
        end
    end
end)

-- ==========================================
-- 4. PARSERS & STRING REPLACEMENT
-- ==========================================
function OUS.ParseXPText(template, curXP, maxXP, restXP, level, mLVL, ktl, isMaxed, compName)
    local str = template or ""
    local needXP = maxXP - curXP
    local curPC = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
    local needPC = maxXP > 0 and math.ceil((needXP / maxXP) * 100) or 0
    local restPC = (maxXP > 0 and restXP > 0) and math.floor((restXP / maxXP) * 100) or 0
    local restLVL = maxXP > 0 and string.format("%.2f", restXP / maxXP) or "0"
    local btl = maxXP > 0 and math.ceil(needXP / (maxXP / 20)) or 0
    
    if isMaxed then 
        str = string.gsub(str, "%[curXP%]/%[maxXP%]", "Max Level")
        str = string.gsub(str, "%[curXP%]", "Max")
        str = string.gsub(str, "%[maxXP%]", "Max")
        str = string.gsub(str, "%[needXP%]", "0")
    else 
        str = string.gsub(str, "%[curXP%]", OUS.FormatLargeNumber(curXP))
        str = string.gsub(str, "%[maxXP%]", OUS.FormatLargeNumber(maxXP))
        str = string.gsub(str, "%[needXP%]", OUS.FormatLargeNumber(needXP)) 
    end
    
    str = string.gsub(str, "%[restXP%]", OUS.FormatLargeNumber(restXP))
    str = string.gsub(str, "%[curPC%]", curPC)
    str = string.gsub(str, "%[needPC%]", needPC)
    str = string.gsub(str, "%[restPC%]", restPC)
    str = string.gsub(str, "%[pLVL%]", level)
    str = string.gsub(str, "%[nLVL%]", level + 1)
    str = string.gsub(str, "%[mLVL%]", mLVL)
    str = string.gsub(str, "%[restLVL%]", restLVL)
    str = string.gsub(str, "%[KTL%]", ktl or "?")
    str = string.gsub(str, "%[BTL%]", btl)
    
    if compName then str = string.gsub(str, "%[compName%]", compName) end
    return str
end

function OUS.ParseRepText(template, name, standingText, curRep, maxRep, isMaxed, curLevel, nextLevel)
    local str = template or ""
    local needRep = maxRep - curRep
    local repPC = maxRep > 0 and math.floor((curRep / maxRep) * 100) or 100
    local needPC = maxRep > 0 and math.ceil((needRep / maxRep) * 100) or 0
    
    if isMaxed then 
        str = string.gsub(str, "%[curRep%]/%[maxRep%]", "Max Level")
        str = string.gsub(str, "%[curRep%]", "Max")
        str = string.gsub(str, "%[maxRep%]", "Max")
        str = string.gsub(str, "%[needRep%]", "0")
    else 
        str = string.gsub(str, "%[curRep%]", OUS.FormatLargeNumber(curRep))
        str = string.gsub(str, "%[maxRep%]", OUS.FormatLargeNumber(maxRep))
        str = string.gsub(str, "%[needRep%]", OUS.FormatLargeNumber(needRep)) 
    end
    
    str = string.gsub(str, "%[faction%]", name or "Unknown")
    str = string.gsub(str, "%[standing%]", standingText or "Neutral")
    str = string.gsub(str, "%[repPC%]", repPC)
    str = string.gsub(str, "%[needPC%]", needPC)
    str = string.gsub(str, "%[curLVL%]", tostring(curLevel or "?"))
    str = string.gsub(str, "%[nextLVL%]", tostring(nextLevel or "?"))
    return str
end

function OUS.ApplyBlizzardKiller()
    if OdysseusDB and OdysseusDB.xpBar.hideBlizz and StatusTrackingBarManager then
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide()
        OUS.LogDebug("XPBar", "Blizzard Default Status Bars hidden.")
    end
end

-- ==========================================
-- 5. FACTION DATA HELPERS
-- ==========================================
function OUS.GetFactionDetails(factionID)
    if not factionID then return nil end
    local data = C_Reputation.GetFactionDataByID(factionID)
    if not data then return nil end
    
    local name = data.name
    local reaction = data.reaction or 4
    local standingText = GetText("FACTION_STANDING_LABEL" .. reaction) or "Neutral"
    local curRep, maxRep = 0, 1
    local isMaxed, hasRewardPending = false, false
    local iconPath = "Interface\\Icons\\Achievement_Reputation_01"
    local textureKit = nil
    
    -- Handle Major Factions (Renown)
    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        local majorData = C_MajorFactions.GetMajorFactionData(factionID)
        if majorData then
            standingText = "Renown " .. majorData.renownLevel
            curRep = majorData.renownReputationEarned or 0
            maxRep = majorData.renownLevelThreshold or 1
            if majorData.textureKit then 
                textureKit = majorData.textureKit
                iconPath = "Interface\\Icons\\UI_MajorFaction_" .. textureKit 
            end
            if C_MajorFactions.HasMaximumRenown(factionID) then 
                isMaxed = true
                standingText = "Max Renown"
                curRep = 1
                maxRep = 1 
            end
        end
    end
    
    -- Handle Friendship Factions (Gossip/Ranks)
    if not isMaxed and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local repInfo = C_GossipInfo.GetFriendshipReputation(factionID)
        if repInfo and repInfo.friendshipFactionID > 0 then
            if repInfo.texture and repInfo.texture > 0 then iconPath = repInfo.texture end
            local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionID)
            if rankInfo and rankInfo.currentLevel then 
                standingText = "Rank " .. rankInfo.currentLevel
                if rankInfo.currentLevel >= rankInfo.maxLevel then 
                    isMaxed = true
                    standingText = "Max Rank"
                    curRep = 1
                    maxRep = 1 
                else 
                    curRep = repInfo.standing - repInfo.reactionThreshold
                    maxRep = repInfo.nextThreshold - repInfo.reactionThreshold 
                end 
            end
        end
    end
    
    -- Standard Legacy Factions
    if curRep == 0 and maxRep == 1 and data.currentStanding then
        if data.currentValue then 
            curRep, maxRep = data.currentValue, data.maxValue 
        else 
            curRep = data.currentStanding - data.currentReactionThreshold
            maxRep = data.nextReactionThreshold - data.currentReactionThreshold 
        end
        if curRep >= maxRep and maxRep > 0 then 
            isMaxed = true; curRep = 1; maxRep = 1 
        end
    end
    
    -- Paragon Detection
    if isMaxed and C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold, _, hasReward = C_Reputation.GetFactionParagonInfo(factionID)
        if currentValue and threshold and threshold > 0 then 
            isMaxed = false
            curRep = currentValue % threshold
            maxRep = threshold
            hasRewardPending = hasReward
            if hasRewardPending then 
                standingText = "Paragon (Reward Ready!)"
                if curRep == 0 then curRep = maxRep end 
            else 
                standingText = "Paragon" 
            end 
        end
    end
    
    if maxRep == 0 then maxRep = 1 end
    local repPC = math.floor((curRep / maxRep) * 100)
    
    return { name = name, standingText = standingText, curRep = curRep, maxRep = maxRep, repPC = repPC, isMaxed = isMaxed, hasRewardPending = hasRewardPending, description = data.description, reaction = reaction, icon = iconPath, textureKit = textureKit }
end

local function ScanFactionsForPopups(isInitialLogin)
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.factionID then
            local fid = data.factionID
            local name = data.name
            
            -- Scan for Renown Level Ups
            if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                local majorData = C_MajorFactions.GetMajorFactionData(fid)
                if majorData then
                    local rLvl = majorData.renownLevel
                    if not isInitialLogin and Session.repCache.renown[fid] and rLvl > Session.repCache.renown[fid] then
                        local tex = majorData.textureKit and ("Interface\\Icons\\UI_MajorFaction_" .. majorData.textureKit) or nil
                        OUS.ShowToast("Renown Increased!", name .. " reached Rank " .. rLvl, tex, fid)
                        OUS.LogDebug("XPBar", "Popup Triggered: Renown increased for " .. name)
                    end
                    Session.repCache.renown[fid] = rLvl
                end
            end
            
            -- Scan for Paragon Rewards
            if C_Reputation.IsFactionParagon(fid) then
                local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(fid)
                if not isInitialLogin and hasRewardPending and not Session.repCache.paragon[fid] then
                    OUS.ShowToast("Paragon Reward!", "A reward is ready for " .. name, nil, fid)
                    OUS.LogDebug("XPBar", "Popup Triggered: Paragon reward ready for " .. name)
                end
                Session.repCache.paragon[fid] = hasRewardPending
            end
        end
    end
end

-- ==========================================
-- 6. BAR RENDER HELPERS
-- ==========================================
local function NormalizeFactionName(name)
    if not name then return "" end

    name = tostring(name)
    name = string.lower(name)
    name = string.gsub(name, "[%[%]%.]", "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    name = string.gsub(name, "%s+", " ")

    return name
end

local function GetPersistentRepFallbackName()
    if not OdysseusDB or not OdysseusDB.xpBar then return nil end
    return OdysseusDB.xpBar.lastRepFactionName
end

local function SetPersistentRepFallbackName(factionName)
    if not factionName or factionName == "" then return end
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    OdysseusDB.xpBar.lastRepFactionName = factionName
end

local function ResolveTargetFactionID()
    local targetFactionID = nil
    local playerLevel = UnitLevel("player")
    local maxExpansionLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = (playerLevel >= maxExpansionLevel) or (IsXPUserDisabled and IsXPUserDisabled())

    local function FindFactionIDByName(factionName)
        if not factionName or factionName == "" then return nil end

        local targetName = NormalizeFactionName(factionName)

        -- Special-case Guild reputation
        if targetName == "guild" and C_Reputation and C_Reputation.GetGuildFactionData then
            local guildData = C_Reputation.GetGuildFactionData()
            if guildData and guildData.factionID then
                return guildData.factionID
            end
        end

        if C_Reputation and C_Reputation.GetNumFactions then
            for i = 1, C_Reputation.GetNumFactions() do
                local data = C_Reputation.GetFactionDataByIndex(i)
                if data and not data.isHidden then
                    local dataName = NormalizeFactionName(data.name)
                    if dataName == targetName and not (data.isHeader and not data.isHeaderWithRep) then
                        return data.factionID
                    end
                end
            end
        end

        return nil
    end

    -- 1. Temporary rep-gain override always wins while active.
    if Session.forceRepDisplay and Session.lastGainedFactionName then
        targetFactionID = FindFactionIDByName(Session.lastGainedFactionName)
    end

    -- 2. Normal watched faction should win during regular max-level display.
    if not targetFactionID then
        local watchedData = C_Reputation.GetWatchedFactionData()
        if watchedData then
            targetFactionID = watchedData.factionID
        end
    end

    -- 3. Only if nothing is watched, use remembered fallback at max level.
    if not targetFactionID and isMaxLevel then
        targetFactionID = FindFactionIDByName(Session.lastGainedFactionName or GetPersistentRepFallbackName())
    end

    return targetFactionID
end

local function ResolveReputationColor(info, db)
    local reactionToKey = {
        [1] = "hated",
        [2] = "hostile",
        [3] = "unfriendly",
        [4] = "neutral",
        [5] = "friendly",
        [6] = "honored",
        [7] = "revered",
        [8] = "exalted",
    }

    local repColor = db.repColors.neutral

    if string.find(info.standingText, "Renown") then
        repColor = db.repColors.renown
    elseif string.find(info.standingText, "Paragon") then
        repColor = db.repColors.paragon
    elseif info.reaction and reactionToKey[info.reaction] then
        repColor = db.repColors[reactionToKey[info.reaction]]
    end

    return repColor
end

local function RenderXPBar(db, playerLevel, maxExpansionLevel)
    local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
    local restXP = GetXPExhaustion() or 0
    local killsToLevel = "?"

    if Session.lastXPGain > 0 then
        killsToLevel = tostring(math.ceil((maxXP - curXP) / Session.lastXPGain))
    end

    xpBar.progressBar:SetMinMaxValues(0, maxXP)
    xpBar.progressBar:SetValue(curXP)
    xpBar.progressBar:SetStatusBarColor(db.xpColor.r, db.xpColor.g, db.xpColor.b, 0.9)

    if restXP > 0 then
        xpBar.restedBar:SetMinMaxValues(0, maxXP)
        xpBar.restedBar:SetValue(math.min(curXP + restXP, maxXP))
        xpBar.restedBar:SetStatusBarColor(db.restColor.r, db.restColor.g, db.restColor.b, 0.6)
        xpBar.restedBar:Show()
    else
        xpBar.restedBar:Hide()
    end

    xpBar.text:SetTextColor(db.xpTextColor.r, db.xpTextColor.g, db.xpTextColor.b)

    local parsedText = OUS.ParseXPText(
        db.xpTemplate,
        curXP,
        maxXP,
        restXP,
        playerLevel,
        maxExpansionLevel,
        killsToLevel,
        false,
        nil
    )

    -- FEATURE: Zzzz Resting Icon Injection!
    if IsResting() and db.showRestIcon then
        parsedText = "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:-2:64:64:0:32:0:32|t " .. parsedText
    end

    xpBar.text:SetText(parsedText)
    xpBar:Show()
end

local function RenderReputationBar(db, targetFactionID)
    xpBar.restedBar:Hide()

    if not targetFactionID then
        xpBar:Hide()
        return
    end

    local info = OUS.GetFactionDetails(targetFactionID)
    if not info then
        xpBar:Hide()
        return
    end

    xpBar.progressBar:SetMinMaxValues(0, info.maxRep)
    xpBar.progressBar:SetValue(info.curRep)

    local repColor = ResolveReputationColor(info, db)
    xpBar.progressBar:SetStatusBarColor(repColor.r, repColor.g, repColor.b, 0.9)
    xpBar.text:SetTextColor(db.repTextColor.r, db.repTextColor.g, db.repTextColor.b)

    local repText = OUS.ParseRepText(
        db.repTemplate,
        info.name,
        info.standingText,
        info.curRep,
        info.maxRep,
        info.isMaxed
    )

    if info.hasRewardPending then
        repText = repText .. " |TInterface\\Icons\\UI-LFG-Loot-Bag:16:16:0:0|t"
    end

    xpBar.text:SetText(repText)
    xpBar:Show()
end

function OUS.UpdateBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end

    local db = OdysseusDB.xpBar
    local playerLevel = UnitLevel("player")
    local maxExpansionLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = (playerLevel >= maxExpansionLevel) or (IsXPUserDisabled and IsXPUserDisabled())
    local targetFactionID = ResolveTargetFactionID()

    if not isMaxLevel and not (Session.forceRepDisplay and targetFactionID) then
        RenderXPBar(db, playerLevel, maxExpansionLevel)
    else
        RenderReputationBar(db, targetFactionID)
    end

    OUS.UpdateDelveBar()
end

-- ==========================================
-- 7. EVENT REGISTRATION
-- ==========================================
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("SCENARIO_UPDATE")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("UPDATE_EXHAUSTION")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("PARTY_MEMBER_ENABLE")
f:RegisterEvent("GROUP_LEFT")

-- ==========================================
-- 8. EVENT HANDLERS
-- ==========================================
local function HandleAddonLoaded(loadedAddonName)
    if loadedAddonName ~= addonName then return end

    OdysseusDB = OdysseusDB or {}
    OdysseusDB.xpBar = OdysseusDB.xpBar or {}

    for k, v in pairs(OUS.defaults) do
        if OdysseusDB.xpBar[k] == nil or (type(v) == "string" and OdysseusDB.xpBar[k] == "") then
            if type(v) == "table" then
                OdysseusDB.xpBar[k] = OUS.DeepCopyTable(v)
            else
                OdysseusDB.xpBar[k] = v
            end
        end
    end

    if OUS.BuildXPConfigUI then
        OUS.BuildXPConfigUI()
    end

    OUS.ApplyFonts()

    local xpPos = OdysseusDB.xpBar.xpBarPos
    xpBar:ClearAllPoints()
    xpBar:SetPoint(xpPos.p, UIParent, xpPos.rP, xpPos.x, xpPos.y)

    local delvePos = OdysseusDB.xpBar.delveBarPos
    delveBar:ClearAllPoints()
    delveBar:SetPoint(delvePos.p, UIParent, delvePos.rP, delvePos.x, delvePos.y)

    local toastPos = OdysseusDB.xpBar.toastPos
    toast:ClearAllPoints()
    toast:SetPoint(toastPos.p, UIParent, toastPos.rP, toastPos.x, toastPos.y)

    OUS.ApplyDimensions()
    OUS.ApplyXPBarBorders()

    Session.sessionXP = 0
    Session.lastXPGain = 0
    Session.lastXP = UnitXP("player")
    Session.lastMaxXP = UnitXPMax("player")
    Session.lastGainedFactionName = OdysseusDB.xpBar.lastRepFactionName

    OUS.WakeBars()
    OUS.SleepBars()

    if OdysseusDB and OdysseusDB.modules and not OdysseusDB.modules.xpBar then
        xpBar:Hide()
        delveBar:Hide()
    end

    OUS.UpdateBar()
    OUS.LogDebug("XPBar", "Engine Loaded & Initialized.")
end

local function HandleZoneChange()
    OUS.ApplyBlizzardKiller()

    -- Perform an immediate update. This will instantly hide the bar when leaving a delve.
    OUS.UpdateBar()

    -- The aggressive check is only needed if the immediate check didn't already show the bar.
    -- This handles the edge case of entering a delve where the API is slow to update.
    if not delveBar:IsShown() and OUS.TriggerAggressiveDelveCheck then
        OUS.TriggerAggressiveDelveCheck()
    end

    ScanFactionsForPopups(true)
    OUS.WakeBars()
    OUS.SleepBars()
end

local function HandleScenarioOrGroupUpdate()
    OUS.UpdateBar()
end

local function HandleXPUpdate()
    local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")

    if currentXP > Session.lastXP and maxXP == Session.lastMaxXP then
        Session.lastXPGain = currentXP - Session.lastXP
        Session.sessionXP = Session.sessionXP + Session.lastXPGain
    elseif currentXP < Session.lastXP or maxXP > Session.lastMaxXP then
        Session.lastXPGain = (Session.lastMaxXP - Session.lastXP) + currentXP
        Session.sessionXP = Session.sessionXP + Session.lastXPGain
    end

    Session.lastXP = currentXP
    Session.lastMaxXP = maxXP

    if Session.forceRepDisplay then
        Session.forceRepDisplay = false
        if Session.repTimer then
            Session.repTimer:Cancel()
        end
    end

    RefreshBars()

    OUS.LogDebug("XPBar", "XP Gain Detected: +" .. tostring(Session.lastXPGain))
end

local function StartRepDisplayTimer()
    Session.forceRepDisplay = true

    if Session.repTimer then
        Session.repTimer:Cancel()
    end

    Session.repTimer = C_Timer.NewTimer(OdysseusDB.xpBar.repDisplayTime or 15, function()
        Session.forceRepDisplay = false
        RefreshBars()
    end)
end

local function HandleFactionUpdate()
    ScanFactionsForPopups(false)

    -- Show the newly gained faction at any level.
    if Session.lastGainedFactionName then
        StartRepDisplayTimer()
    end

    RefreshBars()
end

local function HandleFactionChatMessage(rawMessage)
    if not rawMessage or type(rawMessage) ~= "string" then return end

    local isSafe, safeString = pcall(string.match, rawMessage, ".*")
    if not isSafe then return end

    local msg = string.gsub(safeString, "|c%x%x%x%x%x%x%x%x", "")
    msg = string.gsub(msg, "|r", "")
    msg = string.gsub(msg, "|H.-|h(.-)|h", "%1")

    -- Check for Warband first to avoid regex confusion.
    local faction, amount = string.match(msg, "Warband's reputation with (.-) increased by (%d+)")
    if not faction then
        faction, amount = string.match(msg, "[Rr]eputation with (.-) increased by (%d+)")
    end

    if faction and amount then
        faction = string.gsub(faction, "[%[%]%.]", "")
        faction = string.gsub(faction, "^%s+", "")
        faction = string.gsub(faction, "%s+$", "")

        Session.sessionRep = Session.sessionRep or {}
        Session.sessionRep[faction] = (Session.sessionRep[faction] or 0) + tonumber(amount)
        Session.lastGainedFactionName = faction
        SetPersistentRepFallbackName(faction)

        -- Flip to the new faction immediately.
        StartRepDisplayTimer()

        RefreshBars()

        OUS.LogDebug("XPBar", string.format("Rep Gain: %s (+%s)", faction, amount))
    end
end

local function HandleCombatStart()
    OUS.WakeBars()
end

local function HandleCombatEnd()
    OUS.SleepBars()
end

-- ==========================================
-- 9. EVENT DISPATCH
-- ==========================================
f:SetScript("OnEvent", function(self, event, arg1)
    -- ADDON_LOADED must always run to initialize the database and frames.
    -- All other events are guarded by the module toggle.
    if event ~= "ADDON_LOADED" then
        if not OdysseusDB or not OdysseusDB.modules or not OdysseusDB.modules.xpBar then
            return
        end
    end

    if event == "ADDON_LOADED" then
        HandleAddonLoaded(arg1)

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        HandleZoneChange()

    elseif event == "SCENARIO_UPDATE" or event == "UPDATE_INSTANCE_INFO" or event == "PARTY_MEMBER_ENABLE" or event == "GROUP_LEFT" then
        HandleScenarioOrGroupUpdate()

    elseif event == "PLAYER_XP_UPDATE" then
        HandleXPUpdate()

    elseif event == "UPDATE_FACTION" then
        HandleFactionUpdate()

    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" or event == "CHAT_MSG_SYSTEM" then
        HandleFactionChatMessage(arg1)

    elseif event == "PLAYER_REGEN_DISABLED" then
        HandleCombatStart()

    elseif event == "PLAYER_REGEN_ENABLED" then
        HandleCombatEnd()
    end
end)