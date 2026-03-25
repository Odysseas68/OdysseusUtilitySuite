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

    local function OpenColorPicker(dbColor, colorBoxFrame)
        ColorPickerFrame:SetupColorPickerAndShow({ 
            r = dbColor.r, g = dbColor.g, b = dbColor.b, 
            hasOpacity = false, 
            swatchFunc = function() 
                local r, g, b = ColorPickerFrame:GetColorRGB()
                dbColor.r, dbColor.g, dbColor.b = r, g, b
                colorBoxFrame:SetBackdropColor(r, g, b, 1)
                OUS.UpdateBar() 
            end, 
            cancelFunc = function(previousValues) 
                dbColor.r, dbColor.g, dbColor.b = previousValues.r, previousValues.g, previousValues.b
                colorBoxFrame:SetBackdropColor(previousValues.r, previousValues.g, previousValues.b, 1)
                OUS.UpdateBar() 
            end 
        })
    end

    local function CreateColorBox(parent, labelText, xOffset, yOffset, dbKey)
        local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
        box:SetSize(22, 22)
        box:SetPoint("TOPLEFT", xOffset, yOffset)
        box:SetBackdrop({ 
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
            edgeFile = "Interface\\Buttons\\WHITE8x8", 
            edgeSize = 1 
        })
        box:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        
        local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", box, "RIGHT", 6, 0)
        text:SetText(labelText)
        
        box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end)
        box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end)
        box:SetScript("OnClick", function(self) OpenColorPicker(OdysseusDB.xpBar[dbKey], self) end)
        return box
    end

    local sliderCounter = 1
    local function CreatePremiumSlider(parent, titleText, yOffset, dbKey, minVal, maxVal, step, onUpdate)
        local sliderName = "OdysseusXPSlider" .. sliderCounter
        sliderCounter = sliderCounter + 1
        
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(450, 40)
        container:SetPoint("TOPLEFT", 12, yOffset)
        
        local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(titleText)
        
        local btnMinus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btnMinus:SetSize(20, 20)
        btnMinus:SetPoint("BOTTOMLEFT", 0, 0)
        btnMinus:SetText("<")
        
        local slider = CreateFrame("Slider", sliderName, container, "OptionsSliderTemplate")
        slider:SetPoint("LEFT", btnMinus, "RIGHT", 6, 0)
        slider:SetWidth(250)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        
        _G[slider:GetName() .. "Text"]:SetText("")
        _G[slider:GetName() .. "Low"]:SetText("")
        _G[slider:GetName() .. "High"]:SetText("")
        
        local btnPlus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btnPlus:SetSize(20, 20)
        btnPlus:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        btnPlus:SetText(">")
        
        local editBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
        editBg:SetSize(40, 22)
        editBg:SetPoint("LEFT", btnPlus, "RIGHT", 10, 0)
        editBg:SetBackdrop({ 
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            tile = false, edgeSize = 12, 
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        editBg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)
        
        local editBox = CreateFrame("EditBox", nil, editBg)
        editBox:SetFontObject("GameFontHighlightSmall")
        editBox:SetPoint("TOPLEFT", 4, -2)
        editBox:SetPoint("BOTTOMRIGHT", -4, 2)
        editBox:SetAutoFocus(false)
        editBox:SetJustifyH("CENTER")

        local initVal = OdysseusDB.xpBar[dbKey] or minVal
        slider:SetValue(initVal)
        editBox:SetText(initVal)

        btnMinus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() - step) end)
        btnPlus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + step) end)
        
        editBox:SetScript("OnEscapePressed", function(self) 
            self:ClearFocus()
            self:SetText(slider:GetValue()) 
        end)
        
        editBox:SetScript("OnEnterPressed", function(self) 
            self:ClearFocus()
            local val = tonumber(self:GetText())
            if val then 
                val = math.max(minVal, math.min(maxVal, val))
                slider:SetValue(val) 
            else 
                self:SetText(slider:GetValue()) 
            end 
        end)
        
        slider:SetScript("OnValueChanged", function(self, value) 
            local snappedValue 
            if step < 1 then 
                snappedValue = math.floor(value * 100 + 0.5) / 100 
            else 
                snappedValue = math.floor(value + 0.5) 
            end
            OdysseusDB.xpBar[dbKey] = snappedValue
            editBox:SetText(snappedValue)
            if onUpdate then onUpdate() end 
        end)
        return slider, editBox
    end

    -- ==========================================
    -- 4. TAB 1: GLOBAL SETTINGS
    -- ==========================================
    local fontSizeSlider, fontSizeBox = CreatePremiumSlider(pages[1], "Global Font Size", -10, "xpFontSize", 8, 32, 1, OUS.ApplyFonts)
    
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

    local repTimeSlider, repTimeBox = CreatePremiumSlider(pages[1], "Auto-Switch Display Time (Seconds)", -180, "repDisplayTime", 5, 60, 1, function() OUS.WakeBars(); OUS.SleepBars() end)
    local fadeDelaySlider, fadeDelayBox = CreatePremiumSlider(pages[1], "Auto-Hide Fade Delay (Seconds)", -230, "fadeDelay", 0, 60, 1, function() OUS.WakeBars(); OUS.SleepBars() end)
    local activeAlphaSlider, activeAlphaBox = CreatePremiumSlider(pages[1], "Active Opacity (%)", -280, "activeAlpha", 10, 100, 5, function() OUS.WakeBars(); OUS.SleepBars() end)
    local fadedAlphaSlider, fadedAlphaBox = CreatePremiumSlider(pages[1], "Faded Opacity (%)", -330, "fadedAlpha", 0, 100, 5, function() OUS.WakeBars(); OUS.SleepBars() end)
    
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
        
        if ApplyBlizzardKiller then ApplyBlizzardKiller() end
        OUS.ApplyFonts()
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
    end)

    -- ==========================================
    -- 5. TAB 2: EXPERIENCE SETTINGS
    -- ==========================================
    local xpEditBox = CreateTemplateBox(pages[2], "Text Format", -10, "xpTemplate")
    local xpColorBox = CreateColorBox(pages[2], "Main Experience Color", 12, -70, "xpColor")
    local restColorBox = CreateColorBox(pages[2], "Rested Experience Color", 220, -70, "restColor")
    
    local xpWidthSlider, xpWidthBox = CreatePremiumSlider(pages[2], "Main Bar Width", -110, "xpBarWidth", 100, 1000, 10, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local xpHeightSlider, xpHeightBox = CreatePremiumSlider(pages[2], "Main Bar Height", -160, "xpBarHeight", 10, 100, 1, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local xpScaleSlider, xpScaleBox = CreatePremiumSlider(pages[2], "Main Bar Scale", -210, "xpBarScale", 0.5, 2.0, 0.05, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    
    local resetXPBtn = CreateFrame("Button", nil, pages[2], "UIPanelButtonTemplate")
    resetXPBtn:SetSize(120, 24)
    resetXPBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetXPBtn:SetText("Reset Defaults")
    resetXPBtn:SetScript("OnClick", function() 
        OdysseusDB.xpBar.xpTemplate = OUS.defaults.xpTemplate
        OdysseusDB.xpBar.xpColor = OUS.DeepCopyTable(OUS.defaults.xpColor)
        OdysseusDB.xpBar.restColor = OUS.DeepCopyTable(OUS.defaults.restColor)
        OdysseusDB.xpBar.xpBarWidth = OUS.defaults.xpBarWidth
        OdysseusDB.xpBar.xpBarHeight = OUS.defaults.xpBarHeight
        OdysseusDB.xpBar.xpBarScale = OUS.defaults.xpBarScale
        OdysseusDB.xpBar.xpBarPos = OUS.DeepCopyTable(OUS.defaults.xpBarPos)
        
        xpEditBox:SetText(OUS.defaults.xpTemplate)
        xpEditBox:SetCursorPosition(0)
        xpColorBox:SetBackdropColor(OUS.defaults.xpColor.r, OUS.defaults.xpColor.g, OUS.defaults.xpColor.b, 1)
        restColorBox:SetBackdropColor(OUS.defaults.restColor.r, OUS.defaults.restColor.g, OUS.defaults.restColor.b, 1)
        xpWidthSlider:SetValue(OUS.defaults.xpBarWidth)
        xpWidthBox:SetText(OUS.defaults.xpBarWidth)
        xpHeightSlider:SetValue(OUS.defaults.xpBarHeight)
        xpHeightBox:SetText(OUS.defaults.xpBarHeight)
        xpScaleSlider:SetValue(OUS.defaults.xpBarScale)
        xpScaleBox:SetText(OUS.defaults.xpBarScale)
        
        OUS.xpBarFrame:ClearAllPoints()
        OUS.xpBarFrame:SetPoint(OUS.defaults.xpBarPos.p, UIParent, OUS.defaults.xpBarPos.rP, OUS.defaults.xpBarPos.x, OUS.defaults.xpBarPos.y)
        OUS.ApplyDimensions()
        OUS.WakeBars()
        OUS.UpdateBar()
        OUS.SleepBars() 
        OUS.LogDebug("XPBar", "Experience defaults restored.")
    end)

    -- ==========================================
    -- 6. TAB 3: REPUTATION SETTINGS
    -- ==========================================
    local repEditBox = CreateTemplateBox(pages[3], "Text Format", -10, "repTemplate")
    local repColorBox = CreateColorBox(pages[3], "Main Reputation Color", 12, -70, "repColor")
    
    local toastEnableCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate")
    toastEnableCheck:SetPoint("TOPLEFT", 12, -110)
    toastEnableCheck.text = toastEnableCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastEnableCheck.text:SetPoint("LEFT", toastEnableCheck, "RIGHT", 4, 0)
    toastEnableCheck.text:SetText("Enable Renown & Paragon Reward Popups")
    toastEnableCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastEnabled = self:GetChecked() end)
    
    local toastSoundCheck = CreateFrame("CheckButton", nil, pages[3], "UICheckButtonTemplate")
    toastSoundCheck:SetPoint("TOPLEFT", 32, -140)
    toastSoundCheck.text = toastSoundCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastSoundCheck.text:SetPoint("LEFT", toastSoundCheck, "RIGHT", 4, 0)
    toastSoundCheck.text:SetText("Play Sound on Reward Popup")
    toastSoundCheck:SetScript("OnClick", function(self) OdysseusDB.xpBar.toastSound = self:GetChecked() end)

    local modLbl = pages[3]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modLbl:SetPoint("TOPLEFT", 12, -180)
    modLbl:SetText("Right-Click Modifier for Faction Menu:")
    
    local modBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate")
    modBtn:SetSize(120, 24)
    modBtn:SetPoint("TOPLEFT", 12, -195)
    modBtn:SetText(OdysseusDB.xpBar.repMenuMod or "CTRL")
    modBtn:SetScript("OnClick", function(self) 
        local current = OdysseusDB.xpBar.repMenuMod or "CTRL"
        local nextMod = "CTRL"
        if current == "CTRL" then nextMod = "SHIFT" 
        elseif current == "SHIFT" then nextMod = "ALT" 
        elseif current == "ALT" then nextMod = "NONE" 
        else nextMod = "CTRL" end
        
        OdysseusDB.xpBar.repMenuMod = nextMod
        self:SetText(nextMod) 
    end)

    local resetRepBtn = CreateFrame("Button", nil, pages[3], "UIPanelButtonTemplate")
    resetRepBtn:SetSize(120, 24)
    resetRepBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetRepBtn:SetText("Reset Defaults")
    resetRepBtn:SetScript("OnClick", function() 
        OdysseusDB.xpBar.repTemplate = OUS.defaults.repTemplate
        OdysseusDB.xpBar.repColor = OUS.DeepCopyTable(OUS.defaults.repColor)
        OdysseusDB.xpBar.toastEnabled = OUS.defaults.toastEnabled
        OdysseusDB.xpBar.toastSound = OUS.defaults.toastSound
        OdysseusDB.xpBar.repMenuMod = OUS.defaults.repMenuMod
        
        repEditBox:SetText(OUS.defaults.repTemplate)
        repEditBox:SetCursorPosition(0)
        repColorBox:SetBackdropColor(OUS.defaults.repColor.r, OUS.defaults.repColor.g, OUS.defaults.repColor.b, 1)
        toastEnableCheck:SetChecked(OUS.defaults.toastEnabled)
        toastSoundCheck:SetChecked(OUS.defaults.toastSound)
        modBtn:SetText(OUS.defaults.repMenuMod)
        
        OUS.WakeBars()
        OUS.UpdateBar()
        OUS.SleepBars() 
        OUS.LogDebug("XPBar", "Reputation defaults restored.")
    end)

    -- ==========================================
    -- 7. TAB 4: DELVE SETTINGS
    -- ==========================================
    local delveCompEditBox = CreateTemplateBox(pages[4], "Companion Text Format", -10, "delveCompTemplate")
    local delveJourEditBox = CreateTemplateBox(pages[4], "Journey Text Format", -65, "delveJourTemplate")
    
    local delveCompColorBox = CreateColorBox(pages[4], "Companion Color", 12, -120, "delveCompColor")
    local delveJourColorBox = CreateColorBox(pages[4], "Journey Color", 220, -120, "delveJourColor")
    
    local delveWidthSlider, delveWidthBox = CreatePremiumSlider(pages[4], "Delve Bar Width", -160, "delveBarWidth", 100, 1000, 10, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local delveHeightSlider, delveHeightBox = CreatePremiumSlider(pages[4], "Delve Bar Height", -210, "delveBarHeight", 20, 100, 2, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    local delveScaleSlider, delveScaleBox = CreatePremiumSlider(pages[4], "Delve Bar Scale", -260, "delveBarScale", 0.5, 2.0, 0.05, function() OUS.ApplyDimensions(); OUS.WakeBars(); OUS.SleepBars() end)
    
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
    toastEnableCheck:SetChecked(OdysseusDB.xpBar.toastEnabled)
    toastSoundCheck:SetChecked(OdysseusDB.xpBar.toastSound)
    
    xpEditBox:SetText(OdysseusDB.xpBar.xpTemplate or "")
    repEditBox:SetText(OdysseusDB.xpBar.repTemplate or "")
    delveCompEditBox:SetText(OdysseusDB.xpBar.delveCompTemplate or "")
    delveJourEditBox:SetText(OdysseusDB.xpBar.delveJourTemplate or "")
    
    local cXP = OdysseusDB.xpBar.xpColor
    local cRest = OdysseusDB.xpBar.restColor
    local cRep = OdysseusDB.xpBar.repColor
    local cDC = OdysseusDB.xpBar.delveCompColor
    local cDJ = OdysseusDB.xpBar.delveJourColor
    
    if cXP then xpColorBox:SetBackdropColor(cXP.r, cXP.g, cXP.b, 1) end
    if cRest then restColorBox:SetBackdropColor(cRest.r, cRest.g, cRest.b, 1) end
    if cRep then repColorBox:SetBackdropColor(cRep.r, cRep.g, cRep.b, 1) end
    if cDC then delveCompColorBox:SetBackdropColor(cDC.r, cDC.g, cDC.b, 1) end
    if cDJ then delveJourColorBox:SetBackdropColor(cDJ.r, cDJ.g, cDJ.b, 1) end
end