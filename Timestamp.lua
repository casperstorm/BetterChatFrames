local _, Addon = ...

local savedBlizzardTimestampFormat = nil

local function GetSafeFormat()
    local format = Addon:GetSetting("timestampFormat")
    if type(format) ~= "string" or format == "" then
        return "[%H:%M:%S]"
    end

    local ok, rendered = pcall(date, format)
    if not ok or type(rendered) ~= "string" or rendered == "" then
        return "[%H:%M:%S]"
    end

    return format
end

function Addon:ApplyTimestampSettings()
    if savedBlizzardTimestampFormat == nil then
        savedBlizzardTimestampFormat = GetCVar("showTimestamps")
    end

    if not Addon:GetSetting("timestampEnabled") then
        if savedBlizzardTimestampFormat and savedBlizzardTimestampFormat ~= "" then
            SetCVar("showTimestamps", savedBlizzardTimestampFormat)
        else
            SetCVar("showTimestamps", "none")
        end
        return
    end

    SetCVar("showTimestamps", GetSafeFormat())
end

function Addon:HookTimestamps()
    Addon:ApplyTimestampSettings()
end
