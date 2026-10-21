local frames, filters, callbacks = {}, {}, {}
local ctrl, shift = false, false
local secret = {}
local methods = {}
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
function methods:CreateTexture() return frame("Texture") end
CreateFrame = frame
UIParent = { GetWidth = function() return 1920 end, GetHeight = function() return 1080 end }
UISpecialFrames = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
issecretvalue = function(value) return value == secret end
GetNormalizedRealmName = function() return "HomeRealm" end
GetRealmName = function() return "Home Realm" end
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
for _, file in ipairs({"Core.lua", "BuffThanks.lua", "ExtendedIgnore.lua", "DoNotDisturb.lua", "NameAlerts.lua", "WhisperConversations.lua", "Settings.lua", "ChatAccess.lua"}) do
    assert(loadfile("CommunicationToolsForever/" .. file))("CommunicationToolsForever", FC)
end
for _, f in ipairs(frames) do
    if f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", "CommunicationToolsForever") end
end
assert(#FC.tools == 5, "All tools initialize before settings")
assert(FC.db.extendedIgnore.enabled)
assert(FC:AddBlacklistName("  Alice  "))
assert(FC:IsBlacklisted("ALICE-Home Realm"), "Case and realm whitespace normalization")
assert(FC:IsBlacklisted("alice"), "Unqualified author matches current realm")
assert(not FC:IsBlacklisted("Alice-OtherRealm"), "Do not block same name on another realm")
assert(not FC:AddBlacklistName("Alice-HomeRealm"), "Duplicate add")
assert(FC:AddBlacklistName("Bob-Other Realm"))
for event, filter in pairs(filters) do
    assert(filter({}, event, "message", "Bob-OtherRealm") == true, event .. " filters blocked author")
    assert(filter({}, event, "message", "Unknown-OtherRealm") == false, event .. " passes other author")
    assert(filter({}, event, "message", secret) == false, event .. " skips secret author")
end
assert(filters.CHAT_MSG_WHISPER and filters.CHAT_MSG_CHANNEL and filters.CHAT_MSG_GUILD)
assert(not filters.CHAT_MSG_WHISPER_INFORM, "Don't suppress outgoing whispers")
assert(not FC:AddBlacklistName("Bad|Hplayer:Link"))
assert(FC:AddBlacklistName("Some One"), "Forever names can contain surnames")
assert(FC:IsBlacklisted("some one-HomeRealm"))
assert(not FC:IsBlacklisted("Some One-OtherRealm"))
assert(not FC:AddBlacklistName("Name#1234"))
assert(not FC:AddBlacklistName("Name-"))
assert(not FC:AddBlacklistName(secret))
assert(FC:AddBlacklistName("Chloé-HomeRealm"), "Accented character names")
FC:SetExtendedIgnoreEnabled(false)
assert(not FC:IsBlacklisted("Alice"), "Disabled tool passes messages")
assert(FC.db.extendedIgnore.blacklist["alice-homerealm"], "Disabling preserves list")
local click = callbacks["ChatFrame.OnHyperlinkClick"]
local function nameClick(link, button)
    click[1](click[2], {}, link, "[Name]", button or "LeftButton")
end
ctrl, shift = true, true
nameClick("player:Disabled:12:WHISPER")
assert(not FC.db.extendedIgnore.blacklist["disabled-homerealm"])
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
local input, add, remove
for _, f in ipairs(frames) do
    if f.kind == "EditBox" and f.parent == FC.settingsPages.extendedIgnore.content and not input then input = f end
    if f.text == "Add to blacklist" then add = f end
    if f.text == "Remove" and not remove then remove = f end
end
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
assert(#FC.toolMenuControls == 5)
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


dofile("tests/test_buff_startup.lua")
dofile("tests/test_dnd.lua")
dofile("tests/test_ignore_reply.lua")
dofile("tests/test_name_alerts.lua")
dofile("tests/test_whisper_conversations.lua")

