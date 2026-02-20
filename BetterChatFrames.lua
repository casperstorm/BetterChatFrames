local addonName, Addon = ...

local defaults = {
    showBrackets = true,
    linkColor = "66ccff",
    timestampEnabled = true,
    timestampFormat = "[%H:%M:%S]",
    hideActionBar = false,
    hideSocialIcon = false,
    hideTabBackground = false,
    inputBoxOpacity = 1.0,
}

local function InitializeDB()
    if not BetterChatFramesDB then
        BetterChatFramesDB = {}
    end

    for key, value in pairs(defaults) do
        if BetterChatFramesDB[key] == nil then
            BetterChatFramesDB[key] = value
        end
    end
end

function Addon:GetSetting(key)
    return BetterChatFramesDB and BetterChatFramesDB[key]
end

function Addon:SetSetting(key, value)
    if not BetterChatFramesDB then
        BetterChatFramesDB = {}
    end
    BetterChatFramesDB[key] = value

    if (key == "timestampEnabled" or key == "timestampFormat") and Addon.ApplyTimestampSettings then
        Addon:ApplyTimestampSettings()
    end

    if (key == "hideActionBar" or key == "hideSocialIcon" or key == "hideTabBackground" or key == "inputBoxOpacity") and Addon.ApplyChatUISettings then
        Addon:ApplyChatUISettings()
    end
end

local function RegisterOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "BetterChatFrames"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("BetterChatFrames")

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(150, 24)
    openBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    openBtn:SetText("Open Settings")
    openBtn:SetScript("OnClick", function()
        HideUIPanel(SettingsPanel)
        Addon:OpenConfig()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitializeDB()
        RegisterOptionsPanel()
    elseif event == "PLAYER_LOGIN" and Addon.HookURLs then
        Addon:HookURLs()
        if Addon.HookTimestamps then
            Addon:HookTimestamps()
        end
        if Addon.HookChatUI then
            Addon:HookChatUI()
        end
    end
end)

SLASH_BETTERCHATFRAMES1 = "/bcf"
SLASH_BETTERCHATFRAMES2 = "/betterchatframes"

SlashCmdList["BETTERCHATFRAMES"] = function()
    Addon:OpenConfig()
end
