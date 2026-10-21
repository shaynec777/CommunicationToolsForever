local function fixture(saved)
    local frames, clock, combat, blocked, sends = {}, 1000, false, {}, {}
    local methods = {}
    function methods:SetScript(event, fn) self.scripts[event] = fn end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text or "" end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:HasFocus() return self.focus == true end
    function methods:SetPoint(point, relative, relativePoint, x, y)
        if type(relative) == "table" then self.x, self.y = x, y end
    end
    function methods:GetCenter() return 960 + (self.x or 0), 540 + (self.y or 0) end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:Clear() self.lines = {} end
    function methods:AddMessage(text) self.lines[#self.lines + 1] = text end
    local function frame(kind)
        local f = {kind = kind, scripts = {}, shown = true, lines = {}}
        setmetatable(f, {__index = function(_, key) return methods[key] or function() end end})
        frames[#frames + 1] = f
        return f
    end
    methods.CreateFontString = function() return frame("FontString") end
    CreateFrame = frame
    UIParent = {GetWidth = function() return 1920 end, GetHeight = function() return 1080 end}
    time = function() return clock end
    GetTime = time
    date = function() return "12:00" end
    InCombatLockdown = function() return combat end
    C_ChatInfo = {SendChatMessage = function(message, channel, language, target)
        sends[#sends + 1] = {message, channel, target}
    end}
    local secret = {}
    local FC = {modules = {}, db = saved or {}, tools = {}}
    function FC:IsPublic(v) return v ~= secret end
    function FC:NormalizeBlacklistName(name)
        if type(name) ~= "string" then return end
        name = name:match("^([^%-]+)")
        if name:find("[|%d]") then return end
        return name:lower(), name .. "-ClassicBetaPvE2"
    end
    function FC:IsBlacklisted(name) return blocked[name] end
    function FC:RegisterTool(tool) self.tools[#self.tools + 1] = tool end
    function FC:Print() end
    assert(loadfile("CommunicationToolsForever/WhisperConversations.lua"))("CommunicationToolsForever", FC)
    FC.modules[1]:Initialize()
    local function find(width)
        for _, f in ipairs(frames) do if f.width == width and f.kind == "Frame" then return f end end
    end
    return {fc = FC, frames = frames, blocked = blocked, sends = sends, secret = secret,
        clock = function(v) clock = v end, combat = function(v) combat = v end,
        main = function() return find(540) end, detached = function() return find(360) end}
end
local f = fixture()
local fc = f.fc
local settings = fc.db.whisperConversations
assert(settings.enabled and settings.mode == "tabbed" and settings.limit == 100)
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Hello", "Fenty Od-ClassicBetaPvE2")
assert(settings.history["fenty od"].messages[1].text == "Hello")
local main = f.main()
assert(main:IsShown() and main.title.text == "Fenty Od")
main.reply:SetText("draft for Fenty")
f.clock(1001)
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Hi", "Proba Croisus")
assert(main.title.text == "Proba Croisus")
fc:OpenWhisperConversation("fenty od")
assert(main.reply:GetText() == "draft for Fenty", "Tab switching preserves drafts")
fc:DetachWhisperConversation("fenty od")
local detached = f.detached()
assert(detached:IsShown() and detached.reply:GetText() == "draft for Fenty")
detached.reply:SetText("detached draft")
fc:OpenWhisperConversation("fenty od", true)
assert(not detached:IsShown() and main.reply:GetText() == "detached draft", "Reattach preserves draft")
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Still tabbed", "Fenty Od")
assert(not detached:IsShown(), "Reattached conversations stay tabbed")
assert(fc:SendConversationWhisper("fenty od", "Thanks!"))
assert(f.sends[1][3] == "Fenty Od" and f.sends[1][2] == "WHISPER", "Replies use full Forever names without realm")
assert(#settings.history["fenty od"].messages == 2, "Submission alone does not duplicate outgoing history")
fc:RecordConversationWhisper("CHAT_MSG_WHISPER_INFORM", "Thanks!", "Fenty Od")
assert(settings.history["fenty od"].messages[3].outgoing)
assert(not fc:SendConversationWhisper("fenty od", string.rep("x", 256)))
fc:SetWhisperConversationMode("separate")
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Separate", "Fenty Od")
assert(detached:IsShown() and not main:IsShown(), "Separate mode opens a person window")
fc:SetWhisperConversationMode("tabbed")
f.combat(true)
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "In combat", "Proba Croisus")
assert(not main:IsShown() and settings.history["proba croisus"].unread == 1)
f.combat(false)
fc.db.doNotDisturb = {enabled = true, hide = true}
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "DND", "Proba Croisus")
assert(not main:IsShown(), "DND hide suppresses popup")
f.blocked["Blocked Person"] = true
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "ignored", "Blocked Person")
assert(not settings.history["blocked person"])
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", f.secret, "Secret Person")
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "GM", "Game Master", "GM")
assert(not settings.history["secret person"] and not settings.history["game master"])
settings.autoOpen = false
for i = 1, 110 do fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Line " .. i, "Fenty Od") end
assert(#settings.history["fenty od"].messages == 100)
fc:SetWhisperConversationsEnabled(false)
fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "disabled", "New Person")
assert(not settings.history["new person"] and not main:IsShown() and not detached:IsShown())
local reloaded = fixture(fc.db)
assert(#reloaded.fc.db.whisperConversations.history["fenty od"].messages == 100, "History survives initialization/reload")
reloaded.fc:ClearWhisperHistory()
assert(next(reloaded.fc.db.whisperConversations.history) == nil)
print("PASS: whisper tabs, detached/reattached drafts, separate mode, reply addressing/echo, history retention/reload, unread, combat/DND/ignore/secret guards and disabling")

local g = fixture()
g.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "First", "Alpha Person")
g.main().reply.focus = true
g.main().reply:SetText("typing")
g.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Second", "Beta Person")
assert(g.main().title.text == "Alpha Person" and g.main().reply:GetText() == "typing", "Incoming whisper must not change recipient while typing")
assert(g.fc.db.whisperConversations.history["beta person"].unread == 1)
g.fc.db.whisperConversations.autoOpen = false
for i = 1, 45 do
    g.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Many people", "Person " .. string.char(64 + math.floor((i-1)/26) + 1) .. string.char(65 + (i-1)%26))
end
local count = 0
for _ in pairs(g.fc.db.whisperConversations.history) do count = count + 1 end
assert(count == 40, "Saved conversations stay bounded")
assert(g.fc.db.whisperConversations.history["person bs"], "Newest contact survives same-second eviction")
print("PASS: typing preserves recipient/draft, unread tabs and bounded contacts with same-second messages")

local h = fixture()
h.fc:SetWhisperConversationMode("separate")
h.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Hello", "Lyonnesse")
local lyon = h.detached()
local originalX, originalY = lyon.x, lyon.y
h.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Hello", "Other Person")
local other
for _, w in ipairs(h.frames) do if w.kind == "Frame" and w.width == 360 and w ~= lyon then other = w end end
assert(other and (other.x ~= originalX or other.y ~= originalY), "New windows cascade away from open chats")
lyon.x, lyon.y = -240, 120
lyon.scripts.OnDragStop(lyon)
assert(h.fc.db.whisperConversations.history.lyonnesse.position.x == -240)
lyon:Hide()
h.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Back", "Lyonnesse")
assert(lyon.x == -240 and lyon.y == 120, "Moved window reopens at saved position")
local restored = fixture(h.fc.db)
restored.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "After reload", "Lyonnesse")
assert(restored.detached().x == -240 and restored.detached().y == 120, "Position survives reload")
print("PASS: detached window cascade and per-person positions across close/reopen and reload")

local j = fixture()
j.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "One", "First Person")
j.clock(1001)
j.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "Two", "Second Person")
j.fc:DetachWhisperConversation("first person")
local oldWindow = j.detached()
local deleteFirst
for _, b in ipairs(j.frames) do
    if b.text == "X" and b.key == "first person" then deleteFirst = b end
end
assert(deleteFirst, "Every tab has an adjacent delete button")
deleteFirst.scripts.OnClick(deleteFirst)
assert(not j.fc.db.whisperConversations.history["first person"] and not oldWindow:IsShown())
assert(j.fc.db.whisperConversations.history["second person"], "Deleting one chat preserves others")
j.fc:DeleteWhisperConversation("second person")
assert(next(j.fc.db.whisperConversations.history) == nil and j.main().reply:GetText() == "")
j.fc:RecordConversationWhisper("CHAT_MSG_WHISPER", "New conversation", "First Person")
assert(#j.fc.db.whisperConversations.history["first person"].messages == 1, "New whispers start fresh after deletion")
print("PASS: per-tab delete removes only selected history, closes detached chat, handles final tab, and allows fresh conversations")

local k = fixture()
k.fc:OpenWhisperConversation()
local tabbed = k.main()
tabbed.x, tabbed.y = 230, -170
tabbed.scripts.OnDragStop(tabbed)
assert(k.fc.db.whisperConversations.position.x == 230 and k.fc.db.whisperConversations.position.y == -170)
tabbed:Hide()
k.fc:OpenWhisperConversation()
assert(tabbed.x == 230 and tabbed.y == -170, "Tabbed window retains moved coordinates on reopen")
local restart = fixture(k.fc.db)
restart.fc:OpenWhisperConversation()
assert(restart.main().x == 230 and restart.main().y == -170, "Tabbed coordinates survive reload")
restart.fc:ClearWhisperHistory()
assert(restart.fc.db.whisperConversations.position.x == 230, "Clearing chats preserves main window placement")
print("PASS: tabbed window coordinates persist across close/reopen, reload and clearing history")
