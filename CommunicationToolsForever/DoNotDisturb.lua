local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local prefix, forwardPrefix = "[CT DND] ", "[CT Forward] "
local replied, budgetStart, budgetUsed = {}, 0, 0
FC.defaultDNDResponse = "I'm currently unavailable. I'll get back to you when I can."

local function public(value) return FC:IsPublic(value) end
local function characterName(value)
    local key, full = FC:NormalizeBlacklistName(value)
    if not key then return nil end
    return full:match("^([^%-]+)")
end
local function myName()
    local getter = UnitNameUnmodified or UnitName
    if not getter then return end
    local ok, first, last = pcall(getter, "player")
    if not ok or not public(first) or not public(last) or type(first) ~= "string" then return end
    if type(last) == "string" and last ~= "" and first:sub(-#last - 1):lower() ~= (" " .. last):lower() then
        first = first .. " " .. last
    end
    return first
end

function FC:SetDNDEnabled(enabled)
    self.db.doNotDisturb.enabled = enabled == true
    if self.RefreshSettings then self:RefreshSettings() end
end
function FC:SaveDNDSettings(response, forwarding, target, mode, hide)
    if type(response) ~= "string" or not response:find("%S") or #response > 230 or response:find("[%c|]") then
        return false, "Enter a plain-text response of 1-230 bytes, without line breaks or formatting codes."
    end
    local name = target:match("^%s*(.-)%s*$")
    if name ~= "" then
        name = characterName(name)
        if not name then return false, "Enter the other player's full character name, including their surname." end
        local own = myName()
        if own and name:lower() == own:lower() then return false, "Choose another player, not yourself." end
    end
    if forwarding and name == "" then return false, "Enter a player name before enabling forwarding." end
    if mode ~= "relay" and mode ~= "refer" then return false, "Choose relay or referral." end
    local combined = prefix .. response
    if forwarding and mode == "refer" then combined = combined .. " Please whisper " .. name .. "." end
    if #combined > 255 then return false, "Shorten the response so it fits with the referral name (255 bytes total)." end
    local settings = self.db.doNotDisturb
    settings.response, settings.forwarding, settings.target = response, forwarding == true, name
    settings.mode, settings.hide = mode, hide == true
    if self.RefreshDNDSettings then self:RefreshDNDSettings() end
    return true, "Do Not Disturb settings saved."
end

local function send(message, target)
    local now = GetTime()
    if now - budgetStart >= 10 then budgetStart, budgetUsed = now, 0 end
    if budgetUsed >= 20 then return false end
    budgetUsed = budgetUsed + 1
    local api = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if not api then return false end
    return pcall(api, message, "WHISPER", nil, target)
end
local function plain(text)
    return text:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", "[icon]"):gsub("|A.-|a", "[icon]"):gsub("[%c]", " "):gsub("|", "")
end
local function splitForward(message, author)
    local header = forwardPrefix .. "From " .. author .. ": "
    local remaining, chunks = plain(message), {}
    local limit = 255 - #header
    while #remaining > 0 do
        local count = math.min(limit, #remaining)
        while count > 0 do
            local nextByte = remaining:byte(count + 1)
            if not nextByte or nextByte < 128 or nextByte >= 192 then break end
            count = count - 1
        end
        if count == 0 then break end
        chunks[#chunks + 1] = header .. remaining:sub(1, count)
        remaining = remaining:sub(count + 1)
    end
    return chunks
end

function FC:BuildDNDSettings(panel, text)
    text("Configure the reply people receive while this tool is enabled. Forwarding is optional. Use the main menu's Enabled checkbox to turn DND on or off.",
        "GameFontHighlightSmall", 20, -8, 440)
    text("Auto-response", "GameFontNormal", 20, -72, 440)
    local response = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    response:SetPoint("TOPLEFT", 24, -96)
    response:SetSize(430, 30)
    response:SetAutoFocus(false)
    response:SetMaxBytes(230)
    local function check(value, top)
        local control = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", 16, top)
        control:SetSize(28, 28)
        local caption = control:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        caption:SetPoint("LEFT", control, "RIGHT", 4, 0)
        caption:SetText(value)
        return control
    end
    local forwarding = check("Enable forwarding / referral", -148)
    text("Other player's full name (include surname)", "GameFontNormal", 20, -190, 440)
    local target = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    target:SetPoint("TOPLEFT", 24, -214)
    target:SetSize(430, 30)
    target:SetAutoFocus(false)
    target:SetMaxBytes(160)
    local relay = check("Relay incoming whispers to this player", -264)
    local refer = check("Tell the sender to contact this player instead", -300)
    local hide = check("Hide incoming whispers while DND is enabled", -346)
    local preview = text("", "GameFontHighlightSmall", 20, -398, 440)
    local feedback = text("", "GameFontHighlightSmall", 20, -480, 440)
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetPoint("TOPLEFT", 20, -528)
    save:SetSize(160, 28)
    save:SetText("Save DND settings")
    local mode = "relay"
    local function updatePreview()
        local message = prefix .. response:GetText()
        if forwarding:GetChecked() and mode == "refer" then message = message .. " Please whisper " .. target:GetText() .. "." end
        preview:SetText("Reply preview (not sent): " .. message)
        relay:SetChecked(mode == "relay")
        refer:SetChecked(mode == "refer")
    end
    response:SetScript("OnTextChanged", updatePreview)
    target:SetScript("OnTextChanged", updatePreview)
    forwarding:SetScript("OnClick", updatePreview)
    relay:SetScript("OnClick", function() mode = "relay"; updatePreview() end)
    refer:SetScript("OnClick", function() mode = "refer"; updatePreview() end)
    local function saveSettings()
        local success, message = FC:SaveDNDSettings(response:GetText(), forwarding:GetChecked(), target:GetText(), mode, hide:GetChecked())
        if success then response:ClearFocus(); target:ClearFocus() end
        feedback:SetText(message)
    end
    save:SetScript("OnClick", saveSettings)
    response:SetScript("OnEnterPressed", saveSettings)
    target:SetScript("OnEnterPressed", saveSettings)
    response:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    target:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    text("Replies are limited to once per sender per minute. Forwarded messages are labeled with their sender; automated messages and the forwarding recipient are excluded to prevent loops. Blacklisted senders get no DND reply or forwarding.",
        "GameFontHighlightSmall", 20, -582, 440)
    text("DND handles character whispers only and leaves Blizzard's /dnd status unchanged. Forwarding sends the original whisper text to the named player. Save changes before leaving this page.",
        "GameFontHighlightSmall", 20, -658, 440)
    function FC:RefreshDNDSettings()
        local settings = self.db.doNotDisturb
        if not response:HasFocus() then response:SetText(settings.response) end
        if not target:HasFocus() then target:SetText(settings.target) end
        forwarding:SetChecked(settings.forwarding)
        hide:SetChecked(settings.hide)
        mode = settings.mode
        updatePreview()
    end
    self:RefreshDNDSettings()
    return 740
end

function module:Initialize()
    if type(FC.db.doNotDisturb) ~= "table" then FC.db.doNotDisturb = {} end
    local settings = FC.db.doNotDisturb
    local defaults = { enabled = false, response = FC.defaultDNDResponse, forwarding = false,
        target = "", mode = "relay", hide = false }
    for key, value in pairs(defaults) do if type(settings[key]) ~= type(value) then settings[key] = value end end
    if not FC:SaveDNDSettings(settings.response, settings.forwarding, settings.target, settings.mode, settings.hide) then
        settings.response, settings.forwarding, settings.target, settings.mode = FC.defaultDNDResponse, false, "", "relay"
    end
    FC:RegisterTool({ name = "Do Not Disturb", settingsPage = "doNotDisturb",
        description = "Auto-reply to whispers and optionally forward them.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(value) FC:SetDNDEnabled(value) end })
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_WHISPER")
    frame:SetScript("OnEvent", function(_, event, message, author, _, _, _, flags, ...)
        if event ~= "CHAT_MSG_WHISPER" or not settings.enabled then return end
        if not public(message) or not public(author) or not public(flags) or type(message) ~= "string" or type(author) ~= "string" then return end
        if flags == "GM" or FC:IsBlacklisted(author) then return end
        local name = characterName(author)
        if not name then return end
        local own = myName()
        if own and name:lower() == own:lower() then return end
        -- Never reply to or re-forward another copy's automated messages.
        if message:sub(1, #prefix) == prefix or message:sub(1, #forwardPrefix) == forwardPrefix or message:match("^%[CT Ignore%]") then return end
        if settings.forwarding and settings.target ~= "" and name:lower() == settings.target:lower() then return end
        local now, key = GetTime(), name:lower()
        for old, timestamp in pairs(replied) do if now - timestamp >= 60 then replied[old] = nil end end
        if not replied[key] then
            replied[key] = now
            local response = prefix .. settings.response
            if settings.forwarding and settings.mode == "refer" then response = response .. " Please whisper " .. settings.target .. "." end
            if not send(response, name) then FC:Print("DND reply was blocked or rate-limited.") end
        end
        if settings.forwarding and settings.mode == "relay" and settings.target ~= "" then
            for _, chunk in ipairs(splitForward(message, name)) do
                if not send(chunk, settings.target) then FC:Print("DND forwarding was blocked or rate-limited."); break end
            end
        end
    end)
    local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if addFilter then
        addFilter("CHAT_MSG_WHISPER", function(_, _, _, _, _, _, _, flags)
            return settings.enabled and settings.hide and public(flags) and flags ~= "GM"
        end)
    end
end
