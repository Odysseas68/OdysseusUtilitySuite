-- Addon   : OdysseusUtilitySuite
-- File    : Config2\OUS2ScaleControl.lua
-- Version : 2026.06.21
-- Desc    : Reusable OUS2 numeric scale control
-- ================================================

local _, OUS = ...
local T = OUS.Theme
local C = OUS.Config2

local function GetPrecision(step)
    local text = string.format("%.6f", step):gsub("0+$", "")
    local decimals = text:match("%.(%d+)")
    return decimals and #decimals or 0
end

function C.CreateScaleControl(parent, minValue, maxValue, step, initialValue, onValueChanged)
    minValue = tonumber(minValue) or T.Scale.minValue
    maxValue = tonumber(maxValue) or T.Scale.maxValue
    step = tonumber(step) or T.Scale.step

    if maxValue < minValue then
        minValue, maxValue = maxValue, minValue
    end
    if step <= 0 then
        step = T.Scale.step
    end

    local precision = GetPrecision(step)
    local roundFactor = 10 ^ precision
    local gap = 6
    local editGap = 10
    local controlWidth = (T.Scale.arrowW * 2) + T.Scale.trackW + T.Scale.editW + (gap * 2) + editGap
    local controlHeight = math.max(T.Scale.arrowH, T.Scale.thumbH, T.Scale.editH)

    local control = CreateFrame("Frame", nil, parent)
    control:SetSize(controlWidth, controlHeight)

    local leftButton = CreateFrame("Button", nil, control)
    leftButton:SetSize(T.Scale.arrowW, T.Scale.arrowH)
    leftButton:SetPoint("LEFT", control, "LEFT", 0, 0)
    leftButton:SetNormalTexture(T.Tex("ScaleArrowLeft"))
    leftButton:SetHighlightTexture(T.Tex("ScaleArrowLeftH"))

    local slider = CreateFrame("Slider", nil, control)
    slider:SetSize(T.Scale.trackW, T.Scale.thumbH)
    slider:SetPoint("LEFT", leftButton, "RIGHT", gap, 0)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(T.Tex("ScaleTrack"))
    track:SetSize(T.Scale.trackW, T.Scale.trackH)
    track:SetPoint("CENTER")

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(T.Tex("ScaleFill"))
    fill:SetHeight(T.Scale.trackH)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)

    slider:SetThumbTexture(T.Tex("ScaleThumb"))
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(T.Scale.thumbW, T.Scale.thumbH)

    local rightButton = CreateFrame("Button", nil, control)
    rightButton:SetSize(T.Scale.arrowW, T.Scale.arrowH)
    rightButton:SetPoint("LEFT", slider, "RIGHT", gap, 0)
    rightButton:SetNormalTexture(T.Tex("ScaleArrowRight"))
    rightButton:SetHighlightTexture(T.Tex("ScaleArrowRightH"))

    local editBox = CreateFrame("EditBox", nil, control)
    editBox:SetSize(T.Scale.editW, T.Scale.editH)
    editBox:SetPoint("LEFT", rightButton, "RIGHT", editGap, 0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(_G[T.Fonts.highlight])
    editBox:SetJustifyH("CENTER")
    editBox:SetMaxLetters(8)
    editBox:SetTextColor(T.Colors.text[1], T.Colors.text[2], T.Colors.text[3], T.Colors.text[4])

    local editBackground = editBox:CreateTexture(nil, "BACKGROUND")
    editBackground:SetTexture(T.Tex("ScaleEditBox"))
    editBackground:SetAllPoints()

    local currentValue
    local updating

    local function NormalizeValue(value)
        value = tonumber(value) or currentValue or minValue
        value = math.max(minValue, math.min(maxValue, value))
        value = minValue + (math.floor(((value - minValue) / step) + 0.5) * step)
        value = math.max(minValue, math.min(maxValue, value))
        return math.floor((value * roundFactor) + 0.5) / roundFactor
    end

    local function UpdateVisuals(value)
        local range = maxValue - minValue
        local ratio = range > 0 and ((value - minValue) / range) or 0

        if ratio > 0 then
            fill:Show()
            fill:SetWidth(math.max(1, T.Scale.trackW * ratio))
        else
            fill:Hide()
        end

        editBox:SetText(string.format("%." .. precision .. "f", value))
    end

    local function SetValue(value, notify)
        local newValue = NormalizeValue(value)
        local changed = currentValue == nil or newValue ~= currentValue
        currentValue = newValue

        updating = true
        slider:SetValue(newValue)
        updating = false
        UpdateVisuals(newValue)

        if notify and changed and onValueChanged then
            onValueChanged(newValue)
        end
    end

    slider:SetScript("OnValueChanged", function(_, value)
        if not updating then
            SetValue(value, true)
        end
    end)

    leftButton:SetScript("OnClick", function()
        SetValue(currentValue - step, true)
    end)

    rightButton:SetScript("OnClick", function()
        SetValue(currentValue + step, true)
    end)

    local function CommitEditValue()
        local value = tonumber(editBox:GetText())
        if value then
            SetValue(value, true)
        else
            UpdateVisuals(currentValue)
        end
        editBox:ClearFocus()
    end

    editBox:SetScript("OnEnterPressed", CommitEditValue)
    editBox:SetScript("OnEditFocusLost", CommitEditValue)
    editBox:SetScript("OnEscapePressed", function()
        UpdateVisuals(currentValue)
        editBox:ClearFocus()
    end)

    function control:SetValue(value, suppressCallback)
        SetValue(value, not suppressCallback)
    end

    function control:GetValue()
        return currentValue
    end

    control.leftButton = leftButton
    control.rightButton = rightButton
    control.slider = slider
    control.editBox = editBox

    SetValue(initialValue, false)
    return control
end
