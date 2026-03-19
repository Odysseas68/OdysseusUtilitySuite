local addonName, OUS = ...
local LSM = LibStub("LibSharedMedia-3.0")

local cfg = CreateFrame("Frame", "OdysseusConfigFrame", UIParent, "BackdropTemplate")
cfg:SetSize(520, 480)
cfg:SetPoint("CENTER")
cfg:Hide()
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop", cfg.StopMovingOrSizing)
tinsert(UISpecialFrames, cfg:GetName())
OUS.ConfigFrame = cfg

-- Midnight Theme Backdrop
cfg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
cfg:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
cfg:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

cfg.headerBg = cfg:CreateTexture(nil, "BACKGROUND", nil, 2)
cfg.headerBg:SetPoint("TOPLEFT", 4, -4)
cfg.headerBg:SetPoint("TOPRIGHT", -4, -4)
cfg.headerBg:SetHeight(30)
cfg.headerBg:SetColorTexture(1, 1, 1, 1)
cfg.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

cfg.title = cfg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
cfg.title:SetPoint("TOP", cfg, "TOP", 0, -10)
cfg.title:SetText("Odysseus Utility Suite")
cfg.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

cfg.closeBtn = CreateFrame("Button", nil, cfg, "UIPanelCloseButton")
cfg.closeBtn:SetPoint("TOPRIGHT", cfg, "TOPRIGHT", -2, -2)

-- Left Navigation Panel
local navPanel = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
navPanel:SetSize(140, 440)
navPanel:SetPoint("TOPLEFT", cfg, "TOPLEFT", 4, -34)
navPanel:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
navPanel:SetBackdropColor(0, 0, 0, 0.3)

-- Right Content Panel Container
local contentPanel = CreateFrame("Frame", nil, cfg)
contentPanel:SetSize(370, 440)
contentPanel:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 0, 0)

-- Tab Frames
local tabs = {}
tabs.General = CreateFrame("Frame", nil, contentPanel)
tabs.FlightMaster = CreateFrame("Frame", nil, contentPanel)
tabs.FasterLoot = CreateFrame("Frame", nil, contentPanel)
tabs.Fishing = CreateFrame("Frame", nil, contentPanel)

for _, tab in pairs(tabs) do
    tab:SetAllPoints()
    tab:Hide()
end

-- Tab Switching Logic
local function ShowTab(tabName)
    for k, tab in pairs(tabs) do
        if k == tabName then tab:Show() else tab:Hide() end
    end
end

local function CreateNavButton(label, yOffset, targetTab)
    local btn = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
    btn:SetSize(130, 30)
    btn:SetPoint("TOP", navPanel, "TOP", 0, yOffset)
    btn:SetText(label)
    btn:SetScript("OnClick", function() ShowTab(targetTab) end)
end

CreateNavButton("General", -10, "General")
CreateNavButton("Flight Master", -45, "FlightMaster")
CreateNavButton("Faster Loot", -80, "FasterLoot")
CreateNavButton("Fishing Tracker", -115, "Fishing")


-- =====================================
-- GLOBALS: WIPES & EXPORTS
-- =====================================
StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE"] = {
    text = "Are you sure you want to wipe ALL recorded flight times? This cannot be undone.",
    button1 = "Yes, Wipe",
    button2 = "Cancel",
    OnAccept = function()
        OdysseusDB.flightSettings.times = {}
        print("|cFF00CCFFOdysseus:|r All recorded flight times |cFFFF0000wiped|r!")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE_FISHING"] = {
    text = "Are you sure you want to wipe ALL recorded fishing history? This cannot be undone.",
    button1 = "Yes, Wipe",
    button2 = "Cancel",
    OnAccept = function()
        if OdysseusDB and OdysseusDB.fishingSettings then
            OdysseusDB.fishingSettings.history = {}
            print("|cFF00CCFFOdysseus:|r All recorded fishing history |cFFFF0000wiped|r!")
            if OUS.UpdateFishingUI then
                OUS.UpdateFishingUI()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local exportFrame = CreateFrame("Frame", "OdysseusExportFrame", UIParent, "BackdropTemplate")
exportFrame:SetSize(450, 400)
exportFrame:SetPoint("CENTER")
exportFrame:SetFrameStrata("DIALOG")
exportFrame:Hide()
tinsert(UISpecialFrames, exportFrame:GetName())

exportFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
exportFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
exportFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

exportFrame.headerBg = exportFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
exportFrame.headerBg:SetPoint("TOPLEFT", 4, -4)
exportFrame.headerBg:SetPoint("TOPRIGHT", -4, -4)
exportFrame.headerBg:SetHeight(26)
exportFrame.headerBg:SetColorTexture(1, 1, 1, 1)
exportFrame.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
exportFrame.title:SetPoint("TOP", exportFrame, "TOP", 0, -8)
exportFrame.title:SetText("Export Flight Data")
exportFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local exportScroll = CreateFrame("ScrollFrame", "OdysseusExportScroll", exportFrame, "UIPanelScrollFrameTemplate")
exportScroll:SetPoint("TOPLEFT", 15, -40)
exportScroll:SetPoint("BOTTOMRIGHT", -35, 45)

local exportEditBox = CreateFrame("EditBox", "OdysseusExportEditBox", exportScroll)
exportEditBox:SetSize(exportScroll:GetSize())
exportEditBox:SetMultiLine(true)
exportEditBox:SetAutoFocus(false)
exportEditBox:SetFontObject("ChatFontNormal")
exportEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); exportFrame:Hide() end)
exportScroll:SetScrollChild(exportEditBox)

local selectAllBtn = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
selectAllBtn:SetSize(120, 25)
selectAllBtn:SetPoint("BOTTOMLEFT", 15, 10)
selectAllBtn:SetText("Select All")
selectAllBtn:SetScript("OnClick", function()
    exportEditBox:HighlightText()
    exportEditBox:SetFocus()
end)

local closeExpBtn = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
closeExpBtn:SetSize(120, 25)
closeExpBtn:SetPoint("BOTTOMRIGHT", -15, 10)
closeExpBtn:SetText("Close")
closeExpBtn:SetScript("OnClick", function() exportFrame:Hide() end)


-- =====================================
-- GLOBALS: DROPDOWNS & SLIDERS
-- =====================================
local dropDown = CreateFrame("Frame", "OdysseusMediaDropDown", cfg, "BackdropTemplate")
dropDown:SetSize(220, 350)
dropDown:SetPoint("TOPLEFT", cfg, "TOPRIGHT", 5, 0)
dropDown:Hide()
dropDown:SetFrameStrata("TOOLTIP")

dropDown:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
dropDown:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
dropDown:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

dropDown.headerBg = dropDown:CreateTexture(nil, "BACKGROUND", nil, 2)
dropDown.headerBg:SetPoint("TOPLEFT", 4, -4)
dropDown.headerBg:SetPoint("TOPRIGHT", -4, -4)
dropDown.headerBg:SetHeight(26)
dropDown.headerBg:SetColorTexture(1, 1, 1, 1)
dropDown.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

dropDown.title = dropDown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dropDown.title:SetPoint("TOP", dropDown, "TOP", 0, -10)
dropDown.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

local scrollFrame = CreateFrame("ScrollFrame", "OdysseusMediaScroll", dropDown, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(180, 1)

local dropdownButtons = {}

local function OpenDropDown(mediaType, currentName, onSelect)
    dropDown:Show()
    dropDown.title:SetText("Select " .. (mediaType == "font" and "Font" or (mediaType == "statusbar" and "Texture" or "Border")))
    local list = LSM:List(mediaType)
    for _, btn in ipairs(dropdownButtons) do btn:Hide() end

    local yOffset = 0
    for i, name in ipairs(list) do
        local btn = dropdownButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            btn:SetSize(180, 24)
            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.txt:SetPoint("CENTER")
            btn.txt:SetWidth(150)
            btn.txt:SetWordWrap(false)
            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.15) 
            table.insert(dropdownButtons, btn)
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 0, -yOffset)
        local path = LSM:Fetch(mediaType, name)
        
        btn:SetBackdrop(nil)
        
        if mediaType == "statusbar" then
            btn.bg:SetColorTexture(1, 1, 1, 1) 
            btn.bg:SetTexture(path)
            btn.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        elseif mediaType == "font" then
            btn.bg:SetTexture(nil)
            btn.bg:SetColorTexture(0.05, 0.05, 0.08, 0.8) 
            local success = pcall(function() btn.txt:SetFont(path, 12, "OUTLINE") end)
            if not success then btn.txt:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") end
        elseif mediaType == "border" then
            btn.bg:SetTexture(nil)
            btn.bg:SetColorTexture(0.1, 0.1, 0.15, 1) 
            btn.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            if path then
                btn:SetBackdrop({ edgeFile = path, edgeSize = 12 })
            end
        end

        btn.txt:SetText(name)
        if name == currentName then btn.txt:SetTextColor(1, 0.82, 0) else btn.txt:SetTextColor(0.9, 0.9, 0.9) end
        btn:SetScript("OnClick", function() onSelect(name) dropDown:Hide() end)
        btn:Show()
        yOffset = yOffset + 24
    end
    scrollChild:SetHeight(yOffset)
end

local function CreateLabeledButton(parent, labelText, xOffset, yOffset, defaultBtnText, width, onClick)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset - 5)
    lbl:SetText(labelText)
    lbl:SetTextColor(0.8, 0.7, 0.9) 
    
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 25)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset + 55, yOffset) 
    btn:SetText(defaultBtnText)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreateSliderControl(parent, labelText, xOffset, yOffset, minV, maxV, stepV, onUpdate)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset - 5)
    lbl:SetText(labelText)
    lbl:SetTextColor(0.8, 0.7, 0.9) 

    local sliderName = "OdysseusSlider_" .. string.gsub(labelText, "%W", "")
    
    local leftBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    leftBtn:SetSize(20, 20)
    leftBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset - 22)
    leftBtn:SetText("<")
    
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetSize(90, 15)
    slider:SetPoint("LEFT", leftBtn, "RIGHT", 2, 0)
    
    local rightBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    rightBtn:SetSize(20, 20)
    rightBtn:SetPoint("LEFT", slider, "RIGHT", 2, 0)
    rightBtn:SetText(">")

    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(stepV)
    slider:SetObeyStepOnDrag(true)

    _G[sliderName.."Low"]:SetText("")
    _G[sliderName.."High"]:SetText("")
    _G[sliderName.."Text"]:SetText("")

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(35, 20)
    box:SetPoint("LEFT", rightBtn, "RIGHT", 8, 0)
    box:SetAutoFocus(false)
    box:SetJustifyH("CENTER")

    local isUpdating = false 
    local function SyncValues(val)
        if isUpdating then return end
        isUpdating = true
        if val < minV then val = minV end
        if val > maxV then val = maxV end
        local inv = 1 / stepV
        val = math.floor(val * inv + 0.5) / inv
        slider:SetValue(val)
        box:SetText(val)
        onUpdate(val)
        isUpdating = false
    end

    slider:SetScript("OnValueChanged", function(self, value) SyncValues(value) end)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local val = tonumber(self:GetText())
        if val then SyncValues(val) else self:SetText(slider:GetValue()) end
    end)
    leftBtn:SetScript("OnClick", function() SyncValues(slider:GetValue() - stepV) end)
    rightBtn:SetScript("OnClick", function() SyncValues(slider:GetValue() + stepV) end)
    
    return slider, box
end

-- =====================================
-- TAB 1: GENERAL (Module Toggles)
-- =====================================
local genTitle = tabs.General:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
genTitle:SetPoint("TOPLEFT", 20, -20)
genTitle:SetText("Module Management")

local function CreateModuleToggle(parent, label, yOffset, dbKey)
    local frameName = "OdysseusToggle_" .. dbKey
    local cb = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    _G[cb:GetName().."Text"]:SetText(label)
    
    cb:SetScript("OnShow", function(self)
        if OdysseusDB and OdysseusDB.modules then
            self:SetChecked(OdysseusDB.modules[dbKey])
        end
    end)
    
    cb:SetScript("OnClick", function(self)
        OdysseusDB.modules[dbKey] = self:GetChecked()
        
        if dbKey == "fishingTracker" and not self:GetChecked() and OdysseusFishingMain then
            OdysseusFishingMain:Hide()
        end
    end)
end

CreateModuleToggle(tabs.General, " Enable Flight Master", -60, "flightMaster")
CreateModuleToggle(tabs.General, " Enable Faster Loot", -95, "fasterLoot")
CreateModuleToggle(tabs.General, " Enable Fishing Tracker", -130, "fishingTracker")

-- =====================================
-- TAB 2: FLIGHT MASTER (Two-Column Layout)
-- =====================================
local fmTitle = tabs.FlightMaster:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
fmTitle:SetPoint("TOPLEFT", 20, -20)
fmTitle:SetText("Flight Master Settings")

-- LEFT COLUMN (Buttons & Dropdowns)
local lockBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
lockBtn:SetSize(160, 25)
lockBtn:SetPoint("TOPLEFT", 20, -55)
lockBtn:SetText("Unlock Timer Bar")
lockBtn:SetScript("OnClick", function(self)
    OUS.isFlightBarUnlocked = not OUS.isFlightBarUnlocked
    if OUS.isFlightBarUnlocked then
        self:SetText("Lock Timer Bar")
        OUS.ApplyFlightBorder() 
        OUS.timerBar:EnableMouse(true)
        OUS.timerBar:Show()
        OUS.timerBar:SetMinMaxValues(0, 1)
        OUS.timerBar:SetValue(1)
        OUS.timerText:SetText("Drag to move")
        OUS.timerTopText:SetText("Config Mode")
    else
        self:SetText("Unlock Timer Bar")
        OUS.timerBar:EnableMouse(false)
        OUS.timerBar:Hide()
        OUS.timerText:SetText("")
        OUS.timerTopText:SetText("")
    end
end)

local colorBtn = CreateLabeledButton(tabs.FlightMaster, "Color:", 20, -95, "Change Color", 105, function()
    local r, g, b = OUS.timerBar:GetStatusBarColor()
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b,
        swatchFunc = function()
            local cr, cg, cb = ColorPickerFrame:GetColorRGB()
            OUS.timerBar:SetStatusBarColor(cr, cg, cb)
            OdysseusDB.flightSettings.color = {cr, cg, cb}
        end,
        cancelFunc = function(prev)
            OUS.timerBar:SetStatusBarColor(prev.r, prev.g, prev.b)
            OdysseusDB.flightSettings.color = {prev.r, prev.g, prev.b}
        end
    })
end)

local texBtn = CreateLabeledButton(tabs.FlightMaster, "Texture:", 20, -130, "Loading...", 105, function(self)
    if dropDown:IsShown() and dropDown.title:GetText() == "Select Texture" then dropDown:Hide() else
        OpenDropDown("statusbar", OdysseusDB.flightSettings.textureName, function(name)
            OdysseusDB.flightSettings.textureName = name
            self:SetText(string.sub(name, 1, 14)) 
            OUS.ApplyFlightTexture()
        end)
    end
end)

local fontBtn = CreateLabeledButton(tabs.FlightMaster, "Font:", 20, -165, "Loading...", 105, function(self)
    if dropDown:IsShown() and dropDown.title:GetText() == "Select Font" then dropDown:Hide() else
        OpenDropDown("font", OdysseusDB.flightSettings.fontName, function(name)
            OdysseusDB.flightSettings.fontName = name
            self:SetText(string.sub(name, 1, 14))
            OUS.ApplyFlightFonts()
        end)
    end
end)

local borderBtn = CreateLabeledButton(tabs.FlightMaster, "Border:", 20, -200, "Loading...", 105, function(self)
    if dropDown:IsShown() and dropDown.title:GetText() == "Select Border" then dropDown:Hide() else
        OpenDropDown("border", OdysseusDB.flightSettings.borderName, function(name)
            OdysseusDB.flightSettings.borderName = name
            self:SetText(string.sub(name, 1, 14))
            OUS.ApplyFlightBorder()
        end)
    end
end)

local tooltipCB = CreateFrame("CheckButton", "OdysseusTooltipCheckButton", tabs.FlightMaster, "ChatConfigCheckButtonTemplate")
tooltipCB:SetPoint("TOPLEFT", 15, -235)
_G[tooltipCB:GetName().."Text"]:SetText(" Show Map Tooltips")
tooltipCB:SetScript("OnClick", function(self)
    OdysseusDB.flightSettings.showTooltips = self:GetChecked()
end)

local expBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
expBtn:SetSize(160, 25)
expBtn:SetPoint("TOPLEFT", 20, -280)
expBtn:SetText("Export Flight Data")
expBtn:SetScript("OnClick", function()
    local t = "-- Exported on " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
    local hasData = false
    if OdysseusDB.flightSettings.times then
        for startNode, dests in pairs(OdysseusDB.flightSettings.times) do
            if type(dests) == "table" then
                t = t .. "    [\"" .. startNode .. "\"] = {\n"
                for destNode, time in pairs(dests) do
                    t = t .. "        [\"" .. destNode .. "\"] = " .. time .. ",\n"
                    hasData = true
                end
                t = t .. "    },\n"
            end
        end
    end
    if not hasData then
        exportEditBox:SetText("-- No new flights to export yet!\n-- Your database is empty.")
    else
        exportEditBox:SetText(t)
    end
    exportFrame:Show()
end)

local wipeBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
wipeBtn:SetSize(160, 25)
wipeBtn:SetPoint("TOPLEFT", 20, -310)
wipeBtn:SetText("Wipe Saved Data")
wipeBtn:SetScript("OnClick", function()
    StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE")
end)

-- RIGHT COLUMN (Sliders)
local widthSlider, widthBox = CreateSliderControl(tabs.FlightMaster, "Bar Width:", 185, -55, 50, 600, 10, function(val)
    OdysseusDB.flightSettings.width = val; OUS.timerBar:SetWidth(val)
end)

local heightSlider, heightBox = CreateSliderControl(tabs.FlightMaster, "Bar Height:", 185, -110, 5, 100, 1, function(val)
    OdysseusDB.flightSettings.height = val; OUS.timerBar:SetHeight(val)
end)

local scaleSlider, scaleBox = CreateSliderControl(tabs.FlightMaster, "Bar Scale:", 185, -165, 0.5, 3.0, 0.1, function(val)
    OdysseusDB.flightSettings.scale = val; OUS.timerBar:SetScale(val)
end)

local fontSlider, fontBox = CreateSliderControl(tabs.FlightMaster, "Font Size:", 185, -220, 6, 40, 1, function(val)
    OdysseusDB.flightSettings.fontSize = val; OUS.ApplyFlightFonts()
end)

local borderSlider, borderBox = CreateSliderControl(tabs.FlightMaster, "Border Size:", 185, -275, 0, 50, 1, function(val)
    OdysseusDB.flightSettings.borderSize = val; OUS.ApplyFlightBorder()
end)

tabs.FlightMaster:SetScript("OnShow", function()
    fontBtn:SetText(string.sub(OdysseusDB.flightSettings.fontName or "Friz Quadrata TT", 1, 14))
    texBtn:SetText(string.sub(OdysseusDB.flightSettings.textureName or "Blizzard", 1, 14))
    borderBtn:SetText(string.sub(OdysseusDB.flightSettings.borderName or "None", 1, 14))
    
    fontSlider:SetValue(OdysseusDB.flightSettings.fontSize or 12)
    fontBox:SetText(OdysseusDB.flightSettings.fontSize or 12)
    
    widthSlider:SetValue(OdysseusDB.flightSettings.width or 200)
    widthBox:SetText(OdysseusDB.flightSettings.width or 200)
    
    heightSlider:SetValue(OdysseusDB.flightSettings.height or 20)
    heightBox:SetText(OdysseusDB.flightSettings.height or 20)
    
    scaleSlider:SetValue(OdysseusDB.flightSettings.scale or 1.0)
    scaleBox:SetText(OdysseusDB.flightSettings.scale or 1.0)
    
    borderSlider:SetValue(OdysseusDB.flightSettings.borderSize or 16)
    borderBox:SetText(OdysseusDB.flightSettings.borderSize or 16)
    
    tooltipCB:SetChecked(OdysseusDB.flightSettings.showTooltips or false)
end)


-- =====================================
-- TAB 3: FASTER LOOT
-- =====================================
local lootTitle = tabs.FasterLoot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
lootTitle:SetPoint("TOPLEFT", 20, -20)
lootTitle:SetText("Faster Loot")

local lootDesc = tabs.FasterLoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lootDesc:SetPoint("TOPLEFT", 20, -50)
lootDesc:SetWidth(330)
lootDesc:SetJustifyH("LEFT")
lootDesc:SetText("Faster Loot operates silently in the background.\n\nIt dynamically reads your Auto-Loot settings and Shift-Click modifiers. When triggered, it loots items directly from memory, bypassing the Blizzard UI rendering delay.")
lootDesc:SetTextColor(0.8, 0.8, 0.8)

-- =====================================
-- TAB 4: FISHING TRACKER
-- =====================================
local fishTitle = tabs.Fishing:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
fishTitle:SetPoint("TOPLEFT", 20, -20)
fishTitle:SetText("Fishing Tracker Settings")

local function CreateFishingToggle(parent, label, yOffset, dbKey)
    local frameName = "OdysseusFishingToggle_" .. dbKey
    local cb = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    _G[cb:GetName().."Text"]:SetText(label)
    
    cb:SetScript("OnShow", function(self)
        if OdysseusDB and OdysseusDB.fishingSettings then
            self:SetChecked(OdysseusDB.fishingSettings[dbKey])
        end
    end)
    
    cb:SetScript("OnClick", function(self)
        OdysseusDB.fishingSettings[dbKey] = self:GetChecked()
    end)
end

CreateFishingToggle(tabs.Fishing, " Auto-close when not fishing or AFK", -60, "autoCloseInactive")
CreateFishingToggle(tabs.Fishing, " Auto-close when mounted/skyriding", -95, "autoCloseMounted")

local delaySlider, delayBox = CreateSliderControl(tabs.Fishing, "Auto-close Delay (sec):", 25, -145, 10, 60, 1, function(val)
    if OdysseusDB and OdysseusDB.fishingSettings then
        OdysseusDB.fishingSettings.autoCloseDelay = val
    end
end)

-- NEW: Alpha Transparency Slider (0.1 to 1.0)
local alphaSlider, alphaBox = CreateSliderControl(tabs.Fishing, "Frame Transparency:", 25, -200, 0.1, 1.0, 0.05, function(val)
    if OdysseusDB and OdysseusDB.fishingSettings then
        OdysseusDB.fishingSettings.alpha = val
        if OUS.UpdateFishingAlpha then
            OUS.UpdateFishingAlpha()
        end
    end
end)

local wipeFishBtn = CreateFrame("Button", nil, tabs.Fishing, "UIPanelButtonTemplate")
wipeFishBtn:SetSize(160, 25)
wipeFishBtn:SetPoint("TOPLEFT", 20, -265)
wipeFishBtn:SetText("Wipe Saved Data")
wipeFishBtn:SetScript("OnClick", function()
    StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_FISHING")
end)

tabs.Fishing:SetScript("OnShow", function()
    if OdysseusDB and OdysseusDB.fishingSettings then
        local delay = OdysseusDB.fishingSettings.autoCloseDelay or 30
        delaySlider:SetValue(delay)
        delayBox:SetText(delay)
        
        local alpha = OdysseusDB.fishingSettings.alpha or 1.0
        alphaSlider:SetValue(alpha)
        alphaBox:SetText(alpha)
    end
end)

-- Hide Dropdown if config is closed
cfg:SetScript("OnHide", function() dropDown:Hide() end)

-- Show default tab
ShowTab("General")