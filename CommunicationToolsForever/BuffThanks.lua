local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local seen, thanked = {}, {}
local ready = false
local worldEntered, settleUntil, baselineTime = false, 0, 0
local generation = 0

local function public(value) return FC:IsPublic(value) end
local function identify(aura)
    if not public(aura) or not aura then return end
    local id, spell, source = aura.auraInstanceID, aura.name, aura.sourceUnit
    if not public(id) or not public(spell) or not public(source) then return end
    if type(id) ~= "number" then return end
    return id, spell, source
end

local function note(message)
    FC:BuffThanksNote(message)
end

local casterLookupFailed = false
local function unitCharacterName(unit)
    -- Forever's unit-name getters return first name + surname, not name + realm.
    for _, getter in ipairs({UnitNameUnmodified or false, UnitName or false, UnitFullName or false}) do
        if type(getter) == "function" then
            local ok, first, surname = pcall(getter, unit)
            if ok and public(first) and public(surname) and type(first) == "string" and first ~= "" then
                if type(surname) == "string" and surname ~= "" then
                    local suffix = " " .. surname
                    if first:sub(-#suffix):lower() ~= suffix:lower() then return first .. suffix end
                end
                return first
            end
        end
    end
end

local function resolveCaster(id, source)
    if type(source) == "string" then
        local isPlayer, isSelf = UnitIsPlayer(source), UnitIsUnit(source, "player")
        if not public(isPlayer) or not public(isSelf) then return nil, nil, "caster identity is restricted" end
        if isSelf then return nil, nil, "self buff" end
        if isPlayer then
            local name = unitCharacterName(source)
            if name then return name end
        end
    end

    -- A passer-by may have no unit token. Query only this new aura's caster,
    -- and only when the client explicitly reports unrestricted aura access.
    if casterLookupFailed or not C_UnitAuras or not C_UnitAuras.GetAuraCasterGUID
        or not C_Secrets or not C_Secrets.ShouldAurasBeSecret or not GetPlayerInfoByGUID or not UnitGUID then
        return nil, nil, "caster unit is unavailable; GUID lookup is unavailable"
    end
    local ok, restricted = pcall(C_Secrets.ShouldAurasBeSecret)
    if not ok or not public(restricted) or restricted ~= false then
        return nil, nil, "caster unit is unavailable; GUID lookup is restricted"
    end
    local success, guid = pcall(C_UnitAuras.GetAuraCasterGUID, "player", id)
    if not success then
        casterLookupFailed = true
        return nil, nil, "caster lookup failed; further GUID queries disabled until reload"
    end
    if not public(guid) or type(guid) ~= "string" then return nil, nil, "caster GUID is unavailable or restricted" end
    if not guid:match("^Player%-") then return nil, nil, "pet or NPC buff" end
    local selfGUID = UnitGUID("player")
    if not public(selfGUID) or type(selfGUID) ~= "string" then return nil, nil, "cannot verify caster is another player" end
    if guid == selfGUID then return nil, nil, "self buff" end
    if UnitTokenFromGUID then
        local tokenOK, unit = pcall(UnitTokenFromGUID, guid)
        if tokenOK and public(unit) and type(unit) == "string" then
            local name = unitCharacterName(unit)
            if name then return name end
        end
    end
    local found, _, _, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, guid)
    if not found or not public(name) or not public(realm) or type(name) ~= "string" then
        return nil, nil, "caster GUID found, but player name is not available"
    end
    return name, realm
end

function FC:SetBuffExclusions(text)
    if type(text) ~= "string" or #text > 4000 or text:find("[|%z]") then return false, "Use plain buff names, one per line (up to 4000 bytes)." end
    local entries = {}
    for line in text:gmatch("[^\r\n]+") do
        local name = line:match("^%s*(.-)%s*$")
        if name ~= "" then entries[(strlower or string.lower)(name)] = name end
    end
    self.db.buffExclusions = entries
    return true
end
function FC:GetBuffExclusionsText()
    local names = {}
    for _, name in pairs(self.db.buffExclusions or {}) do names[#names + 1] = name end
    table.sort(names)
    return table.concat(names, "\n")
end

local function thank(aura)
    -- A buff the player can cast still qualifies when someone else casts it.
    -- Never use canApplyAura, class, or spellbook knowledge to exclude it.
    local id, spell, source = identify(aura)
    if not FC.db.enabled then note("Skipped: Buff Thanks is disabled."); return end
    if not id or type(spell) ~= "string" then note("Skipped: buff identity is unavailable or restricted."); return end
    if FC.db.buffExclusions and FC.db.buffExclusions[(strlower or string.lower)(spell)] then
        note("Skipped " .. spell .. ": excluded buff."); return
    end
    if not public(aura.isHelpful) or not aura.isHelpful then note("Skipped: aura is not a readable helpful buff."); return end
    -- Reject late synchronization of a timed aura that predates our baseline.
    local duration, expiration = aura.duration, aura.expirationTime
    if not public(duration) or not public(expiration) then note("Skipped " .. spell .. ": buff timing is restricted."); return end
    if type(duration) ~= "number" or type(expiration) ~= "number" or duration <= 0 then note("Skipped " .. spell .. ": cannot verify when this buff was applied."); return end
    if expiration - duration <= baselineTime then note("Skipped " .. spell .. ": buff predates the login/recovery baseline."); return end
    local name, realm, reason = resolveCaster(id, source)
    if not name then note("Skipped " .. spell .. ": " .. reason .. "."); return end
    local target = name
    -- Forever uses full character names; API realm labels are not whisper addresses.
    local key = target .. "\031" .. spell
    local now = GetTime()
    if thanked[key] and now - thanked[key] < FC.db.cooldown then note("Skipped " .. spell .. ": repeat cooldown."); return end
    -- Keep the session cache bounded even during long play sessions.
    for previous, time in pairs(thanked) do
        if now - time >= 3600 then thanked[previous] = nil end
    end
    local message = FC:FormatThanks(spell, name)
    if not message then note("Skipped " .. spell .. ": completed message is too long."); return end
    thanked[key] = now
    local scheduledGeneration = generation
    C_Timer.After(2, function()
        if not worldEntered or generation ~= scheduledGeneration or not FC.db.enabled then return end
        if FC.db.buffExclusions and FC.db.buffExclusions[(strlower or string.lower)(spell)] then return end
        FC:Deliver(message, target)
        note("Submitted thanks for " .. spell .. " to " .. target .. " via " .. FC.db.channel .. (FC.db.channel == "SAY" and " (click send button)." or "."))
    end)
end

local function establishBaseline()
    -- Never enumerate auras: Forever can raise a taint error even inside pcall.
    -- Only subsequent incremental events with a newer application time qualify.
    seen = {}
    baselineTime = GetTime()
    return true
end

function module:Initialize()
    if type(FC.db.buffExclusions) ~= "table" then
        FC.db.buffExclusions = { ["cantation of manifestation"] = "Cantation of Manifestation" }
    end
    FC:RegisterTool({
        name = "Buff Thanks",
        settingsPage = "buffThanks",
        description = "Thank players by name for buffs they give you.",
        IsEnabled = function() return FC.db.enabled end,
        SetEnabled = function(enabled) FC:SetBuffThanksEnabled(enabled) end,
    })
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:SetScript("OnEvent", function(_, event, unit, update)
        if event == "PLAYER_LEAVING_WORLD" then
            generation = generation + 1
            ready, worldEntered = false, false
            FC:ClearQueue()
            return
        elseif event == "PLAYER_ENTERING_WORLD" then
            generation = generation + 1
            local currentGeneration = generation
            ready, worldEntered = false, true
            settleUntil = GetTime() + 5
            note("Startup: ignoring existing buffs for five seconds.")
            FC:ClearQueue()
            establishBaseline()
            if C_Timer and C_Timer.After then
                C_Timer.After(5, function()
                    if worldEntered and generation == currentGeneration then ready = establishBaseline() end
                end)
            end
            return
        end
        if not worldEntered then return end
        if GetTime() < settleUntil then establishBaseline(); return end
        if not ready then ready = establishBaseline(); note("Recovery: baseline reset without sending thanks."); return end
        if not public(update) then ready = false; note("Skipped: aura update is restricted."); return end
        if not update or not public(update.isFullUpdate) or update.isFullUpdate then
            -- Full refreshes are baselines: don't thank for old or newly revealed auras.
            ready = establishBaseline()
            note("Full aura refresh: baseline reset without sending thanks.")
            return
        end
        if not public(update.addedAuras) then note("Skipped: new aura list is restricted."); return end
        for _, aura in ipairs(update.addedAuras or {}) do
            local id = identify(aura)
            if id then
                if not seen[id] then thank(aura) end
                seen[id] = true
            else
                note("Skipped: aura identity or source is restricted.")
            end
        end
        if public(update.removedAuraInstanceIDs) then
            for _, id in ipairs(update.removedAuraInstanceIDs or {}) do
                if public(id) then seen[id] = nil end
            end
        end
    end)
end
