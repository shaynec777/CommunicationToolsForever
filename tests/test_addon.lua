local frames, filters, callbacks = {}, {}, {}
local ctrl, shift = false, false
local secret = {}
local methods = {}
function methods:RegisterEvent(event)
    assert(event ~= "UNIT_GUILD_UPDATE", "Forever rejects the unsupported UNIT_GUILD_UPDATE event")
end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:HookScript(event, callback)
    local previous = self.scripts[event]
    self.scripts[event] = function(...)
        if previous then previous(...) end
        callback(...)
    end
end
function methods:SetText(value)
    self.text = value
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function methods:GetText() return rawget(self, "text") or "" end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:HasFocus() return false end
function methods:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.shown = false end
local function frame(kind, name, parent)
    local obj = { kind = kind, name = name, parent = parent, scripts = {} }
    setmetatable(obj, { __index = function(_, key) return methods[key] or function() end end })
    frames[#frames + 1] = obj
    return obj
end
function methods:CreateFontString() return frame("FontString") end
function methods:GetThumbTexture() return frame("Texture") end
function methods:CreateTexture() return frame("Texture") end
CreateFrame = frame
UIParent = { GetWidth = function() return 1920 end, GetHeight = function() return 1080 end }
UISpecialFrames = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
issecretvalue = function(value) return value == secret end
UnitGUID = function() return "Player-TestOwner" end
GetNormalizedRealmName = function() return "HomeRealm" end
GetRealmName = function() return "Home Realm" end
Enum = {GameRule = {HardcoreRuleset = 1, RPRuleset = 2, PvPRuleset = 3}}
C_GameRules = {IsGameRuleActive = function() return false end}
UnitFactionGroup = function() return "Alliance" end
GetTime = function() return 100 end
IsControlKeyDown = function() return ctrl end
IsShiftKeyDown = function() return shift end
C_UnitAuras = { GetAuraDataByIndex = function() return nil end }
ChatFrameUtil = { AddMessageEventFilter = function(event, fn)
    local previous = filters[event]
    filters[event] = function(...)
        if previous and previous(...) then return true end
        return fn(...)
    end
end }
EventRegistry = { RegisterCallback = function(_, event, fn, owner) callbacks[event] = {fn, owner} end }
Settings = {
    RegisterCanvasLayoutCategory = function(container, name) return {name = name, GetID = function() return 42 end} end,
    RegisterAddOnCategory = function() end,
}
local openedCategory, openCount = nil, 0
Settings.OpenToCategory = function(id) openedCategory = id; openCount = openCount + 1 end
ChatFrame1 = frame("ScrollingMessageFrame", "ChatFrame1")
local originalClicks = 0
ChatFrame1:SetScript("OnMouseUp", function() originalClicks = originalClicks + 1 end)
CHAT_FRAMES = {"ChatFrame1"}
local hooks = {}
hooksecurefunc = function(name, callback) hooks[name] = callback end
FCF_OpenNewWindow = function() end
FCF_OpenTemporaryWindow = function() end
local FC = {}
for _, file in ipairs({"Core.lua", "RaceThanks.lua", "BuffThanks.lua", "ExtendedIgnore.lua", "DoNotDisturb.lua", "NameAlerts.lua", "WhisperConversations.lua", "FilterChat.lua", "FilterGuild.lua", "FriendsList.lua", "Settings.lua", "ChatAccess.lua"}) do
    assert(loadfile("CommunicationToolsForever/" .. file))("CommunicationToolsForever", FC)
end
for _, f in ipairs(frames) do
    if f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", "CommunicationToolsForever") end
end
assert(#FC.tools == 8, "All tools initialize before settings")
assert(FC.db.extendedIgnore.enabled)
assert(FC:AddBlacklistName("  Alice  "))
assert(FC:IsBlacklisted("ALICE-Home Realm"), "Case and realm whitespace normalization")
assert(FC:IsBlacklisted("alice"), "Unqualified author matches current realm")
assert(FC:IsBlacklisted("Alice-OtherRealm"), "Forever display suffix does not split a context identity")
assert(not FC:AddBlacklistName("Alice-HomeRealm"), "Duplicate add")
assert(FC:AddBlacklistName("Bob-Other Realm"))
for event, filter in pairs(filters) do
    assert(filter({}, event, "message", "Bob-OtherRealm") == (event ~= "CHAT_MSG_BN_WHISPER"), event .. " filters blocked author where character ignore applies")
    assert(filter({}, event, "message", "Unknown-OtherRealm") == false, event .. " passes other author")
    assert(filter({}, event, "message", secret) == false, event .. " skips secret author")
end
assert(filters.CHAT_MSG_WHISPER and filters.CHAT_MSG_CHANNEL and filters.CHAT_MSG_GUILD)
assert(not filters.CHAT_MSG_WHISPER_INFORM, "Don't suppress outgoing whispers")
assert(not FC:AddBlacklistName("Bad|Hplayer:Link"))
assert(FC:AddBlacklistName("Some One"), "Forever names can contain surnames")
assert(FC:IsBlacklisted("some one-HomeRealm"))
assert(FC:IsBlacklisted("Some One-OtherRealm"))
assert(not FC:AddBlacklistName("Name#1234"))
assert(not FC:AddBlacklistName("Name-"))
assert(not FC:AddBlacklistName(secret))
assert(FC:AddBlacklistName("Chloé-HomeRealm"), "Accented character names")
FC:SetExtendedIgnoreEnabled(false)
assert(not FC:IsBlacklisted("Alice"), "Disabled tool passes messages")
assert(FC.db.extendedIgnore.blacklist["alice"], "Disabling preserves list")
local click = callbacks["ChatFrame.OnHyperlinkClick"]
local function nameClick(link, button)
    click[1](click[2], {}, link, "[Name]", button or "LeftButton")
end
ctrl, shift = true, true
nameClick("player:Disabled:12:WHISPER")
assert(not FC.db.extendedIgnore.blacklist["disabled"])
FC:SetExtendedIgnoreEnabled(true)
ctrl, shift = true, false
nameClick("player:Charlie:12:WHISPER")
assert(not FC:IsBlacklisted("Charlie"))
ctrl, shift = true, true
nameClick("player:Charlie-OtherRealm:12:WHISPER")
assert(FC:IsBlacklisted("Charlie-OtherRealm"), "Modifier name click adds full character")
nameClick("player:Voljen Mindshaper:12:CHANNEL")
assert(FC:IsBlacklisted("Voljen Mindshaper"), "Modifier click accepts Forever multi-part name")
assert(not FC:AddBlacklistName("Voljen Mindshaper-HomeRealm"), "Multi-part duplicate detection")
assert(FC:RemoveBlacklistName("Voljen Mindshaper"))
assert(not FC:IsBlacklisted("Voljen Mindshaper"))
nameClick("player:Rightclick:12", "RightButton")
nameClick("item:1234")
assert(not FC:IsBlacklisted("Rightclick"))
assert(FC:RemoveBlacklistName("alice"))
assert(not FC:IsBlacklisted("Alice"))
assert(not FC:RemoveBlacklistName("alice"))
-- Reinitialization exercises persisted lists and rejects malformed saved entries.
FC.db.extendedIgnore.blacklist.invalid = false
FC.modules[2]:Initialize()
assert(FC:IsBlacklisted("Charlie-OtherRealm"), "Persisted names survive initialization")
assert(not FC.db.extendedIgnore.blacklist.invalid)
-- Exercise the settings editor's Add button and a visible Remove button.
local input, add, remove = FC.ignoreListEditor.input, FC.ignoreListEditor.add, FC.ignoreListEditor.rows[1].remove
input:SetText("Editorname")
add.scripts.OnClick(add)
assert(FC:IsBlacklisted("Editorname"), "Settings editor adds character")
local before = 0
for _ in pairs(FC.db.extendedIgnore.blacklist) do before = before + 1 end
remove.scripts.OnClick(remove)
local after = 0
for _ in pairs(FC.db.extendedIgnore.blacklist) do after = after + 1 end
assert(after == before - 1, "Settings Remove button removes an entry")
local ignoreReplyToggle
for _, f in ipairs(frames) do
    if f.name == "CommunicationToolsForeverIgnoreReplyToggle" then ignoreReplyToggle = f end
end
assert(ignoreReplyToggle)
ignoreReplyToggle:SetChecked(false)
ignoreReplyToggle.scripts.OnClick(ignoreReplyToggle)
assert(not FC.db.extendedIgnore.replyEnabled, "Ignore reply toggle applies without Save")
ignoreReplyToggle:SetChecked(true)
ignoreReplyToggle.scripts.OnClick(ignoreReplyToggle)
assert(FC.db.extendedIgnore.replyEnabled)
-- Existing template behavior still handles arbitrary order, repeated tokens and percent signs.
local template = "100% thanks for <buffname>, <buffername>! <buffname>"
assert(FC:SetThanksTemplate(template))
assert(FC:FormatThanks("Fortitude", "Alex") == "100% thanks for Fortitude, Alex! Fortitude")
assert(FC:SetThanksTemplate("Thanks!"))
assert(FC:FormatThanks("Fortitude", "Alex") == "Thanks!", "Plain message without labels saves and renders")
assert(FC:SetThanksTemplate("Thanks for <buffname>!"))
assert(FC:FormatThanks("Fortitude", "Alex") == "Thanks for Fortitude!")
assert(FC:SetThanksTemplate("Thanks, <buffername>!"))
assert(FC:FormatThanks("Fortitude", "Alex") == "Thanks, Alex!")
assert(not FC:SetThanksTemplate(" "))
FC.db.thanksTemplates = nil
FC.db.thanksTemplate = "Custom thanks to <buffername> for <buffname>!"
FC:InitializeThanksTemplates()
assert(FC.db.thanksTemplates[1] == FC.db.thanksTemplate and #FC.db.thanksTemplates == 4, "Migration preserves custom message and adds three defaults")
local pool = {}
for index = 1, 4 do pool[index] = "Choice " .. index .. ": <buffname>, <buffername>!" end
assert(FC:SetThanksTemplates(pool))
local random = math.random
for index = 1, 4 do
    math.random = function(count) assert(count == 4); return index end
    assert(FC:FormatThanks("Fortitude", "Alex") == "Choice " .. index .. ": Fortitude, Alex!", "Every pool entry can be selected")
end
math.random = random
assert(not FC:SetThanksTemplates({"", "", "", ""}), "All-blank pools rejected")
assert(not FC:SetThanksTemplates({pool[1], "Invalid | formatting", "", ""}))
assert(FC.db.thanksTemplates[2] == pool[2], "Invalid pool save is atomic")
assert(FC:SetThanksTemplates({"", pool[2], " ", ""}))
assert(FC:FormatThanks("Fortitude", "Alex") == "Choice 2: Fortitude, Alex!", "Blank slots excluded")
local longTemplate = string.rep("x", 164) .. " <buffname> <buffername>"
assert(FC:SetThanksTemplates({longTemplate, pool[2], "", ""}))
local longBuff = string.rep("b", 100)
assert(FC:FormatThanks(longBuff, "Alex") == "Choice 2: " .. longBuff .. ", Alex!", "Overlong expanded entries excluded without losing valid choices")
assert(FC:SetThanksTemplates(FC.defaultThanksTemplates))
local editors, savePool = {}, nil
for _, f in ipairs(frames) do
    if f.kind == "EditBox" and f.parent == FC.settingsPages.buffThanks.content and f.isBuffExclusions ~= true then editors[#editors + 1] = f end
    if f.text == "Save messages" then savePool = f end
end
assert(#editors == 4 and savePool)
for index, editor in ipairs(editors) do editor:SetText(pool[index]) end
savePool.scripts.OnClick()
for index = 1, 4 do assert(FC.db.thanksTemplates[index] == pool[index]) end
print("PASS: four-template migration, editor save, random selection, blanks, atomic validation and expanded message length")
local openSettings = FC.OpenSettings
FC.OpenSettings = function(self)
    openCount = openCount + 1
    return openSettings(self)
end
local function mouse(frame, button)
    frame.scripts.OnMouseDown(frame, button)
    frame.scripts.OnMouseUp(frame, button)
end
mouse(ChatFrame1, "RightButton")
assert(FC.currentSettingsPage == "main" and openCount == 1, "Right-click opens main tool menu")
assert(originalClicks == 1, "Original mouse handler preserved")
mouse(ChatFrame1, "LeftButton")
assert(openCount == 1, "Left-click doesn't open settings")
ChatFrame1.scripts.OnHyperlinkEnter(ChatFrame1, "player:Name")
mouse(ChatFrame1, "RightButton")
assert(openCount == 1, "Name/link right-click doesn't open settings")
ChatFrame1.scripts.OnMouseDown(ChatFrame1, "RightButton")
ChatFrame1.scripts.OnHyperlinkLeave(ChatFrame1)
ChatFrame1.scripts.OnMouseUp(ChatFrame1, "RightButton")
assert(openCount == 1, "Link remains excluded if its menu causes hover to leave")
mouse(ChatFrame1, "RightButton")
assert(openCount == 2)
ChatFrame99 = frame("ScrollingMessageFrame", "ChatFrame99")
CHAT_FRAMES[#CHAT_FRAMES + 1] = "ChatFrame99"
hooks.FCF_OpenTemporaryWindow()
hooks.FCF_OpenNewWindow()
mouse(ChatFrame99, "RightButton")
assert(openCount == 3, "New windows hooked once")
mouse(ChatFrame1, "RightButton")
assert(openCount == 4, "Repeated scans don't duplicate hooks")
assert(SLASH_FOREVERCOMMUNICATIONS1 == "/ct" and SLASH_FOREVERCOMMUNICATIONS3 == "/fc")
SlashCmdList.FOREVERCOMMUNICATIONS("")
assert(openCount == 5, "Bare /ct opens settings")
SlashCmdList.FOREVERCOMMUNICATIONS("status")
assert(openCount == 5, "Explicit status does not open settings")
assert(#FC.toolMenuControls == 8)
local buffCard, ignoreCard = FC.toolMenuControls[1], FC.toolMenuControls[2]
buffCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "buffThanks")
assert(FC.settingsPages.buffThanks.root.shown and not FC.settingsPages.extendedIgnore.root.shown and not FC.settingsPages.main.root.shown)
ignoreCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "extendedIgnore")
assert(FC.settingsPages.extendedIgnore.root.shown and not FC.settingsPages.buffThanks.root.shown)
FC:OpenSettings()
buffCard.control:SetChecked(false)
buffCard.control.scripts.OnClick(buffCard.control)
assert(not FC.db.enabled and FC.db.extendedIgnore.enabled, "Main menu toggles tools independently")
buffCard.control:SetChecked(true)
buffCard.control.scripts.OnClick(buffCard.control)
ignoreCard.control:SetChecked(false)
ignoreCard.control.scripts.OnClick(ignoreCard.control)
assert(FC.db.enabled and not FC.db.extendedIgnore.enabled)
ignoreCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "extendedIgnore", "Disabled tools remain configurable")
local backButton
for _, f in ipairs(frames) do
    if f.text == "Back to tools" and f.parent == FC.settingsPages.extendedIgnore.root then backButton = f end
end
assert(backButton)
backButton.scripts.OnClick()
assert(FC.currentSettingsPage == "main" and FC.settingsPages.main.root.shown)
local dndCard = FC.toolMenuControls[3]
assert(not FC.db.doNotDisturb.enabled, "DND starts disabled")
dndCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "doNotDisturb" and FC.settingsPages.doNotDisturb.root.shown)
local dndInputs, saveDND = {}, nil
for _, f in ipairs(frames) do
    if f.kind == "EditBox" and f.parent == FC.settingsPages.doNotDisturb.content then dndInputs[#dndInputs + 1] = f end
    if f.text == "Save DND settings" then saveDND = f end
end
assert(#dndInputs == 2 and saveDND)
dndInputs[1]:SetText("Busy at the moment.")
saveDND.scripts.OnClick()
assert(FC.db.doNotDisturb.response == "Busy at the moment.", "DND page saves its response")
dndCard.control:SetChecked(true)
dndCard.control.scripts.OnClick(dndCard.control)
assert(FC.db.doNotDisturb.enabled and FC.db.enabled, "DND enable is independent")
dndCard.control:SetChecked(false)
dndCard.control.scripts.OnClick(dndCard.control)
local namesCard = FC.toolMenuControls[4]
namesCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "nameAlerts" and FC.settingsPages.nameAlerts.root.shown)
namesCard.control:SetChecked(false)
namesCard.control.scripts.OnClick(namesCard.control)
assert(not FC.db.nameAlerts.enabled)
namesCard.control:SetChecked(true)
namesCard.control.scripts.OnClick(namesCard.control)
print("PASS: Lua 5.1 addon initialization, blacklist filters/editor/clicks, persistence, templates, and right-click access with link exclusion and new windows")
print("PASS: main tool cards, separate tool pages, independent enable checkboxes, disabled-tool settings and back navigation")
assert(FC:SetBuffExclusions("Cantation of Manifestation\n Test Buff "))
assert(FC.db.buffExclusions["test buff"] == "Test Buff")
assert(FC:GetBuffExclusionsText():find("Cantation of Manifestation", 1, true))
assert(not FC:SetBuffExclusions("|Hbad"))
assert(FC:SetBuffExclusions(""))
assert(next(FC.db.buffExclusions) == nil)
local conversationCard = FC.toolMenuControls[5]
conversationCard.configure.scripts.OnClick()
assert(FC.currentSettingsPage == "whisperConversations" and FC.settingsPages.whisperConversations.root.shown)
conversationCard.control:SetChecked(false)
conversationCard.control.scripts.OnClick(conversationCard.control)
assert(not FC.db.whisperConversations.enabled)
conversationCard.control:SetChecked(true)
conversationCard.control.scripts.OnClick(conversationCard.control)
assert(FC.db.whisperConversations.enabled)
local openConversations
for _, f in ipairs(frames) do if f.text == "Open conversations" then openConversations = f end end
assert(openConversations)
openConversations.scripts.OnClick()
assert(not FC.settingsPages.whisperConversations.root.shown and FC.currentSettingsPage == nil,
    "Opening conversations dismisses settings rather than overlapping controls")
local conversationWindow
for _, f in ipairs(frames) do if f.messages and type(f.messages) == "table" and f.reply and type(f.reply) == "table" then conversationWindow = f end end
assert(conversationWindow and conversationWindow.shown, "Conversation window opens after settings closes")


assert(FC.db.thanksInInstances == false, "Instance thanks start off for existing and new settings")
local savedFocus, savedTimer, savedChat, savedChannel = FC.IsConversationReplyFocused, C_Timer, C_ChatInfo, FC.db.channel
local typing, delayed, delivered = true, {}, {}
FC.IsConversationReplyFocused = function() return typing end
C_Timer = {After = function(delay, callback) assert(delay == 0.5); delayed[#delayed + 1] = callback end}
C_ChatInfo = {SendChatMessage = function(message, channel, language, target) delivered[#delivered + 1] = {message, target} end}
FC.db.channel, FC.db.enabled = "WHISPER", true
assert(FC:Deliver("Thanks!", "Norpse Numnum") == "queued")
assert(#delivered == 0)
delayed[1]()
assert(#delivered == 0 and #delayed == 2, "Do not send while typing continues")
typing = false
delayed[2]()
assert(#delivered == 1 and delivered[1][2] == "Norpse Numnum", "Send to buff caster after focus clears")
typing = true
FC:Deliver("Thanks again", "Other Person")
FC:ClearQueue()
typing = false
delayed[3]()
assert(#delivered == 1, "Clearing queue cancels deferred whispers")
FC.IsConversationReplyFocused, C_Timer, C_ChatInfo, FC.db.channel = savedFocus, savedTimer, savedChat, savedChannel
print("PASS: buff thanks defers while typing and cancels stale queued delivery")

assert(FC:SetChatFilterKeywords("  boost\nWTS\n100%\na.b\nBOOST\n"))
assert(#FC.db.filterChat.keywords == 4)
assert(FC:IsChatFiltered("Selling BOOSTS today"))
assert(FC:IsChatFiltered("100% ready"))
assert(FC:IsChatFiltered("a.b"))
assert(not FC:IsChatFiltered("axb"), "Keywords are literal, not Lua patterns")
assert(not FC:IsChatFiltered(secret))
assert(not FC:IsChatFiltered(nil))
assert(FC:IsChatFiltered("|cff00ff00WTS|r |Hitem:123|h[Item]|h"))
assert(not FC:IsChatFiltered("|Hitem:boost|h[Item]|h"), "Ignore hidden link identifiers")
assert(filters.CHAT_MSG_CHANNEL({}, "CHAT_MSG_CHANNEL", "wts items", "Unknown"))
FC.db.filterChat.enabled = false
assert(not FC:IsChatFiltered("boost"))
FC.db.filterChat.enabled = true
assert(not FC:SetChatFilterKeywords("|Hbad"))
assert(FC:IsChatFiltered("boost"), "Invalid save preserves list")
FC.db.filterChat.scopes.guild = false
assert(not FC:IsChatFiltered("boost", "CHAT_MSG_GUILD"))
assert(FC:IsChatFiltered("boost", "CHAT_MSG_CHANNEL", 2))
FC.db.filterChat.scopes.trade = false
assert(not FC:IsChatFiltered("boost", "CHAT_MSG_CHANNEL", 2))
assert(FC:IsChatFiltered("boost", "CHAT_MSG_CHANNEL", 1))
FC.db.filterChat.scopes.guild, FC.db.filterChat.scopes.trade = true, true
assert(FC:SetGuildFilterNames(" Bad Guild\nBAD GUILD\nOther Guild"))
assert(#FC.db.filterGuild.guilds == 2)
local originalGUID, originalGuild, originalToken = UnitGUID, GetGuildInfo, UnitTokenFromGUID
UnitGUID = function(unit) return unit == "target" and "Player-123" or nil end
GetGuildInfo = function() return "Bad Guild" end
UnitTokenFromGUID = function(guid) return guid == "Player-123" and "target" or nil end
assert(FC:IsGuildFiltered("Somebody", "Player-123"))
assert(filters.CHAT_MSG_CHANNEL({}, "CHAT_MSG_CHANNEL", "hello", "Somebody", nil, nil, nil, nil, 2, 2, "Trade", nil, 1, "Player-123"), "Guild filter receives sender GUID")
local oldClock = GetTime
GetTime = function() return 401 end
UnitTokenFromGUID = function() return nil end
assert(FC:IsGuildFiltered("Somebody", "Player-123"), "Learned membership does not expire after five minutes")
GetTime = oldClock
UnitTokenFromGUID = function() return "target" end
assert(FC:IsGuildFiltered("Somebody", "Player-123"))
GetGuildInfo = function() error("unavailable") end
assert(FC:IsGuildFiltered("Somebody", "Player-123"), "Temporary failure retains recent sighting")
GetGuildInfo = function() return "Bad Guild" end
FC.db.filterGuild.enabled = false
assert(not FC:IsGuildFiltered("Somebody", "Player-123"))
FC.db.filterGuild.enabled = true

assert(not FC:IsGuildFiltered("Unknown", "Player-999"))
assert(not FC:IsGuildFiltered("Secret", secret))
UnitTokenFromGUID = function() return nil end
assert(FC:IsGuildFiltered("Somebody", "Player-123"), "Recent sightings are cached")
UnitTokenFromGUID = function() return "target" end
GetGuildInfo = function() return nil end
assert(not FC:IsGuildFiltered("Somebody", "Player-123"), "Guildless observation clears membership")
GetGuildInfo = function() return "Bad Guild Extra" end
assert(not FC:IsGuildFiltered("Somebody", "Player-123"), "Full guild names match exactly")
UnitGUID, GetGuildInfo, UnitTokenFromGUID = originalGUID, originalGuild, originalToken
assert(not FC.db.filterGuild.useImports, "Imports are off by default")
assert(FC:ImportGuildRoster("Bad Guild", "Alice Raven\nALICE RAVEN\nBob Stone"))
assert(FC.db.filterGuild.imports["bad guild"].count == 2)
assert(not FC:IsGuildFiltered("Alice Raven", nil))
FC.db.filterGuild.useImports = true
assert(FC:IsGuildFiltered("Alice Raven", nil), "Optional import identifies unavailable senders")
assert(FC:IsGuildFiltered("Alice Raven-OtherRealm", nil), "Forever import matches full name within its ruleset/faction context")
assert(not FC:IsGuildFiltered(secret, nil))
assert(not FC:IsGuildFiltered("Alice Raven", secret))
assert(not FC:ImportGuildRoster("Bad Guild", "Alice Raven\n|Hbad"))
assert(FC:IsGuildFiltered("Alice Raven", nil), "Invalid replacement is atomic")
assert(FC:ImportGuildRoster("Unlisted Guild", "Unknown Person"))
assert(not FC:IsGuildFiltered("Unknown Person", nil), "Imports do not add guilds to blacklist")
assert(FC:ImportGuildRoster("Activated Guild", "Imported Tester", true))
assert(FC.db.filterGuild.useImports and FC:GuildNameMatchesFilter("Activated Guild"))
assert(FC:IsGuildFiltered("Imported Tester", nil), "UI imports activate guild and roster")
local importedVisible = false
for _, group in ipairs(FC:GetGuildMemberBlacklists()) do
    if group.guild == "Activated Guild" and #group.members == 1 then importedVisible = true end
end
assert(importedVisible, "Activated import appears in guild blacklists")
assert(FC:RemoveGuildFilterName("Activated Guild"))
assert(FC:ImportGuildRoster("Bad Guild", "New Member"))
assert(not FC:IsGuildFiltered("Alice Raven", nil), "Replacing removes departed members")
assert(FC:IsGuildFiltered("New Member", nil))
UnitGUID = function() return "Player-123" end
GetGuildInfo = function() return "Allowed Guild" end
UnitTokenFromGUID = function() return "target" end
assert(not FC:IsGuildFiltered("New Member", "Player-123"), "Current membership overrides stale import")
UnitGUID, GetGuildInfo, UnitTokenFromGUID = originalGUID, originalGuild, originalToken
assert(FC:RemoveImportedGuildRoster("Bad Guild"))
assert(not FC:IsGuildFiltered("New Member", nil))
assert(not FC:RemoveImportedGuildRoster("Missing Guild"))
local reloaded = {modules = {}, db = FC.db, IsPublic = FC.IsPublic, NormalizeBlacklistName = FC.NormalizeBlacklistName, RegisterTool = function() end, Print = function() end}
FC.db.filterGuild.learned.invalid = {guild = "Bad Guild"}
FC.db.filterGuild.learned["Player-Broken"] = {guild = false}
assert(loadfile("CommunicationToolsForever/FilterGuild.lua"))("CommunicationToolsForever", reloaded)
reloaded.modules[1]:Initialize()
UnitTokenFromGUID = function() return nil end
assert(reloaded.db.filterGuild.learned["Player-123"], "Learned membership survives addon reinitialization")
assert(not reloaded.db.filterGuild.learned.invalid and not reloaded.db.filterGuild.learned["Player-Broken"], "Invalid saved observations are dropped")
assert(not reloaded:IsGuildFiltered("Somebody", "Player-123"), "Observed different guild persists across sessions")
reloaded.db.filterGuild.learned["Player-456"] = {guild = "Bad Guild"}
assert(reloaded:IsGuildFiltered("Remembered Player", "Player-456"), "Persisted member filters without a visible unit")
reloaded:ForgetLearnedGuilds()
assert(not reloaded:IsGuildFiltered("Remembered Player", "Player-456"))
UnitTokenFromGUID = originalToken
print("PASS: learned guild membership persistence, saved-data validation, guild changes and manual reset")
print("PASS: optional guild imports, deduplication, validation, replacements, removal and live membership precedence")
FC.toolMenuControls[7].configure.scripts.OnClick()
assert(FC.currentSettingsPage == "filterGuild")
print("PASS: channel scopes and guild blacklist identity, recent sightings and membership changes")
assert(FC:SetChatFilterKeywords(""))
assert(not FC:IsChatFiltered("boost"))
FC.toolMenuControls[6].configure.scripts.OnClick()
assert(FC.currentSettingsPage == "filterChat")
print("PASS: Filter Chat settings, literal case-insensitive matching, links, restricted values and enable toggle")

local filterInput, addTerm, termScrollbar = FC.chatFilterEditor.input, FC.chatFilterEditor.add, FC.chatFilterEditor.scrollbar
local deleteTerms = {}
for _, row in ipairs(FC.chatFilterEditor.rows) do deleteTerms[#deleteTerms + 1] = row.remove end
assert(filterInput and addTerm and termScrollbar and #deleteTerms == 6)
filterInput:SetText("  Example phrase  ")
addTerm.scripts.OnClick()
assert(FC.db.filterChat.keywords[1] == "Example phrase" and filterInput:GetText() == "", "Add saves and clears input")
assert(not FC:AddChatFilterKeyword("EXAMPLE PHRASE"), "Duplicate terms ignore capitalization")
assert(not FC:AddChatFilterKeyword(" ") and not FC:AddChatFilterKeyword(secret))
assert(not FC:AddChatFilterKeyword("one\ntwo"), "Add one term at a time")
assert(not FC:AddChatFilterKeyword(string.rep("a", 4000)), "Total keyword budget is enforced atomically")
assert(#FC.db.filterChat.keywords == 1)
for i = 1, 6 do assert(FC:AddChatFilterKeyword("Term " .. i)) end
termScrollbar.scripts.OnValueChanged(termScrollbar, 1)
deleteTerms[6].scripts.OnClick()
assert(#FC.db.filterChat.keywords == 6 and not FC:IsChatFiltered("Term 6"), "Delete last visible term and clamp scroll offset")
deleteTerms[1].scripts.OnClick()
assert(#FC.db.filterChat.keywords == 5 and not FC:IsChatFiltered("Example phrase"), "Row deletion saves immediately")
assert(FC:RemoveChatFilterKeyword("TERM 1"))
assert(not FC:RemoveChatFilterKeyword("missing"))
assert(FC:SetChatFilterKeywords(""))
FC:RefreshFilterChatSettings()
print("PASS: term input Add/Enter controls, duplicate/size validation, scrollable row deletion and saved list preservation")
assert(FC.guildFilterEditor.rows[1].scan and FC.guildFilterEditor.rows[1].scan.scripts.OnClick, "Each guild row has a Scan action")
assert(not FC:IsGuildFilterPartial("Olympus"), "Guild names match exactly by default")
assert(FC:SetGuildFilterNames("Olympus"))
assert(FC:GuildNameMatchesFilter("OLYMPUS"))
assert(not FC:GuildNameMatchesFilter("Olympus IX"))
assert(FC:SetGuildFilterPartial("Olympus", true))
for _, name in ipairs({"OLYMPUS IX", "Olympus II", "New Olympus"}) do assert(FC:GuildNameMatchesFilter(name)) end
assert(not FC:GuildNameMatchesFilter("Other Guild") and not FC:GuildNameMatchesFilter(secret))
assert(FC:AddGuildFilterName("a.b"))
assert(FC:SetGuildFilterPartial("a.b", true))
assert(not FC:AddGuildFilterName("A.B"))
assert(FC:GuildNameMatchesFilter("a.b Guild") and not FC:GuildNameMatchesFilter("axb Guild"), "Partial guild matches are literal")
assert(FC:ImportGuildRoster("Olympus IX", "Imported Member"))
FC.db.filterGuild.useImports = true
assert(FC:IsGuildFiltered("Imported Member", nil), "Partial names apply to imported rosters")
assert(FC:RemoveGuildFilterName("Olympus"))
assert(not FC:IsGuildFiltered("Imported Member", nil))
FC.guildFilterEditor.input:SetText("Olympus")
FC.guildFilterEditor.input.scripts.OnEnterPressed()
FC.guildFilterEditor.rows[2].mode.scripts.OnClick()
assert(FC:GuildNameMatchesFilter("Olympus II") and FC.guildFilterEditor.input:GetText() == "")
FC.guildFilterEditor.rows[2].remove.scripts.OnClick()
assert(not FC:GuildNameMatchesFilter("Olympus II"))
FC.buffExclusionEditor.input:SetText("Example Buff")
FC.buffExclusionEditor.input.scripts.OnEnterPressed()
assert(FC.db.buffExclusions["example buff"] == "Example Buff")
assert(not FC:AddBuffExclusion("EXAMPLE BUFF"))
FC.buffExclusionEditor.rows[1].remove.scripts.OnClick()
assert(not FC.db.buffExclusions["example buff"])
print("PASS: shared add/delete editors, exact/partial literal guild matches including Olympus variants and imported rosters")
FC.toolMenuControls[8].configure.scripts.OnClick()
assert(FC.currentSettingsPage == "friendsList" and FC.settingsPages.friendsList.root.shown)
assert(FC:SetGuildFilterNames("Directory Guild"))
assert(FC:AddGuildBlacklistMember("Directory Guild", "Example Member"))
FC:ShowSettingsPage("guildMembers")
local directoryButton = FC.guildDirectoryButtons[1]
assert(directoryButton.guildName == "Directory Guild" and directoryButton.scan and directoryButton.scan.scripts.OnClick)
directoryButton.scripts.OnClick(directoryButton)
assert(FC.currentSettingsPage == "guildRoster" and FC.selectedGuildBlacklist == "Directory Guild")
FC.guildMembersEditor.rows[1].remove.scripts.OnClick()
assert(not FC:IsGuildFiltered("Example Member", nil))
FC:ShowSettingsPage("guildMembers")
assert(FC.guildDirectoryButtons[1].guildName == "Directory Guild", "Keep empty guild accessible for restore")
directoryButton.remove.scripts.OnClick()
assert(#FC:GetGuildMemberDirectory() == 0 and #FC.db.filterGuild.guilds == 0, "Directory x removes exact guild and member data")
FC:RestoreRemovedGuilds()
assert(FC:GuildNameMatchesFilter("Directory Guild"))
print("PASS: clickable guild directory opens selected blacklist and preserves member removal")
local importPageButton, rosterImportButton
for _, f in ipairs(frames) do
    if f.text == "Import guild roster" and f.parent == FC.settingsPages.filterGuild.content then importPageButton = f end
    if f.text == "Import / replace roster" then rosterImportButton = f end
end
assert(importPageButton and rosterImportButton.parent == FC.settingsPages.guildImport.content)
importPageButton.scripts.OnClick()
assert(FC.currentSettingsPage == "guildImport" and FC.settingsPages.guildImport.root.shown)
assert(not FC.settingsPages.filterGuild.root.shown)
print("PASS: visible Guild Import navigation opens separate roster import page")
dofile("tests/test_guild_scan.lua")
dofile("tests/test_friends_list.lua")
dofile("tests/test_buff_startup.lua")
dofile("tests/test_dnd.lua")
dofile("tests/test_ignore_reply.lua")
dofile("tests/test_name_alerts.lua")
dofile("tests/test_whisper_conversations.lua")

dofile("tests/test_combat_thanks.lua")

dofile("tests/test_forever_context.lua")

-- Realm APIs may be unavailable; none are needed for Forever names or popups.
local oldNormalized, oldRealm = GetNormalizedRealmName, GetRealmName
GetNormalizedRealmName = function() error("Display realm API must not be called") end
GetRealmName = GetNormalizedRealmName
assert(FC:NormalizeBlacklistName("Danath Trollbane") == "danath trollbane")
assert(FC:NormalizeBlacklistName("Danath Trollbane-LegacyRealm") == "danath trollbane")
FC.db.extendedIgnore.blacklist["legacy person-oldrealm"] = "Legacy Person-OldRealm"
FC.modules[2]:Initialize()
FC.db.extendedIgnore.enabled = true
assert(FC:IsBlacklisted("Legacy Person"), "Existing scoped ignored names migrate without a realm")
FC.db.friendsList.muted["character:legacy muted-oldrealm"] = true
FC.modules[8]:Initialize()
assert(FC:IsFriendMuted("Legacy Muted"), "Existing character mutes retain their context identity")
FC.db.filterGuild.guilds = {"Legacy Guild"}
FC.db.filterGuild.allowedMembers["legacy guild\nlegacy member-oldrealm"] = true
FC.db.filterGuild.imports["legacy guild"] = {name = "Legacy Guild", count = 1, members = {["legacy member-oldrealm"] = true}}
FC.modules[7]:Initialize()
assert(FC.db.filterGuild.allowedMembers["legacy guild\nlegacy member"], "Existing guild member exceptions migrate")
assert(FC.db.filterGuild.imports["legacy guild"].members["legacy member"], "Existing imported names migrate")
FC.db.whisperConversations.enabled = true
FC.db.whisperConversations.autoOpen = true
FC.db.doNotDisturb.enabled = false
InCombatLockdown = function() return false end
FC:RecordConversationWhisper("CHAT_MSG_WHISPER", "Test message", "Danath Trollbane")
assert(FC.db.whisperConversations.history["danath trollbane"], "Incoming whisper records without display-realm APIs")
assert(FC.whisperLastDecision == "Conversation window opened" or FC.whisperLastDecision == "Conversation already visible")
GetNormalizedRealmName, GetRealmName = oldNormalized, oldRealm
print("PASS: Forever whisper popup and legacy names work without display realm APIs")

assert(loadfile("tests/test_race_thanks.lua"))(FC)
