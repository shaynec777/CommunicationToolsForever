local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module

local function lower(value) return (strlower or string.lower)(value) end
local function parse(value)
    if type(value) ~= "string" or #value > 4000 then return nil, "Use at most 4000 bytes." end
    local entries, seen = {}, {}
    for line in value:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            if line:find("[%c|]") then return nil, "Use plain text without chat formatting codes." end
            local key = lower(line)
            if not seen[key] then entries[#entries + 1] = line; seen[key] = true end
        end
    end
    return entries
end

function FC:SetChatFilterKeywords(value)
    local entries, reason = parse(value)
    if not entries then return false, reason end
    self.db.filterChat.keywords = entries
    return true, "Chat blacklist saved."
end

local function term(value)
    if not FC:IsPublic(value) or type(value) ~= "string" or value:find("[%c|]") then return nil, "Enter one plain-text word or phrase." end
    value = value:match("^%s*(.-)%s*$")
    if value == "" then return nil, "Enter a word or phrase to add." end
    return value
end
function FC:AddChatFilterKeyword(value)
    local keyword, reason = term(value)
    if not keyword then return false, reason end
    local entries = {}
    for _, existing in ipairs(self.db.filterChat.keywords) do
        if lower(existing) == lower(keyword) then return false, "That word or phrase is already listed." end
        entries[#entries + 1] = existing
    end
    entries[#entries + 1] = keyword
    local ok, errorMessage = self:SetChatFilterKeywords(table.concat(entries, "\n"))
    if not ok then return false, errorMessage end
    if self.RefreshFilterChatSettings then self:RefreshFilterChatSettings() end
    return true, "Added: " .. keyword
end
function FC:RemoveChatFilterKeyword(value)
    local keyword, reason = term(value)
    if not keyword then return false, reason end
    for index, existing in ipairs(self.db.filterChat.keywords) do
        if lower(existing) == lower(keyword) then
            table.remove(self.db.filterChat.keywords, index)
            if self.RefreshFilterChatSettings then self:RefreshFilterChatSettings() end
            return true, "Removed: " .. existing
        end
    end
    return false, "That word or phrase is no longer listed."
end

local scopes = {{"trade", "Trade"}, {"channels", "Other public channels"}, {"guild", "Guild and officer"}, {"group", "Party, raid and instance"}, {"localChat", "Say, yell and emotes"}, {"whispers", "Whispers"}, {"community", "Community chat"}}
function FC:ChatFilterScope(event, channelID)
    if event == "CHAT_MSG_CHANNEL" then
        if self:IsPublic(channelID) and channelID == 2 then return "trade" end
        return "channels"
    end
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" or event == "CHAT_MSG_GUILD_DISCORD" then return "guild" end
    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then return "whispers" end
    if event == "CHAT_MSG_COMMUNITIES_CHANNEL" then return "community" end
    if event and (event:find("PARTY", 1, true) or event:find("RAID", 1, true) or event:find("INSTANCE", 1, true) or event:find("BATTLEGROUND", 1, true)) then return "group" end
    return "localChat"
end
function FC:IsChatFiltered(message, event, channelID)
    local settings = self.db and self.db.filterChat
    if not settings or not settings.enabled or not self:IsPublic(message) or type(message) ~= "string" then return false end
    if event and settings.scopes[self:ChatFilterScope(event, channelID)] == false then return false end
    -- Match displayed link text rather than hidden item/player link identifiers.
    local body = lower(message:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    for _, keyword in ipairs(settings.keywords) do
        if body:find(lower(keyword), 1, true) then return true end
    end
    return false
end

function FC:BuildFilterChatSettings(panel, text)
    local editor = self:CreateEntryEditor(panel, text, {
        caption = "Words to trigger filter", addLabel = "Add term", countLabel = "Filter terms",
        help = "Add a word or phrase. Matches ignore capitalization and include parts of longer words. Press Enter to keep adding; use the scrollbar or mouse wheel to browse.",
        GetEntries = function() return FC.db.filterChat.keywords end,
        Add = function(value) return FC:AddChatFilterKeyword(value) end,
        Remove = function(value) return FC:RemoveChatFilterKeyword(value) end,
    })
    self.chatFilterEditor = editor
    text("Filter these chats", "GameFontNormal", 20, -442, 440)
    local checks = {}
    for index, entry in ipairs(scopes) do
        local key = entry[1]
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 16 + ((index - 1) % 2) * 225, -478 - math.floor((index - 1) / 2) * 28)
        check:SetSize(28, 28)
        local caption = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        caption:SetPoint("LEFT", check, "RIGHT", 4, 0)
        caption:SetText(entry[2])
        check:SetScript("OnClick", function(self) FC.db.filterChat.scopes[key] = self:GetChecked() == true end)
        checks[key] = check
    end
    text("Adds, deletions and channel choices save immediately, account-wide. Use \195\151 to delete a term. Restricted messages are not inspected.", "GameFontHighlightSmall", 20, -604, 440)
    function FC:RefreshFilterChatSettings()
        for key, check in pairs(checks) do check:SetChecked(self.db.filterChat.scopes[key]) end
        editor.Refresh()
    end
    self:RefreshFilterChatSettings()
    return 665
end

function module:Initialize()
    if type(FC.db.filterChat) ~= "table" then FC.db.filterChat = {} end
    local settings = FC.db.filterChat
    if type(settings.enabled) ~= "boolean" then settings.enabled = true end
    if type(settings.scopes) ~= "table" then settings.scopes = {} end
    for _, entry in ipairs(scopes) do if type(settings.scopes[entry[1]]) ~= "boolean" then settings.scopes[entry[1]] = true end end
    local valid = {}
    if type(settings.keywords) == "table" then
        for _, value in ipairs(settings.keywords) do
            if type(value) == "string" then valid[#valid + 1] = value end
        end
    end
    settings.keywords = parse(table.concat(valid, "\n")) or {}
    FC:RegisterTool({
        name = "Filter Chat", settingsPage = "filterChat",
        description = "Hide messages containing blacklisted keywords or phrases.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(enabled)
            settings.enabled = enabled == true
            if FC.RefreshSettings then FC:RefreshSettings() end
        end,
    })
    local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if not addFilter then FC:Print("Filter Chat: this client does not expose chat message filters."); return end
    local function filter(_, event, message, author, language, channelName, target, flags, channelID) return FC:IsChatFiltered(message, event, channelID) end
    local events = {
        "SAY", "YELL", "WHISPER", "EMOTE", "TEXT_EMOTE", "GUILD", "OFFICER",
        "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING",
        "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "CHANNEL", "COMMUNITIES_CHANNEL",
        "BATTLEGROUND", "BATTLEGROUND_LEADER", "AFK", "DND", "GUILD_DISCORD", "VOICE_TEXT",
    }
    for _, event in ipairs(events) do addFilter("CHAT_MSG_" .. event, filter) end
end
