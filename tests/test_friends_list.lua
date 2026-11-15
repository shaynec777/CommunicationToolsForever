local addonPath = ... or "CommunicationToolsForever"
local saved = {C_BattleNet = C_BattleNet, C_FriendList = C_FriendList, BNGetNumFriends = BNGetNumFriends, BNGetNumFriendInvites = BNGetNumFriendInvites,
    BNAcceptFriendInvite = BNAcceptFriendInvite, BNDeclineFriendInvite = BNDeclineFriendInvite, BNRemoveFriend = BNRemoveFriend, CreateFrame = CreateFrame, ChatFrameUtil = ChatFrameUtil, Enum = Enum}
local FC = {modules = {}, db = {}, tools = {}}
local secret = {}
function FC:IsPublic(v) return v ~= secret end
function FC:NormalizeBlacklistName(value)
    if not self:IsPublic(value) or type(value) ~= "string" then return nil end
    return value:lower()
end
function FC:RegisterTool(tool) self.tools[#self.tools + 1] = tool end
local account = {bnetAccountID = 20, battleTag = "Example#1234", accountName = "Example", friendLevel = 2}
local legacy = {name = "Alice Raven"}
local request = {inviteID = 77, accountName = "New Friend", friendLevel = 3}
local accepted, declined, removed, legacyRemoved = {}, {}, {}, {}
Enum = {BattleNetFriendLevel = {RealID = 1, BattleTag = 2, Title = 3}}
C_BattleNet = {
    GetFriendAccountInfo = function(i) if i == 1 then return account end end,
    GetFriendInviteInfo = function(i) if i == 1 then return request end end,
    GetAccountInfoByID = function(id) if id == account.bnetAccountID then return account end end,
    GetAccountInfoByGUID = function(guid) if guid == "Player-20" then return account end end,
}
C_FriendList = {GetNumFriends = function() return 1 end, GetFriendInfoByIndex = function() return legacy end,
    RemoveFriend = function(name) legacyRemoved[#legacyRemoved + 1] = name; return true end}
BNGetNumFriends = function() return 1 end
BNGetNumFriendInvites = function() return request and 1 or 0 end
BNAcceptFriendInvite = function(id) accepted[#accepted + 1] = id end
BNDeclineFriendInvite = function(id) declined[#declined + 1] = id end
BNRemoveFriend = function(id) removed[#removed + 1] = id end
local filters, listeners = {}, {}
ChatFrameUtil = {AddMessageEventFilter = function(event, fn) filters[event] = fn end}
CreateFrame = function()
    local f = {}
    function f:RegisterEvent(event) if event == "BN_FRIEND_INFO_CHANGED" then error("missing event") end end
    function f:SetScript(event, fn) listeners[event] = fn end
    return f
end
assert(loadfile(addonPath .. "/FriendsList.lua"))("CommunicationToolsForever", FC)
FC.modules[1]:Initialize()
assert(#FC.tools == 1 and FC.db.friendsList.enabled)
local friends, requests = FC:GetSocialEntries()
assert(#friends == 2 and #requests == 1 and requests[1].detail == "WoW-only")
assert(FC:RespondToFriendRequest(77, true) and accepted[1] == 77)
assert(FC:RespondToFriendRequest(77, false) and declined[1] == 77)
assert(not FC:RespondToFriendRequest(99, true) and #accepted == 1)
BNAcceptFriendInvite = nil
assert(not FC:RespondToFriendRequest(77, true) and #declined == 1, "Missing approve must never decline")
BNAcceptFriendInvite = function() error("blocked") end
assert(not FC:RespondToFriendRequest(77, true))
assert(FC:SetSocialFriendMuted(friends[1], true))
assert(FC:IsFriendMuted(nil, nil, 20))
assert(FC:IsFriendMuted("Example Player", "Player-20"))
assert(filters.CHAT_MSG_BN_WHISPER({}, "CHAT_MSG_BN_WHISPER", "hello", "Example", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 20))
assert(not filters.CHAT_MSG_WHISPER_INFORM and not filters.CHAT_MSG_BN_WHISPER_INFORM)
assert(not FC:IsFriendMuted(secret, secret, secret))
assert(FC:SetSocialFriendMuted(friends[2], true))
assert(FC:IsFriendMuted("ALICE RAVEN"))
assert(FC:SetSocialFriendMuted(friends[2], false) and not FC:IsFriendMuted("Alice Raven"))
FC.db.friendsList.enabled = false
assert(not FC:IsFriendMuted(nil, nil, 20))
FC.db.friendsList.enabled = true
account.bnetAccountID = 21
assert(FC:IsFriendMuted(nil, nil, 21), "Stable BattleTag mute survives account ID changes")
assert(not FC:RemoveSocialFriend(friends[1]) and #removed == 0, "Stale IDs cannot remove another friend")
friends = FC:GetSocialEntries()
assert(FC:RemoveSocialFriend(friends[1]) and removed[1] == 21)
BNRemoveFriend = nil
assert(not FC:RemoveSocialFriend(friends[1]) and #legacyRemoved == 0, "Missing account API cannot call character removal")
assert(FC:RemoveSocialFriend(friends[2]) and legacyRemoved[1] == "Alice Raven")
legacy.name = "Changed Name"
assert(not FC:SetSocialFriendMuted(friends[2], true), "Stale row cannot mute replacement friend")
request = nil
assert(not FC:RespondToFriendRequest(77, true))
account = {bnetAccountID = 22, accountName = "Title Friend"}
friends = FC:GetSocialEntries()
assert(FC:SetSocialFriendMuted(friends[1], true))
assert(FC:IsFriendMuted(nil, nil, 22), "Unidentified stable account supports session mute")
account = secret
assert(#FC:GetSocialEntries() == 1, "Restricted account data is not inspected")
for key, value in pairs(saved) do _G[key] = value end
-- Restore globals that were nil before this isolated suite.
for _, key in ipairs({"C_BattleNet", "C_FriendList", "BNGetNumFriends", "BNGetNumFriendInvites", "BNAcceptFriendInvite", "BNDeclineFriendInvite", "BNRemoveFriend", "Enum"}) do _G[key] = saved[key] end
print("PASS: friend requests, stale identities, removal API selection, character/account mutes, restricted values and optional events")
