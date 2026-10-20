local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local replyPrefix = "[CT Ignore] "
local replied, budgetStart, budgetUsed = {}, 0, 0
FC.defaultIgnoreReply = "You're on my ignore list. Your messages are not being read."

function FC:SaveIgnoreReply(enabled, message)
    if type(message) ~= "string" or not message:find("%S") or #message > 230 or message:find("[%c|]") then
        return false, "Enter a plain-text reply of 1-230 bytes without line breaks or formatting codes."
    end
    self.db.extendedIgnore.replyEnabled = enabled == true
    self.db.extendedIgnore.replyMessage = message
    return true, "Ignore reply saved."
end

-- Store full names to avoid ignoring unrelated characters on other realms.
function FC:NormalizeBlacklistName(value)
    if not self:IsPublic(value) or type(value) ~= "string" then return nil, "Enter a character name." end
    value = value:match("^%s*(.-)%s*$")
    if #value == 0 or #value > 160 then return nil, "Enter Name or Name-Realm." end
    local name, realm = value:match("^([^%-]+)%-(.+)$")
    if not name then name = value end
    -- Forever character names may include a surname. Keep internal spaces as
    -- part of the character identity; only realm names lose their spaces.
    if name:find("[%c]") then return nil, "Enter a character name without line breaks." end
    name = name:match("^%s*(.-)%s*$"):gsub(" +", " ")
    local letters = name:gsub(" ", ""):gsub("'", "")
    if letters == "" or letters:find("[%s%d%p%c]") then return nil, "Enter a character name, not a chat link or BattleTag." end
    realm = realm or (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
    if not self:IsPublic(realm) or type(realm) ~= "string" then return nil, "Realm unavailable. Enter Name-Realm." end
    realm = realm:gsub("%s+", "")
    if realm == "" or realm:find("[%c|:<>/\\%-]") then return nil, "Enter a valid realm after the dash." end
    local fullName = name .. "-" .. realm
    local lower = strlower or string.lower
    return lower(fullName), fullName
end

function FC:SetExtendedIgnoreEnabled(enabled)
    self.db.extendedIgnore.enabled = enabled == true
    if self.RefreshSettings then self:RefreshSettings() end
end

function FC:AddBlacklistName(value)
    local key, name = self:NormalizeBlacklistName(value)
    if not key then return false, name end
    local entries = self.db.extendedIgnore.blacklist
    if entries[key] then return false, name .. " is already blacklisted." end
    entries[key] = name
    if self.RefreshBlacklist then self:RefreshBlacklist() end
    return true, name .. " added to the blacklist."
end

function FC:RemoveBlacklistName(value)
    local key, name = self:NormalizeBlacklistName(value)
    if not key then return false, name end
    if not self.db.extendedIgnore.blacklist[key] then return false, name .. " is not blacklisted." end
    self.db.extendedIgnore.blacklist[key] = nil
    if self.RefreshBlacklist then self:RefreshBlacklist() end
    return true, name .. " removed from the blacklist."
end

function FC:IsBlacklisted(value)
    local settings = self.db and self.db.extendedIgnore
    if not settings or not settings.enabled then return false end
    local key = self:NormalizeBlacklistName(value)
    return key ~= nil and settings.blacklist[key] ~= nil
end

local events = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL", "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_GUILD_DISCORD", "CHAT_MSG_VOICE_TEXT",
}

function FC:BuildExtendedIgnoreSettings(panel, top, text)
    local replyTop = top
    top = top - 280
    text("Extended Ignore: blacklist", "GameFontNormal", 20, top)
    text("Ctrl+Shift+left-click a character name in chat to add it. Or enter Name-Realm below; a name alone uses your current realm.",
        "GameFontHighlightSmall", 20, top - 24, 440)
    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(284, 30)
    input:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, top - 72)
    input:SetAutoFocus(false)
    input:SetMaxBytes(160)
    local add = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    add:SetSize(120, 26)
    add:SetPoint("LEFT", input, "RIGHT", 12, 0)
    add:SetText("Add to blacklist")
    local feedback = text("", "GameFontHighlightSmall", 20, top - 112, 440)
    local function addName()
        local success, message = FC:AddBlacklistName(input:GetText())
        if success then input:SetText(""); input:ClearFocus() end
        feedback:SetText(message)
    end
    add:SetScript("OnClick", addName)
    input:SetScript("OnEnterPressed", addName)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local count = text("", "GameFontNormal", 20, top - 160, 440)
    local rows, page, pageSize = {}, 1, 8
    for index = 1, pageSize do
        local label = text("", "GameFontHighlightSmall", 24, top - 190 - (index - 1) * 30, 300)
        local remove = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        remove:SetSize(100, 24)
        remove:SetPoint("TOPLEFT", panel, "TOPLEFT", 340, top - 184 - (index - 1) * 30)
        remove:SetText("Remove")
        local row = { label = label, remove = remove }
        rows[index] = row
        remove:SetScript("OnClick", function()
            if row.name then
                local _, message = FC:RemoveBlacklistName(row.name)
                feedback:SetText(message)
            end
        end)
    end
    local previous = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previous:SetSize(100, 26)
    previous:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, top - 440)
    previous:SetText("Previous")
    local nextPage = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    nextPage:SetSize(100, 26)
    nextPage:SetPoint("LEFT", previous, "RIGHT", 12, 0)
    nextPage:SetText("Next")
    function FC:RefreshBlacklist()
        local names = {}
        for _, name in pairs(self.db.extendedIgnore.blacklist) do names[#names + 1] = name end
        table.sort(names)
        local pages = math.max(1, math.ceil(#names / pageSize))
        page = math.max(1, math.min(page, pages))
        count:SetText(#names .. " blacklisted | Page " .. page .. " of " .. pages)
        for index, row in ipairs(rows) do
            row.name = names[(page - 1) * pageSize + index]
            row.label:SetText(row.name or (index == 1 and #names == 0 and "Your blacklist is empty." or ""))
            row.remove:SetShown(row.name ~= nil)
        end
        previous:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pages)
    end
    previous:SetScript("OnClick", function() page = page - 1; FC:RefreshBlacklist() end)
    nextPage:SetScript("OnClick", function() page = page + 1; FC:RefreshBlacklist() end)
    text("The list is saved account-wide. Disabling Extended Ignore keeps your list. This filters new character chat locally; it does not change Blizzard's ignore list or remove earlier messages.",
        "GameFontHighlightSmall", 20, top - 484, 440)
    local notify = CreateFrame("CheckButton", "CommunicationToolsForeverIgnoreReplyToggle", panel, "UICheckButtonTemplate")
    notify:SetPoint("TOPLEFT", 16, replyTop - 8)
    notify:SetSize(28, 28)
    local notifyLabel = notify:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    notifyLabel:SetPoint("LEFT", notify, "RIGHT", 4, 0)
    notifyLabel:SetText("Enable auto-ignore reply")
    local reply = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    reply:SetPoint("TOPLEFT", 24, replyTop - 52)
    reply:SetSize(430, 30)
    reply:SetAutoFocus(false)
    reply:SetMaxBytes(230)
    local saveReply = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveReply:SetPoint("TOPLEFT", 20, replyTop - 94)
    saveReply:SetSize(160, 28)
    saveReply:SetText("Save ignore reply")
    local replyFeedback = text("", "GameFontHighlightSmall", 20, replyTop - 136, 440)
    notify:SetScript("OnClick", function(self)
        FC.db.extendedIgnore.replyEnabled = self:GetChecked() == true
        replyFeedback:SetText(FC.db.extendedIgnore.replyEnabled and "Auto-ignore reply enabled." or "Auto-ignore reply disabled.")
    end)
    local function save()
        local success, message = FC:SaveIgnoreReply(notify:GetChecked(), reply:GetText())
        if success then reply:ClearFocus() end
        replyFeedback:SetText(message)
    end
    saveReply:SetScript("OnClick", save)
    reply:SetScript("OnEnterPressed", save)
    reply:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    text("The checkbox applies immediately. Edit the message above and click Save ignore reply to save its text. Replies carry a [CT Ignore] label, at most once per sender per minute. Incoming messages stay hidden.",
        "GameFontHighlightSmall", 20, replyTop - 184, 440)
    function FC:RefreshIgnoreReplySettings()
        notify:SetChecked(self.db.extendedIgnore.replyEnabled)
        if not reply:HasFocus() then reply:SetText(self.db.extendedIgnore.replyMessage) end
    end
    self:RefreshIgnoreReplySettings()
    self:RefreshBlacklist()
    return -top + 560
end

function module:Initialize()
    local db = FC.db
    if type(db.extendedIgnore) ~= "table" then db.extendedIgnore = {} end
    local settings = db.extendedIgnore
    if type(settings.enabled) ~= "boolean" then settings.enabled = true end
    if type(settings.replyEnabled) ~= "boolean" then settings.replyEnabled = true end
    if not FC:SaveIgnoreReply(settings.replyEnabled, settings.replyMessage) then settings.replyMessage = FC.defaultIgnoreReply end
    local blacklist = {}
    if type(settings.blacklist) == "table" then
        for _, name in pairs(settings.blacklist) do
            local key, fullName = FC:NormalizeBlacklistName(name)
            if key then blacklist[key] = fullName end
        end
    end
    settings.blacklist = blacklist
    FC:RegisterTool({
        name = "Extended Ignore",
        settingsPage = "extendedIgnore",
        description = "Hide chat and whispers from characters on your blacklist.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(enabled) FC:SetExtendedIgnoreEnabled(enabled) end,
    })

    local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if addFilter then
        local function filter(_, _, _, author)
            return FC:IsBlacklisted(author)
        end
        for _, event in ipairs(events) do addFilter(event, filter) end
    else
        FC:Print("Extended Ignore: this client does not expose chat message filters.")
    end

    -- Reply once per received event, never from per-window display filters.
    local whispers = CreateFrame("Frame")
    whispers:RegisterEvent("CHAT_MSG_WHISPER")
    whispers:SetScript("OnEvent", function(_, event, message, author, _, _, _, flags)
        if event ~= "CHAT_MSG_WHISPER" or not settings.replyEnabled or not FC:IsBlacklisted(author) then return end
        if not FC:IsPublic(message) or not FC:IsPublic(flags) or type(message) ~= "string" or flags == "GM" then return end
        if message:match("^%[CT Ignore%]") or message:match("^%[CT DND%]") or message:match("^%[CT Forward%]") then return end
        local key, full = FC:NormalizeBlacklistName(author)
        if not key then return end
        local target = full:match("^([^%-]+)")
        local getter = UnitNameUnmodified or UnitName
        if getter then
            local ok, first, last = pcall(getter, "player")
            if ok and FC:IsPublic(first) and FC:IsPublic(last) and type(first) == "string" then
                if type(last) == "string" and last ~= "" and first:sub(-#last - 1):lower() ~= (" " .. last):lower() then first = first .. " " .. last end
                if first:lower() == target:lower() then return end
            end
        end
        local now = GetTime()
        for previous, timestamp in pairs(replied) do if now - timestamp >= 60 then replied[previous] = nil end end
        if replied[key] then return end
        replied[key] = now
        if now - budgetStart >= 10 then budgetStart, budgetUsed = now, 0 end
        if budgetUsed >= 10 then return end
        budgetUsed = budgetUsed + 1
        local api = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if api then pcall(api, replyPrefix .. settings.replyMessage, "WHISPER", nil, target) end
    end)

    local function nameClick(link, button)
        if not settings.enabled or button ~= "LeftButton" or not IsControlKeyDown() or not IsShiftKeyDown() then return end
        if not FC:IsPublic(link) or type(link) ~= "string" then return end
        local name = link:match("^player:([^:]+)")
        if not name then return end
        local _, message = FC:AddBlacklistName(name)
        FC:Print(message)
    end
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkClick", function(_, _, link, _, button)
            nameClick(link, button)
        end, module)
    elseif hooksecurefunc and SetItemRef then
        hooksecurefunc("SetItemRef", function(link, _, button) nameClick(link, button) end)
    end
end
