local ADDON_NAME = ...

local TEX = "Interface\\AddOns\\OUS2ArtTest\\Media\\Assets\\"
local DEBUG_GRID     = false
local DEBUG_UNDERLAY = false
local DEBUG_SCROLLBOX = true
local DEBUG_UNDERLAY_COLOR = {1, 0, 1, 1} -- magenta
local SCROLLBAR_RIGHT_MARGIN = 70
local CONTENT_GAP = 20
local CONTENT_WIDTH = 360

local frame

local function AddTexture(parent, file, layer, width, height)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    tex:SetTexture(TEX .. file)
    tex:SetSize(width, height)
    return tex
end

local function CreateTestFrame()
    if frame then
        frame:SetShown(not frame:IsShown())
        return
    end

    frame = CreateFrame("Frame", "OUS2ArtTestFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1050, 700)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Resize settings
    local MIN_WIDTH  = 1050
    local MIN_HEIGHT = 700
    local MAX_WIDTH  = 1600
    local MAX_HEIGHT = 1000

    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)

    frame:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "OUS2ArtTestFrame")

    -- Dark safety underlay behind all artwork
    if DEBUG_UNDERLAY then
        local underlay = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
            underlay:SetColorTexture(unpack(DEBUG_UNDERLAY_COLOR))
        underlay:SetAllPoints()
    end

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(TEX .. "Background.tga")

    local bgInsetX = 12
    local bgInsetY = 20

    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", bgInsetX, -bgInsetY)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -bgInsetX, bgInsetY)

    -- Known asset sizes
    local corner = 80
    local topH   = 25
    local sideW  = 20
    local edgeInset = 64
    local VedgeInset = 5

    -- Edges
    local top = AddTexture(frame, "Top.tga", "BORDER", 512, topH)
    top:SetPoint("TOPLEFT",  frame, "TOPLEFT",  edgeInset, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -edgeInset, 0)

    local bottom = AddTexture(frame, "Bottom.tga", "BORDER", 512, topH)
    bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  edgeInset, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -edgeInset, 0)

    -- Vertical edges stretch from y=100 to y=600
    -- Vertical edges stretch between the corner areas
    local verticalTopInset = 0
    local verticalBottomInset = 0

    local left = AddTexture(frame, "Vertical_Left.tga", "BORDER", sideW, 172)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", VedgeInset, -verticalTopInset)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", VedgeInset, verticalBottomInset)
    left:SetWidth(sideW)

    local right = AddTexture(frame, "Vertical_Right.tga", "BORDER", sideW, 172)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -VedgeInset, -verticalTopInset)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -VedgeInset, verticalBottomInset)
    right:SetWidth(sideW)

    -- Corners 100x100
    local tl = AddTexture(frame, "TopLeft.tga", "OVERLAY", corner, corner)
    tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    local tr = AddTexture(frame, "TopRight.tga", "OVERLAY", corner, corner)
    tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    local bl = AddTexture(frame, "BottomLeft.tga", "OVERLAY", corner, corner)
    bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local br = AddTexture(frame, "BottomRight.tga", "OVERLAY", corner, corner)
    br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    -- Gems centered on top/bottom edges
    local headerGem = AddTexture(frame, "HeaderGem.tga", "OVERLAY", 128, 20)
    headerGem:SetPoint("TOP", frame, "TOP", 0, -15)

    local footerGem = AddTexture(frame, "FooterGem.tga", "OVERLAY", 128, 20)
    footerGem:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)

    -- Scrollbar test
    local scrollTest = CreateFrame("Frame", nil, frame)
    scrollTest:SetSize(50, 340)
    scrollTest:SetPoint("RIGHT", frame, "RIGHT", -SCROLLBAR_RIGHT_MARGIN, 0)

    -- local scrollBG = scrollTest:CreateTexture(nil, "BACKGROUND")
    -- scrollBG:SetColorTexture(1, 0, 0, 0.3)
    -- scrollBG:SetAllPoints()

    local track = scrollTest:CreateTexture(nil, "ARTWORK")
    track:SetTexture(TEX .. "ScrollTrack.tga")
    track:SetSize(15, 320)
    track:SetPoint("CENTER")

    local thumb = scrollTest:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(TEX .. "ScrollThumb.tga")
    thumb:SetSize(15, 60)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, 0)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", scrollTest, "BOTTOM", 0, -8)
    label:SetText("Scrollbar")

    -- Scroll content test
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetSize(CONTENT_WIDTH, 100)
    scrollFrame:SetPoint("CENTER")

    if DEBUG_SCROLLBOX then
    -- Visual debug box around scroll content area
    local scrollDebugBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    scrollDebugBox:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scrollDebugBox:SetBackdropBorderColor(0, 1, 1, 0.8)
    scrollDebugBox:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -1, 1)
    scrollDebugBox:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 1, -1)
    end

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(340, 700)
    scrollFrame:SetScrollChild(content)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = 30

        if delta < 0 then
            self:SetVerticalScroll(math.min(current + step, maxScroll))
        else
            self:SetVerticalScroll(math.max(current - step, 0))
        end
    end)

local function UpdateScrollLayout()
    local frameH = frame:GetHeight()

    local trackHeight = frameH - 260
    local thumbHeight = math.max(60, math.floor(trackHeight * 0.30))

    scrollTest:SetSize(50, trackHeight + 20)
    scrollTest:ClearAllPoints()
    scrollTest:SetPoint("RIGHT", frame, "RIGHT", -SCROLLBAR_RIGHT_MARGIN, 0)

    track:SetSize(15, trackHeight)
    track:ClearAllPoints()
    track:SetPoint("CENTER", scrollTest, "CENTER")

    scrollFrame:SetSize(CONTENT_WIDTH, trackHeight)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("RIGHT", scrollTest, "LEFT", -CONTENT_GAP, 0)

    thumb:SetSize(15, thumbHeight)

    local maxScroll = scrollFrame:GetVerticalScrollRange()
    local current = scrollFrame:GetVerticalScroll()
    local travel = trackHeight - thumbHeight

    local offset = 0
    if maxScroll > 0 and travel > 0 then
        offset = (current / maxScroll) * travel
    end

    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -offset)
end

    local function UpdateCustomThumb()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local current = scrollFrame:GetVerticalScroll()

        local trackHeight = track:GetHeight()
        local thumbHeight = thumb:GetHeight()
        local travel = trackHeight - thumbHeight

        local offset = 0
        if maxScroll > 0 then
            offset = (current / maxScroll) * travel
        end

        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -offset)
    end

    for i = 1, 30 do
        local line = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        line:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10 - ((i - 1) * 22))
        line:SetText("Sample setting row " .. i .. "  -  [ ] Example option with tooltip text")
    end

    scrollFrame:HookScript("OnVerticalScroll", UpdateCustomThumb)
    frame:HookScript("OnSizeChanged", function()
        UpdateScrollLayout()
        UpdateCustomThumb()
    end)

    UpdateScrollLayout()
    UpdateCustomThumb()

    -- Resize handle: right edge
    local resizeRight = CreateFrame("Button", nil, frame)
    resizeRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -90)
    resizeRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 90)
    resizeRight:SetWidth(12)
    resizeRight:SetScript("OnMouseDown", function()
        frame:StartSizing("RIGHT")
    end)
    resizeRight:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    -- Resize handle: bottom edge
    local resizeBottom = CreateFrame("Button", nil, frame)
    resizeBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 90, 0)
    resizeBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -90, 0)
    resizeBottom:SetHeight(12)
    resizeBottom:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOM")
    end)
    resizeBottom:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    -- Resize handle: bottom-right corner
    local resizeCorner = CreateFrame("Button", nil, frame)
    resizeCorner:SetSize(28, 28)
    resizeCorner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    resizeCorner:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeCorner:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeCorner:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeCorner:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resizeCorner:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    -- Temporary close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -24)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -46)
    title:SetText("OUS2 Art Test")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("CENTER")
    hint:SetText("Drag the frame. Use /ous2test to toggle.")

    if DEBUG_GRID then
        -- Coordinate grid overlay for positioning reference
    local gridStep = 25  -- grid line every 25px

    -- Vertical lines (left to right)
    for x = 0, 1050, gridStep do
        local line = frame:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 1, 0, 0.4)
        line:SetSize(1, 700)
        line:SetPoint("TOPLEFT", frame, "TOPLEFT", x, 0)

        if x > 0 then
            local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 2, -2)
            lbl:SetTextColor(1, 1, 0, 0.8)
            lbl:SetText(tostring(x))
        end
    end

    -- Horizontal lines (top to bottom)
    for y = 0, 700, gridStep do
        local line = frame:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 1, 0, 0.4)
        line:SetSize(1050, 1)
        line:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)

        if y > 0 then
            local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -y - 2)
            lbl:SetTextColor(1, 1, 0, 0.8)
            lbl:SetText(tostring(y))
        end
    end
    end

end

SLASH_OUS2ARTTEST1 = "/ous2test"
SlashCmdList["OUS2ARTTEST"] = CreateTestFrame