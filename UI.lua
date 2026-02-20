local _, Addon = ...

local eventFrame = CreateFrame("Frame")
local hooksInstalled = false
local inButtonSideHook = false
local socialIconHooked = false

local function ClampOpacity(value)
    if type(value) ~= "number" then
        return 1.0
    end
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function SetButtonFrameState(buttonFrame, chatFrame, shouldHide, skipButtonSideUpdate)
    if not buttonFrame then
        return
    end

    if shouldHide then
        if buttonFrame._bcfPrevAlpha == nil then
            buttonFrame._bcfPrevAlpha = buttonFrame:GetAlpha()
        end
        if buttonFrame.Background and buttonFrame._bcfPrevBgAlpha == nil then
            buttonFrame._bcfPrevBgAlpha = buttonFrame.Background:GetAlpha()
        end
        if buttonFrame._bcfPrevWidth == nil then
            buttonFrame._bcfPrevWidth = buttonFrame:GetWidth()
        end

        if not buttonFrame._bcfShowHooked then
            hooksecurefunc(buttonFrame, "Show", function(self)
                if Addon:GetSetting("hideActionBar") then
                    self:Hide()
                end
            end)
            buttonFrame._bcfShowHooked = true
        end

        buttonFrame:SetWidth(1)
        buttonFrame:SetAlpha(0)
        buttonFrame:EnableMouse(false)
        buttonFrame:Hide()

        if buttonFrame.Background then
            buttonFrame.Background:SetAlpha(0)
        end

        if not skipButtonSideUpdate and FCF_UpdateButtonSide and chatFrame and not inButtonSideHook then
            FCF_UpdateButtonSide(chatFrame)
        end
        return
    end

    if buttonFrame._bcfPrevWidth ~= nil then
        buttonFrame:SetWidth(buttonFrame._bcfPrevWidth)
    end
    if buttonFrame._bcfPrevAlpha ~= nil then
        buttonFrame:SetAlpha(buttonFrame._bcfPrevAlpha)
    end
    buttonFrame:EnableMouse(true)
    if buttonFrame.Background then
        if buttonFrame._bcfPrevBgAlpha ~= nil then
            buttonFrame.Background:SetAlpha(buttonFrame._bcfPrevBgAlpha)
        end
    end

    buttonFrame:Show()

    if not skipButtonSideUpdate and FCF_UpdateButtonSide and chatFrame and not inButtonSideHook then
        FCF_UpdateButtonSide(chatFrame)
    end
end

local function ReapplyHiddenLayoutIfNeeded(chatFrame)
    if not chatFrame or not chatFrame.GetName then
        return
    end
    if not Addon:GetSetting("hideActionBar") then
        return
    end

    local index = chatFrame:GetID()
    if not index then
        return
    end

    local buttonFrame = _G["ChatFrame" .. index .. "ButtonFrame"]
    if not buttonFrame then
        return
    end

    -- Blizzard can reset layout during updates; enforce collapsed layout again.
    SetButtonFrameState(buttonFrame, chatFrame, true, true)
end

local function SetEditBoxTextureAlpha(editBox, alpha)
    if not editBox then
        return
    end

    local regions = { editBox:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(alpha)
        end
    end
end

local function SetTabBackgroundHidden(tab, hideBackground)
    if not tab then
        return
    end

    local regions = { tab:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            if hideBackground then
                if region._bcfPrevAlpha == nil then
                    region._bcfPrevAlpha = region:GetAlpha()
                end
                region:SetAlpha(0)
            else
                if region._bcfPrevAlpha ~= nil then
                    region:SetAlpha(region._bcfPrevAlpha)
                    region._bcfPrevAlpha = nil
                end
            end
        end
    end
end

local function SetSocialIconHidden(hideSocialIcon)
    local socialButton = _G.QuickJoinToastButton
    if not socialButton then
        return
    end

    if hideSocialIcon then
        if not socialIconHooked then
            hooksecurefunc(socialButton, "Show", function(self)
                if Addon:GetSetting("hideSocialIcon") then
                    self:Hide()
                end
            end)
            socialIconHooked = true
        end

        if socialButton._bcfPrevAlpha == nil then
            socialButton._bcfPrevAlpha = socialButton:GetAlpha()
        end
        socialButton:SetAlpha(0)
        socialButton:EnableMouse(false)
        socialButton:Hide()
        return
    end

    if socialButton._bcfPrevAlpha ~= nil then
        socialButton:SetAlpha(socialButton._bcfPrevAlpha)
    end
    socialButton:EnableMouse(true)
    socialButton:Show()
end

function Addon:ApplyChatUISettings()
    local hideActionBar = Addon:GetSetting("hideActionBar")
    local hideSocialIcon = Addon:GetSetting("hideSocialIcon")
    local hideTabBackground = Addon:GetSetting("hideTabBackground")
    local inputBoxOpacity = ClampOpacity(Addon:GetSetting("inputBoxOpacity"))

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
        SetButtonFrameState(buttonFrame, chatFrame, hideActionBar, false)

        local tab = _G["ChatFrame" .. i .. "Tab"]
        SetTabBackgroundHidden(tab, hideTabBackground)

        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        SetEditBoxTextureAlpha(editBox, inputBoxOpacity)
    end

    SetSocialIconHidden(hideSocialIcon)
end

function Addon:HookChatUI()
    eventFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function()
        C_Timer.After(0, function()
            Addon:ApplyChatUISettings()
        end)
    end)

    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        C_Timer.After(0, function()
            Addon:ApplyChatUISettings()
        end)
    end)

    if not hooksInstalled then
        hooksecurefunc("FCF_UpdateButtonSide", function(chatFrame)
            inButtonSideHook = true
            ReapplyHiddenLayoutIfNeeded(chatFrame)
            inButtonSideHook = false
        end)
        hooksInstalled = true
    end

    Addon:ApplyChatUISettings()
end
