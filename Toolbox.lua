-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : Toolbox.lua
-- Version : 2026.05.29
-- Desc    : Floating icon toolbar engine — toggleable module shortcuts
-- ============================================================

local addonName, OUS = ...

-- ==========================================
-- Toolbox — floating icon bar, one button per openable panel
-- ==========================================

local db        -- reference to OdysseusDB.toolbox, set on init
local frame
local dragHandle
local opPopup
local opPopupButtonIndex  -- pool index of the Openables button, set during layout

local BUTTON_SIZE   = 32
local BUTTON_PAD    = 4
local FRAME_PADDING = 6

local buttonPool = {}  -- declared before BUTTONS so action closures can close over it

-- key = module DB key (nil = always visible)
-- icon = texture path
-- tooltip = GameTooltip label
-- action = function called on click
local BUTTONS = {
    {
        key     = nil,
        icon    = "Interface\\AddOns\\OdysseusUtilitySuite\\media\\icon\\OUS_icon_128.tga",
        tooltip = "Odysseus Config",
        action  = function()
            if not OUS.ConfigFrame then return end
            if OUS.ConfigFrame:IsShown()
                and (OUS.ConfigFrame.currentNavTab == "General") then
                OUS.ConfigFrame:Hide()
            else
                OUS.ConfigFrame:Show()
                if OUS.ConfigFrame.ShowTab then OUS.ConfigFrame.ShowTab("General") end
            end
        end,
    },
    {
        key     = "xpBar",
        icon    = "Interface\\Icons\\inv_misc_note_01",
        tooltip = "XP Bar Stats",
        action  = function()
            if OUS.statsFrame then
                if OUS.statsFrame:IsShown() then
                    OUS.statsFrame:Hide()
                else
                    OUS.statsFrame:UpdateData()
                    OUS.statsFrame:Show()
                end
            end
        end,
    },
    {
        key     = "flightMaster",
        icon    = "Interface\\Icons\\ability_vehicle_rocketbooster",
        tooltip = "Flight Master Settings",
        action  = function()
            if not OUS.ConfigFrame then return end
            if OUS.ConfigFrame:IsShown()
                and (OUS.ConfigFrame.currentNavTab == "FlightMaster") then
                OUS.ConfigFrame:Hide()
            else
                OUS.ConfigFrame:Show()
                if OUS.ConfigFrame.ShowTab then OUS.ConfigFrame.ShowTab("FlightMaster") end
            end
        end,
    },
    {
        key     = "fishingTracker",
        icon    = "Interface\\Icons\\inv_fishingpole_02",
        tooltip = "Fishing Tracker",
        action  = function()
            if OUS.ToggleFishingTracker then OUS.ToggleFishingTracker() end
        end,
    },
    {
        key     = "autoRemount",
        icon    = "Interface\\Icons\\ability_mount_ridinghorse",
        tooltip = "Auto Remount Settings",
        action  = function()
            if not OUS.ConfigFrame then return end
            if OUS.ConfigFrame:IsShown()
                and (OUS.ConfigFrame.currentNavTab == "AutoRemount") then
                OUS.ConfigFrame:Hide()
            else
                OUS.ConfigFrame:Show()
                if OUS.ConfigFrame.ShowTab then OUS.ConfigFrame.ShowTab("AutoRemount") end
            end
        end,
    },
    {
        key     = "statsBar",
        icon    = "Interface\\Icons\\inv_misc_paperbundle04a",
        tooltip = "Stats Bar Toggle",
        action  = function()
            local charDB = OdysseusCharDB and OdysseusCharDB.statsBar
            if not charDB then return end
            if charDB.tableEnabled then
                -- Table mode: toggle the table frame directly, preserve mode
                local stFrame = _G["OdysseusStatsTableFrame"]
                if stFrame then
                    if stFrame:IsShown() then stFrame:Hide() else stFrame:Show() end
                end
            else
                -- Single-line mode: toggle the bar frame directly
                local sbFrame = _G["OdysseusStatsBarFrame"]
                if sbFrame then
                    if sbFrame:IsShown() then sbFrame:Hide() else sbFrame:Show() end
                end
            end
        end,
    },
    {
        key     = "openables",
        icon    = "Interface\\Icons\\inv_misc_bag_10_blue",
        tooltip = "Openables",
        action  = function()
            if not opPopup then return end
            if opPopup:IsShown() then
                opPopup:Hide()
                return
            end

            local btn = buttonPool[opPopupButtonIndex]
            if not btn then return end

            -- Anchor based on bar orientation, not just raw space
            local scale   = btn:GetEffectiveScale()
            local uiScale = UIParent:GetEffectiveScale()
            local bLeft   = btn:GetLeft()   * scale / uiScale
            local bBottom = btn:GetBottom() * scale / uiScale
            local bRight  = bLeft + btn:GetWidth()  * scale / uiScale
            local bTop    = bBottom + btn:GetHeight() * scale / uiScale

            local scrW = UIParent:GetWidth()
            local scrH = UIParent:GetHeight()

            local popW = opPopup:GetWidth()  * scale / uiScale
            local popH = opPopup:GetHeight() * scale / uiScale

            opPopup:ClearAllPoints()

            local vertical = db and (db.direction == "vertical")

            if vertical then
                -- Vertical bar: popup goes left or right of the bar
                -- Anchor top-aligned by default, but flip to bottom-aligned if it overflows
                local spaceRight  = scrW - bRight
                local spaceBottom = bBottom  -- pixels below the button's bottom edge

                local vAnchor, vRelAnchor
                if spaceBottom >= popH then
                    vAnchor = "TOPLEFT";    vRelAnchor = "TOPRIGHT"
                else
                    vAnchor = "BOTTOMLEFT"; vRelAnchor = "BOTTOMRIGHT"
                end

                if spaceRight >= popW then
                    opPopup:SetPoint(vAnchor, btn, vRelAnchor, 4, 0)
                else
                    -- flip horizontal anchors for left side
                    local lAnchor    = vAnchor:gsub("LEFT", "RIGHT")
                    local lRelAnchor = vRelAnchor:gsub("RIGHT", "LEFT")
                    opPopup:SetPoint(lAnchor, btn, lRelAnchor, -4, 0)
                end
            else
                -- Horizontal bar: prefer above, fall back to below
                local spaceAbove = scrH - bTop
                if spaceAbove >= popH then
                    opPopup:SetPoint("BOTTOM", btn, "TOP", 0, 4)
                else
                    opPopup:SetPoint("TOP", btn, "BOTTOM", 0, -4)
                end
            end

            opPopup:Show()
        end,
    },
}

-- ==========================================
-- Helpers
-- ==========================================

local function IsButtonVisible(entry)
    if not entry.key then return true end
    return OdysseusDB.modules[entry.key] ~= false
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point    = point
    db.relPoint = relPoint
    db.x        = x
    db.y        = y
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(db.point or "CENTER", UIParent, db.relPoint or "CENTER", db.x or 0, db.y or 0)
end

-- ==========================================
-- Button pool & layout
-- ==========================================

local function GetOrCreateButton(index)
    if buttonPool[index] then return buttonPool[index] end

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-Quickslot2", edgeFile = "Interface\\Buttons\\UI-Quickslot-Depress", edgeSize = 4 })

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = tex

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    btn:SetHighlightTexture(hl)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.tooltipText or "", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    buttonPool[index] = btn
    return btn
end

local function LayoutButtons()
    local vertical = (db.direction == "vertical")

    local visible = {}
    for _, entry in ipairs(BUTTONS) do
        if IsButtonVisible(entry) then
            visible[#visible + 1] = entry
        end
    end

    local count = #visible
    local w, h
    if vertical then
        w = FRAME_PADDING * 2 + BUTTON_SIZE
        h = FRAME_PADDING * 2 + count * BUTTON_SIZE + math.max(0, count - 1) * BUTTON_PAD
    else
        w = FRAME_PADDING * 2 + count * BUTTON_SIZE + math.max(0, count - 1) * BUTTON_PAD
        h = FRAME_PADDING * 2 + BUTTON_SIZE
    end

    frame:SetSize(w > 0 and w or 1, h > 0 and h or 1)

    for _, btn in ipairs(buttonPool) do btn:Hide() end

    for i, entry in ipairs(visible) do
        local btn = GetOrCreateButton(i)
        btn.tooltipText = entry.tooltip
        btn.icon:SetTexture(entry.icon)
        btn:SetScript("OnClick", entry.action)
        btn:ClearAllPoints()

        local offset = FRAME_PADDING + (i - 1) * (BUTTON_SIZE + BUTTON_PAD)
        if vertical then
            btn:SetPoint("TOP", frame, "TOP", 0, -offset)
        else
            btn:SetPoint("LEFT", frame, "LEFT", offset, 0)
        end

        btn:Show()

        -- Track which pool slot the Openables button lands in
        if entry.key == "openables" then opPopupButtonIndex = i end
    end

    -- Keep drag handle covering the full frame after resize
    if dragHandle then dragHandle:SetAllPoints(frame) end
end

-- ==========================================
-- Openables quick-action popup
-- ==========================================

local OP_POPUP_ENTRIES = {
    { label = "Mass Add",     cmd = "madd"  },
    { label = "Custom List",  cmd = "clist" },
    { label = "Blacklist",    cmd = "list"  },
}
local OP_BTN_W, OP_BTN_H, OP_BTN_PAD = 80, 22, 0

local function CreateOpPopup()
    local totalH = #OP_POPUP_ENTRIES * (OP_BTN_H + OP_BTN_PAD) - OP_BTN_PAD

    -- Invisible container — just for anchoring and UISpecialFrames
    opPopup = CreateFrame("Frame", "OUSToolboxOpPopup", UIParent)
    opPopup:SetSize(OP_BTN_W, totalH)
    opPopup:SetFrameStrata("HIGH")
    opPopup:SetFrameLevel(20)
    opPopup:Hide()
    tinsert(UISpecialFrames, opPopup:GetName())

    for i, entry in ipairs(OP_POPUP_ENTRIES) do
        local btn = CreateFrame("Button", nil, opPopup, "BackdropTemplate")
        btn:SetSize(OP_BTN_W, OP_BTN_H)
        btn:SetPoint("TOP", opPopup, "TOP", 0, -(i - 1) * (OP_BTN_H + OP_BTN_PAD))
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile     = false,
            edgeSize = 1,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.13, 0.13, 0.16, 0.94)
        btn:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)

        local base = btn:CreateTexture(nil, "BACKGROUND")
        base:SetPoint("TOPLEFT", 1, -1)
        base:SetPoint("BOTTOMRIGHT", -1, 1)
        base:SetColorTexture(0.13, 0.13, 0.16, 0.94)

        local sheen = btn:CreateTexture(nil, "ARTWORK")
        sheen:SetPoint("TOPLEFT", 1, -1)
        sheen:SetPoint("TOPRIGHT", -1, -1)
        sheen:SetHeight(10)
        sheen:SetTexture("Interface\\Buttons\\WHITE8x8")
        sheen:SetGradient("VERTICAL",
            CreateColor(0.90, 0.90, 0.96, 0.12),
            CreateColor(0.55, 0.55, 0.62, 0.01))

        local accent = btn:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT", 1, -1)
        accent:SetPoint("BOTTOMLEFT", 1, 1)
        accent:SetWidth(3)
        accent:SetColorTexture(0.58, 0.45, 0.78, 0.90)
        accent:Hide()

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        label:SetPoint("CENTER", btn, "CENTER", 4, 0)
        label:SetText(entry.label)
        label:SetTextColor(0.82, 0.82, 0.88)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.16, 0.16, 0.20, 0.97)
            self:SetBackdropBorderColor(0.48, 0.48, 0.56, 1)
            base:SetColorTexture(0.16, 0.16, 0.20, 0.97)
            accent:Show()
            label:SetTextColor(0.96, 0.94, 0.98)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.13, 0.13, 0.16, 0.94)
            self:SetBackdropBorderColor(0.30, 0.30, 0.36, 1)
            base:SetColorTexture(0.13, 0.13, 0.16, 0.94)
            accent:Hide()
            label:SetTextColor(0.82, 0.82, 0.88)
        end)
        btn:SetScript("OnMouseDown", function(self)
            self:SetBackdropColor(0.09, 0.09, 0.12, 0.99)
            base:SetColorTexture(0.09, 0.09, 0.12, 0.99)
        end)
        btn:SetScript("OnMouseUp", function(self)
            self:SetBackdropColor(0.13, 0.13, 0.16, 0.94)
            base:SetColorTexture(0.13, 0.13, 0.16, 0.94)
        end)

        local cmd = entry.cmd
        btn:SetScript("OnClick", function()
            opPopup:Hide()
            if OUS.Openables and OUS.Openables.SlashHandler then
                OUS.Openables.SlashHandler(cmd)
            end
        end)
    end
end

local function CreateDragHandle()
    dragHandle = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dragHandle:SetAllPoints(frame)
    dragHandle:SetFrameLevel(frame:GetFrameLevel() + 10)
    dragHandle:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    dragHandle:SetBackdropColor(0.1, 0.05, 0.2, 0.85)
    dragHandle:SetBackdropBorderColor(0.8, 0.5, 1.0, 1)

    local cross = dragHandle:CreateTexture(nil, "ARTWORK")
    cross:SetSize(20, 20)
    cross:SetPoint("CENTER")
    cross:SetTexture("Interface\\Cursor\\UI-Cursor-Move")

    local label = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", dragHandle, "BOTTOM", 0, 4)
    label:SetText("|cFFAA88FFDrag to move|r")

    dragHandle:EnableMouse(true)

    dragHandle:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then frame:StartMoving() end
    end)
    dragHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)

    dragHandle:Hide()
end

-- ==========================================
-- Lock / unlock
-- ==========================================

local function SetLocked(locked)
    db.locked = locked
    if locked then
        frame:SetMovable(false)
        for _, btn in ipairs(buttonPool) do btn:EnableMouse(true) end
        if dragHandle then dragHandle:Hide() end
    else
        frame:SetMovable(true)
        for _, btn in ipairs(buttonPool) do btn:EnableMouse(false) end
        if dragHandle then dragHandle:Show() end
    end
end

-- ==========================================
-- Public API
-- ==========================================

function OUS.ToggleToolbox()
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        LayoutButtons()
        frame:Show()
    end
end

function OUS.LockToolbox(locked)
    if not frame then return end
    SetLocked(locked)
end

function OUS.RefreshToolbox()
    if frame and frame:IsShown() then LayoutButtons() end
end

local function ApplyScale(scale)
    db.scale = scale
    if frame then frame:SetScale(scale) end
end

local function ApplyDirection(dir)
    db.direction = dir
    if frame then LayoutButtons() end
end

-- ==========================================
-- Slash handler  /tb  /toolbox
-- ==========================================
OUS.Toolbox = {}

function OUS.Toolbox.SlashHandler(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()

    if cmd == "scale" then
        local val = tonumber(arg)
        if val and val >= 0.5 and val <= 2.0 then
            local old = db.scale or 1.0
            ApplyScale(val)
            print(string.format("|cFF00CCFFOdysseus Toolbox:|r Scale set to %.2f (was %.2f)", val, old))
        else
            print(string.format("|cFF00CCFFOdysseus Toolbox:|r Usage: /tb scale [0.5-2.0]  (current: %.2f)", db.scale or 1.0))
        end
    elseif cmd == "lock" then
        OUS.LockToolbox(true)
        print("|cFF00CCFFOdysseus Toolbox:|r Locked.")
    elseif cmd == "unlock" then
        OUS.LockToolbox(false)
        print("|cFF00CCFFOdysseus Toolbox:|r Unlocked — drag handle active.")
    elseif cmd == "ver" or cmd == "vertical" then
        ApplyDirection("vertical")
        print("|cFF00CCFFOdysseus Toolbox:|r Layout → Vertical.")
    elseif cmd == "hor" or cmd == "horizontal" then
        ApplyDirection("horizontal")
        print("|cFF00CCFFOdysseus Toolbox:|r Layout → Horizontal.")
    elseif cmd == "toggle" then
        OUS.ToggleToolbox()
    else
        print("|cFF00CCFFOdysseus Toolbox:|r Commands:")
        print("  /tb toggle — Show/hide toolbox")
        print("  /tb lock / unlock — Lock or unlock position")
        print(string.format("  /tb scale [0.5-2.0] — Set icon scale  (current: %.2f)", db and db.scale or 1.0))
        print("  /tb ver / hor — Vertical or horizontal layout")
    end
end

-- ==========================================
-- Init
-- ==========================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    db = OdysseusDB.toolbox

    if not OdysseusDB.modules.toolbox then return end

    frame = CreateFrame("Frame", "OUSToolboxFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\UI-Quickslot2",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.85)
    frame:SetBackdropBorderColor(0.4, 0.35, 0.6, 0.9)
    frame:SetClampedToScreen(true)

    CreateDragHandle()
    CreateOpPopup()
    ApplyPosition()
    LayoutButtons()
    SetLocked(db.locked)
    if db.scale then frame:SetScale(db.scale) end

    if db.shown then frame:Show() else frame:Hide() end

    frame:SetScript("OnHide", function() db.shown = false end)
    frame:SetScript("OnShow",  function() db.shown = true  end)

    OUS.LogDebug("Toolbox", "Initialized")
end)
