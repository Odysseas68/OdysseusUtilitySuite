-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP & REP ENGINE
-- ==========================================
local addonName, OUS = ...
local f = CreateFrame("Frame")
local Session = OUS.Session
local xpBar, delveBar, toast = OUS.xpBarFrame, OUS.delveBarFrame, OUS.toastFrame

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
local function ParseXPText(template, curXP, maxXP, restXP, level, mLVL, ktl, isMaxed, compName)
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

local function ParseRepText(template, name, standingText, curRep, maxRep, isMaxed)
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
    return str
end

local function ApplyBlizzardKiller()
    if OdysseusDB and OdysseusDB.xpBar.hideBlizz and StatusTrackingBarManager then 
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide() 
        OUS.LogDebug("XPBar", "Blizzard Default Status Bars hidden.")
    end
end

-- ==========================================
-- 5. DATABASE PARSERS (FACTION & DELVES)
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
    if Session.isTestingDelve then return true end
    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID and difficultyID >= 205 and difficultyID <= 220 then return true end
    return false
end

local function GetFactionDetails(factionID)
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
-- 6. BAR RENDER ENGINES
-- ==========================================
function OUS.UpdateDelveBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    
    if IsPlayerInDelve() then
        local compName, compFactionID = GetActiveDelveCompanion()
        local cXP, cMax, cLvl, isMaxed = 0, 1, 1, false
        
        if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
            local repInfo = C_GossipInfo.GetFriendshipReputation(compFactionID)
            if repInfo and repInfo.friendshipFactionID > 0 then
                local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(compFactionID)
                if rankInfo and rankInfo.currentLevel then 
                    cLvl = rankInfo.currentLevel
                    if rankInfo.currentLevel >= rankInfo.maxLevel then 
                        isMaxed = true; cMax = 1; cXP = 1 
                    else 
                        cXP = repInfo.standing - repInfo.reactionThreshold
                        cMax = repInfo.nextThreshold - repInfo.reactionThreshold 
                    end 
                end
            end
        end
        
        local jRep, jMax = 0, 1
        local journeyData = C_Reputation.GetFactionDataByID(db.journeyID)
        if journeyData then 
            jRep = journeyData.currentStanding
            jMax = journeyData.nextReactionThreshold
            if jMax == 0 then jMax = 1 end 
        end
        
        if Session.isTestingDelve and cMax <= 1 and jMax <= 1 then 
            cXP, cMax, cLvl = 25000, 83000, 15
            jRep, jMax = 1200, 5000
            isMaxed = false 
        end

        delveBar.compBar:SetMinMaxValues(0, cMax)
        delveBar.compBar:SetValue(cXP)
        delveBar.compBar:SetStatusBarColor(db.delveCompColor.r, db.delveCompColor.g, db.delveCompColor.b, 1)
        delveBar.compText:SetText(ParseXPText(db.delveCompTemplate, cXP, cMax, 0, cLvl, 60, "?", isMaxed, compName))
        
        delveBar.jourBar:SetMinMaxValues(0, jMax)
        delveBar.jourBar:SetValue(jRep)
        delveBar.jourBar:SetStatusBarColor(db.delveJourColor.r, db.delveJourColor.g, db.delveJourColor.b, 1)
        delveBar.jourText:SetText(ParseRepText(db.delveJourTemplate, "Journey", "Active", jRep, jMax, false))
        
        delveBar:Show()
    else 
        delveBar:Hide() 
    end
end

function OUS.UpdateBar()
    if not OdysseusDB or not OdysseusDB.xpBar then return end
    local db = OdysseusDB.xpBar
    local playerLevel = UnitLevel("player")
    local maxExpansionLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = (playerLevel >= maxExpansionLevel) or (IsXPUserDisabled and IsXPUserDisabled())
    
    local targetFactionID = nil
    
    if Session.forceRepDisplay and Session.lastGainedFactionName then
        if C_Reputation and C_Reputation.GetNumFactions then
            for i = 1, C_Reputation.GetNumFactions() do 
                local data = C_Reputation.GetFactionDataByIndex(i)
                if data and data.name == Session.lastGainedFactionName and not data.isHeader then 
                    targetFactionID = data.factionID
                    break 
                end 
            end
        end
    end
    
    if not targetFactionID then 
        local w = C_Reputation.GetWatchedFactionData()
        if w then targetFactionID = w.factionID end 
    end

    if not isMaxLevel and not (Session.forceRepDisplay and targetFactionID) then
        local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
        local restXP = GetXPExhaustion() or 0
        local ktl = "?"
        
        if Session.lastXPGain > 0 then ktl = tostring(math.ceil((maxXP - curXP) / Session.lastXPGain)) end
        
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
        
        -- Apply Text Color
        xpBar.text:SetTextColor(db.xpTextColor.r, db.xpTextColor.g, db.xpTextColor.b)
        
        local parsedText = ParseXPText(db.xpTemplate, curXP, maxXP, restXP, playerLevel, maxExpansionLevel, ktl, false, nil)
        
        -- FEATURE: Zzzz Resting Icon Injection!
-- FEATURE: Zzzz Resting Icon Injection!
        if IsResting() and db.showRestIcon then
            -- 0:32:0:32 grabs the Top-Left quadrant (Zzzz). And we append parsedText AFTER it so it sits on the left!
            parsedText = "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:-2:64:64:0:32:0:32|t " .. parsedText
        end
        
        xpBar.text:SetText(parsedText)
        xpBar:Show()
    else
        -- Render Reputation
        xpBar.restedBar:Hide()
        if targetFactionID then
            local info = GetFactionDetails(targetFactionID)
            if info then
                xpBar.progressBar:SetMinMaxValues(0, info.maxRep)
                xpBar.progressBar:SetValue(info.curRep)
                
                -- FEATURE: Dynamic Reputation Colors
                local reactionToKey = { [1]="hated", [2]="hostile", [3]="unfriendly", [4]="neutral", [5]="friendly", [6]="honored", [7]="revered", [8]="exalted" }
                local rColor = db.repColors.neutral -- Safe fallback
                
                if string.find(info.standingText, "Renown") then rColor = db.repColors.renown
                elseif string.find(info.standingText, "Paragon") then rColor = db.repColors.paragon
                elseif info.reaction and reactionToKey[info.reaction] then rColor = db.repColors[reactionToKey[info.reaction]] end
                
                xpBar.progressBar:SetStatusBarColor(rColor.r, rColor.g, rColor.b, 0.9)
                xpBar.text:SetTextColor(db.repTextColor.r, db.repTextColor.g, db.repTextColor.b)
                
                local repText = ParseRepText(db.repTemplate, info.name, info.standingText, info.curRep, info.maxRep, info.isMaxed)
                if info.hasRewardPending then repText = repText .. " |TInterface\\Icons\\UI-LFG-Loot-Bag:16:16:0:0|t" end
                
                xpBar.text:SetText(repText)
                xpBar:Show()
            else xpBar:Hide() end
        else xpBar:Hide() end
    end
    
    OUS.UpdateDelveBar()
end

local function TriggerAggressiveDelveCheck()
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

-- ==========================================
-- 7. REPUTATION ADVANCED MENUS & SMART HOVER
-- ==========================================
OUS.factionSelectFrame = CreateFrame("Frame", "OdysseusFactionSelectFrame", UIParent, "BackdropTemplate")
local factionSelectFrame = OUS.factionSelectFrame
factionSelectFrame:SetSize(460, 500)
factionSelectFrame:SetPoint("CENTER")
factionSelectFrame:SetFrameStrata("DIALOG")
factionSelectFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
factionSelectFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
factionSelectFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
factionSelectFrame:Hide()
factionSelectFrame:SetMovable(true)
factionSelectFrame:EnableMouse(true)
factionSelectFrame:RegisterForDrag("LeftButton")
factionSelectFrame:SetScript("OnDragStart", factionSelectFrame.StartMoving)
factionSelectFrame:SetScript("OnDragStop", factionSelectFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, factionSelectFrame:GetName())

factionSelectFrame.headerBg = factionSelectFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
factionSelectFrame.headerBg:SetPoint("TOPLEFT", 4, -4)
factionSelectFrame.headerBg:SetPoint("TOPRIGHT", -4, -4)
factionSelectFrame.headerBg:SetHeight(30)
factionSelectFrame.headerBg:SetColorTexture(1, 1, 1, 1)
factionSelectFrame.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

factionSelectFrame.title = factionSelectFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
factionSelectFrame.title:SetPoint("TOP", 0, -8)
factionSelectFrame.title:SetText("Select Favorites to Track")
factionSelectFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local fsCloseBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelCloseButton")
fsCloseBtn:SetPoint("TOPRIGHT", -2, -2)

local fsSaveBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelButtonTemplate")
fsSaveBtn:SetSize(120, 26)
fsSaveBtn:SetPoint("BOTTOMRIGHT", -15, 15)
fsSaveBtn:SetText("Save Favorites")

local fsCancelBtn = CreateFrame("Button", nil, factionSelectFrame, "UIPanelButtonTemplate")
fsCancelBtn:SetSize(100, 26)
fsCancelBtn:SetPoint("RIGHT", fsSaveBtn, "LEFT", -10, 0)
fsCancelBtn:SetText("Cancel")
fsCancelBtn:SetScript("OnClick", function() factionSelectFrame:Hide() end)

local fsScroll = CreateFrame("ScrollFrame", "OdysseusFactionScroll", factionSelectFrame, "UIPanelScrollFrameTemplate")
fsScroll:SetPoint("TOPLEFT", 15, -45)
fsScroll:SetPoint("BOTTOMRIGHT", -35, 50)
local fsScrollChild = CreateFrame("Frame")
fsScroll:SetScrollChild(fsScrollChild)

local fsButtons = {}
local tempFavorites = {}

local function RefreshFactionSelectTree()
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for _, btn in pairs(fsButtons) do btn:Hide() end
    local yOffset = 0
    local numFactions = C_Reputation.GetNumFactions()
    
    for i = 1, numFactions do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and not data.isHidden then
            local btn = fsButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, fsScrollChild, "BackdropTemplate")
                btn:SetSize(380, 26)
                btn:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
                btn:SetBackdropColor(0, 0, 0, 0.4)
                btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                
                btn.expand = CreateFrame("Button", nil, btn)
                btn.expand:SetSize(16, 16)
                btn.expand:SetNormalFontObject("GameFontNormal")
                
                btn.check = CreateFrame("CheckButton", nil, btn, "ChatConfigCheckButtonTemplate")
                btn.check:SetSize(24, 24)
                btn.check:SetHitRectInsets(0, 0, 0, 0)
                
                btn.wbIcon = btn:CreateTexture(nil, "OVERLAY")
                btn.wbIcon:SetSize(14, 14)
                pcall(function() btn.wbIcon:SetAtlas("warbands-icon") end)
                
                btn.facIcon = btn:CreateTexture(nil, "OVERLAY")
                btn.facIcon:SetSize(16, 16)
                
                btn.bar = CreateFrame("StatusBar", nil, btn)
                btn.bar:SetSize(100, 14)
                btn.bar:SetPoint("RIGHT", -5, 0)
                btn.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                btn.bar.bg = btn.bar:CreateTexture(nil, "BACKGROUND")
                btn.bar.bg:SetAllPoints()
                btn.bar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                btn.bar.txt = btn.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.bar.txt:SetPoint("CENTER")
                btn.bar.txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                btn.bar:EnableMouse(false)
                
                btn.txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.txt:SetJustifyH("LEFT")
                btn.txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                btn.txt:SetPoint("RIGHT", btn.bar, "LEFT", -5, 0)
                btn.txt:SetWordWrap(false)
                
                local function RowHoverOn()
                    btn:SetBackdropColor(0.2, 0.15, 0.3, 0.8)
                    btn:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
                    local info = GetFactionDetails(btn.data.factionID)
                    if info then
                        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                        local iconStr = ""
                        if info.textureKit then iconStr = "|A:UI-MajorFaction-"..info.textureKit..":18:18|a " elseif info.icon then iconStr = "|T"..info.icon..":18:18:0:0|t " end
                        GameTooltip:SetText(iconStr .. info.name, 0.6, 0.2, 0.8)
                        GameTooltip:AddLine(info.standingText .. " - " .. OUS.FormatLargeNumber(info.curRep) .. " / " .. OUS.FormatLargeNumber(info.maxRep), 1, 1, 1)
                        if info.hasRewardPending then GameTooltip:AddLine("Paragon Reward Ready!", 0, 1, 0) end
                        if info.description and info.description ~= "" then 
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(info.description, 0.8, 0.8, 0.8, true) 
                        end
                        GameTooltip:Show()
                    end
                end
                
                local function RowHoverOff() 
                    btn:SetBackdropColor(0, 0, 0, 0.4)
                    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                    GameTooltip:Hide() 
                end
                
                btn:SetScript("OnEnter", RowHoverOn)
                btn:SetScript("OnLeave", RowHoverOff)
                btn.check:HookScript("OnEnter", RowHoverOn)
                btn.check:HookScript("OnLeave", RowHoverOff)
                fsButtons[i] = btn
            end
            
            btn.data = data
            btn.check:SetChecked(tempFavorites[data.factionID] == true)
            local indent = data.isHeader and 5 or 25
            if data.isHeader and data.isHeaderWithRep then indent = 15 end
            btn.expand:ClearAllPoints()
            btn.expand:SetPoint("LEFT", indent, 0)
            btn.check:ClearAllPoints()
            btn.check:SetPoint("LEFT", btn.expand, "RIGHT", 0, 0)
            
            if data.isAccountWide then 
                btn.wbIcon:SetPoint("LEFT", btn.check, "RIGHT", 2, 0)
                btn.wbIcon:Show()
                btn.facIcon:SetPoint("LEFT", btn.wbIcon, "RIGHT", 4, 0) 
            else 
                btn.wbIcon:Hide()
                btn.facIcon:SetPoint("LEFT", btn.check, "RIGHT", 4, 0) 
            end

            local info = GetFactionDetails(data.factionID)
            if info and info.textureKit then 
                local s = pcall(function() btn.facIcon:SetAtlas("UI-MajorFaction-" .. info.textureKit) end)
                if not s then btn.facIcon:SetTexture(info.icon) end 
            elseif info and info.icon then 
                btn.facIcon:SetTexture(info.icon) 
            end
            
            if data.isHeader and not data.isHeaderWithRep then btn.facIcon:Hide() else btn.facIcon:Show() end
            btn.txt:SetPoint("LEFT", btn.facIcon, "RIGHT", 4, 0)
            
            if data.isHeader and not data.isHeaderWithRep then
                btn.bar:Hide()
                btn.expand:Show()
                btn.expand:SetText(data.isCollapsed and "[+]" or "[-]")
                btn.expand:SetScript("OnClick", function() 
                    if data.isCollapsed then C_Reputation.ExpandFactionHeader(i) else C_Reputation.CollapseFactionHeader(i) end
                    RefreshFactionSelectTree() 
                end)
                btn.txt:SetText("|cFFB088FF" .. data.name .. "|r")
            else
                if data.isHeader then 
                    btn.expand:Show()
                    btn.expand:SetText(data.isCollapsed and "[+]" or "[-]")
                    btn.expand:SetScript("OnClick", function() 
                        if data.isCollapsed then C_Reputation.ExpandFactionHeader(i) else C_Reputation.CollapseFactionHeader(i) end
                        RefreshFactionSelectTree() 
                    end) 
                else 
                    btn.expand:Hide() 
                end
                
                btn.txt:SetText(data.name)
                
                if info then
                    btn.bar:Show()
                    btn.bar:SetMinMaxValues(0, info.maxRep)
                    btn.bar:SetValue(info.curRep)
                    if info.hasRewardPending then 
                        btn.bar:SetStatusBarColor(0.2, 0.8, 0.4, 1) 
                    elseif string.find(info.standingText, "Renown") then 
                        btn.bar:SetStatusBarColor(0.0, 0.6, 0.8, 1) 
                    elseif string.find(info.standingText, "Paragon") then 
                        btn.bar:SetStatusBarColor(0.5, 0.3, 0.8, 1) 
                    elseif info.reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[info.reaction] then 
                        local c = FACTION_BAR_COLORS[info.reaction]
                        btn.bar:SetStatusBarColor(c.r, c.g, c.b, 1) 
                    else 
                        btn.bar:SetStatusBarColor(0.5, 0.5, 0.5, 1) 
                    end
                    local displayCur = info.isMaxed and info.maxRep or info.curRep
                    btn.bar.txt:SetText(OUS.FormatLargeNumber(displayCur) .. " / " .. OUS.FormatLargeNumber(info.maxRep))
                else 
                    btn.bar:Hide() 
                end
            end
            
            btn.check:SetScript("OnClick", function(self)
                local isChecked = self:GetChecked()
                tempFavorites[data.factionID] = isChecked
                if data.isHeader then
                    for j = i + 1, C_Reputation.GetNumFactions() do
                        local childData = C_Reputation.GetFactionDataByIndex(j)
                        if not childData then break end
                        if childData.isHeader and (childData.isChild == data.isChild or (not childData.isChild and data.isChild)) then break end
                        tempFavorites[childData.factionID] = isChecked
                    end
                    RefreshFactionSelectTree()
                end
            end)
            
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", 0, -yOffset)
            btn:Show()
            yOffset = yOffset + 28
        end
    end
    fsScrollChild:SetSize(380, yOffset)
end

fsSaveBtn:SetScript("OnClick", function() 
    if not OdysseusDB.xpBar.favFactions then OdysseusDB.xpBar.favFactions = {} end
    OdysseusDB.xpBar.favFactions = OUS.DeepCopyTable(tempFavorites)
    factionSelectFrame:Hide()
    OUS.LogDebug("XPBar", "Favorites list updated and saved.")
end)

-- Hover Dashboard
OUS.favHoverFrame = CreateFrame("Frame", "OdysseusFavRepFrame", UIParent, "BackdropTemplate")
local favFrame = OUS.favHoverFrame
favFrame:SetSize(400, 200)
favFrame:SetFrameStrata("TOOLTIP")
favFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 }})
favFrame:SetBackdropColor(0.05, 0.03, 0.08, 0.95)
favFrame:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
favFrame:Hide()

-- FEATURE: Enable mouse detection on the frame so our Smart Timer knows when you are inside it!
favFrame:EnableMouse(true)

favFrame:SetScript("OnEnter", function()
    -- If they move into the frame, cancel the timer so it stays open forever!
    if Session.favTimer then Session.favTimer:Cancel(); Session.favTimer = nil end
    OUS.WakeBars()
end)

favFrame:SetScript("OnLeave", function()
    -- If they leave the frame, close it instantly (0.2s grace period)
    if Session.favTimer then Session.favTimer:Cancel() end
    Session.favTimer = C_Timer.NewTimer(0.2, function()
        if not favFrame:IsMouseOver() and not xpBar:IsMouseOver() then
            favFrame:Hide()
            OUS.SleepBars()
        end
    end)
end)

local favTitle = favFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
favTitle:SetPoint("TOP", 0, -8)
favTitle:SetText("|cFFB088FFOdysseus Favorites Dashboard|r")

local favScroll = CreateFrame("ScrollFrame", "OdysseusFavScroll", favFrame, "UIPanelScrollFrameTemplate")
favScroll:SetPoint("TOPLEFT", 10, -25)
favScroll:SetPoint("BOTTOMRIGHT", -30, 10)

local favScrollChild = CreateFrame("Frame")
favScroll:SetScrollChild(favScrollChild)
local favRows = {}

local function RefreshHoverFavorites()
    if not OdysseusDB or not OdysseusDB.xpBar.favFactions then return end
    for _, row in pairs(favRows) do row:Hide() end
    
    local favList = {}
    for fid, isFav in pairs(OdysseusDB.xpBar.favFactions) do 
        if isFav then table.insert(favList, fid) end 
    end
    
    if #favList == 0 then return end
    
    table.sort(favList, function(a, b) 
        local da = C_Reputation.GetFactionDataByID(a)
        local db = C_Reputation.GetFactionDataByID(b)
        return (da and da.name or "") < (db and db.name or "") 
    end)
    
    local yOffset = 0
    local index = 1
    
    if C_Reputation and C_Reputation.GetNumFactions then
        for i = 1, C_Reputation.GetNumFactions() do
            local data = C_Reputation.GetFactionDataByIndex(i)
            if data and OdysseusDB.xpBar.favFactions[data.factionID] then
                if not (data.isHeader and not data.isHeaderWithRep) then
                    local info = GetFactionDetails(data.factionID)
                    if info then
                        local row = favRows[index]
                        if not row then
                            row = CreateFrame("Button", nil, favScrollChild, "BackdropTemplate")
                            row:SetSize(340, 26)
                            row:RegisterForClicks("AnyUp")
                            row:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 }})
                            row:SetBackdropColor(0, 0, 0, 0.4)
                            row:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                            
                            row.wbIcon = row:CreateTexture(nil, "OVERLAY")
                            row.wbIcon:SetSize(14, 14)
                            pcall(function() row.wbIcon:SetAtlas("warbands-icon") end)
                            
                            row.facIcon = row:CreateTexture(nil, "OVERLAY")
                            row.facIcon:SetSize(16, 16)
                            
                            row.bar = CreateFrame("StatusBar", nil, row)
                            row.bar:SetSize(100, 14)
                            row.bar:SetPoint("RIGHT", -5, 0)
                            row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                            
                            row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
                            row.bar.bg:SetAllPoints()
                            row.bar.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                            
                            row.bar.txt = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            row.bar.txt:SetPoint("CENTER")
                            row.bar.txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                            row.bar:EnableMouse(false)
                            
                            row.txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            row.txt:SetJustifyH("LEFT")
                            row.txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                            row.txt:SetPoint("RIGHT", row.bar, "LEFT", -5, 0)
                            row.txt:SetWordWrap(false)
                            
                            row:SetScript("OnEnter", function(self)
                                -- Stop the frame from closing while we look at a specific row tooltip
                                if Session.favTimer then Session.favTimer:Cancel(); Session.favTimer = nil end
                                self:SetBackdropColor(0.2, 0.15, 0.3, 0.8)
                                self:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
                                OUS.WakeBars()
                                
                                local rInfo = GetFactionDetails(self.factionID)
                                if rInfo then
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    local iconStr = ""
                                    if rInfo.textureKit then iconStr = "|A:UI-MajorFaction-"..rInfo.textureKit..":18:18|a " elseif rInfo.icon then iconStr = "|T"..rInfo.icon..":18:18:0:0|t " end
                                    GameTooltip:SetText(iconStr .. rInfo.name, 0.6, 0.2, 0.8)
                                    GameTooltip:AddLine(rInfo.standingText .. " - " .. OUS.FormatLargeNumber(rInfo.curRep) .. " / " .. OUS.FormatLargeNumber(rInfo.maxRep), 1, 1, 1)
                                    if rInfo.hasRewardPending then GameTooltip:AddLine("Paragon Reward Ready!", 0, 1, 0) end
                                    if rInfo.description and rInfo.description ~= "" then GameTooltip:AddLine(" "); GameTooltip:AddLine(rInfo.description, 0.8, 0.8, 0.8, true) end
                                    GameTooltip:Show()
                                end
                            end)
                            
                            row:SetScript("OnLeave", function(self) 
                                self:SetBackdropColor(0, 0, 0, 0.4)
                                self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                                GameTooltip:Hide()
                                
                                -- Re-arm the closing timer in case we slid off the edge of the row and out of the frame
                                if Session.favTimer then Session.favTimer:Cancel() end
                                Session.favTimer = C_Timer.NewTimer(0.2, function()
                                    if not favFrame:IsMouseOver() and not xpBar:IsMouseOver() then 
                                        favFrame:Hide()
                                        OUS.SleepBars() 
                                    end 
                                end) 
                            end)
                            favRows[index] = row
                        end
                        
                        row.factionID = data.factionID
                        if data.isAccountWide then 
                            row.wbIcon:SetPoint("LEFT", 5, 0)
                            row.wbIcon:Show()
                            row.facIcon:SetPoint("LEFT", row.wbIcon, "RIGHT", 4, 0) 
                        else 
                            row.wbIcon:Hide()
                            row.facIcon:SetPoint("LEFT", 5, 0) 
                        end
                        
                        if info.textureKit then 
                            local s = pcall(function() row.facIcon:SetAtlas("UI-MajorFaction-" .. info.textureKit) end)
                            if not s then row.facIcon:SetTexture(info.icon) end 
                        else 
                            row.facIcon:SetTexture(info.icon) 
                        end
                        
                        row.txt:SetPoint("LEFT", row.facIcon, "RIGHT", 4, 0)
                        row.txt:SetText(info.name)
                        row.bar:SetMinMaxValues(0, info.maxRep)
                        row.bar:SetValue(info.curRep)
                        
                        if info.hasRewardPending then 
                            row.bar:SetStatusBarColor(0.2, 0.8, 0.4, 1) 
                        elseif string.find(info.standingText, "Renown") then 
                            row.bar:SetStatusBarColor(0.0, 0.6, 0.8, 1) 
                        elseif string.find(info.standingText, "Paragon") then 
                            row.bar:SetStatusBarColor(0.5, 0.3, 0.8, 1) 
                        elseif info.reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[info.reaction] then 
                            local c = FACTION_BAR_COLORS[info.reaction]
                            row.bar:SetStatusBarColor(c.r, c.g, c.b, 1) 
                        else 
                            row.bar:SetStatusBarColor(0.5, 0.5, 0.5, 1) 
                        end
                        
                        local displayCur = info.isMaxed and info.maxRep or info.curRep
                        row.bar.txt:SetText(OUS.FormatLargeNumber(displayCur) .. " / " .. OUS.FormatLargeNumber(info.maxRep))
                        
                        row:SetScript("OnClick", function(self, button)
                            if button == "RightButton" then
                                local fData = OUS.FactionData and OUS.FactionData[self.factionID]
                                if fData and fData.rewardNPC and fData.rewardNPC.mapID > 0 then
                                    local npc = fData.rewardNPC
                                    if TomTom and TomTom.AddWaypoint then TomTom:AddWaypoint(npc.mapID, npc.x/100, npc.y/100, { title = "Quartermaster", persistent = false, minimap = true, world = true }) end
                                    if C_Map.CanSetUserWaypointOnMap(npc.mapID) then
                                        C_Map.ClearUserWaypoint()
                                        local pt = UiMapPoint.CreateFromCoordinates(npc.mapID, npc.x/100, npc.y/100)
                                        C_Map.SetUserWaypoint(pt)
                                        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                                        PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_WIDGET_CLICK)
                                        print("|cFF00FF00Odysseus:|r Waypoint set for Quartermaster!")
                                    else
                                        print("|cFFFF0000Odysseus:|r Map API rejected the pin. Map ID " .. npc.mapID .. " might be invalid or instanced.")
                                    end
                                else
                                    print("|cFF00FFFFOdysseus:|r No location data saved for this faction.")
                                end
                            else
                                local cIndex = nil
                                for j = 1, C_Reputation.GetNumFactions() do 
                                    local d = C_Reputation.GetFactionDataByIndex(j)
                                    if d and d.factionID == data.factionID then cIndex = j; break end 
                                end
                                if cIndex then 
                                    C_Reputation.SetWatchedFactionByIndex(cIndex)
                                    Session.lastGainedFactionName = nil
                                    Session.forceRepDisplay = false
                                    if OUS.UpdateBar then OUS.UpdateBar() end
                                    favFrame:Hide() 
                                end
                            end
                        end)
                        
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT", 0, -yOffset)
                        row:Show()
                        yOffset = yOffset + 28
                        index = index + 1
                    end
                end
            end
        end
    end
    favScrollChild:SetSize(340, yOffset)
    favFrame:SetHeight(math.min(400, math.max(80, yOffset + 40)))
end

xpBar:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local mod = OdysseusDB.xpBar.repMenuMod or "CTRL"
        local open = false
        if mod == "CTRL" and IsControlKeyDown() then open = true 
        elseif mod == "SHIFT" and IsShiftKeyDown() then open = true 
        elseif mod == "ALT" and IsAltKeyDown() then open = true 
        elseif mod == "NONE" then open = true end
        
        if open then 
            if factionSelectFrame:IsShown() then 
                factionSelectFrame:Hide() 
            else 
                tempFavorites = OUS.DeepCopyTable(OdysseusDB.xpBar.favFactions or {})
                RefreshFactionSelectTree()
                factionSelectFrame:Show() 
            end 
        end
    end
end)

-- FEATURE: XP Bar Smart Hover Tracking
xpBar:HookScript("OnEnter", function()
    OUS.WakeBars()
    RefreshHoverFavorites()
    local hasFavs = false
    if OdysseusDB and OdysseusDB.xpBar.favFactions then 
        for k, v in pairs(OdysseusDB.xpBar.favFactions) do 
            if v then hasFavs = true; break end 
        end 
    end
    
    if hasFavs then 
        favFrame:ClearAllPoints()
        local point = OdysseusDB.xpBar.xpBarPos.p or "BOTTOM"
        if string.find(point, "BOTTOM") then 
            favFrame:SetPoint("BOTTOM", xpBar, "TOP", 0, 5) 
        else 
            favFrame:SetPoint("TOP", xpBar, "BOTTOM", 0, -5) 
        end
        favFrame:Show() 
        
        -- Start the 3-second auto-close timer if they just hover the bar without moving up
        if Session.favTimer then Session.favTimer:Cancel() end
        Session.favTimer = C_Timer.NewTimer(3.0, function()
            if not favFrame:IsMouseOver() and not xpBar:IsMouseOver() then
                favFrame:Hide()
                OUS.SleepBars()
            end
        end)
    end
end)

xpBar:HookScript("OnLeave", function()
    -- Give them 0.5s to move their mouse from the XP Bar into the Favorites Frame before closing it
    if Session.favTimer then Session.favTimer:Cancel() end
    Session.favTimer = C_Timer.NewTimer(0.5, function()
        if not favFrame:IsMouseOver() and not xpBar:IsMouseOver() then
            favFrame:Hide()
            OUS.SleepBars()
        end
    end)
end)

-- ==========================================
-- 8. EVENT LISTENERS
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

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
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
        
        if OUS.BuildXPConfigUI then OUS.BuildXPConfigUI() end
        OUS.ApplyFonts()
        
        local xpP = OdysseusDB.xpBar.xpBarPos
        xpBar:ClearAllPoints()
        xpBar:SetPoint(xpP.p, UIParent, xpP.rP, xpP.x, xpP.y)
        
        local dbP = OdysseusDB.xpBar.delveBarPos
        delveBar:ClearAllPoints()
        delveBar:SetPoint(dbP.p, UIParent, dbP.rP, dbP.x, dbP.y)
        
        local tP = OdysseusDB.xpBar.toastPos
        toast:ClearAllPoints()
        toast:SetPoint(tP.p, UIParent, tP.rP, tP.x, tP.y)
        
        OUS.ApplyDimensions()
        OUS.ApplyXPBarBorders()
        Session.lastXP, Session.lastMaxXP = UnitXP("player"), UnitXPMax("player")
        OUS.WakeBars()
        OUS.SleepBars()
        OUS.LogDebug("XPBar", "Engine Loaded & Initialized.")
        
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ApplyBlizzardKiller()
        TriggerAggressiveDelveCheck()
        ScanFactionsForPopups(true)
        OUS.WakeBars()
        OUS.SleepBars()
        
    elseif event == "SCENARIO_UPDATE" or event == "UPDATE_INSTANCE_INFO" then
        OUS.UpdateBar()
        
    elseif event == "PLAYER_XP_UPDATE" then
        local currentXP, maxXP = UnitXP("player"), UnitXPMax("player")
        
        if currentXP > Session.lastXP and maxXP == Session.lastMaxXP then 
            Session.lastXPGain = currentXP - Session.lastXP
            Session.sessionXP = Session.sessionXP + Session.lastXPGain 
        elseif currentXP < Session.lastXP or maxXP > Session.lastMaxXP then 
            Session.lastXPGain = (Session.lastMaxXP - Session.lastXP) + currentXP
            Session.sessionXP = Session.sessionXP + Session.lastXPGain 
        end
        
        Session.lastXP, Session.lastMaxXP = currentXP, maxXP
        
        if Session.forceRepDisplay then 
            Session.forceRepDisplay = false
            if Session.repTimer then Session.repTimer:Cancel() end 
        end
        
        OUS.WakeBars()
        OUS.UpdateBar()
        OUS.SleepBars()
        OUS.LogDebug("XPBar", "XP Gain Detected: +" .. tostring(Session.lastXPGain))
        
    elseif event == "UPDATE_FACTION" then
        ScanFactionsForPopups(false)
        local isMaxLevel = (UnitLevel("player") >= (GetMaxPlayerLevel and GetMaxPlayerLevel() or 80)) or (IsXPUserDisabled and IsXPUserDisabled())
        
        if not isMaxLevel then 
            Session.forceRepDisplay = true
            if Session.repTimer then Session.repTimer:Cancel() end
            Session.repTimer = C_Timer.NewTimer(OdysseusDB.xpBar.repDisplayTime or 15, function() 
                Session.forceRepDisplay = false
                OUS.WakeBars()
                OUS.UpdateBar()
                OUS.SleepBars() 
            end) 
        end
        
        OUS.WakeBars()
        OUS.UpdateBar()
        OUS.SleepBars()
        
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" or event == "CHAT_MSG_SYSTEM" then
        if not arg1 or type(arg1) ~= "string" then return end
        local isSafe, safeString = pcall(string.match, arg1, ".*")
        if not isSafe then return end
        
        local msg = string.gsub(safeString, "|c%x%x%x%x%x%x%x%x", "")
        msg = string.gsub(msg, "|r", "")
        msg = string.gsub(msg, "|H.-|h(.-)|h", "%1")
        
        local faction, amount = string.match(msg, "[Rr]eputation with (.-) increased by (%d+)")
        if not faction then 
            faction, amount = string.match(msg, "Warband's reputation with (.-) increased by (%d+)") 
        end
        
        if faction and amount then 
            faction = string.gsub(faction, "[%[%]%.]", "")
            faction = string.gsub(faction, "^%s+", "")
            faction = string.gsub(faction, "%s+$", "")
            Session.sessionRep[faction] = (Session.sessionRep[faction] or 0) + tonumber(amount)
            Session.lastGainedFactionName = faction 
            OUS.LogDebug("XPBar", string.format("Rep Gain: %s (+%s)", faction, amount))
        end
        
    elseif event == "PLAYER_REGEN_DISABLED" then 
        OUS.WakeBars() 
    elseif event == "PLAYER_REGEN_ENABLED" then 
        OUS.SleepBars() 
    end
end)