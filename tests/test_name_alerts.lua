local FC = { modules = {}, db = { doNotDisturb = { enabled = false, hide = false } } }
local secret, clock, soundCount, notices, listener = {}, 100, 0, {}, nil
local timers, first, surname = {}, "Ann", "Raven"
local combat = false
InCombatLockdown = function() return combat end
function FC:IsPublic(value) return value ~= secret end
function FC:RegisterTool() end
function FC:Print(message) notices[#notices + 1] = message end
function FC:IsBlacklisted(name) return name == "Ignored Person" end
function FC:NormalizeBlacklistName(name) return type(name) == "string" and name:lower() or nil end
GetTime = function() return clock end
UnitNameUnmodified = function() return first, surname end
PlaySound = function() soundCount = soundCount + 1 end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
CreateFrame = function()
    local frame = { scripts = {} }
    setmetatable(frame, { __index = function(_, key)
        if key == "SetScript" then return function(self, event, callback) self.scripts[event] = callback; listener = self end end
        if key == "CreateFontString" then return function() return CreateFrame() end end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        return function() end
    end })
    return frame
end
assert(loadfile("CommunicationToolsForever/NameAlerts.lua"))("CommunicationToolsForever", FC)
FC.modules[1]:Initialize()
local settings = FC.db.nameAlerts
assert(FC:NameMentionMatches("Hey ANN!"), "First name, case insensitive")
assert(FC:NameMentionMatches("Raven, you around?"), "Surname")
assert(FC:NameMentionMatches("Thanks Ann Raven."), "Full name")
assert(not FC:NameMentionMatches("A banner and ravens."), "Whole-word boundaries reject longer words")
assert(not FC:NameMentionMatches("ann_thing"), "Underscore is a word boundary exclusion")
assert(FC:NameMentionMatches("|Hplayer:Ann Raven:1|h[Ann Raven]|h says hi"), "Displayed hyperlink name")
assert(not FC:NameMentionMatches("|Hitem:Ann|h[Unrelated item]|h"), "Hyperlink metadata ignored")
settings.insideWords = true
assert(FC:NameMentionMatches("A banner"), "Optional substring match")
settings.insideWords = false
settings.first, settings.last = false, false
assert(not FC:NameMentionMatches("Hi Ann!"))
assert(FC:NameMentionMatches("Hi Ann Raven!"))
settings.first, settings.last = true, true
assert(not FC:NameMentionMatches(secret))
local function chat(event, message, author, channelName, channelIndex)
    listener.scripts.OnEvent(listener, event, message, author or "Other Person", nil, channelName, nil, nil, nil, channelIndex)
end
chat("CHAT_MSG_CHANNEL", "Hi Ann!", nil, "Trade - English", 2)
assert(#notices == 1 and soundCount == 1 and FC.nameAlertBanner.shown)
assert(notices[1]:find("[2. Trade - English]", 1, true), "Notice identifies numbered channel")
assert(FC:NameAlertChannel("CHAT_MSG_CHANNEL", "2. Trade - English", 2) == "2. Trade - English", "No duplicate channel number")
assert(FC:NameAlertChannel("CHAT_MSG_CHANNEL", secret, secret, "General") == "General", "Restricted channel metadata skipped safely")
assert(FC:NameAlertChannel("CHAT_MSG_GUILD") == "Guild")
assert(FC:NameAlertChannel("CHAT_MSG_PARTY") == "Party")
assert(FC:NameAlertChannel("CHAT_MSG_RAID_WARNING") == "Raid Warning")
assert(FC:NameAlertChannel("CHAT_MSG_COMMUNITIES_CHANNEL") == "Community")
chat("CHAT_MSG_SAY", "Hi Raven!")
assert(#notices == 1, "Cooldown across chat types")
clock = 106
chat("CHAT_MSG_SAY", "Ann!", "Ann Raven")
chat("CHAT_MSG_SAY", "Ann!", "Ignored Person")
chat("CHAT_MSG_SAY", "[CT Ignore] Ann!")
chat("CHAT_MSG_SAY", secret)
chat("CHAT_MSG_SAY", "Ann!", secret)
chat("CHAT_MSG_WHISPER", "Ann!")
assert(#notices == 1, "Self, ignored, automated, secret and disabled-channel exclusions")
settings.whispers = true
FC.db.doNotDisturb.enabled, FC.db.doNotDisturb.hide = true, true
chat("CHAT_MSG_WHISPER", "Ann!")
assert(#notices == 1, "DND-hidden whispers do not alert")
FC.db.doNotDisturb.hide = false
chat("CHAT_MSG_WHISPER", "Ann!")
assert(#notices == 2)
assert(notices[2]:find("[Whisper]", 1, true))
timers[1]()
assert(FC.nameAlertBanner.shown, "Older expiry doesn't hide newer alert")
timers[2]()
assert(not FC.nameAlertBanner.shown)
FC:SetNameAlertsEnabled(false)
clock = 120
chat("CHAT_MSG_SAY", "Ann!")
assert(#notices == 2)
FC:SetNameAlertsEnabled(true)
settings.sound, settings.banner = false, false
chat("CHAT_MSG_SAY", "Ann!")
assert(#notices == 3 and soundCount == 2 and not FC.nameAlertBanner.shown, "Sound and banner optional")
first, surname = "Ann Raven", "Raven"
assert(FC:GetNameAlertIdentity() == "Ann Raven", "Combined API names do not duplicate surname")
first, surname = "Зомби", "Терапевт"
assert(FC:NameMentionMatches("Привет, Терапевт!"), "UTF-8 names supported")
assert(not FC:NameMentionMatches("НеТерапевт"), "No match within a larger UTF-8 word")
settings.banner, settings.sound = true, true
assert(settings.suppressInCombat, "Combat suppression defaults on")
FC:ShowNameAlert("Tester", "Outside combat", "Party")
assert(FC.nameAlertBanner.shown)
combat = true
chat("PLAYER_REGEN_DISABLED", "")
assert(not FC.nameAlertBanner.shown, "Combat entry hides existing banner")
local soundsBefore, noticesBefore = soundCount, #notices
FC:ShowNameAlert("Tester", "During combat", "Party")
assert(not FC.nameAlertBanner.shown and soundCount == soundsBefore + 1 and #notices == noticesBefore + 1, "Only popup suppressed in combat")
settings.suppressInCombat = false
FC:ShowNameAlert("Tester", "Opted in during combat", "Party")
assert(FC.nameAlertBanner.shown, "Combat suppression can be disabled")
combat = false
print("PASS: Name Alerts identity, full/first/surname, word/substring matches, channels, cooldown, sound/banner, ignored/self/secret/DND exclusions and UTF-8 names")
print("PASS: combat entry hides popup; combat suppression preserves sound/chat and can be disabled")
