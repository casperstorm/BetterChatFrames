local _, Addon = ...

local configFrame = nil

local function HexToRGB(hex)
    if type(hex) ~= "string" or hex:len() ~= 6 then
        return 0.4, 0.8, 1.0
    end

    local r = tonumber(hex:sub(1, 2), 16) or 102
    local g = tonumber(hex:sub(3, 4), 16) or 204
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return r / 255, g / 255, b / 255
end

local function RGBToHex(r, g, b)
    r = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
    g = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
    b = math.floor(math.max(0, math.min(1, b)) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

local function CreateCheckbox(parent, label, dbKey, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.Text:SetText(label)
    checkbox.Text:SetFontObject("GameFontNormal")

    checkbox:SetChecked(Addon:GetSetting(dbKey))
    checkbox:SetScript("OnClick", function(self)
        Addon:SetSetting(dbKey, self:GetChecked())
        if onClick then
            onClick(self:GetChecked())
        end
    end)

    return checkbox
end

local function CreateEditBox(parent, label, dbKey, width)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 320, 42)

    local text = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", 6, 0)
    text:SetText(label)

    local editBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetSize((width or 320) - 12, 24)
    editBox:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -2, -6)
    editBox:SetText(Addon:GetSetting(dbKey) or "")
    editBox:SetCursorPosition(0)

    local function SaveValue()
        local value = editBox:GetText()
        if value == nil or value == "" then
            value = "[%H:%M:%S]"
            editBox:SetText(value)
        end
        Addon:SetSetting(dbKey, value)
    end

    editBox:SetScript("OnEnterPressed", function(self)
        SaveValue()
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(Addon:GetSetting(dbKey) or "[%H:%M:%S]")
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusLost", SaveValue)

    container.editBox = editBox
    return container
end

local function CreateSlider(parent, label, dbKey, minVal, maxVal, step, yOffset, onChange, isPercent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 0, yOffset)
    container:SetPoint("TOPRIGHT", 0, yOffset)
    container:SetHeight(32)

    local currentValue = Addon:GetSetting(dbKey)
    if type(currentValue) ~= "number" then
        currentValue = minVal
    end

    local function FormatValue(val)
        if isPercent then
            return string.format("%d%%", math.floor(val * 100 + 0.5))
        end
        return tostring(math.floor(val + 0.5))
    end

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetWidth(170)
    labelText:SetJustifyH("LEFT")
    labelText:SetText(label)

    local sliderFrame = CreateFrame("Frame", nil, container, "MinimalSliderWithSteppersTemplate")
    sliderFrame:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
    sliderFrame:SetPoint("RIGHT", -40, 0)
    sliderFrame:SetHeight(16)

    local steps = math.floor((maxVal - minVal) / step + 0.5)

    local formatters = {}
    formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        function(val) return FormatValue(val) end
    )

    sliderFrame.initInProgress = true
    sliderFrame:Init(currentValue, minVal, maxVal, steps, formatters)

    if sliderFrame.MinText then sliderFrame.MinText:Hide() end
    if sliderFrame.MaxText then sliderFrame.MaxText:Hide() end

    sliderFrame.initInProgress = false

    if sliderFrame.Slider then
        sliderFrame.Slider:HookScript("OnValueChanged", function(self, value)
            if not sliderFrame.initInProgress then
                value = math.floor(value / step + 0.5) * step
                Addon:SetSetting(dbKey, value)
                if onChange then onChange(value) end
            end
        end)
    end

    return container
end

local function CreateColorSwatchButton(parent, dbKey)
    local swatchButton = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatchButton:SetSize(28, 18)
    swatchButton:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local function SetColor(r, g, b)
        local hex = RGBToHex(r, g, b)
        Addon:SetSetting(dbKey, hex)
        swatchButton:SetBackdropColor(r, g, b, 1)
    end

    local initial = Addon:GetSetting(dbKey) or "66ccff"
    local r, g, b = HexToRGB(initial)
    swatchButton:SetBackdropColor(r, g, b, 1)

    swatchButton:SetScript("OnClick", function()
        local current = Addon:GetSetting(dbKey) or "66ccff"
        local currentR, currentG, currentB = HexToRGB(current)

        local info = {
            r = currentR,
            g = currentG,
            b = currentB,
            hasOpacity = false,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                SetColor(newR, newG, newB)
            end,
            cancelFunc = function(previousValues)
                if previousValues then
                    SetColor(previousValues.r, previousValues.g, previousValues.b)
                end
            end,
        }

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    return swatchButton
end

local function CreateConfigFrame()
    local frame = CreateFrame("Frame", "BetterChatFramesConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 395)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)

    frame.TitleText:SetText("Better Chat Frames")

    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    tinsert(UISpecialFrames, "BetterChatFramesConfigFrame")

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", frame.InsetBg, "BOTTOMRIGHT", -20, 10)

    local y = 0

    local hideActionBarCheckbox = CreateCheckbox(content, "Hide chat action bar", "hideActionBar")
    hideActionBarCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    y = y - 35

    local hideSocialIconCheckbox = CreateCheckbox(content, "Hide social icon", "hideSocialIcon")
    hideSocialIconCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    y = y - 35

    local hideTabBackgroundCheckbox = CreateCheckbox(content, "Hide chat tab background/border", "hideTabBackground")
    hideTabBackgroundCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    y = y - 35

    CreateSlider(
        content,
        "Input box frame opacity",
        "inputBoxOpacity",
        0,
        1,
        0.05,
        y,
        function()
            if Addon.ApplyChatUISettings then
                Addon:ApplyChatUISettings()
            end
        end,
        true
    )

    y = y - 35

    local showBracketsCheckbox = CreateCheckbox(content, "Show URL brackets [ ]", "showBrackets")
    showBracketsCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    y = y - 35

    local urlColorCheckbox = CreateFrame("Frame", nil, content)
    urlColorCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    urlColorCheckbox:SetSize(300, 24)

    local colorLabel = urlColorCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("LEFT", 6, 0)
    colorLabel:SetText("URL Link Color")

    local colorSwatch = CreateColorSwatchButton(urlColorCheckbox, "linkColor")
    colorSwatch:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)

    y = y - 35

    local timestampCheckbox = CreateCheckbox(content, "Customize timestamps", "timestampEnabled")
    timestampCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    y = y - 40

    local timestampFormatEdit = CreateEditBox(content, "Timestamp Format (strftime)", "timestampFormat", 340)
    timestampFormatEdit:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)

    local previewText = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    previewText:SetPoint("TOPLEFT", timestampFormatEdit, "BOTTOMLEFT", 6, -4)
    previewText:SetText("Examples: [%H:%M], [%I:%M:%S %p], %H:%M:%S")

    return frame
end

function Addon:OpenConfig()
    if not configFrame then
        configFrame = CreateConfigFrame()
        configFrame:Show()
        return
    end

    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end
