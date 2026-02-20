local _, Addon = ...

local eventFrame = CreateFrame("Frame")
local hooksInstalled = false
local inButtonSideHook = false
local socialIconHooked = false
local SetEditBoxPosition

local function SetChatFrameClampState(chatFrame, clampToScreen)
    if not chatFrame or not chatFrame.SetClampedToScreen then
        return
    end

    chatFrame:SetClampedToScreen(clampToScreen and true or false)
end

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
    local hideActionBar = Addon:GetSetting("hideActionBar")
    local clampToScreen = Addon:GetSetting("clampToScreen")
    local moveInputAboveChat = Addon:GetSetting("moveInputAboveChat")
    if not hideActionBar and clampToScreen and not moveInputAboveChat then
        return
    end

    local index = chatFrame:GetID()
    if not index then
        return
    end

    local buttonFrame = _G["ChatFrame" .. index .. "ButtonFrame"]
    if hideActionBar and buttonFrame then
        -- Blizzard can reset layout during updates; enforce collapsed layout again.
        SetButtonFrameState(buttonFrame, chatFrame, true, true)
    end
    SetChatFrameClampState(chatFrame, clampToScreen)

    local editBox = _G["ChatFrame" .. index .. "EditBox"]
    SetEditBoxPosition(editBox, chatFrame, moveInputAboveChat)
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

local function SaveEditBoxAnchors(editBox)
    if not editBox or editBox._bcfSavedPoints then
        return
    end

    editBox._bcfSavedPoints = {}
    for i = 1, editBox:GetNumPoints() do
        local point, relativeTo, relativePoint, xOffset, yOffset = editBox:GetPoint(i)
        editBox._bcfSavedPoints[i] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOffset = xOffset,
            yOffset = yOffset,
        }
    end
end

local function RestoreEditBoxAnchors(editBox)
    if not editBox or not editBox._bcfSavedPoints then
        return
    end

    editBox:ClearAllPoints()
    for _, anchor in ipairs(editBox._bcfSavedPoints) do
        editBox:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.xOffset, anchor.yOffset)
    end
end

SetEditBoxPosition = function(editBox, chatFrame, moveAboveChat)
    if not editBox or not chatFrame then
        return
    end

    SaveEditBoxAnchors(editBox)

    if moveAboveChat then
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", -5, 18)
        editBox:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 8, 18)
        return
    end

    RestoreEditBoxAnchors(editBox)
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
    local clampToScreen = Addon:GetSetting("clampToScreen")
    local moveInputAboveChat = Addon:GetSetting("moveInputAboveChat")
    local hideSocialIcon = Addon:GetSetting("hideSocialIcon")
    local hideTabBackground = Addon:GetSetting("hideTabBackground")
    local inputBoxOpacity = ClampOpacity(Addon:GetSetting("inputBoxOpacity"))

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
        SetButtonFrameState(buttonFrame, chatFrame, hideActionBar, false)
        SetChatFrameClampState(chatFrame, clampToScreen)

        local tab = _G["ChatFrame" .. i .. "Tab"]
        SetTabBackgroundHidden(tab, hideTabBackground)

        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        SetEditBoxPosition(editBox, chatFrame, moveInputAboveChat)
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

    hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
        if not editBox or not editBox.chatFrame then
            return
        end
        SetEditBoxPosition(editBox, editBox.chatFrame, Addon:GetSetting("moveInputAboveChat"))
    end)

    if not hooksInstalled then
        hooksecurefunc("FCF_UpdateButtonSide", function(chatFrame)
            inButtonSideHook = true
            ReapplyHiddenLayoutIfNeeded(chatFrame)
            inButtonSideHook = false
        end)

        hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(chatFrame)
            ReapplyHiddenLayoutIfNeeded(chatFrame)
        end)

        hooksecurefunc("FCF_DockFrame", function(chatFrame)
            ReapplyHiddenLayoutIfNeeded(chatFrame)
        end)

        hooksecurefunc("FCF_UnDockFrame", function(chatFrame)
            ReapplyHiddenLayoutIfNeeded(chatFrame)
        end)

        hooksInstalled = true
    end

    Addon:ApplyChatUISettings()
end
