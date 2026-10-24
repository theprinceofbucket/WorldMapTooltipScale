-- World Map Tooltip Scale
-- Compatible with World of Warcraft: Wrath of the Lich King 3.3.5a (Interface 30300).

local addonName = "WorldMapTooltipScale"
local DEFAULT_SCALE = 0.60
local MIN_SCALE = 0.30
local MAX_SCALE = 1.50
local STEP = 0.05

local eventFrame = CreateFrame("Frame")
local optionsFrame
local scaleSlider
local valueText

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end

    return value
end

local function RoundToStep(value)
    return math.floor((value / STEP) + 0.5) * STEP
end

local function GetScale()
    if not WorldMapTooltipScaleDB or type(WorldMapTooltipScaleDB.scale) ~= "number" then
        return DEFAULT_SCALE
    end

    return Clamp(RoundToStep(WorldMapTooltipScaleDB.scale), MIN_SCALE, MAX_SCALE)
end

local function UpdateValueText(scale)
    if valueText then
        valueText:SetText(string.format("%d%%", math.floor((scale * 100) + 0.5)))
    end
end

local function ApplyScale()
    local scale = GetScale()

    if WorldMapTooltip then
        WorldMapTooltip:SetScale(scale)
    end

    return scale
end

local function SetScale(scale)
    scale = Clamp(RoundToStep(scale), MIN_SCALE, MAX_SCALE)
    WorldMapTooltipScaleDB.scale = scale
    ApplyScale()
    UpdateValueText(scale)

    if scaleSlider and math.abs(scaleSlider:GetValue() - scale) > 0.001 then
        scaleSlider:SetValue(scale)
    end
end

local function ToggleOptions()
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        local scale = ApplyScale()
        scaleSlider:SetValue(scale)
        UpdateValueText(scale)
        optionsFrame:Show()
    end
end

local function GetMinimapButtonPosition(angle)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    return x, y
end

local function PositionMinimapButton(button)
    local angle = WorldMapTooltipScaleDB.minimapAngle or 225
    local radians = math.rad(angle)
    local x, y = GetMinimapButtonPosition(radians)

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateMinimapButtonPosition(button)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetScale()
    local angle

    px = px / scale
    py = py / scale
    angle = math.deg(math.atan2(py - my, px - mx))

    WorldMapTooltipScaleDB.minimapAngle = angle
    PositionMinimapButton(button)
end

local function CreateOptionsFrame()
    optionsFrame = CreateFrame("Frame", "WorldMapTooltipScaleOptionsFrame", UIParent)
    optionsFrame:SetWidth(235)
    optionsFrame:SetHeight(115)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    optionsFrame:Hide()

    local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", optionsFrame, "TOP", 0, -18)
    title:SetText("WorldMapTooltip Skalierung")

    local closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -4, -4)

    scaleSlider = CreateFrame("Slider", "WorldMapTooltipScaleSlider", optionsFrame, "OptionsSliderTemplate")
    scaleSlider:SetWidth(155)
    scaleSlider:SetHeight(17)
    scaleSlider:SetPoint("CENTER", optionsFrame, "CENTER", -16, -4)
    scaleSlider:SetMinMaxValues(MIN_SCALE, MAX_SCALE)
    scaleSlider:SetValueStep(STEP)
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        if WorldMapTooltipScaleDB then
            SetScale(value)
        end
    end)

    _G[scaleSlider:GetName() .. "Low"]:SetText("30%")
    _G[scaleSlider:GetName() .. "High"]:SetText("150%")
    _G[scaleSlider:GetName() .. "Text"]:SetText("Tooltip-Größe")

    valueText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    valueText:SetPoint("LEFT", scaleSlider, "RIGHT", 12, 0)
    UpdateValueText(GetScale())
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "WorldMapTooltipScaleButton", Minimap)
    button:SetWidth(31)
    button:SetHeight(31)
    button:SetFrameStrata("MEDIUM")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(52)
    border:SetHeight(52)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    button:SetScript("OnClick", ToggleOptions)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(frame)
            UpdateMinimapButtonPosition(frame)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("WorldMapTooltip Skalierung")
        GameTooltip:AddLine("Linksklick: Skalierung einstellen", 1, 1, 1)
        GameTooltip:AddLine("Ziehen: Position ändern", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    PositionMinimapButton(button)
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(WorldMapTooltipScaleDB) ~= "table" then
            WorldMapTooltipScaleDB = {}
        end

        WorldMapTooltipScaleDB.scale = GetScale()
        CreateOptionsFrame()
        CreateMinimapButton()
        ApplyScale()
    elseif event == "PLAYER_LOGIN" then
        ApplyScale()
    elseif event == "ADDON_LOADED" then
        -- Some UI components are loaded after login; applying again is harmless.
        ApplyScale()
    end
end)
