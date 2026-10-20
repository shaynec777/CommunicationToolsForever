local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local eventGroups = {
    CHAT_MSG_SAY = "public", CHAT_MSG_YELL = "public", CHAT_MSG_CHANNEL = "public",
    CHAT_MSG_EMOTE = "public", CHAT_MSG_TEXT_EMOTE = "public",
    CHAT_MSG_PARTY = "group", CHAT_MSG_PARTY_LEADER = "group", CHAT_MSG_RAID = "group",
    CHAT_MSG_RAID_LEADER = "group", CHAT_MSG_RAID_WARNING = "group",
    CHAT_MSG_INSTANCE_CHAT = "group", CHAT_MSG_INSTANCE_CHAT_LEADER = "group",
    CHAT_MSG_GUILD = "guild", CHAT_MSG_OFFICER = "guild", CHAT_MSG_COMMUNITIES_CHANNEL = "guild",
    CHAT_MSG_WHISPER = "whispers",
}
local defaults = { enabled = true, full = true, first = true, last = true,
    insideWords = false, sound = true, banner = true, suppressInCombat = true,
    public = true, group = true, guild = true, whispers = false }
local channelLabels = {
    CHAT_MSG_SAY = "Say", CHAT_MSG_YELL = "Yell", CHAT_MSG_EMOTE = "Emote", CHAT_MSG_TEXT_EMOTE = "Emote",
    CHAT_MSG_PARTY = "Party", CHAT_MSG_PARTY_LEADER = "Party (Leader)", CHAT_MSG_RAID = "Raid",
    CHAT_MSG_RAID_LEADER = "Raid (Leader)", CHAT_MSG_RAID_WARNING = "Raid Warning",
    CHAT_MSG_INSTANCE_CHAT = "Instance", CHAT_MSG_INSTANCE_CHAT_LEADER = "Instance (Leader)",
    CHAT_MSG_GUILD = "Guild", CHAT_MSG_OFFICER = "Officer", CHAT_MSG_WHISPER = "Whisper",
}
local function lower(value) return (strlower or string.lower)(value) end
local function public(value) return FC:IsPublic(value) end
function FC:NameAlertChannel(event, channelName, channelIndex, channelBase)
    if channelLabels[event] then return channelLabels[event] end
    local name
    if public(channelName) and type(channelName) == "string" and channelName ~= "" then name = channelName
    elseif public(channelBase) and type(channelBase) == "string" and channelBase ~= "" then name = channelBase end
    if name then
        if public(channelIndex) and type(channelIndex) == "number" and channelIndex > 0 and not name:match("^%d+%.") then
            name = channelIndex .. ". " .. name
        end
        return name
    end
    return event == "CHAT_MSG_COMMUNITIES_CHANNEL" and "Community" or "Public channel"
end
local function clean(message)
    return message:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", " "):gsub("|A.-|a", " "):gsub("[%c]", " ")
end
local function wordByte(byte)
    return byte and ((byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90)
        or (byte >= 97 and byte <= 122) or byte == 95 or byte >= 128)
end
local function contains(message, value, insideWords)
    if not value or value == "" then return false end
    local start = 1
    while true do
        local first, last = message:find(value, start, true)
        if not first then return false end
        if insideWords or (not wordByte(message:byte(first - 1)) and not wordByte(message:byte(last + 1))) then return true end
        start = first + 1
    end
end
function FC:GetNameAlertIdentity()
    for _, getter in ipairs({UnitNameUnmodified or false, UnitName or false, UnitFullName or false}) do
        if type(getter) == "function" then
            local ok, first, last = pcall(getter, "player")
            if ok and public(first) and public(last) and type(first) == "string" and first ~= "" then
                local full = first
                if type(last) == "string" and last ~= "" then
                    local suffix = " " .. last
                    if first:sub(-#suffix):lower() ~= suffix:lower() then full = first .. suffix end
                end
                local given, surname = full:match("^(%S+)%s+(.+)$")
                return full, given or full, surname
            end
        end
    end
end
function FC:NameMentionMatches(message)
    if not public(message) or type(message) ~= "string" then return false end
    local full, first, last = self:GetNameAlertIdentity()
    if not full then return false end
    local settings = self.db.nameAlerts
    local body = lower(clean(message))
    for _, spec in ipairs({{settings.full, full}, {settings.first, first}, {settings.last, last}}) do
        if spec[1] and spec[2] and contains(body, lower(spec[2]), settings.insideWords) then return true end
    end
    return false
end
function FC:SetNameAlertsEnabled(value)
    self.db.nameAlerts.enabled = value == true
    if not value and self.nameAlertBanner then self.nameAlertBanner:Hide() end
    if self.RefreshSettings then self:RefreshSettings() end
end
function FC:BuildNameAlertsSettings(panel, text)
    local identity = text("", "GameFontHighlight", 20, -8, 440)
    text("Alert when another player mentions you. Full name, first name, and surname can be matched independently. Changes apply immediately.",
        "GameFontHighlightSmall", 20, -48, 440)
    local controls = {}
    local function check(key, caption, top)
        local control = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", 16, top)
        control:SetSize(28, 28)
        local label = control:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", control, "RIGHT", 4, 0)
        label:SetText(caption)
        control:SetScript("OnClick", function(self)
            FC.db.nameAlerts[key] = self:GetChecked() == true
            if (key == "banner" and not self:GetChecked()) or
                (key == "suppressInCombat" and self:GetChecked() and InCombatLockdown and InCombatLockdown()) then
                if FC.nameAlertBanner then FC.nameAlertBanner:Hide() end
            end
        end)
        controls[key] = control
    end
    check("full", "Match full character name", -100)
    check("first", "Match first name", -134)
    check("last", "Match surname", -168)
    check("insideWords", "Also match inside longer words", -202)
    check("sound", "Play a sound", -250)
    check("banner", "Show an on-screen banner", -284)
    check("suppressInCombat", "Suppress popup in combat (sound/chat unchanged)", -318)
    text("Monitor these chat types", "GameFontNormal", 20, -370, 440)
    check("public", "Say, yell, emotes and public channels", -394)
    check("group", "Party, raid and instance chat", -428)
    check("guild", "Guild, officer and community chat", -462)
    check("whispers", "Character whispers", -496)
    text("Whole-name/word matching is the default: Ann matches 'Ann!' but not 'banner'. Alerts share a five-second cooldown. Your own messages, ignored players, automated CT messages, and DND-hidden whispers are excluded. A local chat line records each alert. Restricted messages and Battle.net account chat are not inspected.",
        "GameFontHighlightSmall", 20, -548, 440)
    local test = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test:SetSize(160, 28)
    test:SetPoint("TOPLEFT", 20, -658)
    test:SetText("Test name alert")
    test:SetScript("OnClick", function() FC:ShowNameAlert("Preview", "Someone mentioned your name. (Local preview only)", "2. Trade - English") end)
    function FC:RefreshNameAlertsSettings()
        local full = self:GetNameAlertIdentity()
        identity:SetText("Your character: " .. (full or "name unavailable"))
        for key, control in pairs(controls) do control:SetChecked(self.db.nameAlerts[key]) end
    end
    self:RefreshNameAlertsSettings()
    return 726
end
function module:Initialize()
    if type(FC.db.nameAlerts) ~= "table" then FC.db.nameAlerts = {} end
    local settings = FC.db.nameAlerts
    for key, value in pairs(defaults) do if type(settings[key]) ~= "boolean" then settings[key] = value end end
    FC:RegisterTool({ name = "Name Alerts", settingsPage = "nameAlerts",
        description = "Notice mentions of your full name, first name or surname.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(value) FC:SetNameAlertsEnabled(value) end })
    local banner = CreateFrame("Frame", "CommunicationToolsForeverNameAlert", UIParent, "BackdropTemplate")
    FC.nameAlertBanner = banner
    banner:SetSize(540, 118)
    banner:SetPoint("TOP", UIParent, "TOP", 0, -140)
    banner:SetFrameStrata("DIALOG")
    banner:SetClampedToScreen(true)
    banner:EnableMouse(true)
    local close = CreateFrame("Button", "CommunicationToolsForeverNameAlertClose", banner, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() banner:Hide() end)
    banner:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24})
    banner:SetBackdropColor(0.035, 0.047, 0.044, 0.95)
    local title = banner:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetSize(500, 36)
    title:SetText("Your name was mentioned")
    local body = banner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 20, -60)
    body:SetSize(500, 42)
    body:SetJustifyH("LEFT")
    banner:Hide()
    local generation, lastAlert = 0, -math.huge
    function FC:ShowNameAlert(author, message, channel)
        local plain = clean(message)
        channel = channel or "Preview"
        self:Print("Name Alerts [" .. channel .. "] - " .. author .. ": " .. plain)
        if settings.sound and PlaySound then pcall(PlaySound, SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end
        local suppress = settings.suppressInCombat and InCombatLockdown and InCombatLockdown()
        if settings.banner and not suppress then
            title:SetText("Mention in " .. channel)
            body:SetText(author .. ": " .. plain)
            banner:Show()
            generation = generation + 1
            local current = generation
            if C_Timer and C_Timer.After then C_Timer.After(12, function() if current == generation then banner:Hide() end end) end
        elseif suppress then
            banner:Hide()
        end
    end
    local listener = CreateFrame("Frame")
    for event in pairs(eventGroups) do listener:RegisterEvent(event) end
    listener:RegisterEvent("PLAYER_REGEN_DISABLED")
    listener:SetScript("OnEvent", function(_, event, message, author, _, channelName, _, _, _, channelIndex, channelBase)
        if event == "PLAYER_REGEN_DISABLED" then
            if settings.suppressInCombat then banner:Hide() end
            return
        end
        if not settings.enabled or not settings[eventGroups[event]] then return end
        if not public(message) or not public(author) or type(message) ~= "string" or type(author) ~= "string" then return end
        if FC:IsBlacklisted(author) or message:match("^%[CT [^%]]+%]") then return end
        local full = FC:GetNameAlertIdentity()
        if not full then return end
        local authorKey = FC:NormalizeBlacklistName(author)
        local selfKey = FC:NormalizeBlacklistName(full)
        if authorKey and selfKey and authorKey == selfKey then return end
        local dnd = FC.db.doNotDisturb
        if event == "CHAT_MSG_WHISPER" and dnd and dnd.enabled and dnd.hide then return end
        if not FC:NameMentionMatches(message) then return end
        local now = GetTime()
        if now - lastAlert < 5 then return end
        lastAlert = now
        FC:ShowNameAlert(author, message, FC:NameAlertChannel(event, channelName, channelIndex, channelBase))
    end)
end
