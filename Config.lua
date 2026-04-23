local addonName, OUS = ...
local LSM = LibStub("LibSharedMedia-3.0")

local cfg = CreateFrame("Frame", "OdysseusConfigFrame", UIParent, "BackdropTemplate")
cfg:SetSize(650, 620)
cfg:SetPoint("CENTER")
cfg:SetFrameStrata("DIALOG")
cfg:Hide()
cfg:SetMovable(true)
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
        if OdysseusDB and OdysseusDB.fishingSettings then
            OdysseusDB.fishingSettings.history = {}
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
local genHeader = CreateContentHeader(tabs.General, -15, "Module Management")

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
    end)
end

CreateModuleToggle(tabs.General, " Enable Flight Master", -60, "flightMaster")
CreateModuleToggle(tabs.General, " Enable Faster Loot", -95, "fasterLoot")
CreateModuleToggle(tabs.General, " Enable Fishing Tracker", -130, "fishingTracker")
CreateModuleToggle(tabs.General, " Enable Exp & Rep Bar", -165, "xpBar")

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
    CreateARToggle(" Spy mode (discover unknown gather spells)", -175, "spyMode")

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

    local charMountText = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charMountText:SetPoint("TOPLEFT", 20, -310)
    charMountText:SetTextColor(0.8, 0.8, 0.8)

    local clearCharBtn = CreateFrame("Button", nil, tabs.AutoRemount, "UIPanelButtonTemplate")
    clearCharBtn:SetSize(60, 22)
    clearCharBtn:SetPoint("LEFT", charMountText, "RIGHT", 10, 0)
    clearCharBtn:SetText("Clear")
    clearCharBtn:SetScript("OnClick", function()
        OdysseusDB.autoRemountChar.mountID = nil
        charMountText:SetText("|cFF888888None (using account or favourite)|r")
    end)

    -- Account mount display
    local acctMountLabel = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    acctMountLabel:SetPoint("TOPLEFT", 20, -340)
    acctMountLabel:SetText("Account Mount:")

    local acctMountText = tabs.AutoRemount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    acctMountText:SetPoint("TOPLEFT", 20, -355)
    acctMountText:SetTextColor(0.8, 0.8, 0.8)

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
        OdysseusDB.autoRemountChar.mountID = nil
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
        local delay = OdysseusDB.autoRemount.delay or 0.5
        if arDelaySlider then arDelaySlider:SetValue(delay) end
        if arDelayBox then arDelayBox:SetText(tostring(delay)) end
    end
end)

cfg:SetScript("OnHide", function() dropDown:Hide() end)
ShowTab("General")

-- =====================================
-- ON-SCREEN HELP FRAME
-- =====================================
local helpFrame = CreateFrame("Frame", "OdysseusHelpFrame", UIParent, "BackdropTemplate")
helpFrame:SetSize(350, 280)
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

local helpTextStr = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
helpTextStr:SetPoint("TOPLEFT", 20, -45)
helpTextStr:SetJustifyH("LEFT")
helpTextStr:SetText(
    "|cFF00FF00/ous|r - Open Main Configuration Panel\n\n" ..
    "|cFF00FF00/ous help|r - Show This Window\n\n" ..
    "|cFF00FF00/xpstats|r - Show Session XP & Rep Data\n\n" ..
    "|cFF00FF00/toasttest|r - Test Popup (Hold Shift to Move!)\n\n" ..
    "|cFF00FF00/delvetest|r - Toggle Fake Delve Bar\n\n" ..
    "|cFF00FF00/delvedebug|r - Print Advanced Delve IDs\n\n" ..
    "|cFF00FF00/ousdebug|r - Toggle Global Debug Mode"
)
