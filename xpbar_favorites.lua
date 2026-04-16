-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP FAVORITES & SMART HOVER
-- ==========================================
local addonName, OUS = ...
local Session = OUS.XPBarSession
local xpBar = OUS.xpBarFrame
local GetFactionDetails = OUS.GetFactionDetails

-- ==========================================
-- 2. FAVORITES SELECTION FRAME
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

local function ApplyFactionBarColor(statusBar, info)
    if info.hasRewardPending then
        statusBar:SetStatusBarColor(0.2, 0.8, 0.4, 1)
    elseif string.find(info.standingText, "Renown") then
        statusBar:SetStatusBarColor(0.0, 0.6, 0.8, 1)
    elseif string.find(info.standingText, "Paragon") then
        statusBar:SetStatusBarColor(0.5, 0.3, 0.8, 1)
    elseif info.reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[info.reaction] then
        local c = FACTION_BAR_COLORS[info.reaction]
        statusBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        statusBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
    end
end

local function SetFactionBarText(fontString, info)
    local displayCur = info.isMaxed and info.maxRep or info.curRep
    fontString:SetText(OUS.FormatLargeNumber(displayCur) .. " / " .. OUS.FormatLargeNumber(info.maxRep))
end

local function RefreshFactionSelectTree()
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for _, btn in pairs(fsButtons) do btn:Hide() end
    local yOffset = 0
    local numFactions = C_Reputation.GetNumFactions()

    for i = 1, numFactions do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and not data.isHidden then ---@diagnostic disable-line: undefined-field
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
                    ApplyFactionBarColor(btn.bar, info)
                    SetFactionBarText(btn.bar.txt, info)
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

-- ==========================================
-- 3. FAVORITES SAVE HANDLER
-- ==========================================
fsSaveBtn:SetScript("OnClick", function()
    if not OdysseusDB.xpBar.favFactions then OdysseusDB.xpBar.favFactions = {} end
    OdysseusDB.xpBar.favFactions = OUS.DeepCopyTable(tempFavorites)
    factionSelectFrame:Hide()
    OUS.LogDebug("XPBar", "Favorites list updated and saved.")
end)

-- ==========================================
-- 4. HOVER DASHBOARD
-- ==========================================
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
        if Session.favTimer then
            Session.favTimer:Cancel()
            Session.favTimer = nil
        end
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

-- ==========================================
-- 5. HOVER DASHBOARD RENDERING
-- ==========================================
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

                            -- Paragon reward pending indicator, shown to the right of the progress bar
                            row.rewardIcon = row:CreateTexture(nil, "OVERLAY")
                            row.rewardIcon:SetSize(16, 16)
                            row.rewardIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
                            row.rewardIcon:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                            row.rewardIcon:Hide()

                            row:SetScript("OnEnter", function(self)
                                -- Stop the frame from closing while we look at a specific row tooltip
                                if Session.favTimer then
                                    Session.favTimer:Cancel()
                                    Session.favTimer = nil
                                end
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

                        ApplyFactionBarColor(row.bar, info)
                        SetFactionBarText(row.bar.txt, info)

                        -- Reposition bar and show/hide reward icon based on paragon state
                        row.bar:ClearAllPoints()
                        if info.hasRewardPending then
                            row.bar:SetPoint("RIGHT", row.rewardIcon, "LEFT", -3, 0)
                            row.rewardIcon:SetVertexColor(1, 0.85, 0)
                            row.rewardIcon:Show()
                        else
                            row.bar:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                            row.rewardIcon:Hide()
                        end

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

-- ==========================================
-- 6. XP BAR FAVORITES INTERACTIONS
-- ==========================================
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