local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local sessionMutes = {}
local function public(value) return FC:IsPublic(value) end
local function stringValue(value) return public(value) and type(value) == "string" and value ~= "" end
local function numberValue(value) return public(value) and type(value) == "number" and value > 0 end
local function call(api, ...)
    if type(api) ~= "function" then return nil end
    local ok, result = pcall(api, ...)
    if ok and public(result) then return result end
end
local function count(api)
    local value = call(api)
    return numberValue(value) and math.min(math.floor(value), 1000) or 0
end
local function accountKey(info)
    if stringValue(info.battleTag) then return "tag:" .. info.battleTag:lower() end
    local game = info.gameAccountInfo
    if public(game) and type(game) == "table" and stringValue(game.playerGuid) then return "guid:" .. game.playerGuid end
end
local function requestType(level)
    local levels = Enum and Enum.BattleNetFriendLevel
    if levels and public(level) then
        if level == levels.RealID then return "Real ID (shares real name)" end
        if level == levels.Title then return "WoW-only" end
        if level == levels.BattleTag then return "BattleTag" end
    end
    return "Friend request"
end
function FC:GetSocialEntries()
    local friends, requests = {}, {}
    local api = C_BattleNet
    if api and api.GetFriendAccountInfo then
        for index = 1, count(BNGetNumFriends) do
            local info = call(api.GetFriendAccountInfo, index)
            if type(info) == "table" and numberValue(info.bnetAccountID) then
                local name = stringValue(info.battleTag) and info.battleTag or (stringValue(info.accountName) and info.accountName or "Friend")
                local key = accountKey(info)
                friends[#friends + 1] = {kind = "account", id = info.bnetAccountID, name = name, muteKey = key,
                    key = "account:" .. info.bnetAccountID, detail = requestType(info.friendLevel)}
            end
        end
    end
    local legacy = C_FriendList
    if legacy and legacy.GetFriendInfoByIndex then
        for index = 1, count(legacy.GetNumFriends) do
            local info = call(legacy.GetFriendInfoByIndex, index)
            if type(info) == "table" and stringValue(info.name) then
                local key = self:NormalizeBlacklistName(info.name)
                if key then friends[#friends + 1] = {kind = "character", name = info.name, key = "character:" .. key, muteKey = "character:" .. key, detail = "Character"} end
            end
        end
    end
    if api and api.GetFriendInviteInfo then
        for index = 1, count(BNGetNumFriendInvites) do
            local info = call(api.GetFriendInviteInfo, index)
            if type(info) == "table" and numberValue(info.inviteID) then
                requests[#requests + 1] = {id = info.inviteID, name = stringValue(info.accountName) and info.accountName or "Friend request", detail = requestType(info.friendLevel)}
            end
        end
    end
    return friends, requests
end
local function currentFriend(entry)
    if type(entry) ~= "table" then return end
    local friends = FC:GetSocialEntries()
    for _, current in ipairs(friends) do
        if current.key == entry.key and current.name == entry.name and current.muteKey == entry.muteKey then return current end
    end
end
function FC:RespondToFriendRequest(id, accept)
    if not numberValue(id) then return false, "Request unavailable." end
    local _, requests = self:GetSocialEntries()
    for _, request in ipairs(requests) do
        if request.id == id then
            local api
            if accept then api = BNAcceptFriendInvite else api = BNDeclineFriendInvite end
            if type(api) ~= "function" then return false, "This client does not expose this request action." end
            local ok, result = pcall(api, id)
            if not ok or (public(result) and result == false) then return false, "Request could not be updated. Try outside combat." end
            return true, "Friend request " .. (accept and "approval" or "decline") .. " sent."
        end
    end
    return false, "That request is no longer pending. Refresh the list."
end
function FC:RemoveSocialFriend(entry)
    local current = currentFriend(entry)
    if not current then return false, "Friend list changed. Refresh and select the friend again." end
    local api
    if current.kind == "account" then api = BNRemoveFriend else api = C_FriendList and C_FriendList.RemoveFriend end
    if type(api) ~= "function" then return false, "This client does not expose friend removal." end
    local ok, result = pcall(api, current.kind == "account" and current.id or current.name)
    if not ok or (public(result) and result == false) then return false, "Friend could not be removed. Try outside combat." end
    return true, "Removal requested for " .. current.name .. "."
end
function FC:SetSocialFriendMuted(entry, muted)
    local current = currentFriend(entry)
    if not current then return false, "Friend list changed. Refresh and select the friend again." end
    if current.muteKey then self.db.friendsList.muted[current.muteKey] = muted == true or nil
    else sessionMutes[current.key] = muted == true or nil end
    return true, current.name .. (muted and " muted locally." or " unmuted.")
end
function FC:IsSocialEntryMuted(entry)
    return (entry.muteKey and self.db.friendsList.muted[entry.muteKey] == true) or sessionMutes[entry.key] == true
end
function FC:IsFriendMuted(author, guid, senderID)
    local settings = self.db and self.db.friendsList
    if not settings or not settings.enabled then return false end
    if stringValue(author) then
        local key = self:NormalizeBlacklistName(author)
        if key and settings.muted["character:" .. key] then return true end
    end
    if stringValue(guid) and settings.muted["guid:" .. guid] then return true end
    local info
    if numberValue(senderID) and C_BattleNet then info = call(C_BattleNet.GetAccountInfoByID, senderID)
    elseif stringValue(guid) and C_BattleNet then info = call(C_BattleNet.GetAccountInfoByGUID, guid) end
    if type(info) == "table" then
        local key = accountKey(info)
        if key and settings.muted[key] then return true end
        if numberValue(info.bnetAccountID) and sessionMutes["account:" .. info.bnetAccountID] then return true end
    end
    if numberValue(senderID) and sessionMutes["account:" .. senderID] then return true end
    return false
end
function FC:BuildFriendsListSettings(panel, text)
    text("Friends List", "GameFontNormal", 20, -8, 440)
    text("Approve or decline pending WoW-only and Battle.net requests. Request type is shown: Real ID approval shares your real name. Remove changes your actual friend list; click Confirm remove to finish.", "GameFontHighlightSmall", 20, -38, 440)
    text("Mute hides incoming player chat, whispers and Battle.net whispers locally, keeping the friendship. It also suppresses new CT conversation messages, Name Alerts and DND replies. Account mutes apply when WoW identifies the sender. Mutes persist when a stable identity is available; otherwise they last this login. Disabling this tool pauses mutes.", "GameFontHighlightSmall", 20, -124, 440)
    local function button(label, x, y, width, callback)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT", x, y); b:SetSize(width, 26); b:SetText(label); b:SetScript("OnClick", callback)
        return b
    end
    local feedback = text("", "GameFontHighlightSmall", 20, -260, 440)
    local friendsPage, requestsPage, pending = 1, 1, nil
    local friendRows, requestRows = {}, {}
    button("Refresh", 20, -224, 100, function() pending = nil; FC:RefreshFriendsListSettings() end)
    button("Clear all mutes", 140, -224, 150, function()
        FC.db.friendsList.muted = {}; sessionMutes = {}; feedback:SetText("All local friend mutes cleared."); FC:RefreshFriendsListSettings()
    end)
    local requestCount = text("", "GameFontNormal", 20, -310, 440)
    for index = 1, 4 do
        local top = -344 - (index - 1) * 70
        local row = {label = text("", "GameFontHighlightSmall", 20, top, 440)}
        row.accept = button("Approve", 20, top - 26, 100, function()
            if not row.entry then return end
            local _, reason = FC:RespondToFriendRequest(row.entry.id, true)
            feedback:SetText(reason); FC:RefreshFriendsListSettings()
        end)
        row.decline = button("Decline", 132, top - 26, 100, function()
            if not row.entry then return end
            local _, reason = FC:RespondToFriendRequest(row.entry.id, false)
            feedback:SetText(reason); FC:RefreshFriendsListSettings()
        end)
        requestRows[index] = row
    end
    local requestPrev = button("Previous", 20, -630, 100, function() requestsPage = requestsPage - 1; FC:RefreshFriendsListSettings() end)
    local requestNext = button("Next", 132, -630, 100, function() requestsPage = requestsPage + 1; FC:RefreshFriendsListSettings() end)
    local friendCount = text("", "GameFontNormal", 20, -690, 440)
    for index = 1, 8 do
        local top = -726 - (index - 1) * 78
        local row = {label = text("", "GameFontHighlightSmall", 20, top, 440)}
        row.mute = button("Mute", 20, top - 30, 100, function()
            if not row.entry then return end
            local _, reason = FC:SetSocialFriendMuted(row.entry, not FC:IsSocialEntryMuted(row.entry))
            feedback:SetText(reason); FC:RefreshFriendsListSettings()
        end)
        row.remove = button("Remove", 132, top - 30, 150, function()
            if not row.entry then return end
            if pending ~= row.entry.key then pending = row.entry.key; FC:RefreshFriendsListSettings(); return end
            local _, reason = FC:RemoveSocialFriend(row.entry)
            pending = nil; feedback:SetText(reason); FC:RefreshFriendsListSettings()
        end)
        friendRows[index] = row
    end
    local friendPrev = button("Previous", 20, -1360, 100, function() pending = nil; friendsPage = friendsPage - 1; FC:RefreshFriendsListSettings() end)
    local friendNext = button("Next", 132, -1360, 100, function() pending = nil; friendsPage = friendsPage + 1; FC:RefreshFriendsListSettings() end)
    function FC:RefreshFriendsListSettings()
        local friends, requests = self:GetSocialEntries()
        local fp, rp = math.max(1, math.ceil(#friends / 8)), math.max(1, math.ceil(#requests / 4))
        friendsPage, requestsPage = math.max(1, math.min(fp, friendsPage)), math.max(1, math.min(rp, requestsPage))
        requestCount:SetText("Pending requests: " .. #requests .. " (page " .. requestsPage .. "/" .. rp .. ")")
        friendCount:SetText("Friends: " .. #friends .. " (page " .. friendsPage .. "/" .. fp .. ")")
        for index, row in ipairs(requestRows) do
            local entry = requests[(requestsPage - 1) * 4 + index]; row.entry = entry
            row.label:SetText(entry and (entry.name .. " - " .. entry.detail) or "")
            row.accept:SetEnabled(entry ~= nil and type(BNAcceptFriendInvite) == "function")
            row.decline:SetEnabled(entry ~= nil and type(BNDeclineFriendInvite) == "function")
        end
        for index, row in ipairs(friendRows) do
            local entry = friends[(friendsPage - 1) * 8 + index]; row.entry = entry
            row.label:SetText(entry and (entry.name .. " - " .. entry.detail .. (not entry.muteKey and " (session mute)" or "")) or "")
            row.mute:SetEnabled(entry ~= nil); row.remove:SetEnabled(entry ~= nil)
            row.mute:SetText(entry and self:IsSocialEntryMuted(entry) and "Unmute" or "Mute")
            row.remove:SetText(entry and pending == entry.key and "Confirm remove" or "Remove")
        end
        requestPrev:SetEnabled(requestsPage > 1); requestNext:SetEnabled(requestsPage < rp)
        friendPrev:SetEnabled(friendsPage > 1); friendNext:SetEnabled(friendsPage < fp)
    end
    self:RefreshFriendsListSettings()
    return 1420
end
function module:Initialize()
    if type(FC.db.friendsList) ~= "table" then FC.db.friendsList = {} end
    local settings = FC.db.friendsList
    if type(settings.enabled) ~= "boolean" then settings.enabled = true end
    local muted = {}
    if type(settings.muted) == "table" then
        for key, value in pairs(settings.muted) do
            if type(key) == "string" and (key:match("^tag:") or key:match("^guid:") or key:match("^character:")) and value == true then muted[key] = true end
        end
    end
    settings.muted = muted
    FC:RegisterTool({name = "Friends List", settingsPage = "friendsList", description = "Approve requests, remove friends, or mute them locally.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(enabled) settings.enabled = enabled == true; if FC.RefreshSettings then FC:RefreshSettings() end end})
    local observer = CreateFrame("Frame")
    -- These events are used by Blizzard's friends UI. Guard registration so an unavailable event cannot interrupt addon startup.
    for _, event in ipairs({"FRIENDLIST_UPDATE", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_INVITE_ADDED", "BN_FRIEND_INVITE_REMOVED", "BN_FRIEND_INVITE_LIST_INITIALIZED", "BN_CONNECTED", "BN_DISCONNECTED"}) do pcall(observer.RegisterEvent, observer, event) end
    observer:SetScript("OnEvent", function()
        if FC.currentSettingsPage == "friendsList" and FC.RefreshFriendsListSettings then FC:RefreshFriendsListSettings() end
    end)
    local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if addFilter then
        local function filter(_, _, _, author, _, _, _, _, _, _, _, _, _, guid, senderID) return FC:IsFriendMuted(author, guid, senderID) end
        for _, event in ipairs({"SAY", "YELL", "WHISPER", "EMOTE", "TEXT_EMOTE", "GUILD", "OFFICER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "CHANNEL", "COMMUNITIES_CHANNEL", "AFK", "DND", "GUILD_DISCORD", "VOICE_TEXT", "BN_WHISPER"}) do addFilter("CHAT_MSG_" .. event, filter) end
    end
end
