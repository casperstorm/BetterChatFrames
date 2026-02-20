local _, Addon = ...

local LINK_TYPE = "bcfurl"
local POPUP_ID = "BETTER_CHAT_FRAMES_URL"

local chatEvents = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
}

local fullPatterns = {
    "^%a[%w+.-]+://[%w%-%._~:/%?#%[%]@!$&'()*+,;%%=]+$",
    "^www%.[%w%-%._~:/%?#%[%]@!$&'()*+,;%%=]+$",
    "^[%w._%%+%-]+@[%w.%-]+%.[A-Za-z][A-Za-z]+$",
}

local hooksInstalled = false

local function StripTrailingPunctuation(value)
    local trimmed, trailing = value:match("^(.-)([%.%,%!%?%)%]]+)$")
    if trimmed and trimmed ~= "" then
        return trimmed, trailing
    end
    return value, ""
end

local function NormalizeLinkTarget(value)
    if value:find("^%a[%w+.-]+://") then
        return value
    end

    if value:find("@", 1, true) then
        return "mailto:" .. value
    end

    if value:find("^www%.") then
        return "https://" .. value
    end

    return value
end

local function BuildLink(displayValue, targetValue)
    local showBrackets = Addon:GetSetting("showBrackets")
    local color = Addon:GetSetting("linkColor") or "66ccff"
    local label = showBrackets and ("[" .. displayValue .. "]") or displayValue
    local safeTarget = targetValue:gsub("|", "")
    return ("|H%s:%s|h|cff%s%s|r|h"):format(LINK_TYPE, safeTarget, color, label)
end

local function ReplaceUrls(message)
    if type(message) ~= "string" or message == "" then
        return message, false
    end

    if message:find("|H", 1, true) then
        return message, false
    end

    local changed = false
    local result = message:gsub("%S+", function(token)
        local core, trailing = StripTrailingPunctuation(token)
        if core == "" then
            return token
        end

        for _, pattern in ipairs(fullPatterns) do
            if core:match(pattern) then
                changed = true
                return BuildLink(core, NormalizeLinkTarget(core)) .. trailing
            end
        end

        return token
    end)

    return result, changed
end

local function EnsurePopupDialog()
    if StaticPopupDialogs[POPUP_ID] then
        return
    end

    StaticPopupDialogs[POPUP_ID] = {
        text = "Copy URL",
        button1 = CLOSE,
        hasEditBox = true,
        hasWideEditBox = true,
        editBoxWidth = 320,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(dialog)
            dialog:SetWidth(420)
            local editBox = _G[dialog:GetName() .. "WideEditBox"] or _G[dialog:GetName() .. "EditBox"]
            if not editBox then
                return
            end
            editBox:SetText(dialog.urlValue or "")
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        EditBoxOnEscapePressed = function(editBox)
            editBox:GetParent():Hide()
        end,
        OnAccept = function() end,
    }
end

local function ShowUrl(url)
    EnsurePopupDialog()
    local dialog = StaticPopup_Show(POPUP_ID)
    if not dialog then
        return
    end

    dialog.urlValue = url
    local editBox = _G[dialog:GetName() .. "WideEditBox"] or _G[dialog:GetName() .. "EditBox"]
    if editBox then
        editBox:SetText(url)
        editBox:SetFocus()
        editBox:HighlightText()
    end
end

local function OnSetItemRef(link)
    local linkType, value = link:match("^([^:]+):(.+)$")
    if linkType ~= LINK_TYPE or not value then
        return
    end
    ShowUrl(value)
end

local function ChatFilter(_, _, message, ...)
    local output, changed = ReplaceUrls(message)
    if not changed then
        return false, message, ...
    end
    return false, output, ...
end

function Addon:HookURLs()
    if hooksInstalled then
        return
    end

    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, ChatFilter)
    end

    hooksecurefunc("SetItemRef", OnSetItemRef)
    hooksInstalled = true
end
