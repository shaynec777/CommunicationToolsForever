local clock, sent, events, filters = 100, {}, {}, {}
local secret = {}
local FC = { modules = {}, db = {} }
function FC:IsPublic(value) return value ~= secret end
function FC:RegisterTool(tool) self.tool = tool end
function FC:Print(message) self.lastPrint = message end
function FC:IsBlacklisted(name) return name == "Blocked Player" end
function FC:NormalizeBlacklistName(name)
    if type(name) ~= "string" or name == "" or name:find("[%d|:#]") then return end
    return name:lower(), name .. "-Realm"
end
GetTime = function() return clock end
UnitNameUnmodified = function() return "My", "Character" end
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function(_, event, callback) events[event] = callback end }
end
C_ChatInfo = { SendChatMessage = function(message, channel, _, target)
    assert(channel == "WHISPER")
    assert(#message <= 255)
    sent[#sent + 1] = { message = message, target = target }
end }
ChatFrameUtil = { AddMessageEventFilter = function(event, callback) filters[event] = callback end }
assert(loadfile("CommunicationToolsForever/DoNotDisturb.lua"))("CommunicationToolsForever", FC)
FC.modules[1]:Initialize()
local settings = FC.db.doNotDisturb
local function whisper(message, author, flag)
    events.OnEvent({}, "CHAT_MSG_WHISPER", message, author, nil, nil, nil, flag)
end
assert(not settings.enabled and not settings.forwarding)
whisper("Hello", "Alice Person")
assert(#sent == 0, "Disabled DND sends nothing")
assert(FC:SaveDNDSettings("Busy right now.", false, "", "relay", false))
FC:SetDNDEnabled(true)
whisper("Hello", "Alice Person")
assert(#sent == 1 and sent[1].target == "Alice Person" and sent[1].message == "[CT DND] Busy right now.")
whisper("Another message", "Alice Person")
assert(#sent == 1, "One response per sender per minute")
clock = 161
whisper("Later", "Alice Person")
assert(#sent == 2)
whisper("Secret", "Blocked Player")
whisper("Self", "My Character")
whisper(secret, "Other Person")
whisper("Hello", secret)
whisper("Hello", "Game Master", "GM")
whisper("[CT DND] Busy.", "Other Person")
whisper("[CT Forward] From Alice: Hello", "Other Person")
whisper("[CT Ignore] You are ignored.", "Other Person")
assert(#sent == 2, "Blacklist, self, GM, secret and automation exclusions")
assert(not FC:SaveDNDSettings("", false, "", "relay", false))
assert(not FC:SaveDNDSettings("Line\nbreak", false, "", "relay", false))
assert(not FC:SaveDNDSettings("Busy", true, "", "relay", false))
assert(not FC:SaveDNDSettings("Busy", true, "My Character", "relay", false))
assert(not FC:SaveDNDSettings("Busy", true, "Invalid#123", "relay", false))
assert(FC:SaveDNDSettings("Busy", true, "Forward Friend", "relay", false))
clock = 200
whisper("Please contact me", "Third Person")
assert(sent[#sent - 1].target == "Third Person")
assert(sent[#sent].target == "Forward Friend" and sent[#sent].message == "[CT Forward] From Third Person: Please contact me")
local before = #sent
whisper("Follow-up", "Third Person")
assert(#sent == before + 1 and sent[#sent].target == "Forward Friend", "Follow-ups forwarded despite reply cooldown")
before = #sent
whisper("From relay recipient", "Forward Friend")
assert(#sent == before, "Forward destination cannot cause a relay loop")
clock = 220
local long = string.rep("é", 120)
before = #sent
whisper(long, "Unicode Sender")
local reconstructed = ""
for index = before + 2, #sent do
    assert(sent[index].target == "Forward Friend")
    local content = sent[index].message:match("^%[CT Forward%] From Unicode Sender: (.*)$")
    assert(content and #content % 2 == 0, "UTF-8 boundaries preserved")
    reconstructed = reconstructed .. content
end
assert(reconstructed == long, "Forwarding splits long messages without losing text")
assert(FC:SaveDNDSettings("Busy", true, "Forward Friend", "refer", true))
clock = 240
before = #sent
whisper("Hello", "Referral Sender")
assert(#sent == before + 1 and sent[#sent].target == "Referral Sender")
assert(sent[#sent].message == "[CT DND] Busy Please whisper Forward Friend.")
assert(filters.CHAT_MSG_WHISPER({}, "CHAT_MSG_WHISPER", "Hello", "Someone", nil, nil, nil, "") == true)
assert(filters.CHAT_MSG_WHISPER({}, "CHAT_MSG_WHISPER", "Hello", "Someone", nil, nil, nil, "GM") == false)
FC:SetDNDEnabled(false)
assert(filters.CHAT_MSG_WHISPER({}, "CHAT_MSG_WHISPER", "Hello", "Someone", nil, nil, nil, "") == false)
assert(settings.target == "Forward Friend", "Disable preserves saved configuration")
clock = 300
FC:SetDNDEnabled(true)
assert(FC:SaveDNDSettings("Busy", false, "", "relay", false))
before = #sent
for index = 1, 50 do whisper("burst", string.rep("a", index)) end
assert(#sent - before <= 20, "Global outgoing rate limit")
print("PASS: DND defaults, custom replies, cooldown, forwarding/referral, full names, UTF-8 chunks, hide option, loop/blacklist/GM/secret guards and rate limit")
