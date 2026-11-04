local frame, now, callbacks, sent, log = nil, 100, {}, {}, {}
local fc = {modules = {}, db = {enabled = true, cooldown = 60}}
function fc:RegisterTool() end
function fc:ClearQueue() end
function fc:BuffThanksNote() end
function fc:NormalizeBlacklistName(name) return name:lower(), name:find("-",1,true) and name or name .. "-Home" end
function fc:FormatThanks(spell, name) return name .. ":" .. spell end
local messages = {}
function fc:Deliver(message, target) sent[#sent + 1] = target; messages[#messages + 1] = message end
CreateFrame = function() frame = {RegisterEvent = function() end, SetScript = function(self, _, fn) self.event = fn end}; return frame end
GetTime = function() return now end
UnitGUID = function() return "Player-self" end
C_Timer = {After = function(delay, fn) assert(delay == 2); callbacks[#callbacks+1] = fn end}
CombatLogGetCurrentEventInfo = function() return unpack(log) end
assert(loadfile("classic-port/CommunicationToolsClassic/BuffThanks.lua"))("CommunicationToolsClassic", fc)
fc.modules[1]:Initialize()
local function buff(kind, source, destination, aura)
 log = {0,kind,false,source or "Player-other","Bob-OtherRealm",0,0,destination or "Player-self","Me",0,0,123,"Might",1,aura or "BUFF"}
 frame.event(frame,"COMBAT_LOG_EVENT_UNFILTERED")
end
frame.event(frame,"PLAYER_ENTERING_WORLD")
buff("SPELL_AURA_APPLIED")
assert(#callbacks == 0)
now = 106
buff("SPELL_AURA_REFRESH")
buff("SPELL_AURA_APPLIED","Player-self")
buff("SPELL_AURA_APPLIED",nil,"Player-else")
buff("SPELL_AURA_APPLIED",nil,nil,"DEBUFF")
assert(#callbacks == 0)
buff("SPELL_AURA_APPLIED")
assert(#callbacks == 1 and #sent == 0)
callbacks[1]()
assert(sent[1] == "Bob-OtherRealm")
assert(messages[1] == "Bob:Might", "Display name omits realm while destination retains it")
buff("SPELL_AURA_APPLIED")
assert(#callbacks == 1)
now = 170
buff("SPELL_AURA_APPLIED")
frame.event(frame,"PLAYER_LEAVING_WORLD")
callbacks[2]()
assert(#sent == 1)
print("PASS: Classic combat log buff source/destination filters, login silence, refresh/self exclusion, delay, cooldown and world-exit cancellation")
