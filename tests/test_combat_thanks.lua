local corePath = ... or "CommunicationToolsForever/Core.lua"
local keys = {"CreateFrame", "UIParent", "SlashCmdList", "GetTime", "InCombatLockdown", "IsInInstance", "C_Timer", "C_ChatInfo", "ChatEdit_GetActiveWindow", "SLASH_FOREVERCOMMUNICATIONS1", "SLASH_FOREVERCOMMUNICATIONS2", "SLASH_FOREVERCOMMUNICATIONS3"}
local saved = {}; for _, k in ipairs(keys) do saved[k] = _G[k] end
local frames, timers, sent = {}, {}, {}
local now, combat, typing, inside = 100, false, false, false
CreateFrame = function()
    local f = {events = {}, scripts = {}}
    setmetatable(f, {__index = function() return function() end end})
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetScript(e, fn) self.scripts[e] = fn end
    function f:Hide() self.shown = false end
    function f:Show() self.shown = true end
    frames[#frames + 1] = f; return f
end
UIParent, SlashCmdList = {}, {}
GetTime = function() return now end
InCombatLockdown = function() return combat end
IsInInstance = function() return inside, inside and "party" or "none" end
C_Timer = {After = function(delay, fn) assert(delay == 0.5); timers[#timers + 1] = fn end}
C_ChatInfo = {SendChatMessage = function(message, channel, _, target)
    assert(not combat, "Never send a thank-you in combat")
    sent[#sent + 1] = {message, channel, target}
end}
ChatEdit_GetActiveWindow = nil
local FC = {}
assert(loadfile(corePath))("test", FC)
FC.db = {enabled = true, channel = "WHISPER"}
FC.IsConversationReplyFocused = function() return typing end
FC.Print = function() end
local events, button
for _, f in ipairs(frames) do
    if f.events.PLAYER_REGEN_ENABLED then events = f end
    if f.scripts.OnClick then button = f end
end
local function fire(e) events.scripts.OnEvent(events, e) end
local function tick() local fn = table.remove(timers, 1); assert(fn); fn() end
combat = true; fire("PLAYER_REGEN_DISABLED")
assert(FC:Deliver("Thanks A", "Alice") == "queued")
FC:Deliver("Thanks A", "Alice"); FC:Deliver("Thanks B", "Bob")
assert(#sent == 0 and #FC.combatThanks == 2, "Duplicate combat thanks are combined")
now = 1000; typing = true; combat = false; fire("PLAYER_REGEN_ENABLED")
assert(#sent == 0, "Long fights retain thanks and typing still delays them")
typing = false; tick()
assert(#sent == 1 and sent[1][3] == "Alice", "Release oldest thanks first")
combat = true; tick(); assert(#sent == 1, "Re-entering combat pauses the remaining queue")
combat = false; fire("PLAYER_REGEN_ENABLED")
assert(#sent == 2 and sent[2][3] == "Bob", "Resume without duplicates")
-- A whisper waiting on typing must move into the combat buffer if a fight starts.
typing = true; FC:Deliver("Thanks C", "Carol")
combat = true; tick(); assert(#FC.combatThanks == 1 and #sent == 2)
FC:ClearQueue(); combat = false; typing = false; fire("PLAYER_REGEN_ENABLED")
assert(#sent == 2 and #FC.combatThanks == 0, "Clear cancels combat thanks")
combat = true; FC:Deliver("Thanks D", "Dave"); FC:SetBuffThanksEnabled(false)
combat = false; fire("PLAYER_REGEN_ENABLED"); assert(#sent == 2, "Disable cancels buffered thanks")
FC.db.enabled = true; FC.db.channel = "SAY"; combat = true
FC:Deliver("Public thanks", "Alice"); assert(#FC.pending == 0 and not button.shown)
combat = false; fire("PLAYER_REGEN_ENABLED")
assert(#FC.pending == 1 and button.shown and #sent == 2, "Public thanks wait for an out-of-combat click")
combat = true; fire("PLAYER_REGEN_DISABLED"); button.scripts.OnClick(button, "LeftButton")
assert(#FC.pending == 1 and not button.shown and #sent == 2)
now = 2000; combat = false; fire("PLAYER_REGEN_ENABLED"); button.scripts.OnClick(button, "LeftButton")
assert(#sent == 3 and sent[3][2] == "SAY", "Public click works after a long fight")
FC.db.channel = "WHISPER"; combat = true
for i = 1, 20 do FC:Deliver("Thanks " .. i, "Caster" .. i) end
assert(#FC.combatThanks == 10, "Combat buffer stays bounded")
FC:ClearQueue()
combat = false; inside = true
assert(not FC:BuffThanksAllowedHere() and FC:Deliver("Instance thanks", "Alice") == "cancelled", "Instance thanks default off")
local before = #sent
FC:SetThanksInInstances(true)
assert(FC:Deliver("Instance thanks", "Alice") == "requested" and #sent == before + 1, "Opt in permits instance thanks")
combat = true; FC:Deliver("Buffered instance thanks", "Bob")
FC:SetThanksInInstances(false); combat = false; fire("PLAYER_REGEN_ENABLED")
assert(#sent == before + 1 and #FC.combatThanks == 0, "Turning instance thanks off clears pending work")
inside = false; typing = true; FC:Deliver("Outside thanks", "Carol")
inside = true; typing = false; tick()
assert(#sent == before + 1, "Recheck instance state after a typing delay")
FC.db.channel = "SAY"
assert(FC:Deliver("Public instance thanks", "Alice") == "cancelled" and #FC.pending == 0)
inside = false; FC:Deliver("Outside public thanks", "Alice"); inside = true
button.scripts.OnClick(button, "LeftButton")
assert(#FC.pending == 0 and #sent == before + 1, "Public click respects instance opt-out")
for _, k in ipairs(keys) do _G[k] = saved[k] end
print("PASS: combat thanks buffer, long fights, typing, paced drain, re-entry, cancellation, cap and public click")
