-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: XP CONFIG UI
-- ==========================================
local addonName, OUS = ...

StaticPopupDialogs["ODYSSEUS_RELOAD_PROMPT"] = { 
    text = "Changing this setting requires a UI reload to avoid errors. Reload now?", 
    button1 = "Yes", 
    button2 = "No", 
    OnAccept = function() ReloadUI() end, 
    timeout = 0, 
    whileDead = true, 
    hideOnEscape = true, 
    preferredIndex = 3 
}

function OUS.BuildXPConfigUI()
    if not OUS.XPBarTab then return end
    
    local pageContainer = CreateFrame("Frame", nil, OUS.XPBarTab, "BackdropTemplate")
    pageContainer:SetPoint("TOPLEFT", 5, -35)
    pageContainer:SetPoint("BOTTOMRIGHT", -5, 5)
    pageContainer:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = false, edgeSize = 12, 
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    pageContainer:SetBackdropColor(0.07, 0.05, 0.1, 0.5)

    -- ==========================================
    -- 2. INTERNAL TAB SYSTEM
    -- ==========================================
    local tabs, pages = {}, {}
    
    local function SelectTab(id)
        for i = 1, #tabs do 
            if i == id then 
                tabs[i]:SetBackdropColor(0.6, 0.2, 0.8, 0.5)
                tabs[i]:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
                tabs[i].text:SetTextColor(1, 1, 1, 1)
                pages[i]:Show() 
            else 
                tabs[i]:SetBackdropColor(0.05, 0.03, 0.05, 0.8)
                tabs[i]:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                tabs[i].text:SetTextColor(0.5, 0.5, 0.5, 1)
                pages[i]:Hide() 
            end 
        end
    end

    local function CreateTab(id, label)
        local tab = CreateFrame("Button", nil, OUS.XPBarTab, "BackdropTemplate")
        tab:SetID(id)
        tab:SetSize(85, 22)
        tab:SetBackdrop({ 
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            tile = false, edgeSize = 12, 
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(label)
        
        if id == 1 then 
            tab:SetPoint("BOTTOMLEFT", pageContainer, "TOPLEFT", 10, -1) 
        else 
            tab:SetPoint("LEFT", tabs[id-1], "RIGHT", 4, 0) 
        end
        
        tab:SetScript("OnClick", function(self) 
            SelectTab(self:GetID())
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) 
        end)
        
        local page = CreateFrame("Frame", nil, pageContainer)
        page:SetPoint("TOPLEFT", 4, -4)
        page:SetPoint("BOTTOMRIGHT", -4, 4)
        page:Hide()
        
        tabs[id], pages[id] = tab, page
    end

    CreateTab(1, "Global")
    CreateTab(2, "Experience")
    CreateTab(3, "Reputation")
    CreateTab(4, "Delves")
    CreateTab(5, "Help")
    SelectTab(1)

    -- ==========================================
    -- 3. WIDGET FACTORIES
    -- ==========================================
    local function CreateTemplateBox(parent, titleText, yOffset, dbKey)
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 12, yOffset)
        title:SetText(titleText)
        
        local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        bg:SetSize(450, 26)
        bg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        bg:SetBackdrop({ 
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            tile = false, edgeSize = 12, 
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        bg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
        
        local editBox = CreateFrame("EditBox", nil, bg)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetPoint("TOPLEFT", 6, -4)
        editBox:SetPoint("BOTTOMRIGHT", -6, 4)
        editBox:SetAutoFocus(false)
        
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnEnterPressed", function(self) 
            self:ClearFocus()
            OdysseusDB.xpBar[dbKey] = self:GetText()
            OUS.WakeBars()
            OUS.UpdateBar()
            OUS.SleepBars() 
        end)
        return editBox
    end

    -- ==========================================
    -- 4. TAB 1: GLOBAL SETTINGS
    -- ==========================================
    local fontSizeSlider, fontSizeBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Global Font Size", -10, "xpFontSize", 8, 32, 1, OUS.ApplyFonts)
    
    local fontLbl = pages[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontLbl:SetPoint("TOPLEFT", 12, -60)
    fontLbl:SetText("Global Font (Requires LibSharedMedia):")
    
    local fontBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate")
    fontBtn:SetSize(200, 24)
    fontBtn:SetPoint("TOPLEFT", 12, -75)
    fontBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.xpFont or "Friz Quadrata TT"), 1, 25))
    fontBtn:SetScript("OnClick", function(self) 
        if OUS.OpenDropDown then 
            OUS.OpenDropDown("font", OdysseusDB.xpBar.xpFont, function(name) 
                OdysseusDB.xpBar.xpFont = name
                self:SetText(string.sub(tostring(name), 1, 25))
                OUS.ApplyFonts() 
            end) 
        end 
    end)
    
    local hideBlizzCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
    hideBlizzCheck:SetPoint("TOPLEFT", 12, -110)
    hideBlizzCheck.text = hideBlizzCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hideBlizzCheck.text:SetPoint("LEFT", hideBlizzCheck, "RIGHT", 4, 0)
    hideBlizzCheck.text:SetText("Hide Default Blizzard UI (Requires Reload)")
    hideBlizzCheck:SetScript("OnClick", function(self) 
        OdysseusDB.xpBar.hideBlizz = self:GetChecked()
        StaticPopup_Show("ODYSSEUS_RELOAD_PROMPT") 
    end)
    
    local autoHideCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
    autoHideCheck:SetPoint("TOPLEFT", 12, -140)
    autoHideCheck.text = autoHideCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoHideCheck.text:SetPoint("LEFT", autoHideCheck, "RIGHT", 4, 0)
    autoHideCheck.text:SetText("Enable Auto-Hide / Mouseover Engine")
    autoHideCheck:SetScript("OnClick", function(self) 
        OdysseusDB.xpBar.autoHide = self:GetChecked()
        OUS.WakeBars()
        OUS.SleepBars() 
    end)

    local shortNumCheck = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
    shortNumCheck:SetPoint("TOPLEFT", 280, -140) -- Places it nicely in a 2nd column next to Auto-Hide!
    shortNumCheck.text = shortNumCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    shortNumCheck.text:SetPoint("LEFT", shortNumCheck, "RIGHT", 4, 0)
    shortNumCheck.text:SetText("Abbreviate Numbers")
    shortNumCheck:SetScript("OnClick", function(self) 
        OdysseusDB.xpBar.shortNumbers = self:GetChecked()
        OUS.UpdateBar() 
    end)

    local repTimeSlider, repTimeBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Auto-Switch Display Time (Seconds)", -180, "repDisplayTime", 5, 60, 1, function() OUS.WakeBars(); OUS.SleepBars() end)
    local fadeDelaySlider, fadeDelayBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Auto-Hide Fade Delay (Seconds)", -230, "fadeDelay", 0, 60, 1, function() OUS.WakeBars(); OUS.SleepBars() end)
    local activeAlphaSlider, activeAlphaBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Active Opacity (%)", -280, "activeAlpha", 10, 100, 5, function() OUS.WakeBars(); OUS.SleepBars() end)
    local fadedAlphaSlider, fadedAlphaBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Faded Opacity (%)", -330, "fadedAlpha", 0, 100, 5, function() OUS.WakeBars(); OUS.SleepBars() end)    

    local borderLbl = pages[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    borderLbl:SetPoint("TOPLEFT", 12, -380)
    borderLbl:SetText("Bar Border Style (Requires LibSharedMedia):")

    local borderBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate")
    borderBtn:SetSize(200, 24)
    borderBtn:SetPoint("TOPLEFT", borderLbl, "BOTTOMLEFT", 0, -4)
    borderBtn:SetScript("OnClick", function(self)
        if OUS.OpenDropDown then
            OUS.OpenDropDown("border", OdysseusDB.xpBar.barBorderName, function(name)
                OdysseusDB.xpBar.barBorderName = name
                self:SetText(string.sub(tostring(name), 1, 25))
                if OUS.ApplyXPBarBorders then OUS.ApplyXPBarBorders() end
            end)
        end
    end)

    local borderColorBox = OUS.CreateColorBox(pages[1], "Border Color", 230, -400, OdysseusDB.xpBar.barBorderColor, OUS.ApplyXPBarBorders)
    local borderSizeSlider, borderSizeBox = OUS.CreatePremiumSlider(pages[1], OdysseusDB.xpBar, "Bar Border Size", -430, "barBorderSize", 0, 50, 1, function() if OUS.ApplyXPBarBorders then OUS.ApplyXPBarBorders() end end)

    local resetGlobalBtn = CreateFrame("Button", nil, pages[1], "UIPanelButtonTemplate")
    resetGlobalBtn:SetSize(120, 24)
    resetGlobalBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetGlobalBtn:SetText("Reset Defaults")
    resetGlobalBtn:SetScript("OnClick", function() 
        OdysseusDB.xpBar.hideBlizz = OUS.defaults.hideBlizz
        OdysseusDB.xpBar.autoHide = OUS.defaults.autoHide
        OdysseusDB.xpBar.repDisplayTime = OUS.defaults.repDisplayTime
        OdysseusDB.xpBar.fadeDelay = OUS.defaults.fadeDelay
        OdysseusDB.xpBar.activeAlpha = OUS.defaults.activeAlpha
        OdysseusDB.xpBar.fadedAlpha = OUS.defaults.fadedAlpha
        OdysseusDB.xpBar.xpFont = OUS.defaults.xpFont
        OdysseusDB.xpBar.xpFontSize = OUS.defaults.xpFontSize
        OdysseusDB.xpBar.barBorderName = OUS.defaults.barBorderName
        OdysseusDB.xpBar.barBorderSize = OUS.defaults.barBorderSize
        OdysseusDB.xpBar.barBorderColor = OUS.DeepCopyTable(OUS.defaults.barBorderColor)
        
        hideBlizzCheck:SetChecked(OUS.defaults.hideBlizz)
        autoHideCheck:SetChecked(OUS.defaults.autoHide)
        repTimeSlider:SetValue(OUS.defaults.repDisplayTime)
        repTimeBox:SetText(OUS.defaults.repDisplayTime)
        fadeDelaySlider:SetValue(OUS.defaults.fadeDelay)
        fadeDelayBox:SetText(OUS.defaults.fadeDelay)
        activeAlphaSlider:SetValue(OUS.defaults.activeAlpha)
        activeAlphaBox:SetText(OUS.defaults.activeAlpha)
        fadedAlphaSlider:SetValue(OUS.defaults.fadedAlpha)
        fadedAlphaBox:SetText(OUS.defaults.fadedAlpha)
        fontSizeSlider:SetValue(OUS.defaults.xpFontSize)
        fontSizeBox:SetText(OUS.defaults.xpFontSize)
        fontBtn:SetText(OUS.defaults.xpFont)
        borderBtn:SetText(string.sub(tostring(OUS.defaults.barBorderName), 1, 25))
        borderSizeSlider:SetValue(OUS.defaults.barBorderSize)
        borderSizeBox:SetText(OUS.defaults.barBorderSize)
        borderColorBox:SetBackdropColor(OUS.defaults.barBorderColor.r, OUS.defaults.barBorderColor.g, OUS.defaults.barBorderColor.b, 1)
        
        if ApplyBlizzardKiller then ApplyBlizzardKiller() end
        OUS.ApplyFonts()
        if OUS.ApplyXPBarBorders then OUS.ApplyXPBarBorders() end
        OUS.WakeBars()
        OUS.SleepBars() 
        OUS.LogDebug("XPBar", "Global defaults restored.")
    end)
    
    pages[1]:SetScript("OnShow", function() 
        if IsInInstance() then 
            hideBlizzCheck:Disable()
            hideBlizzCheck.text:SetTextColor(0.5, 0.5, 0.5) 
        else 
            hideBlizzCheck:Enable()
            hideBlizzCheck.text:SetTextColor(1, 1, 1) 
        end 
        if fontBtn then 
            fontBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.xpFont or "Friz Quadrata TT"), 1, 25)) 
        end 
        if borderBtn then
            borderBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.barBorderName or "None"), 1, 25))
        end
    end)

-- ==========================================
    -- 5. TAB 2: EXPERIENCE SETTINGS
    -- ==========================================
    local xpEditBox = CreateTemplateBox(pages[2], "Text Format", -10, "xpTemplate")
    
    -- Row 1 of Colors
    local xpColorBox = OUS.CreateColorBox(pages[2], "Main EXP Bar", 12, -70, OdysseusDB.xpBar.xpColor, OUS.UpdateBar)
    local xpTextColorBox = OUS.CreateColorBox(pages[2], "Text Color", 180, -70, OdysseusDB.xpBar.xpTextColor, OUS.UpdateBar)
    -- Row 2 of Colors
    local restColorBox = OUS.CreateColorBox(pages[2], "Rested Bar", 12, -95, OdysseusDB.xpBar.restColor, OUS.UpdateBar)
    
    local restIconCheck = CreateFrame("CheckButton", nil, pages[2], "UICheckButtonTemplate")
    restIconCheck:SetPoint("TOPLEFT", 180, -90)
    restIconCheck.text = restIconCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    restIconCheck.text:SetPoint("LEFT", restIconCheck, "RIGHT", 4, 0)
    restIconCheck.text:SetText("Show 'Zzzz' Icon when Resting")
    restIconCheck:SetChecked(OdysseusDB.xpBar.showRestIcon)
    restIconCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.showRestIcon = self:GetChecked(); OUS.UpdateBar() end)
    
    local xpWidthSlider, xpWidthBox = OUS.CreatePremiumSlider(pages[2], OdysseusDB.xpBar, "Main Bar Width", -135, "xpBarWidth", 100, 1000, 10, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local xpHeightSlider, xpHeightBox = OUS.CreatePremiumSlider(pages[2], OdysseusDB.xpBar, "Main Bar Height", -185, "xpBarHeight", 10, 100, 1, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local xpScaleSlider, xpScaleBox = OUS.CreatePremiumSlider(pages[2], OdysseusDB.xpBar, "Main Bar Scale", -235, "xpBarScale", 0.5, 2.0, 0.05, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    
    local resetXPBtn = CreateFrame("Button", nil, pages[2], "UIPanelButtonTemplate")
    resetXPBtn:SetSize(120, 24)
    resetXPBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetXPBtn:SetText("Reset Defaults")
    -- (You can leave your existing reset logic here, just make sure to add OdysseusDB.xpBar.xpTextColor = OUS.DeepCopyTable(OUS.defaults.xpTextColor) inside it later!)

    -- ==========================================
    -- 6. TAB 3: REPUTATION SETTINGS
    -- ==========================================
    local repEditBox = CreateTemplateBox(pages[3], "Text Format", -10, "repTemplate")
    
    -- Clean 2-Column Grid for Dynamic Reputation Colors
    local repTextColorBox = OUS.CreateColorBox(pages[3], "Rep Text Color", 12, -65, OdysseusDB.xpBar.repTextColor, OUS.UpdateBar)
    
    local cGrid = OdysseusDB.xpBar.repColors
    local h_box = OUS.CreateColorBox(pages[3], "Hated", 12, -95, cGrid.hated, OUS.UpdateBar)
    local ho_box = OUS.CreateColorBox(pages[3], "Hostile", 120, -95, cGrid.hostile, OUS.UpdateBar)
    local u_box = OUS.CreateColorBox(pages[3], "Unfriendly", 220, -95, cGrid.unfriendly, OUS.UpdateBar)
    
    local n_box = OUS.CreateColorBox(pages[3], "Neutral", 12, -120, cGrid.neutral, OUS.UpdateBar)
    local f_box = OUS.CreateColorBox(pages[3], "Friendly", 120, -120, cGrid.friendly, OUS.UpdateBar)
    local hn_box = OUS.CreateColorBox(pages[3], "Honored", 220, -120, cGrid.honored, OUS.UpdateBar)
    
    local r_box = OUS.CreateColorBox(pages[3], "Revered", 12, -145, cGrid.revered, OUS.UpdateBar)
    local e_box = OUS.CreateColorBox(pages[3], "Exalted", 120, -145, cGrid.exalted, OUS.UpdateBar)
    local rn_box = OUS.CreateColorBox(pages[3], "Renown", 220, -145, cGrid.renown, OUS.UpdateBar)
    local p_box = OUS.CreateColorBox(pages[3], "Paragon", 320, -145, cGrid.paragon, OUS.UpdateBar)
    
    local toastEnableCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate")
    toastEnableCheck:SetPoint("TOPLEFT", 12, -175)
    toastEnableCheck.text = toastEnableCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastEnableCheck.text:SetPoint("LEFT", toastEnableCheck, "RIGHT", 4, 0)
    toastEnableCheck.text:SetText("Enable Renown & Paragon Reward Popups")
    toastEnableCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastEnabled = self:GetChecked() end)
    
    local toastSoundCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate")
    toastSoundCheck:SetPoint("TOPLEFT", 32, -200)
    toastSoundCheck.text = toastSoundCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastSoundCheck.text:SetPoint("LEFT", toastSoundCheck, "RIGHT", 4, 0)
    toastSoundCheck.text:SetText("Play Sound on Reward Popup")
    toastSoundCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastSound = self:GetChecked() end)

    local modLbl = pages[3]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modLbl:SetPoint("TOPLEFT", 12, -235)
    modLbl:SetText("Right-Click Modifier for Faction Menu:")
    
    local modBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate")
    modBtn:SetSize(120, 24)
    modBtn:SetPoint("TOPLEFT", 12, -250)
    modBtn:SetText(OdysseusDB.xpBar.repMenuMod or "CTRL")
    modBtn:SetScript("OnClick", function(self) 
        -- (Keep your existing modifier click logic here!)
    end)

    -- ==========================================
    -- 7. TAB 4: DELVE SETTINGS
    -- ==========================================
    local delveCompEditBox = CreateTemplateBox(pages[4], "Companion Text Format", -10, "delveCompTemplate")
    local delveJourEditBox = CreateTemplateBox(pages[4], "Journey Text Format", -65, "delveJourTemplate")
    
    local delveCompColorBox = OUS.CreateColorBox(pages[4], "Companion Color", 12, -120, OdysseusDB.xpBar.delveCompColor, OUS.UpdateDelveBar)
    local delveJourColorBox = OUS.CreateColorBox(pages[4], "Journey Color", 220, -120, OdysseusDB.xpBar.delveJourColor, OUS.UpdateDelveBar)
    
    local delveWidthSlider, delveWidthBox = OUS.CreatePremiumSlider(pages[4], OdysseusDB.xpBar, "Delve Bar Width", -160, "delveBarWidth", 100, 1000, 10, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local delveHeightSlider, delveHeightBox = OUS.CreatePremiumSlider(pages[4], OdysseusDB.xpBar, "Delve Bar Height", -210, "delveBarHeight", 20, 100, 2, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local delveScaleSlider, delveScaleBox = OUS.CreatePremiumSlider(pages[4], OdysseusDB.xpBar, "Delve Bar Scale", -260, "delveBarScale", 0.5, 2.0, 0.05, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    
    local resetDelveBtn = CreateFrame("Button", nil, pages[4], "UIPanelButtonTemplate")
    resetDelveBtn:SetSize(120, 24)
    resetDelveBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetDelveBtn:SetText("Reset Defaults")
    resetDelveBtn:SetScript("OnClick", function() 
        OdysseusDB.xpBar.delveCompTemplate = OUS.defaults.delveCompTemplate
        OdysseusDB.xpBar.delveJourTemplate = OUS.defaults.delveJourTemplate
        OdysseusDB.xpBar.delveCompColor = OUS.DeepCopyTable(OUS.defaults.delveCompColor)
        OdysseusDB.xpBar.delveJourColor = OUS.DeepCopyTable(OUS.defaults.delveJourColor)
        OdysseusDB.xpBar.delveBarWidth = OUS.defaults.delveBarWidth
        OdysseusDB.xpBar.delveBarHeight = OUS.defaults.delveBarHeight
        OdysseusDB.xpBar.delveBarScale = OUS.defaults.delveBarScale
        OdysseusDB.xpBar.delveBarPos = OUS.DeepCopyTable(OUS.defaults.delveBarPos)
        
        delveCompEditBox:SetText(OUS.defaults.delveCompTemplate)
        delveCompEditBox:SetCursorPosition(0)
        delveJourEditBox:SetText(OUS.defaults.delveJourTemplate)
        delveJourEditBox:SetCursorPosition(0)
        delveCompColorBox:SetBackdropColor(OUS.defaults.delveCompColor.r, OUS.defaults.delveCompColor.g, OUS.defaults.delveCompColor.b, 1)
        delveJourColorBox:SetBackdropColor(OUS.defaults.delveJourColor.r, OUS.defaults.delveJourColor.g, OUS.defaults.delveJourColor.b, 1)
        delveWidthSlider:SetValue(OUS.defaults.delveBarWidth)
        delveWidthBox:SetText(OUS.defaults.delveBarWidth)
        delveHeightSlider:SetValue(OUS.defaults.delveBarHeight)
        delveHeightBox:SetText(OUS.defaults.delveBarHeight)
        delveScaleSlider:SetValue(OUS.defaults.delveBarScale)
        delveScaleBox:SetText(OUS.defaults.delveBarScale)
        
        OUS.delveBarFrame:ClearAllPoints()
        OUS.delveBarFrame:SetPoint(OUS.defaults.delveBarPos.p, UIParent, OUS.defaults.delveBarPos.rP, OUS.defaults.delveBarPos.x, OUS.defaults.delveBarPos.y)
        OUS.ApplyDimensions()
        OUS.WakeBars()
        OUS.UpdateBar()
        OUS.SleepBars() 
        OUS.LogDebug("XPBar", "Delve defaults restored.")
    end)

    -- ==========================================
    -- 8. TAB 5: HELP & COMMANDS
    -- ==========================================
    local helpText = pages[5]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", 12, -12)
    helpText:SetJustifyH("LEFT")
    
    local helpString = "|cFFFFD100EXPERIENCE TAGS:|r\n" ..
        "|cFFFFFF00[curXP]|r - Current XP  |  |cFFFFFF00[maxXP]|r - Max XP\n" ..
        "|cFFFFFF00[needXP]|r - Remaining XP  |  |cFFFFFF00[curPC]|r - Current %\n" ..
        "|cFFFFFF00[needPC]|r - Remaining %  |  |cFFFFFF00[restPC]|r - Rested %\n" ..
        "|cFFFFFF00[pLVL]|r - Current Lvl  |  |cFFFFFF00[nLVL]|r - Next Lvl\n" ..
        "|cFFFFFF00[mLVL]|r - Max Lvl  |  |cFFFFFF00[restXP]|r - Rested XP\n" ..
        "|cFFFFFF00[restLVL]|r - Rested XP (Lvl)  |  |cFFFFFF00[KTL]|r - Kills to Level\n\n" ..
        "|cFFFFD100REPUTATION & DELVES TAGS:|r\n" ..
        "|cFF00FF00[faction]|r - Name  |  |cFF00FF00[standing]|r - Standing\n" ..
        "|cFF00FF00[curRep]|r - Cur Rep  |  |cFF00FF00[maxRep]|r - Max Rep\n" ..
        "|cFF00FFFF[compName]|r - Companion Name  |  |cFF00FFFF[pLVL]|r - Comp Lvl\n\n" ..
        "|cFFFFD100MASTER CHAT COMMANDS:|r\n" ..
        "|cFF00FF00/ous|r - Open Main Config\n" ..
        "|cFF00FF00/ous help|r - Show All Commands\n" ..
        "|cFF00FF00/xpstats|r - Show Session XP/Rep\n" ..
        "|cFF00FF00/toasttest|r - Test Popup (Hold Shift to Move!)\n" ..
        "|cFF888888(Tip: Shift+Drag to move the bars!)|r\n" ..
        "|cFF888888(Tip: Mod+Right-Click the XP Bar for the Faction Menu!)|r"
        
    helpText:SetText(helpString)
    
    -- ==========================================
    -- 9. PRE-FILL UI WITH SAVED DATA
    -- ==========================================
    hideBlizzCheck:SetChecked(OdysseusDB.xpBar.hideBlizz)
    autoHideCheck:SetChecked(OdysseusDB.xpBar.autoHide)
    shortNumCheck:SetChecked(OdysseusDB.xpBar.shortNumbers)
    toastEnableCheck:SetChecked(OdysseusDB.xpBar.toastEnabled)
    toastSoundCheck:SetChecked(OdysseusDB.xpBar.toastSound)    
    borderBtn:SetText(string.sub(tostring(OdysseusDB.xpBar.barBorderName or "None"), 1, 25))
    
    xpEditBox:SetText(OdysseusDB.xpBar.xpTemplate or "")
    repEditBox:SetText(OdysseusDB.xpBar.repTemplate or "")
    delveCompEditBox:SetText(OdysseusDB.xpBar.delveCompTemplate or "")
    delveJourEditBox:SetText(OdysseusDB.xpBar.delveJourTemplate or "")
    
    local cXP = OdysseusDB.xpBar.xpColor
    local cRest = OdysseusDB.xpBar.restColor
    local cRep = OdysseusDB.xpBar.repColor
    local cDC = OdysseusDB.xpBar.delveCompColor
    local cDJ = OdysseusDB.xpBar.delveJourColor
    
    --if cXP then xpColorBox:SetBackdropColor(cXP.r, cXP.g, cXP.b, 1) end
    --if cRest then restColorBox:SetBackdropColor(cRest.r, cRest.g, cRest.b, 1) end
    --if cRep then repColorBox:SetBackdropColor(cRep.r, cRep.g, cRep.b, 1) end
    --if cDC then delveCompColorBox:SetBackdropColor(cDC.r, cDC.g, cDC.b, 1) end
    --if cDJ then delveJourColorBox:SetBackdropColor(cDJ.r, cDJ.g, cDJ.b, 1) end
end