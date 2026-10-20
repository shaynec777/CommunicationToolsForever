local FC = { modules = {}, db = {} }
local secret, sent, clock, listener = {}, {}, 100, nil
function FC:IsPublic(value) return value ~= secret end
function FC:Print() end
function FC:RegisterTool() end
GetNormalizedRealmName = function() return "Realm" end
GetTime = function() return clock end
UnitNameUnmodified = function() return "My", "Character" end
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function(_, _, callback) listener = callback end }
end
EventRegistry = { RegisterCallback = function() end }
local filter
ChatFrameUtil = { AddMessageEventFilter = function(event, callback) if event == "CHAT_MSG_WHISPER" then filter = callback end end }
C_ChatInfo = { SendChatMessage = function(message, channel, _, target)
    assert(channel == "WHISPER" and #message <= 255)
    sent[#sent + 1] = { message = message, target = target }
end }
assert(loadfile("CommunicationToolsForever/ExtendedIgnore.lua"))("CommunicationToolsForever", FC)
FC.modules[1]:Initialize()
assert(FC.db.extendedIgnore.replyEnabled, "Requested notification defaults to enabled")
assert(FC:AddBlacklistName("Ignored Person"))
local function whisper(message, author, flags)
    listener({}, "CHAT_MSG_WHISPER", message, author, nil, nil, nil, flags)
end
whisper("Hello", "Ignored Person")
assert(#sent == 1 and sent[1].target == "Ignored Person")
assert(sent[1].message == "[CT Ignore] " .. FC.defaultIgnoreReply)
assert(filter({}, "CHAT_MSG_WHISPER", "Hello", "Ignored Person"), "Reply does not unhide incoming message")
whisper("Again", "Ignored Person")
assert(#sent == 1, "Only one reply per sender per minute")
clock = 161
whisper("[CT Ignore] Ignored.", "Ignored Person")
whisper("[CT DND] Busy.", "Ignored Person")
whisper("[CT Forward] From someone: Hello", "Ignored Person")
whisper(secret, "Ignored Person")
whisper("Hello", secret)
whisper("Hello", "Ignored Person", "GM")
assert(#sent == 1, "No replies to automated, secret, or GM messages")
assert(FC:SaveIgnoreReply(true, "You are on ignore."))
whisper("Hello", "Ignored Person")
assert(#sent == 2 and sent[2].message == "[CT Ignore] You are on ignore.")
assert(not FC:SaveIgnoreReply(true, ""))
assert(not FC:SaveIgnoreReply(true, string.rep("a", 231)))
assert(not FC:SaveIgnoreReply(true, "Bad\ntext"))
assert(FC:SaveIgnoreReply(false, "You are on ignore."))
clock = 222
whisper("No notification", "Ignored Person")
assert(#sent == 2)
assert(FC:SaveIgnoreReply(true, "You are on ignore."))
FC:SetExtendedIgnoreEnabled(false)
whisper("Tool disabled", "Ignored Person")
assert(#sent == 2)
FC:SetExtendedIgnoreEnabled(true)
assert(FC:AddBlacklistName("My Character"))
whisper("Self", "My Character")
assert(#sent == 2, "No self notification")
whisper("Not blacklisted", "Other Person")
assert(#sent == 2)
clock = 300
local before = #sent
for index = 1, 40 do
    local name = string.rep("a", index)
    assert(FC:AddBlacklistName(name))
    whisper("Burst", name)
end
assert(#sent - before == 10, "Global ignore reply rate limit")
print("PASS: ignore notifications, custom text, hidden messages, cooldown, disable, rate limit, and automated/secret/GM/self exclusions")
