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
UnitFullName = function() return "Alice", "OtherRealm" end
local FC = {}
for _, file in ipairs({"Core.lua", "ClassicCompat.lua", "BuffThanks.lua", "ExtendedIgnore.lua", "DoNotDisturb.lua", "NameAlerts.lua", "WhisperConversations.lua", "Settings.lua", "ChatAccess.lua"}) do
    assert(loadfile("classic-port/CommunicationToolsClassic/" .. file))("CommunicationToolsClassic", FC)
end
for _, f in ipairs(frames) do
    if f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", "CommunicationToolsClassic") end
end
assert(#FC.tools == 5)
assert(FC.settingsPages.whisperConversations)
assert(SLASH_FOREVERCOMMUNICATIONS1 == "/ct")
assert(FC:NormalizeBlacklistName("Alice-OtherRealm") == "alice-otherrealm")
assert(FC:SetThanksTemplate("Thanks!"))
UnitFullName = function() return "Alice", "OtherRealm" end
assert(FC:ClassicCharacterName("player") == "Alice-OtherRealm")
assert(FC:GetNameAlertIdentity() == "Alice-OtherRealm")
assert(not FC:SaveDNDSettings("Busy", true, "Alice-OtherRealm", "refer", false))
assert(FC:SaveDNDSettings("Busy", true, "Bob-OtherRealm", "refer", false))
assert(FC.db.doNotDisturb.target == "Bob-OtherRealm")
local typing, timers, sends = true, {}, {}
FC.IsConversationReplyFocused = function() return typing end
C_Timer = {After = function(delay, fn) assert(delay == 0.5); timers[#timers + 1] = fn end}
C_ChatInfo = {SendChatMessage = function(message, channel, language, target) sends[#sends + 1] = target end}
FC.db.channel, FC.db.enabled = "WHISPER", true
assert(FC:Deliver("Thanks!", "Bob-OtherRealm") == "queued")
assert(#sends == 0)
typing = false
timers[1]()
assert(sends[1] == "Bob-OtherRealm")
typing = true
FC:Deliver("Thanks again", "Bob-OtherRealm")
FC:ClearQueue()
typing = false
timers[2]()
assert(#sends == 1)
print("PASS: Classic five-tool initialization, settings, realm identity, optional templates and DND")
dofile("classic-port/tests/test_buffs.lua")
