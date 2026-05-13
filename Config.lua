local addonName, OUS = ...
local LSM = LibStub("LibSharedMedia-3.0")

local cfg = CreateFrame("Frame", "OdysseusConfigFrame", UIParent, "BackdropTemplate")
cfg:SetSize(650, 620)
cfg:SetPoint("CENTER")
cfg:SetFrameStrata("DIALOG")
cfg:Hide()
cfg:SetMovable(true)
cfg:SetClampedToScreen(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop", cfg.StopMovingOrSizing)
tinsert(UISpecialFrames, cfg:GetName())
OUS.ConfigFrame = cfg

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

local navPanel = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
navPanel:SetSize(150, 570)
navPanel:SetPoint("TOPLEFT", cfg, "TOPLEFT", 4, -34)
navPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
navPanel:SetBackdropColor(0.05, 0.05, 0.07, 0.78)
navPanel:SetBackdropBorderColor(0.24, 0.22, 0.30, 0.95)

navPanel.topSheen = navPanel:CreateTexture(nil, "ARTWORK")
navPanel.topSheen:SetPoint("TOPLEFT", 1, -1)
navPanel.topSheen:SetPoint("TOPRIGHT", -1, -1)
navPanel.topSheen:SetHeight(24)
navPanel.topSheen:SetTexture("Interface\\Buttons\\WHITE8x8")
navPanel.topSheen:SetGradient("VERTICAL",
    CreateColor(0.90, 0.90, 0.96, 0.05),
    CreateColor(0.55, 0.55, 0.62, 0.01)
)

navPanel.sideShade = navPanel:CreateTexture(nil, "ARTWORK")
navPanel.sideShade:SetPoint("TOPRIGHT", -1, -1)
navPanel.sideShade:SetPoint("BOTTOMRIGHT", -1, 1)
navPanel.sideShade:SetWidth(10)
navPanel.sideShade:SetTexture("Interface\\Buttons\\WHITE8x8")
navPanel.sideShade:SetGradient("HORIZONTAL",
    CreateColor(0.00, 0.00, 0.00, 0.00),
    CreateColor(0.00, 0.00, 0.00, 0.16)
)

local contentPanel = CreateFrame("Frame", nil, cfg, "BackdropTemplate")
contentPanel:SetSize(480, 570)
contentPanel:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 0, 0)
contentPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
contentPanel:SetBackdropColor(0.07, 0.05, 0.10, 0.18)
contentPanel:SetBackdropBorderColor(0.20, 0.14, 0.28, 0.35)

-- =====================================
-- SHARED WIDGET FACTORIES
-- =====================================
local sliderCounter = 1
function OUS.CreatePremiumSlider(parent, db, titleText, yOffset, dbKey, minVal, maxVal, step, onUpdate)
    local sliderName = "OdysseusPremiumSlider" .. sliderCounter
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
    editBg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }})
    editBg:SetBackdropColor(0.03, 0.02, 0.05, 0.8)

    local editBox = CreateFrame("EditBox", nil, editBg)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetPoint("TOPLEFT", 4, -2)
    editBox:SetPoint("BOTTOMRIGHT", -4, 2)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")

    local initVal = db[dbKey] or minVal
    slider:SetValue(initVal)
    editBox:SetText(tostring(initVal))

    btnMinus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() - step) end)
    btnPlus:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + step) end)

    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(tostring(slider:GetValue())) end)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local val = tonumber(self:GetText())
        if val then val = math.max(minVal, math.min(maxVal, val)); slider:SetValue(val) else self:SetText(tostring(slider:GetValue())) end
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        local snappedValue
        if step < 1 then snappedValue = math.floor(value * 100 + 0.5) / 100 else snappedValue = math.floor(value + 0.5) end
        db[dbKey] = snappedValue
        if step < 1 then
            editBox:SetText(string.format("%.2f", snappedValue):gsub("0+$", ""):gsub("%.$", ""))
        else
            editBox:SetText(tostring(snappedValue))
        end
        if onUpdate then onUpdate() end
    end)
    return slider, editBox
end

function OUS.OpenColorPicker(dbColor, colorBoxFrame, onUpdateFunc)
    local onUpdate = onUpdateFunc or function() end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = dbColor.r, g = dbColor.g, b = dbColor.b,
        hasOpacity = false,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            dbColor.r, dbColor.g, dbColor.b = r, g, b
            colorBoxFrame:SetBackdropColor(r, g, b, 1)
            onUpdate()
        end,
        cancelFunc = function(previousValues)
            dbColor.r, dbColor.g, dbColor.b = previousValues.r, previousValues.g, previousValues.b
            colorBoxFrame:SetBackdropColor(previousValues.r, previousValues.g, previousValues.b, 1)
            onUpdate()
        end
    })
end

function OUS.CreateColorBox(parent, labelText, xOffset, yOffset, colorTableRef, onUpdateFunc)
    local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
    box:SetSize(20, 20)
    box:SetPoint("TOPLEFT", xOffset, yOffset)
    box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    box:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    text:SetText(labelText)

    box:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end)
    box:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) end)
    box:SetScript("OnClick", function(self) OUS.OpenColorPicker(colorTableRef, self, onUpdateFunc) end)

    box:SetBackdropColor(colorTableRef.r, colorTableRef.g, colorTableRef.b, 1)
    return box
end

local tabs = {}
tabs.General = CreateFrame("Frame", nil, contentPanel)
tabs.FlightMaster = CreateFrame("Frame", nil, contentPanel)
tabs.FasterLoot = CreateFrame("Frame", nil, contentPanel)
tabs.Fishing = CreateFrame("Frame", nil, contentPanel)
tabs.XPBar = CreateFrame("Frame", nil, contentPanel)
tabs.AutoRemount = CreateFrame("Frame", nil, contentPanel)
tabs.StatsBar = CreateFrame("Frame", nil, contentPanel)
tabs.Openables = CreateFrame("Frame", nil, contentPanel)

OUS.XPBarTab = tabs.XPBar

for _, tab in pairs(tabs) do
    tab:SetAllPoints()
    tab:Hide()
end

local navButtons = {}
local currentNavTab = nil

local function SetMidnightNavButtonState(btn, isActive)
    if not btn then return end

    if isActive then
        btn:SetBackdropColor(0.12, 0.12, 0.15, 0.97)
        btn:SetBackdropBorderColor(0.62, 0.60, 0.68, 1)

        btn.base:SetColorTexture(0.18, 0.18, 0.22, 0.96)
        btn.accent:SetColorTexture(0.84, 0.80, 0.92, 1)
        btn.accent:Show()

        btn.text:SetTextColor(1.0, 0.97, 0.92)

        btn.topSheen:SetAlpha(0.22)
        btn.bottomShade:SetAlpha(0.28)
        btn.innerGlow:Show()
    else
        btn:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
        btn:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)

        btn.base:SetColorTexture(0.13, 0.13, 0.16, 0.94)
        btn.accent:SetColorTexture(0.58, 0.58, 0.66, 0.90)
        btn.accent:Hide()

        btn.text:SetTextColor(0.82, 0.82, 0.88)

        btn.topSheen:SetAlpha(0.12)
        btn.bottomShade:SetAlpha(0.20)
        btn.innerGlow:Hide()
    end
end

local function RefreshNavButtonStates(selectedTabName)
    currentNavTab = selectedTabName

    for _, btn in ipairs(navButtons) do
        SetMidnightNavButtonState(btn, btn.targetTab == selectedTabName)
    end
end

local function ShowTab(tabName)
    for k, tab in pairs(tabs) do
        if k == tabName then
            tab:Show()
        else
            tab:Hide()
        end
    end

    currentNavTab = tabName
    RefreshNavButtonStates(tabName)
end

local function CreateNavButton(label, yOffset, targetTab)
    local btn = CreateFrame("Button", nil, navPanel, "BackdropTemplate")
    btn:SetSize(138, 32)
    btn:SetPoint("TOP", navPanel, "TOP", 0, yOffset)
    btn.targetTab = targetTab

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    btn.base = btn:CreateTexture(nil, "BACKGROUND")
    btn.base:SetPoint("TOPLEFT", 1, -1)
    btn.base:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.base:SetColorTexture(0.13, 0.13, 0.16, 0.94)

    btn.topSheen = btn:CreateTexture(nil, "ARTWORK")
    btn.topSheen:SetPoint("TOPLEFT", 1, -1)
    btn.topSheen:SetPoint("TOPRIGHT", -1, -1)
    btn.topSheen:SetHeight(11)
    btn.topSheen:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.topSheen:SetGradient("VERTICAL",
        CreateColor(0.90, 0.90, 0.96, 0.14),
        CreateColor(0.55, 0.55, 0.62, 0.02)
    )

    btn.bottomShade = btn:CreateTexture(nil, "ARTWORK")
    btn.bottomShade:SetPoint("BOTTOMLEFT", 1, 1)
    btn.bottomShade:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bottomShade:SetHeight(10)
    btn.bottomShade:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.bottomShade:SetGradient("VERTICAL",
        CreateColor(0.00, 0.00, 0.00, 0.02),
        CreateColor(0.00, 0.00, 0.00, 0.22)
    )

    btn.innerGlow = btn:CreateTexture(nil, "OVERLAY")
    btn.innerGlow:SetPoint("TOPLEFT", 2, -2)
    btn.innerGlow:SetPoint("BOTTOMRIGHT", -2, 2)
    btn.innerGlow:SetColorTexture(0.84, 0.80, 0.92, 0.05)
    btn.innerGlow:Hide()

    btn.accent = btn:CreateTexture(nil, "ARTWORK")
    btn.accent:SetPoint("TOPLEFT", 1, -1)
    btn.accent:SetPoint("BOTTOMLEFT", 1, 1)
    btn.accent:SetWidth(4)
    btn.accent:Hide()

    btn.topLine = btn:CreateTexture(nil, "OVERLAY")
    btn.topLine:SetPoint("TOPLEFT", 2, -2)
    btn.topLine:SetPoint("TOPRIGHT", -2, -2)
    btn.topLine:SetHeight(1)
    btn.topLine:SetColorTexture(1, 1, 1, 0.06)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.text:SetPoint("CENTER")
    btn.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    btn.text:SetText(label)

    btn:SetScript("OnEnter", function(self)
        if currentNavTab == self.targetTab then
            return
        end

        self:SetBackdropColor(0.11, 0.11, 0.14, 0.98)
        self:SetBackdropBorderColor(0.48, 0.48, 0.56, 1)
        self.base:SetColorTexture(0.16, 0.16, 0.20, 0.96)
        self.text:SetTextColor(0.96, 0.94, 0.98)
        self.accent:SetColorTexture(0.72, 0.72, 0.80, 0.95)
        self.accent:Show()
        self.innerGlow:Show()
        self.topSheen:SetAlpha(0.18)
    end)

    btn:SetScript("OnLeave", function(self)
        RefreshNavButtonStates(currentNavTab)
    end)

    btn:SetScript("OnMouseDown", function(self)
        if currentNavTab == self.targetTab then
            return
        end

        self:SetBackdropColor(0.07, 0.07, 0.09, 0.99)
        self:SetBackdropBorderColor(0.40, 0.40, 0.48, 1)
        self.base:SetColorTexture(0.11, 0.11, 0.14, 0.98)
    end)

    btn:SetScript("OnMouseUp", function(self)
        RefreshNavButtonStates(currentNavTab)
    end)

    btn:SetScript("OnClick", function(self)
        ShowTab(self.targetTab)
    end)

    SetMidnightNavButtonState(btn, false)
    table.insert(navButtons, btn)

    return btn
end

local function CreateContentHeader(parent, yOffset, titleText)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(448, 30)
    header:SetPoint("TOPLEFT", 12, yOffset)

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetPoint("TOPLEFT")
    header.bg:SetPoint("TOPRIGHT")
    header.bg:SetHeight(28)
    header.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    header.bg:SetGradient("HORIZONTAL",
        CreateColor(0.18, 0.08, 0.28, 0.92),
        CreateColor(0.09, 0.05, 0.14, 0.92)
    )

    header.bottomLine = header:CreateTexture(nil, "ARTWORK")
    header.bottomLine:SetPoint("BOTTOMLEFT", 0, 0)
    header.bottomLine:SetPoint("BOTTOMRIGHT", 0, 0)
    header.bottomLine:SetHeight(1)
    header.bottomLine:SetColorTexture(0.56, 0.38, 0.78, 0.65)

    header.topLine = header:CreateTexture(nil, "OVERLAY")
    header.topLine:SetPoint("TOPLEFT", 0, 0)
    header.topLine:SetPoint("TOPRIGHT", 0, 0)
    header.topLine:SetHeight(1)
    header.topLine:SetColorTexture(1, 1, 1, 0.06)

    header.title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header.title:SetPoint("LEFT", 10, 0)
    header.title:SetText(titleText)
    header.title:SetTextColor(0.95, 0.90, 1.0)

    return header
end

CreateNavButton("General", -10, "General")
CreateNavButton("Flight Master", -45, "FlightMaster")
CreateNavButton("Faster Loot", -80, "FasterLoot")
CreateNavButton("Fishing Tracker", -115, "Fishing")
CreateNavButton("Exp & Rep Bar", -150, "XPBar")
CreateNavButton("Auto Remount", -185, "AutoRemount")
CreateNavButton("Stats Bar", -220, "StatsBar")
CreateNavButton("Openables", -255, "Openables")

StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE_ALL"] = {
    text = "Are you sure you want to reset ALL Odysseus settings to their defaults? This will require a UI reload and cannot be undone.",
    button1 = "Yes, Reset Everything",
    button2 = "Cancel",
    OnAccept = function()
        if OUS.ResetAllSettings then
            OUS.ResetAllSettings()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE"] = {
    text = "Are you sure you want to wipe ALL recorded flight times? This cannot be undone.",
    button1 = "Yes, Wipe",
    button2 = "Cancel",
    OnAccept = function()
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
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
        if OdysseusFishingDB then
            OdysseusFishingDB.history = {}
            print("|cFF00CCFFOdysseus:|r All recorded fishing history |cFFFF0000wiped|r!")
            if OUS.UpdateFishingUI then OUS.UpdateFishingUI() end
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
exportFrame:SetFrameStrata("FULLSCREEN_DIALOG")
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

local dropDown = CreateFrame("Frame", "OdysseusMediaDropDown", cfg, "BackdropTemplate")
dropDown:SetSize(220, 350)
dropDown:SetPoint("TOPLEFT", cfg, "TOPRIGHT", 5, 0)
dropDown:Hide()
dropDown:SetFrameStrata("FULLSCREEN_DIALOG")

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

-- THE FIX: Exported globally to OUS and added intelligent toggling!
function OUS.OpenDropDown(mediaType, currentName, onSelect)
    local expectedTitle = "Select " .. (mediaType == "font" and "Font" or (mediaType == "statusbar" and "Texture" or "Border"))

    if dropDown:IsShown() and dropDown.title:GetText() == expectedTitle then
        dropDown:Hide()
        return
    end

    dropDown:Show()
    dropDown.title:SetText(expectedTitle)
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

-- =====================================
-- TAB 1: GENERAL (Module Toggles)
-- =====================================
-- Logo image
local genLogo = tabs.General:CreateTexture(nil, "ARTWORK")
genLogo:SetSize(360, 180)
genLogo:SetPoint("TOP", tabs.General, "TOP", 0, -10)
genLogo:SetTexture("Interface\\AddOns\\OdysseusUtilitySuite\\Media\\icon\\OUS_banner")

-- Title next to logo
local genTitle = tabs.General:CreateFontString(nil, "OVERLAY")
genTitle:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
genTitle:SetPoint("TOP", genLogo, "BOTTOM", 0, -8)
genTitle:SetText("|cFF00FFFFOdysseus|r |cFFAA88FFUtility Suite|r")

-- Subtitle
local genSubTitle = tabs.General:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
genSubTitle:SetPoint("TOP", genTitle, "BOTTOM", 0, -4)
genSubTitle:SetTextColor(0.6, 0.6, 0.6)
genSubTitle:SetText("Modular Quality-of-Life Suite for WoW Retail 12.0+")

-- Separator line
local genSep = tabs.General:CreateTexture(nil, "ARTWORK")
genSep:SetHeight(1)
genSep:SetPoint("TOPLEFT", 10, -245)
genSep:SetPoint("TOPRIGHT", -10, -245)
genSep:SetColorTexture(0.4, 0.2, 0.6, 0.8)

-- Section header below separator
local genHeader = tabs.General:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
genHeader:SetPoint("TOPLEFT", 20, -258)
genHeader:SetTextColor(0.7, 0.5, 1)
genHeader:SetText("MODULE TOGGLES")

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

        if dbKey == "xpBar" then
            if self:GetChecked() then
                if OUS.xpBarFrame then OUS.xpBarFrame:Show() end
                if OUS.UpdateBar then OUS.UpdateBar() end
            else
                if OUS.xpBarFrame then OUS.xpBarFrame:Hide() end
                if OUS.delveBarFrame then OUS.delveBarFrame:Hide() end
                if OUS.favHoverFrame then OUS.favHoverFrame:Hide() end
            end
        end
        if dbKey == "statsBar" then
            if OUS.StatsBar then
                OUS.StatsBar.UpdateDisplay()
                OUS.StatsBar.UpdateTable()
            end
        end
        if dbKey == "openables" then
            if OUS.Openables then
                OUS.Openables.UpdateDisplay()
            end
        end
    end)
end

CreateModuleToggle(tabs.General, " Enable Flight Master", -270, "flightMaster")
CreateModuleToggle(tabs.General, " Enable Faster Loot", -305, "fasterLoot")
CreateModuleToggle(tabs.General, " Enable Fishing Tracker", -340, "fishingTracker")
CreateModuleToggle(tabs.General, " Enable Exp & Rep Bar", -375, "xpBar")
CreateModuleToggle(tabs.General, " Enable Stats Bar", -410, "statsBar")
CreateModuleToggle(tabs.General, " Enable Openables", -445, "openables")

local resetAllBtn = CreateFrame("Button", nil, tabs.General, "UIPanelButtonTemplate")
resetAllBtn:SetSize(180, 28)
resetAllBtn:SetPoint("BOTTOM", 0, 20)
resetAllBtn:SetText("Reset All Settings")
resetAllBtn:SetScript("OnClick", function()
    StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_ALL")
end)

local resetTitle = tabs.General:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
resetTitle:SetPoint("BOTTOM", resetAllBtn, "TOP", 0, 15)
resetTitle:SetText("Master Reset")

local resetDesc = tabs.General:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resetDesc:SetPoint("BOTTOM", resetTitle, "TOP", 0, 5)
resetDesc:SetWidth(400)
resetDesc:SetJustifyH("CENTER")
resetDesc:SetText("This will restore |cFFFF0000ALL|r settings for |cFFFF0000ALL|r Odysseus modules to their original defaults and reload the UI. Use with caution.")

-- =====================================
-- TAB 2: FLIGHT MASTER (Two-Column Layout)
-- =====================================
local function EscapeLuaString(text)
    return tostring(text):gsub("\\", "\\\\"):gsub("\"", "\\\"")
end

local fmWidgetsCreated = false
local lockBtn, texBtn, fontBtn, borderBtn, colorBox, tooltipCB, expBtn, wipeBtn
local widthSlider, widthBox, heightSlider, heightBox, scaleSlider, scaleBox, fontSlider, fontBox, borderSlider, borderBox

local function CreateFlightMasterWidgets()
    if fmWidgetsCreated then return end

    local fmHeader = CreateContentHeader(tabs.FlightMaster, -15, "Flight Master Settings")

    lockBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    lockBtn:SetSize(180, 25)
    lockBtn:SetPoint("TOPLEFT", 12, -45)
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

    local texLbl = tabs.FlightMaster:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    texLbl:SetPoint("TOPLEFT", 12, -80)
    texLbl:SetText("Bar Texture:")
    texBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    texBtn:SetSize(200, 24)
    texBtn:SetPoint("TOPLEFT", texLbl, "BOTTOMLEFT", 0, -4)
    texBtn:SetScript("OnClick", function(self)
        OUS.OpenDropDown("statusbar", OdysseusDB.flightSettings.textureName, function(name)
            OdysseusDB.flightSettings.textureName = name
            self:SetText(string.sub(name, 1, 25))
            OUS.ApplyFlightTexture()
        end)
    end)

    local fontLbl = tabs.FlightMaster:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontLbl:SetPoint("TOPLEFT", 12, -130)
    fontLbl:SetText("Bar Font:")
    fontBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    fontBtn:SetSize(200, 24)
    fontBtn:SetPoint("TOPLEFT", fontLbl, "BOTTOMLEFT", 0, -4)
    fontBtn:SetScript("OnClick", function(self)
        OUS.OpenDropDown("font", OdysseusDB.flightSettings.fontName, function(name)
            OdysseusDB.flightSettings.fontName = name
            self:SetText(string.sub(name, 1, 25))
            OUS.ApplyFlightFonts()
        end)
    end)

    local borderLbl = tabs.FlightMaster:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    borderLbl:SetPoint("TOPLEFT", 12, -180)
    borderLbl:SetText("Bar Border:")
    borderBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    borderBtn:SetSize(200, 24)
    borderBtn:SetPoint("TOPLEFT", borderLbl, "BOTTOMLEFT", 0, -4)
    borderBtn:SetScript("OnClick", function(self)
        OUS.OpenDropDown("border", OdysseusDB.flightSettings.borderName, function(name)
            OdysseusDB.flightSettings.borderName = name
            self:SetText(string.sub(name, 1, 25))
            OUS.ApplyFlightBorder()
        end)
    end)

    colorBox = OUS.CreateColorBox(tabs.FlightMaster, "Bar Color", 230, -100, OdysseusDB.flightSettings.color, function()
        local c = OdysseusDB.flightSettings.color
        OUS.timerBar:SetStatusBarColor(c.r, c.g, c.b)
    end)

    tooltipCB = CreateFrame("CheckButton", "OdysseusTooltipCheckButton", tabs.FlightMaster, "ChatConfigCheckButtonTemplate")
    tooltipCB:SetPoint("BOTTOMLEFT", 12, 70)
    _G[tooltipCB:GetName().."Text"]:SetText(" Show Map Tooltips")
    tooltipCB:SetScript("OnClick", function(self)
        OdysseusDB.flightSettings.showTooltips = self:GetChecked()
    end)

    expBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    expBtn:SetSize(120, 24)
    expBtn:SetPoint("BOTTOMLEFT", 12, 40)
    expBtn:SetText("Export Flight Data")
    expBtn:SetScript("OnClick", function()
        local flightSettings = OdysseusDB and OdysseusDB.flightSettings
        local times = flightSettings and flightSettings.times

        local t = "-- Exported on " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
        local hasData = false

        if type(times) == "table" then
            local startNodes = {}
            for startNode, dests in pairs(times) do
                if type(dests) == "table" then
                    table.insert(startNodes, startNode)
                end
            end
            table.sort(startNodes)

            for _, startNode in ipairs(startNodes) do
                local dests = times[startNode]
                local destNodes = {}

                for destNode, time in pairs(dests) do
                    if type(time) == "number" then
                        table.insert(destNodes, destNode)
                    end
                end

                if #destNodes > 0 then
                    table.sort(destNodes)
                    t = t .. "    [\"" .. EscapeLuaString(startNode) .. "\"] = {\n"

                    for _, destNode in ipairs(destNodes) do
                        local time = dests[destNode]
                        t = t .. "        [\"" .. EscapeLuaString(destNode) .. "\"] = " .. time .. ",\n"
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

    wipeBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    wipeBtn:SetSize(120, 24)
    wipeBtn:SetPoint("LEFT", expBtn, "RIGHT", 10, 0)
    wipeBtn:SetText("Wipe Saved Data")
    wipeBtn:SetScript("OnClick", function() StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE") end)

    widthSlider, widthBox = OUS.CreatePremiumSlider(tabs.FlightMaster, OdysseusDB.flightSettings, "Bar Width", -230, "width", 50, 600, 10, function() OUS.timerBar:SetWidth(OdysseusDB.flightSettings.width) end)
    heightSlider, heightBox = OUS.CreatePremiumSlider(tabs.FlightMaster, OdysseusDB.flightSettings, "Bar Height", -280, "height", 5, 100, 1, function() OUS.timerBar:SetHeight(OdysseusDB.flightSettings.height) end)
    scaleSlider, scaleBox = OUS.CreatePremiumSlider(tabs.FlightMaster, OdysseusDB.flightSettings, "Bar Scale", -330, "scale", 0.5, 3.0, 0.05, function() OUS.timerBar:SetScale(OdysseusDB.flightSettings.scale) end)
    fontSlider, fontBox = OUS.CreatePremiumSlider(tabs.FlightMaster, OdysseusDB.flightSettings, "Font Size", -380, "fontSize", 6, 40, 1, OUS.ApplyFlightFonts)
    borderSlider, borderBox = OUS.CreatePremiumSlider(tabs.FlightMaster, OdysseusDB.flightSettings, "Border Size", -430, "borderSize", 0, 50, 1, OUS.ApplyFlightBorder)

    local resetBtn = CreateFrame("Button", nil, tabs.FlightMaster, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        if not OUS.flightDefaults then return end

        for k, v in pairs(OUS.flightDefaults) do
            if type(v) == "table" then
                OdysseusDB.flightSettings[k] = OUS.DeepCopyTable(v)
            else
                OdysseusDB.flightSettings[k] = v
            end
        end

        if widthSlider then widthSlider:SetValue(OUS.flightDefaults.width); widthBox:SetText(OUS.flightDefaults.width) end
        if heightSlider then heightSlider:SetValue(OUS.flightDefaults.height); heightBox:SetText(OUS.flightDefaults.height) end
        if scaleSlider then scaleSlider:SetValue(OUS.flightDefaults.scale); scaleBox:SetText(OUS.flightDefaults.scale) end
        if fontSlider then fontSlider:SetValue(OUS.flightDefaults.fontSize); fontBox:SetText(OUS.flightDefaults.fontSize) end
        if borderSlider then borderSlider:SetValue(OUS.flightDefaults.borderSize); borderBox:SetText(OUS.flightDefaults.borderSize) end

        if texBtn then texBtn:SetText(string.sub(OUS.flightDefaults.textureName, 1, 25)) end
        if fontBtn then fontBtn:SetText(string.sub(OUS.flightDefaults.fontName, 1, 25)) end
        if borderBtn then borderBtn:SetText(string.sub(OUS.flightDefaults.borderName, 1, 25)) end
        if tooltipCB then tooltipCB:SetChecked(OUS.flightDefaults.showTooltips) end

        if colorBox and OUS.flightDefaults.color then
            local c = OUS.flightDefaults.color
            colorBox:SetBackdropColor(c.r, c.g, c.b, 1)
        end

        OUS.timerBar:SetWidth(OUS.flightDefaults.width)
        OUS.timerBar:SetHeight(OUS.flightDefaults.height)
        OUS.timerBar:SetScale(OUS.flightDefaults.scale)
        OUS.ApplyFlightTexture()
        OUS.ApplyFlightFonts()
        OUS.ApplyFlightBorder()
        local c = OUS.flightDefaults.color
        OUS.timerBar:SetStatusBarColor(c.r, c.g, c.b)
        if OUS.LogDebug then
            OUS.LogDebug("Flight", "Flight Master settings restored to default.")
        end
    end)

    fmWidgetsCreated = true
end

tabs.FlightMaster:SetScript("OnShow", function()
    CreateFlightMasterWidgets()

    if fontBtn then fontBtn:SetText(string.sub(OdysseusDB.flightSettings.fontName or "Friz Quadrata TT", 1, 25)) end
    if texBtn then texBtn:SetText(string.sub(OdysseusDB.flightSettings.textureName or "Blizzard", 1, 25)) end
    if borderBtn then borderBtn:SetText(string.sub(OdysseusDB.flightSettings.borderName or "None", 1, 25)) end

    if fontSlider then fontSlider:SetValue(OdysseusDB.flightSettings.fontSize or 12) end
    if fontBox then fontBox:SetText(OdysseusDB.flightSettings.fontSize or 12) end
    if widthSlider then widthSlider:SetValue(OdysseusDB.flightSettings.width or 200) end
    if widthBox then widthBox:SetText(OdysseusDB.flightSettings.width or 200) end
    if heightSlider then heightSlider:SetValue(OdysseusDB.flightSettings.height or 20) end
    if heightBox then heightBox:SetText(OdysseusDB.flightSettings.height or 20) end
    if scaleSlider then scaleSlider:SetValue(OdysseusDB.flightSettings.scale or 1.0) end
    if scaleBox then scaleBox:SetText(OdysseusDB.flightSettings.scale or 1.0) end
    if borderSlider then borderSlider:SetValue(OdysseusDB.flightSettings.borderSize or 16) end
    if borderBox then borderBox:SetText(OdysseusDB.flightSettings.borderSize or 16) end
    if tooltipCB then tooltipCB:SetChecked(OdysseusDB.flightSettings.showTooltips or false) end
    if colorBox and OdysseusDB.flightSettings.color then
        local c = OdysseusDB.flightSettings.color
        colorBox:SetBackdropColor(c.r, c.g, c.b, 1)
    end
end)

-- =====================================
-- TAB 3: FASTER LOOT
-- =====================================
local lootHeader = CreateContentHeader(tabs.FasterLoot, -15, "Faster Loot")

local lootDesc = tabs.FasterLoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lootDesc:SetPoint("TOPLEFT", 20, -58)
lootDesc:SetWidth(420)
lootDesc:SetJustifyH("LEFT")
lootDesc:SetText("Faster Loot operates silently in the background.\n\nIt dynamically reads your Auto-Loot settings and Shift-Click modifiers. When triggered, it loots items directly from memory, bypassing the Blizzard UI rendering delay.")
lootDesc:SetTextColor(0.8, 0.8, 0.8)

-- =====================================
-- TAB 4: FISHING TRACKER
-- =====================================
local fishWidgetsCreated = false
local delaySlider, delayBox, alphaSlider, alphaBox

local function CreateFishingWidgets()
    if fishWidgetsCreated then return end

    local fishHeader = CreateContentHeader(tabs.Fishing, -15, "Fishing Tracker Settings")

    local function CreateFishingToggle(parent, label, yOffset, dbKey)
        local frameName = "OdysseusFishingToggle_" .. dbKey
        local cb = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetScript("OnShow", function(self) if OdysseusDB and OdysseusDB.fishingSettings then self:SetChecked(OdysseusDB.fishingSettings[dbKey]) end end)
        cb:SetScript("OnClick", function(self) OdysseusDB.fishingSettings[dbKey] = self:GetChecked() end)
    end

    CreateFishingToggle(tabs.Fishing, " Auto-close when not fishing or AFK", -50, "autoCloseInactive")
    CreateFishingToggle(tabs.Fishing, " Auto-close when mounted/skyriding", -80, "autoCloseMounted")

    delaySlider, delayBox = OUS.CreatePremiumSlider(tabs.Fishing, OdysseusDB.fishingSettings, "Auto-close Delay (sec)", -120, "autoCloseDelay", 10, 60, 1)
    alphaSlider, alphaBox = OUS.CreatePremiumSlider(tabs.Fishing, OdysseusDB.fishingSettings, "Frame Transparency", -170, "alpha", 0.1, 1.0, 0.05, OUS.UpdateFishingAlpha)

    local wipeFishBtn = CreateFrame("Button", nil, tabs.Fishing, "UIPanelButtonTemplate")
    wipeFishBtn:SetSize(120, 24)
    wipeFishBtn:SetPoint("BOTTOMLEFT", 12, 40)
    wipeFishBtn:SetText("Wipe Saved Data")
    wipeFishBtn:SetScript("OnClick", function() StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_FISHING") end)

    local resetBtn = CreateFrame("Button", nil, tabs.Fishing, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        if not OUS.fishingDefaults then return end

        for k, v in pairs(OUS.fishingDefaults) do
            if type(v) == "table" then
                OdysseusDB.fishingSettings[k] = OUS.DeepCopyTable(v)
            else
                OdysseusDB.fishingSettings[k] = v
            end
        end

        if delaySlider then delaySlider:SetValue(OUS.fishingDefaults.autoCloseDelay); delayBox:SetText(OUS.fishingDefaults.autoCloseDelay) end
        if alphaSlider then alphaSlider:SetValue(OUS.fishingDefaults.alpha); alphaBox:SetText(OUS.fishingDefaults.alpha) end
        if _G["OdysseusFishingToggle_autoCloseInactive"] then _G["OdysseusFishingToggle_autoCloseInactive"]:SetChecked(OUS.fishingDefaults.autoCloseInactive) end
        if _G["OdysseusFishingToggle_autoCloseMounted"] then _G["OdysseusFishingToggle_autoCloseMounted"]:SetChecked(OUS.fishingDefaults.autoCloseMounted) end

        if OUS.UpdateFishingAlpha then OUS.UpdateFishingAlpha() end
        if OUS.LogDebug then
            OUS.LogDebug("Fishing", "Fishing Tracker settings restored to default.")
        end
    end)

    fishWidgetsCreated = true
end

tabs.Fishing:SetScript("OnShow", function()
    CreateFishingWidgets()

    if OdysseusDB and OdysseusDB.fishingSettings then
        if _G["OdysseusFishingToggle_autoCloseInactive"] then
            _G["OdysseusFishingToggle_autoCloseInactive"]:SetChecked(OdysseusDB.fishingSettings.autoCloseInactive)
        end
        if _G["OdysseusFishingToggle_autoCloseMounted"] then
            _G["OdysseusFishingToggle_autoCloseMounted"]:SetChecked(OdysseusDB.fishingSettings.autoCloseMounted)
        end

        local delay = OdysseusDB.fishingSettings.autoCloseDelay or 30
        if delaySlider then delaySlider:SetValue(delay) end
        if delayBox then delayBox:SetText(delay) end

        local alpha = OdysseusDB.fishingSettings.alpha or 1.0
        if alphaSlider then alphaSlider:SetValue(alpha) end
        if alphaBox then alphaBox:SetText(alpha) end
    end
end)

-- =====================================
-- TAB 6: AUTO REMOUNT
-- =====================================
local arWidgetsCreated = false
local arDelaySlider, arDelayBox
local arCharMountText, arAcctMountText

local function CreateAutoRemountWidgets()
    if arWidgetsCreated then return end

    CreateContentHeader(tabs.AutoRemount, -15, "Auto Remount Settings")

    local function CreateARToggle(label, yOffset, dbKey)
        local frameName = "OdysseusARToggle_" .. dbKey
        local cb = CreateFrame("CheckButton", frameName, tabs.AutoRemount, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetScript("OnShow", function(self)
            if OdysseusDB and OdysseusDB.autoRemount then
                self:SetChecked(OdysseusDB.autoRemount[dbKey])
            end
        end)
        cb:SetScript("OnClick", function(self)
            OdysseusDB.autoRemount[dbKey] = self:GetChecked()
        end)
        return cb
    end

    CreateARToggle(" Enable Auto Remount", -55, "enabled")
    CreateARToggle(" Skip Druid Travel Form", -85, "skipDruid")
    CreateARToggle(" Silent mode (suppress mount errors)", -115, "silent")
    CreateARToggle(" Debug mode", -145, "debug")
    CreateARToggle(" Spy mode (print loot-confirmed spells to chat)", -175, "spyMode")

    -- Button to open the spy frame directly from config
    local spyFrameBtn = CreateFrame("Button", nil, tabs.AutoRemount, "UIPanelButtonTemplate")
    spyFrameBtn:SetSize(160, 24)
    spyFrameBtn:SetPoint("TOPLEFT", 20, -205)
    spyFrameBtn:SetText("Open Spy Frame")
    spyFrameBtn:SetScript("OnClick", function()
        if OUS.AutoRemount and OUS.AutoRemount.RefreshSpyFrame then
            OUS.AutoRemount.RefreshSpyFrame()
        end
        local f = _G["OdysseusAutoRemountSpyFrame"]
        if f then f:Show() end
    end)

    arDelaySlider, arDelayBox = OUS.CreatePremiumSlider(
        tabs.AutoRemount, OdysseusDB.autoRemount,
        "Remount Delay (sec)", -235, "delay", 0.1, 5.0, 0.1
    )

    -- Character mount display
    local charMountLabel = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charMountLabel:SetPoint("TOPLEFT", 20, -295)
    charMountLabel:SetText("Character Mount:")

    arCharMountText = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arCharMountText:SetPoint("TOPLEFT", 20, -310)
    arCharMountText:SetTextColor(0.8, 0.8, 0.8)
    local charMountText = arCharMountText

    local clearCharBtn = CreateFrame("Button", nil, tabs.AutoRemount, "UIPanelButtonTemplate")
    clearCharBtn:SetSize(60, 22)
    clearCharBtn:SetPoint("LEFT", charMountText, "RIGHT", 10, 0)
    clearCharBtn:SetText("Clear")
    clearCharBtn:SetScript("OnClick", function()
        OdysseusCharDB.autoRemountChar.mountID = nil
        charMountText:SetText("|cFF888888None (using account or favourite)|r")
    end)

    -- Account mount display
    local acctMountLabel = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    acctMountLabel:SetPoint("TOPLEFT", 20, -340)
    acctMountLabel:SetText("Account Mount:")

    arAcctMountText = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arAcctMountText:SetPoint("TOPLEFT", 20, -355)
    arAcctMountText:SetTextColor(0.8, 0.8, 0.8)
    local acctMountText = arAcctMountText

    local clearAcctBtn = CreateFrame("Button", nil, tabs.AutoRemount, "UIPanelButtonTemplate")
    clearAcctBtn:SetSize(60, 22)
    clearAcctBtn:SetPoint("LEFT", acctMountText, "RIGHT", 10, 0)
    clearAcctBtn:SetText("Clear")
    clearAcctBtn:SetScript("OnClick", function()
        OdysseusDB.autoRemount.accountMountID = nil
        acctMountText:SetText("|cFF888888None (using favourite)|r")
    end)

    -- Reset defaults button
    local resetBtn = CreateFrame("Button", nil, tabs.AutoRemount, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        OdysseusDB.autoRemount.enabled = true
        OdysseusDB.autoRemount.skipDruid = true
        OdysseusDB.autoRemount.silent = true
        OdysseusDB.autoRemount.debug = false
        OdysseusDB.autoRemount.spyMode = false
        if _G["OdysseusARToggle_spyMode"] then _G["OdysseusARToggle_spyMode"]:SetChecked(false) end
        OdysseusDB.autoRemount.delay = 0.5
        OdysseusDB.autoRemount.accountMountID = nil
        OdysseusCharDB.autoRemountChar.mountID = nil
        if arDelaySlider then arDelaySlider:SetValue(0.5) end
        if arDelayBox then arDelayBox:SetText("0.5") end
        if _G["OdysseusARToggle_enabled"] then _G["OdysseusARToggle_enabled"]:SetChecked(true) end
        if _G["OdysseusARToggle_skipDruid"] then _G["OdysseusARToggle_skipDruid"]:SetChecked(true) end
        if _G["OdysseusARToggle_silent"] then _G["OdysseusARToggle_silent"]:SetChecked(true) end
        if _G["OdysseusARToggle_debug"] then _G["OdysseusARToggle_debug"]:SetChecked(false) end
        charMountText:SetText("|cFF888888None (using account or favourite)|r")
        acctMountText:SetText("|cFF888888None (using favourite)|r")
        if OUS.LogDebug then OUS.LogDebug("AutoRemount", "Settings restored to default.") end
    end)

    arWidgetsCreated = true
end

tabs.AutoRemount:SetScript("OnShow", function()
    CreateAutoRemountWidgets()

    if OdysseusDB and OdysseusDB.autoRemount then
        if _G["OdysseusARToggle_enabled"] then _G["OdysseusARToggle_enabled"]:SetChecked(OdysseusDB.autoRemount.enabled) end
        if _G["OdysseusARToggle_skipDruid"] then _G["OdysseusARToggle_skipDruid"]:SetChecked(OdysseusDB.autoRemount.skipDruid) end
        if _G["OdysseusARToggle_silent"] then _G["OdysseusARToggle_silent"]:SetChecked(OdysseusDB.autoRemount.silent) end
        if _G["OdysseusARToggle_debug"] then _G["OdysseusARToggle_debug"]:SetChecked(OdysseusDB.autoRemount.debug) end
        if _G["OdysseusARToggle_spyMode"] then _G["OdysseusARToggle_spyMode"]:SetChecked(OdysseusDB.autoRemount.spyMode) end
        -- Refresh mount name displays
        if arCharMountText then
            local charID = OdysseusCharDB.autoRemountChar.mountID
            if charID then
                local name = C_MountJournal.GetMountInfoByID(charID)
                arCharMountText:SetText(name or "|cFFFF0000Unknown|r")
            else
                arCharMountText:SetText("|cFF888888None (using account or favourite)|r")
            end
        end
        if arAcctMountText then
            local acctID = OdysseusDB.autoRemount.accountMountID
            if acctID then
                local name = C_MountJournal.GetMountInfoByID(acctID)
                arAcctMountText:SetText(name or "|cFFFF0000Unknown|r")
            else
                arAcctMountText:SetText("|cFF888888None (using favourite)|r")
            end
        end
        local delay = OdysseusDB.autoRemount.delay or 0.5
        if arDelaySlider then arDelaySlider:SetValue(delay) end
        if arDelayBox then arDelayBox:SetText(tostring(delay)) end
    end
end)

cfg:SetScript("OnHide", function() dropDown:Hide() end)
ShowTab("General")

-- =====================================
-- TAB 7: STATS BAR
-- =====================================
local sbWidgetsCreated = false
local sbDelaySlider, sbDelayBox
local sbWidthSlider, sbWidthBox

local function CreateStatsBarWidgets()
    if sbWidgetsCreated then return end

    CreateContentHeader(tabs.StatsBar, -15, "Stats Bar Settings")

    local function CreateSBToggle(label, yOffset, dbKey, useGlobalDB)
        local frameName = "OdysseusSBToggle_" .. dbKey
        local cb = CreateFrame("CheckButton", frameName, tabs.StatsBar, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetScript("OnShow", function(self)
            local db = useGlobalDB and (OdysseusDB and OdysseusDB.statsBar) or (OdysseusCharDB and OdysseusCharDB.statsBar)
            if db then self:SetChecked(db[dbKey]) end
        end)
        cb:SetScript("OnClick", function(self)
            local db = useGlobalDB and (OdysseusDB and OdysseusDB.statsBar) or (OdysseusCharDB and OdysseusCharDB.statsBar)
            if db then
                db[dbKey] = self:GetChecked()
                if OUS.StatsBar then
                    if dbKey == "tableEnabled" then
                        OUS.StatsBar.UpdateDisplay()
                        OUS.StatsBar.UpdateTable()
                    elseif dbKey == "locked" then
                        OUS.StatsBar.SetLocked(db[dbKey])
                    elseif dbKey == "tableLocked" then
                        OUS.StatsBar.SetTableLocked(db[dbKey])
                    else
                        OUS.StatsBar.UpdateDisplay()
                    end
                end
            end
        end)
        return cb
    end

    CreateSBToggle(" Table mode (vertical layout)", -55, "tableEnabled", false)
    CreateSBToggle(" Lock single-line bar position", -85, "locked", true)
    CreateSBToggle(" Lock table position", -115, "tableLocked", true)

    -- Font size slider
    local statsBarDB = OdysseusDB and OdysseusDB.statsBar or {}
    sbDelaySlider, sbDelayBox = OUS.CreatePremiumSlider(
        tabs.StatsBar, statsBarDB,
        "Font Size", -155, "fontSize", 8, 24, 1
    )
    if sbDelaySlider then
        sbDelaySlider:HookScript("OnValueChanged", function(self)
            local val = self:GetValue()
            if OdysseusDB and OdysseusDB.statsBar then
                OdysseusDB.statsBar.fontSize = val
            end
            if OUS.StatsBar then
                OUS.StatsBar.UpdateDisplay()
                OUS.StatsBar.UpdateTable()
            end
        end)
    end

    -- Table width slider
    local statsBarDBW = OdysseusDB and OdysseusDB.statsBar or {}
    sbWidthSlider, sbWidthBox = OUS.CreatePremiumSlider(
        tabs.StatsBar, statsBarDBW,
        "Table Width", -215, "tableWidth", 100, 300, 5
    )
    if sbWidthSlider then
        sbWidthSlider:HookScript("OnValueChanged", function(self)
            local val = self:GetValue()
            if OdysseusDB and OdysseusDB.statsBar then
                OdysseusDB.statsBar.tableWidth = val
            end
            if OUS.StatsBar then OUS.StatsBar.UpdateTable() end
        end)
    end

    -- Template label
    local templateLabel = tabs.StatsBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    templateLabel:SetPoint("TOPLEFT", 20, -280)
    templateLabel:SetText("Single-line Template:")

    -- Template EditBox
    local templateBox = CreateFrame("EditBox", "OdysseusSBTemplateBox", tabs.StatsBar, "InputBoxTemplate")
    templateBox:SetSize(260, 22)
    templateBox:SetPoint("TOPLEFT", 20, -292)
    templateBox:SetAutoFocus(false)
    templateBox:SetMaxLetters(200)
    templateBox:SetScript("OnShow", function(self)
        local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
        self:SetText(charDB and charDB.template or "{ilvl} | {spec}")
    end)
    templateBox:SetScript("OnEnterPressed", function(self)
        local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
        if charDB then
            charDB.template = self:GetText()
            if OUS.StatsBar then OUS.StatsBar.UpdateDisplay() end
        end
        self:ClearFocus()
    end)
    templateBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Token hint
    local tokenHint = tabs.StatsBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tokenHint:SetPoint("TOPLEFT", 20, -333)
    tokenHint:SetTextColor(0.7, 0.7, 0.7)
    tokenHint:SetText("{ilvl} {spec} {crit} {haste} {mast} {vers} {int} {agi} {str}")

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, tabs.StatsBar, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    resetBtn:SetText("Reset Defaults")
    StaticPopupDialogs["ODYSSEUS_CONFIRM_RESET_STATSBAR"] = {
        text = "Reset all Stats Bar settings to defaults? This cannot be undone.",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
            local gdb = OdysseusDB and OdysseusDB.statsBar
            if charDB then
                charDB.enabled       = true
                charDB.tableEnabled  = false
                charDB.template      = "{ilvl} | {spec}"
                charDB.x, charDB.y  = 0, 0
                charDB.point, charDB.relPoint = "CENTER", "CENTER"
                charDB.tableX        = 200
                charDB.tableY        = 0
                charDB.tablePoint, charDB.tableRelPoint = "CENTER", "CENTER"
            end
            if gdb then
                gdb.fontSize    = 12
                gdb.tableWidth  = 150
                gdb.locked      = false
                gdb.tableLocked = false
            end
            if sbDelaySlider then sbDelaySlider:SetValue(12) end
            if sbDelayBox then sbDelayBox:SetText("12") end
            if sbWidthSlider then sbWidthSlider:SetValue(150) end
            if sbWidthBox then sbWidthBox:SetText("150") end
            if _G["OdysseusSBToggle_enabled"] then _G["OdysseusSBToggle_enabled"]:SetChecked(true) end
            if _G["OdysseusSBToggle_tableEnabled"] then _G["OdysseusSBToggle_tableEnabled"]:SetChecked(false) end
            if _G["OdysseusSBToggle_locked"] then _G["OdysseusSBToggle_locked"]:SetChecked(false) end
            if _G["OdysseusSBToggle_tableLocked"] then _G["OdysseusSBToggle_tableLocked"]:SetChecked(false) end
            if _G["OdysseusSBTemplateBox"] then _G["OdysseusSBTemplateBox"]:SetText("{ilvl} | {spec}") end
            if OUS.StatsBar then
                OUS.StatsBar.UpdateDisplay()
                OUS.StatsBar.UpdateTable()
                OUS.StatsBar.SetLocked(false)
                OUS.StatsBar.SetTableLocked(false)
            end
            if OUS.LogDebug then OUS.LogDebug("StatsBar", "Settings restored to default.") end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_RESET_STATSBAR")
    end)

    sbWidgetsCreated = true
end

tabs.StatsBar:SetScript("OnShow", function()
    CreateStatsBarWidgets()
    local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
    if charDB then
        if _G["OdysseusSBToggle_enabled"] then _G["OdysseusSBToggle_enabled"]:SetChecked(charDB.enabled) end
        if _G["OdysseusSBToggle_tableEnabled"] then _G["OdysseusSBToggle_tableEnabled"]:SetChecked(charDB.tableEnabled) end
        local gdb = OdysseusDB and OdysseusDB.statsBar
        if _G["OdysseusSBToggle_locked"] then _G["OdysseusSBToggle_locked"]:SetChecked(gdb and gdb.locked or false) end
        if _G["OdysseusSBToggle_tableLocked"] then _G["OdysseusSBToggle_tableLocked"]:SetChecked(gdb and gdb.tableLocked or false) end
        local fs = (gdb and gdb.fontSize) or 12
        if sbDelaySlider then sbDelaySlider:SetValue(fs) end
        if sbDelayBox then sbDelayBox:SetText(tostring(fs)) end
        local tw = (gdb and gdb.tableWidth) or 150
        if sbWidthSlider then sbWidthSlider:SetValue(tw) end
        if sbWidthBox then sbWidthBox:SetText(tostring(tw)) end
        if _G["OdysseusSBTemplateBox"] then _G["OdysseusSBTemplateBox"]:SetText(charDB.template or "{ilvl} | {spec}") end
    end
end)

-- =====================================
-- TAB 8: OPENABLES
-- =====================================
local opWidgetsCreated = false
local opScaleSlider, opScaleBox

local function CreateOpenablesWidgets()
    if opWidgetsCreated then return end

    CreateContentHeader(tabs.Openables, -8, "Openables")

    -- Enable toggle
    local opEnableCheck = CreateFrame("CheckButton", "OdysseusOPToggle_enabled", tabs.Openables, "ChatConfigCheckButtonTemplate")
    opEnableCheck:SetPoint("TOPLEFT", 20, -55)
    _G[opEnableCheck:GetName().."Text"]:SetText(" Enable Openables")
    opEnableCheck:SetScript("OnShow", function(self)
        self:SetChecked(OdysseusDB and OdysseusDB.modules and OdysseusDB.modules.openables)
    end)
    opEnableCheck:SetScript("OnClick", function(self)
        if OdysseusDB and OdysseusDB.modules then
            OdysseusDB.modules.openables = self:GetChecked()
            if OUS.Openables then OUS.Openables.UpdateDisplay() end
        end
    end)

    -- Auto-open toggle
    local opAutoCheck = CreateFrame("CheckButton", "OdysseusOPToggle_autoOpen", tabs.Openables, "ChatConfigCheckButtonTemplate")
    opAutoCheck:SetPoint("TOPLEFT", 20, -90)
    _G[opAutoCheck:GetName().."Text"]:SetText(" Auto-open on bag update")
    opAutoCheck:SetScript("OnShow", function(self)
        local db = OdysseusDB and OdysseusDB.openables
        self:SetChecked(db and db.autoOpen)
    end)
    opAutoCheck:SetScript("OnClick", function(self)
        local db = OdysseusDB and OdysseusDB.openables
        if db then
            db.autoOpen = self:GetChecked()
            if OUS.Openables then OUS.Openables.UpdateDisplay() end
        end
    end)

    -- Button scale slider
    local scaleHeader = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleHeader:SetPoint("TOPLEFT", 20, -135)
    scaleHeader:SetTextColor(0.7, 0.5, 1)
    scaleHeader:SetText("BUTTON SCALE")

    local opScaleDB = setmetatable({}, {
        __index = function()
            return (OdysseusDB and OdysseusDB.openables and OdysseusDB.openables.scale) or 1.0
        end,
        __newindex = function(_, _, v)
            if OdysseusDB and OdysseusDB.openables then
                OdysseusDB.openables.scale = v
                -- Apply scale live
                local container = _G["OdysseusOpenablesContainer"]
                local btn = _G["OdysseusOpenablesButton"]
                local handle = _G["OdysseusOpenablesDragHandle"]
                if container and btn then
                    container:SetSize(64 * v, 64 * v)
                    btn:SetSize(40 * v, 40 * v)
                    if handle then handle:SetSize(40 * v, 40 * v) end
                    if OdysseusDB and OdysseusDB.openables then
                        OdysseusDB.openables.scale = v
                    end
                end
            end
        end,
    })

    opScaleSlider, opScaleBox = OUS.CreatePremiumSlider(
        tabs.Openables, opScaleDB,
        "Button Scale", -155,
        1, 0.5, 2.0, 0.05,
        nil
    )

    -- Reset position button
    local resetPosBtn = CreateFrame("Button", nil, tabs.Openables, "UIPanelButtonTemplate")
    resetPosBtn:SetSize(160, 24)
    resetPosBtn:SetPoint("TOPLEFT", 20, -230)
    resetPosBtn:SetText("Reset Button Position")
    resetPosBtn:SetScript("OnClick", function()
        local db = OdysseusDB and OdysseusDB.openables
        if db then
            db.x, db.y = 300, 0
            db.point, db.relPoint = "CENTER", "CENTER"
            local btn = _G["OdysseusOpenablesContainer"]
            if btn then
                btn:ClearAllPoints()
                btn:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
            end
        end
    end)

    -- Blacklist info line
    local blHeader = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    blHeader:SetPoint("TOPLEFT", 20, -275)
    blHeader:SetTextColor(0.7, 0.5, 1)
    blHeader:SetText("BLACKLIST")

    local blDesc = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    blDesc:SetPoint("TOPLEFT", 20, -295)
    blDesc:SetTextColor(0.6, 0.6, 0.6)
    blDesc:SetText("Manage via /op list  ·  Shift+Right-click button to blacklist an item")

    local blCountLabel = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blCountLabel:SetPoint("TOPLEFT", 20, -318)

    local function RefreshBlCount()
        local db = OdysseusDB and OdysseusDB.openables
        local count = 0
        if db and db.blacklist then
            for _ in pairs(db.blacklist) do count = count + 1 end
        end
        blCountLabel:SetText("Permanently blacklisted items: |cFFFFD100" .. count .. "|r")
    end

    local clearBlBtn = CreateFrame("Button", nil, tabs.Openables, "UIPanelButtonTemplate")
    clearBlBtn:SetSize(140, 24)
    clearBlBtn:SetPoint("TOPLEFT", 20, -345)
    clearBlBtn:SetText("Clear All Blacklist")

    StaticPopupDialogs["ODYSSEUS_CONFIRM_CLEAR_OP_BLACKLIST"] = {
        text = "Clear the entire Openables permanent blacklist? This cannot be undone.",
        button1 = "Yes, Clear",
        button2 = "Cancel",
        OnAccept = function()
            local db = OdysseusDB and OdysseusDB.openables
            if db then
                db.blacklist = {}
                print("|cFF00CCFFOdysseus Openables:|r Permanent blacklist cleared.")
                RefreshBlCount()
                if OUS.Openables then OUS.Openables.UpdateDisplay() end
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    clearBlBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_CLEAR_OP_BLACKLIST")
    end)

    -- ----------------------------------------
    -- CUSTOM ITEMS DB
    -- ----------------------------------------
    local customHeader = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customHeader:SetPoint("TOPLEFT", 20, -385)
    customHeader:SetTextColor(0.7, 0.5, 1)
    customHeader:SetText("CUSTOM ITEMS DB")

    local customDesc = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customDesc:SetPoint("TOPLEFT", 20, -403)
    customDesc:SetTextColor(0.6, 0.6, 0.6)
    customDesc:SetText("Items added via /op add or /op madd")

    local customCountLabel = tabs.Openables:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customCountLabel:SetPoint("TOPLEFT", 20, -422)
    tabs.Openables._customCountLabel = customCountLabel

    local function RefreshCustomCount()
        local db = OdysseusDB and OdysseusDB.openables
        local count = 0
        if db and db.customItems then
            for _ in pairs(db.customItems) do count = count + 1 end
        end
        customCountLabel:SetText("Custom items: |cFFFFD100" .. count .. "|r")
    end
    tabs.Openables._refreshCustomCount = RefreshCustomCount

    -- Export frame (lazy-created)
    local opExportFrame
    local opExportEditBox

    local function OpenExportFrame()
        if not opExportFrame then
            opExportFrame = CreateFrame("Frame", "OdysseusOpenablesExportFrame", UIParent, "BackdropTemplate")
            opExportFrame:SetSize(450, 380)
            opExportFrame:SetPoint("CENTER")
            opExportFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            opExportFrame:SetMovable(true)
            opExportFrame:SetClampedToScreen(true)
            opExportFrame:EnableMouse(true)
            opExportFrame:RegisterForDrag("LeftButton")
            opExportFrame:SetScript("OnDragStart", opExportFrame.StartMoving)
            opExportFrame:SetScript("OnDragStop", opExportFrame.StopMovingOrSizing)
            tinsert(UISpecialFrames, opExportFrame:GetName())

            opExportFrame:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            opExportFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
            opExportFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)

            local hdrBg = opExportFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
            hdrBg:SetPoint("TOPLEFT", 4, -4)
            hdrBg:SetPoint("TOPRIGHT", -4, -4)
            hdrBg:SetHeight(26)
            hdrBg:SetColorTexture(1, 1, 1, 1)
            hdrBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

            local hdrTitle = opExportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            hdrTitle:SetPoint("TOP", opExportFrame, "TOP", 0, -8)
            hdrTitle:SetText("Openables — Custom Items Export")
            hdrTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

            local expCloseBtn = CreateFrame("Button", nil, opExportFrame, "UIPanelCloseButton")
            expCloseBtn:SetPoint("TOPRIGHT", opExportFrame, "TOPRIGHT", -2, -2)
            expCloseBtn:SetScript("OnClick", function() opExportFrame:Hide() end)

            local expScroll = CreateFrame("ScrollFrame", nil, opExportFrame, "UIPanelScrollFrameTemplate")
            expScroll:SetPoint("TOPLEFT", 15, -40)
            expScroll:SetPoint("BOTTOMRIGHT", -35, 45)

            opExportEditBox = CreateFrame("EditBox", nil, expScroll)
            opExportEditBox:SetSize(expScroll:GetSize())
            opExportEditBox:SetMultiLine(true)
            opExportEditBox:SetAutoFocus(false)
            opExportEditBox:SetFontObject("ChatFontNormal")
            opExportEditBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
                opExportFrame:Hide()
            end)
            expScroll:SetScrollChild(opExportEditBox)

            local selectAllBtn = CreateFrame("Button", nil, opExportFrame, "UIPanelButtonTemplate")
            selectAllBtn:SetSize(120, 25)
            selectAllBtn:SetPoint("BOTTOMLEFT", 15, 10)
            selectAllBtn:SetText("Select All")
            selectAllBtn:SetScript("OnClick", function()
                opExportEditBox:HighlightText()
                opExportEditBox:SetFocus()
            end)

            local expClose2Btn = CreateFrame("Button", nil, opExportFrame, "UIPanelButtonTemplate")
            expClose2Btn:SetSize(120, 25)
            expClose2Btn:SetPoint("BOTTOMRIGHT", -15, 10)
            expClose2Btn:SetText("Close")
            expClose2Btn:SetScript("OnClick", function() opExportFrame:Hide() end)
        end

        -- Build export text
        local db = OdysseusDB and OdysseusDB.openables
        if not db or not next(db.customItems) then
            opExportEditBox:SetText("-- Custom list is empty.")
        else
            local lines = {}
            for itemID, qty in pairs(db.customItems) do
                local name = C_Item.GetItemNameByID(itemID) or "Unknown"
                table.insert(lines, string.format("    [%d] = %d,   -- %s", itemID, qty, name))
            end
            table.sort(lines)
            opExportEditBox:SetText(table.concat(lines, "\n"))
        end
        opExportEditBox:HighlightText()
        opExportFrame:Show()
    end

    -- Export button
    local exportCustomBtn = CreateFrame("Button", nil, tabs.Openables, "UIPanelButtonTemplate")
    exportCustomBtn:SetSize(110, 24)
    exportCustomBtn:SetPoint("TOPLEFT", 20, -445)
    exportCustomBtn:SetText("Export DB")
    exportCustomBtn:SetScript("OnClick", OpenExportFrame)

    -- Wipe custom DB button
    local wipeCustomBtn = CreateFrame("Button", nil, tabs.Openables, "UIPanelButtonTemplate")
    wipeCustomBtn:SetSize(110, 24)
    wipeCustomBtn:SetPoint("LEFT", exportCustomBtn, "RIGHT", 8, 0)
    wipeCustomBtn:SetText("Wipe Custom DB")

    StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE_OP_CUSTOM"] = {
        text = "Wipe ALL custom Openables items? This cannot be undone.",
        button1 = "Yes, Wipe",
        button2 = "Cancel",
        OnAccept = function()
            local db = OdysseusDB and OdysseusDB.openables
            if db then
                db.customItems = {}
                print("|cFF00CCFFOdysseus Openables:|r Custom items wiped.")
                if tabs.Openables._refreshCustomCount then tabs.Openables._refreshCustomCount() end
                if OUS.Openables then OUS.Openables.UpdateDisplay() end
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    wipeCustomBtn:SetScript("OnClick", function()
        StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_OP_CUSTOM")
    end)

    opWidgetsCreated = true

    -- Store refs for OnShow refresh
    tabs.Openables._blCountLabel = blCountLabel
    tabs.Openables._refreshBlCount = RefreshBlCount
end

tabs.Openables:SetScript("OnShow", function()
    CreateOpenablesWidgets()
    local db = OdysseusDB and OdysseusDB.openables
    if _G["OdysseusOPToggle_enabled"] then
        _G["OdysseusOPToggle_enabled"]:SetChecked(OdysseusDB and OdysseusDB.modules and OdysseusDB.modules.openables)
    end
    if _G["OdysseusOPToggle_autoOpen"] then
        _G["OdysseusOPToggle_autoOpen"]:SetChecked(db and db.autoOpen)
    end
    local scale = (db and db.scale) or 1.0
    if opScaleSlider then opScaleSlider:SetValue(scale) end
    if opScaleBox then opScaleBox:SetText(string.format("%.2f", scale):gsub("0+$",""):gsub("%.$","")) end
    if tabs.Openables._refreshBlCount then tabs.Openables._refreshBlCount() end
    if tabs.Openables._refreshCustomCount then tabs.Openables._refreshCustomCount() end
end)

-- =====================================
-- ON-SCREEN HELP FRAME
-- =====================================
local helpFrame = CreateFrame("Frame", "OdysseusHelpFrame", UIParent, "BackdropTemplate")
helpFrame:SetSize(380, 460)
helpFrame:SetPoint("CENTER")
helpFrame:SetFrameStrata("DIALOG")
helpFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
helpFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.98)
helpFrame:SetBackdropBorderColor(0.5, 0.3, 0.7, 1)
helpFrame:Hide()
helpFrame:SetMovable(true)
helpFrame:SetClampedToScreen(true)
helpFrame:EnableMouse(true)
helpFrame:RegisterForDrag("LeftButton")
helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, helpFrame:GetName())

helpFrame.headerBg = helpFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
helpFrame.headerBg:SetPoint("TOPLEFT", 4, -4)
helpFrame.headerBg:SetPoint("TOPRIGHT", -4, -4)
helpFrame.headerBg:SetHeight(26)
helpFrame.headerBg:SetColorTexture(1, 1, 1, 1)
helpFrame.headerBg:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))

helpFrame.title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
helpFrame.title:SetPoint("TOP", helpFrame, "TOP", 0, -8)
helpFrame.title:SetText("Odysseus Commands")
helpFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local helpCloseBtn = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
helpCloseBtn:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -2, -2)

local helpMsgFrame = CreateFrame("ScrollingMessageFrame", nil, helpFrame)
helpMsgFrame:SetPoint("TOPLEFT", 14, -38)
helpMsgFrame:SetPoint("BOTTOMRIGHT", -14, 10)
helpMsgFrame:SetFontObject(GameFontNormalSmall)
helpMsgFrame:SetJustifyH("LEFT")
helpMsgFrame:SetFading(false)
helpMsgFrame:SetMaxLines(200)

local function AddHelpSection(title)
    helpMsgFrame:AddMessage("|cFFAA88FF" .. title .. "|r")
end

local function AddHelpCmd(cmd, desc)
    helpMsgFrame:AddMessage("|cFF00FF00" .. cmd .. "|r - " .. desc)
end

local function AddHelpLine(text)
    helpMsgFrame:AddMessage("|cFF888888" .. text .. "|r")
end

-- Main
AddHelpSection("— Main —")
AddHelpCmd("/ous", "Open Main Configuration Panel")
AddHelpCmd("/ous help", "Show This Window")
AddHelpCmd("/ousdebug", "Toggle Global Debug Mode")
AddHelpLine("")

-- XP / Rep Bar
AddHelpSection("— XP / Rep Bar —")
AddHelpCmd("/xpstats", "Show Session XP & Rep Data")
AddHelpCmd("/ousxp", "Toggle XP Bar")
AddHelpCmd("/toasttest", "Test Reward Popup")
AddHelpCmd("/delvetest", "Toggle Fake Delve Bar")
AddHelpCmd("/delvedebug", "Print Advanced Delve IDs")
AddHelpLine("")

-- Auto Remount
AddHelpSection("— Auto Remount —")
AddHelpCmd("/ar mount <n>", "Set character mount")
AddHelpCmd("/ar account <n>", "Set account-wide mount")
AddHelpCmd("/ar reset", "Clear character mount override")
AddHelpCmd("/ar reset account", "Clear account mount override")
AddHelpCmd("/ar toggle", "Toggle on/off")
AddHelpCmd("/ar druid", "Toggle druid form skip")
AddHelpCmd("/ar delay <sec>", "Set remount delay (0.1-5.0)")
AddHelpCmd("/ar silent", "Toggle error notifications")
AddHelpCmd("/ar spy", "Print loot-confirmed unknown spells to chat")
AddHelpCmd("/ar spyfilter", "Manage spy filter blacklist")
AddHelpCmd("/ar add <id>", "Add custom spell ID")
AddHelpCmd("/ar remove <id>", "Remove custom spell ID")
AddHelpCmd("/ar export", "Print custom spell IDs")
AddHelpCmd("/ar wipe", "Clear custom spell IDs")
AddHelpCmd("/ar status", "Show current settings")
AddHelpCmd("/ar help", "Show all AR commands")
AddHelpLine("")

-- Openables
AddHelpSection("— Openables —")
AddHelpCmd("/op add <itemID> [qty]", "Add item to custom list")
AddHelpCmd("/op remove <itemID>", "Remove from custom list")
AddHelpCmd("/op unblacklist <itemID>", "Remove from blacklist")
AddHelpCmd("/op list", "Open blacklist management frame")
AddHelpCmd("/op clist", "Open custom items management frame")
AddHelpCmd("/op madd", "Open drag-and-drop item add frame")
AddHelpCmd("/op auto", "Toggle auto-open")
AddHelpCmd("/op lock / unlock", "Lock/unlock button position")
AddHelpCmd("/op status", "Show current settings")
AddHelpLine("")

-- Stats Bar
AddHelpSection("— Stats Bar —")
AddHelpCmd("/sb toggle", "Toggle on/off")
AddHelpCmd("/sb table", "Toggle table view")
AddHelpCmd("/sb template <text>", "Set single-line template")
AddHelpCmd("/sb size <8-24>", "Set font size")
AddHelpCmd("/sb lock / unlock", "Lock/unlock bar position")
AddHelpCmd("/sb tlock / tunlock", "Lock/unlock table position")
AddHelpCmd("/sb tokens", "Show all template tokens")
AddHelpCmd("/sb reset", "Reset to defaults")
AddHelpCmd("/sb status", "Show current settings")