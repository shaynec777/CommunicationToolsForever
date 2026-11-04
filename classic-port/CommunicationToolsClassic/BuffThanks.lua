local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local generation, readyAt, inWorld = 0, 0, false
local thanked = {}
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


function module:Initialize()
    if type(FC.db.buffExclusions) ~= "table" then FC.db.buffExclusions = {["cantation of manifestation"] = "Cantation of Manifestation"} end
    FC:RegisterTool({name = "Buff Thanks", settingsPage = "buffThanks",
        description = "Thank players for new buffs they cast on you.",
        IsEnabled = function() return FC.db.enabled end,
        SetEnabled = function(value) FC:SetBuffThanksEnabled(value) end})
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            generation = generation + 1; inWorld = true; readyAt = GetTime() + 5
            FC:ClearQueue(); FC:BuffThanksNote("Startup: ignoring buff events for five seconds."); return
        elseif event == "PLAYER_LEAVING_WORLD" then
            generation = generation + 1; inWorld = false; FC:ClearQueue(); return
        end
        if not inWorld or not FC.db.enabled or GetTime() < readyAt then return end
        local _, kind, _, sourceGUID, sourceName, _, _, destGUID, _, _, _, spellID, spell, _, auraType = CombatLogGetCurrentEventInfo()
        if kind ~= "SPELL_AURA_APPLIED" or auraType ~= "BUFF" then return end
        if type(sourceGUID) ~= "string" or not sourceGUID:match("^Player%-") or sourceGUID == UnitGUID("player") or destGUID ~= UnitGUID("player") then return end
        if type(spell) ~= "string" or type(sourceName) ~= "string" then return end
        local _, target = FC:NormalizeBlacklistName(sourceName)
        if not target then return end
        local lower = strlower or string.lower
        if FC.db.buffExclusions[lower(spell)] then return end
        local key, now = sourceGUID .. ":" .. tostring(spellID), GetTime()
        if thanked[key] and now - thanked[key] < FC.db.cooldown then return end
        for old, stamp in pairs(thanked) do if now - stamp >= 3600 then thanked[old] = nil end end
        local displayName = sourceName:match("^([^%-]+)") or sourceName
        local message = FC:FormatThanks(spell, displayName)
        if not message then return end
        thanked[key] = now
        local current = generation
        C_Timer.After(2, function()
            if not inWorld or generation ~= current or not FC.db.enabled or FC.db.buffExclusions[lower(spell)] then return end
            local result = FC:Deliver(message, target)
            if result == "queued" then FC:BuffThanksNote("Queued thanks for " .. spell .. " to " .. target .. " until you finish typing.")
            elseif result ~= "failed" and result ~= "cancelled" and result ~= "expired" then
                FC:BuffThanksNote("Requested thanks for " .. spell .. " to " .. target .. "; delivery not yet confirmed.")
            end
        end)
    end)
end
