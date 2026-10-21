local function fixture()
    local time, list, timers, sends, targets = 100, {}, {}, {}, {}
    local secret, restricted, failScan = {}, false, false
    local reads = 0
    local holdThanks, pendingThanks = false, {}
    local frame
    local FC = { modules = {}, db = { enabled = true, cooldown = 60, channel = "WHISPER" } }
    function FC:IsPublic(value) return value ~= secret end
    function FC:RegisterTool() end
    function FC:ClearQueue() end
    function FC:Print() end
    function FC:BuffThanksNote() end
    function FC:FormatThanks(spell, name) return name .. ": " .. spell end
    function FC:Deliver(message, target) sends[#sends + 1] = message; targets[#targets + 1] = target end
    CreateFrame = function()
        frame = {
            RegisterEvent = function() end, RegisterUnitEvent = function() end,
            SetScript = function(self, _, callback) self.event = callback end,
        }
        return frame
    end
    GetTime = function() return time end
    C_Timer = { After = function(delay, callback)
        if delay == 2 then
            if holdThanks then pendingThanks[#pendingThanks + 1] = { at = time + delay, callback = callback }
            else callback() end
        else timers[#timers + 1] = callback end
    end }
    C_Secrets = { ShouldAurasBeSecret = function() return restricted end }
    C_UnitAuras = { GetAuraDataByIndex = function(_, index)
        reads = reads + 1
        if failScan then error("simulated restricted aura access") end
        return list[index]
    end }
    UnitIsPlayer = function() return true end
    UnitIsUnit = function(unit) return unit == "player" end
    UnitFullName = function() return "Caster", "Realm" end
    UnitNameUnmodified, UnitName, UnitTokenFromGUID = nil, nil, nil
    assert(loadfile("CommunicationToolsForever/BuffThanks.lua"))("CommunicationToolsForever", FC)
    FC.modules[1]:Initialize()
    local function fire(event, update) frame.event(frame, event, "player", update) end
    local function aura(id, start, spell)
        return { auraInstanceID = id, name = spell or "Fortitude", sourceUnit = "party1",
            isHelpful = true, duration = 3600, expirationTime = start + 3600 }
    end
    return {
        db = FC.db,
        holdThanks = function() holdThanks = true end,
        runDue = function()
            for i = #pendingThanks, 1, -1 do
                if pendingThanks[i].at <= time then
                    local entry = table.remove(pendingThanks, i)
                    entry.callback()
                end
            end
        end,
        fire = fire, aura = aura, sends = sends, targets = targets, timers = timers, secret = secret,
        setTime = function(value) time = value end,
        setList = function(value) list = value end,
        restrict = function(value) restricted = value end,
        failScan = function(value) failScan = value end,
        reads = function() return reads end,
    }
end

local f = fixture()
local old, delayed = f.aura(1, 20), f.aura(2, 30, "Kings")
f.setList({old})
f.fire("UNIT_AURA", { addedAuras = {old} })
assert(#f.sends == 0, "No sends before entering world")
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(102)
f.setList({old, delayed})
f.fire("UNIT_AURA", { addedAuras = {delayed} })
assert(#f.sends == 0, "Delayed startup buffs are only baselined")
f.setTime(105)
f.timers[1]()
f.fire("UNIT_AURA", { addedAuras = {old, delayed} })
assert(#f.sends == 0, "Existing buffs never thanked after startup timer")
f.setTime(106)
f.fire("UNIT_AURA", { addedAuras = {f.aura(3, 106, "New Buff")} })
assert(#f.sends == 1, "New post-startup buff is thanked")
f.fire("UNIT_AURA", { addedAuras = {f.aura(4, 40, "Very Late Old Buff")} })
assert(#f.sends == 1, "Late old timed buff rejected by application time")
f.restrict(true)
f.failScan(true)
local readsBeforeRestriction = f.reads()
f.fire("UNIT_AURA", { isFullUpdate = true })
assert(#f.sends == 1, "Restricted aura state does not read or send")
assert(f.reads() == readsBeforeRestriction, "Secret aura state never calls the restricted scan API")
f.restrict(false)
f.fire("UNIT_AURA", { isFullUpdate = true })
assert(#f.sends == 1, "Full refresh never sends thanks")
f.failScan(false)
local recovered = f.aura(5, 106, "Recovered Buff")
f.setList({old, recovered})
f.fire("UNIT_AURA", { addedAuras = {recovered} })
assert(#f.sends == 1, "Recovery establishes a fresh baseline")
f.setTime(107)
f.fire("UNIT_AURA", { addedAuras = {f.aura(6, 107, "After Recovery")} })
assert(#f.sends == 2)
f.fire("PLAYER_LEAVING_WORLD")
f.fire("UNIT_AURA", { addedAuras = {f.aura(7, 108, "During Loading")} })
assert(#f.sends == 2, "Loading screen disarms notifications")
f.fire("PLAYER_ENTERING_WORLD")
f.fire("PLAYER_LEAVING_WORLD")
f.setTime(120)
f.timers[2]()
f.fire("UNIT_AURA", { addedAuras = {f.aura(8, 120, "Stale Timer")} })
assert(#f.sends == 2, "Obsolete startup callback cannot re-arm outside world")
-- Reload is a new Lua instance with existing buffs, not a replay of their applications.
f = fixture()
f.setList({f.aura(1, 20)})
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(105)
f.timers[1]()
f.fire("UNIT_AURA", { addedAuras = {f.aura(1, 20)} })
assert(#f.sends == 0, "Reload with old buffs sends nothing")
f.setTime(106)
f.failScan(true)
f.fire("UNIT_AURA", { addedAuras = {f.aura(10, 106, "Event Only Buff")} })
assert(#f.sends == 1, "New events work without enumeration")
f.fire("UNIT_AURA", { addedAuras = {{auraInstanceID = 11, name = "Undated", sourceUnit = "party1", isHelpful = true}} })
assert(#f.sends == 1, "Unverifiable age never generates thanks")
assert(f.reads() == 0, "No aura enumeration API called during login, reload or new events")
f.restrict(true)
f.setTime(108)
f.fire("UNIT_AURA", { addedAuras = {f.aura(12, 108, "Readable During Restriction")} })
assert(#f.sends == 2, "Readable event data is usable even when other auras are restricted")
f = fixture()
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(105)
f.timers[1]()
f.setTime(110)
local lookups, lookupGUID = 0, "Player-1-Other"
C_UnitAuras.GetAuraCasterGUID = function(unit, id)
    assert(unit == "player" and type(id) == "number")
    lookups = lookups + 1
    return lookupGUID
end
UnitGUID = function() return "Player-1-Self" end
GetPlayerInfoByGUID = function(guid)
    assert(guid == "Player-1-Other")
    return "Paladin", "PALADIN", "Human", "Human", 2, "Passing Paladin", "OtherRealm"
end
local function missingSource(id, start, spell)
    local aura = f.aura(id, start, spell)
    aura.sourceUnit = nil
    return aura
end
f.fire("UNIT_AURA", { addedAuras = {missingSource(20, 110, "Blessing of Might")} })
assert(#f.sends == 1 and lookups == 1, "Passer-by caster resolved by GUID without unit token")
assert(f.sends[1] == "Passing Paladin: Blessing of Might")
assert(f.targets[1] == "Passing Paladin", "Forever whisper omits API realm labels")
local savedRealm = GetNormalizedRealmName
GetNormalizedRealmName = function() return "ClassicBetaPvE2" end
GetPlayerInfoByGUID = function()
    return "Paladin", "PALADIN", "Human", "Human", 2, "Doyler Dartfall", "ClassicBetaPvE2"
end
f.fire("UNIT_AURA", { addedAuras = {missingSource(28, 110, "Local Might")} })
assert(f.targets[2] == "Doyler Dartfall", "Same-realm whisper uses full character name without realm suffix")
GetNormalizedRealmName = savedRealm
table.remove(f.sends)
table.remove(f.targets)
local lookupsBeforeRestriction = lookups
f.restrict(true)
f.fire("UNIT_AURA", { addedAuras = {missingSource(21, 110, "Restricted Might")} })
assert(#f.sends == 1 and lookups == lookupsBeforeRestriction, "Never query caster GUID while aura access is restricted")
f.restrict(false)
lookupGUID = f.secret
f.fire("UNIT_AURA", { addedAuras = {missingSource(22, 110, "Secret GUID")} })
assert(#f.sends == 1, "Secret GUID cannot be used")
lookupGUID = "Player-1-Self"
f.fire("UNIT_AURA", { addedAuras = {missingSource(23, 110, "Own Might")} })
assert(#f.sends == 1, "GUID fallback excludes self")
lookupGUID = "Pet-1-Other"
f.fire("UNIT_AURA", { addedAuras = {missingSource(24, 110, "Pet Buff")} })
assert(#f.sends == 1, "GUID fallback excludes pets")
local beforeOld = lookups
f.fire("UNIT_AURA", { addedAuras = {missingSource(25, 10, "Old Might")} })
assert(lookups == beforeOld, "Old buffs never trigger fallback queries")
C_UnitAuras.GetAuraCasterGUID = function() lookups = lookups + 1; error("simulated lookup refusal") end
f.fire("UNIT_AURA", { addedAuras = {missingSource(26, 110, "Failed Lookup")} })
local afterFailure = lookups
f.fire("UNIT_AURA", { addedAuras = {missingSource(27, 110, "Next Lookup")} })
assert(lookups == afterFailure and #f.sends == 1, "Lookup failure disables retries for the session")
assert(f.reads() == 0)
print("PASS: login/reload silence, delayed old buffs, new events, restriction recovery, stale timers and zero aura enumeration calls")
print("PASS: missing source unit resolved by GUID; restriction, secret, self, pet, old buff and failed-lookup guards")
-- Class/spellbook queries must never decide whether another player's buff qualifies.
local function forbiddenClassCheck() error("Buff Thanks must not query class or spell knowledge") end
UnitClass, IsPlayerSpell, IsSpellKnown = forbiddenClassCheck, forbiddenClassCheck, forbiddenClassCheck
for _, spell in ipairs({"Blessing of Might", "Power Word: Fortitude", "Arcane Intellect", "Mark of the Wild"}) do
    f = fixture()
    f.fire("PLAYER_ENTERING_WORLD")
    f.setTime(105)
    f.timers[1]()
    f.setTime(110)
    local other = f.aura(50, 110, spell)
    other.canApplyAura = true
    f.fire("UNIT_AURA", { addedAuras = {other} })
    assert(#f.sends == 1, "Another player's known/castable buff must qualify: " .. spell)
    local own = f.aura(51, 110, spell)
    own.sourceUnit = "player"
    own.canApplyAura = true
    f.fire("UNIT_AURA", { addedAuras = {own} })
    assert(#f.sends == 1, "Only actual self casts are excluded: " .. spell)
end
UnitClass, IsPlayerSpell, IsSpellKnown = nil, nil, nil
print("PASS: castable/known buffs from other players qualify independently of class; self casts remain excluded")
f = fixture()
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(105)
f.timers[1]()
f.setTime(110)
UnitNameUnmodified = function() return "Bobby", "Eggrollz" end
UnitFullName = function() return "Bobby", "Eggrollz" end
f.fire("UNIT_AURA", { addedAuras = {f.aura(60, 110, "Blessing of Might")} })
assert(f.targets[1] == "Bobby Eggrollz", "Recipient joins Forever first name and surname")
assert(f.sends[1] == "Bobby Eggrollz: Blessing of Might", "Template receives complete character name")
UnitNameUnmodified = function() return "Bobby Eggrollz", "Eggrollz" end
f.fire("UNIT_AURA", { addedAuras = {f.aura(61, 110, "Blessing of Wisdom")} })
assert(f.targets[2] == "Bobby Eggrollz", "Already-combined names don't duplicate surnames")
UnitNameUnmodified = nil
f.fire("UNIT_AURA", { addedAuras = {f.aura(62, 110, "Blessing of Kings")} })
assert(f.targets[3] == "Bobby Eggrollz", "UnitFullName fallback also preserves surname")
print("PASS: Forever first-name/surname recipient and template formatting, no duplicated surnames")

-- Delayed delivery remains silent until two seconds and cancels on disable/world exit.
f = fixture()
f.holdThanks()
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(105)
f.timers[1]()
f.setTime(110)
f.fire("UNIT_AURA", { addedAuras = {f.aura(70, 110)} })
assert(#f.sends == 0, "Thanks must not send immediately")
f.setTime(111.99)
f.runDue()
assert(#f.sends == 0, "Thanks must wait the full two seconds")
f.setTime(112)
f.runDue()
assert(#f.sends == 1, "Thanks sends after two seconds")
f.setTime(113)
f.fire("UNIT_AURA", { addedAuras = {f.aura(71, 113, "Kings")} })
f.db.enabled = false
f.setTime(115)
f.runDue()
assert(#f.sends == 1, "Disabling tool cancels pending thanks")
f.db.enabled = true
f.fire("UNIT_AURA", { addedAuras = {f.aura(72, 115, "Wisdom")} })
f.fire("PLAYER_LEAVING_WORLD")
f.setTime(117)
f.runDue()
assert(#f.sends == 1, "Leaving world cancels pending thanks")
print("PASS: two-second buff thanks delay and pending delivery cancellation")

f = fixture()
f.fire("PLAYER_ENTERING_WORLD")
f.setTime(105)
f.timers[1]()
f.setTime(110)
f.fire("UNIT_AURA", {addedAuras = {f.aura(90, 110, "Cantation of Manifestation")}})
assert(#f.sends == 0, "Quest effect excluded by default")
f.fire("UNIT_AURA", {addedAuras = {f.aura(91, 110, "Blessing of Might")}})
assert(#f.sends == 1, "Normal buffs remain eligible")
print("PASS: incidental quest effect excluded while normal buffs still qualify")
