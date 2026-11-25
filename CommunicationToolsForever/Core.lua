local addonName, FC = ...
FC.version = "0.10.18"
FC.buffThanksDiagnostics = {}
function FC:BuffThanksNote(message)
    local entries = self.buffThanksDiagnostics
    if entries[#entries] ~= message then
        entries[#entries + 1] = message
        if #entries > 12 then table.remove(entries, 1) end
        if self.buffThanksDebug then self:Print("Buff Thanks: " .. message) end
    end
end
FC.modules = {}
FC.tools = {}
FC.pending = {}
function FC:RegisterTool(tool)
    self.tools[#self.tools + 1] = tool
end
FC.defaultThanksTemplate = "Thanks, <buffername>, for <buffname>!"
FC.defaultThanksTemplates = {
    FC.defaultThanksTemplate,
    "Much appreciated, <buffername>! Thanks for <buffname>.",
    "Thanks for <buffname>, <buffername>. That helps!",
    "<buffername>, thank you for the <buffname> buff!",
}
local defaults = { enabled = true, channel = "WHISPER", cooldown = 60, thanksInInstances = false,
    thanksTemplate = FC.defaultThanksTemplate }

function FC:ValidateThanksTemplate(template)
    if type(template) ~= "string" or not template:find("%S") or #template > 200 then
        return false, "Use a nonblank template of at most 200 bytes."
    end
    if template:find("[%c|]") then return false, "Use plain text without line breaks or chat formatting codes." end
    return true
end

function FC:FormatThanks(buffName, bufferName, template)
    local values = { ["<buffname>"] = buffName, ["<buffername>"] = bufferName }
    local function render(value)
        local message = value:gsub("<%a+>", function(token) return values[token] or token end)
        if #message <= 255 then return message end
    end
    if template then
        local message = render(template)
        if message then return message end
    else
        local pool, messages = self.db.thanksTemplates or {self.db.thanksTemplate}, {}
        for index = 1, 4 do
            local value = pool[index]
            if self:ValidateThanksTemplate(value) then
                local message = render(value)
                if message then messages[#messages + 1] = message end
            end
        end
        if #messages > 0 then return messages[math.random(#messages)] end
    end
    return nil, "No thank-you fits within 255 bytes. Shorten a template."
end

function FC:SetThanksTemplate(template)
    local valid, reason = self:ValidateThanksTemplate(template)
    if not valid then return false, reason end
    return self:SetThanksTemplates({template, "", "", ""})
end

function FC:SetThanksTemplates(templates)
    local pool, count = {}, 0
    for index = 1, 4 do
        local value = templates[index] or ""
        if type(value) ~= "string" then return false, "Message " .. index .. " must be text." end
        if value:find("%S") then
            local valid, reason = self:ValidateThanksTemplate(value)
            if not valid then return false, "Message " .. index .. ": " .. reason end
            count = count + 1
        else value = "" end
        pool[index] = value
    end
    if count == 0 then return false, "Keep at least one nonblank thank-you message." end
    self.db.thanksTemplates = pool
    self.db.thanksTemplatesCustomized = true
    for _, value in ipairs(pool) do if value ~= "" then self.db.thanksTemplate = value; break end end
    self:ClearQueue()
    if self.RefreshSettings then self:RefreshSettings() end
    return true
end

function FC:InitializeThanksTemplates()
    local pool, count = {}, 0
    if type(self.db.thanksTemplates) == "table" then
        for index = 1, 4 do
            local value = self.db.thanksTemplates[index]
            pool[index] = self:ValidateThanksTemplate(value) and value or ""
            if pool[index] ~= "" then count = count + 1 end
        end
    end
    if count == 0 then
        pool[1] = self:ValidateThanksTemplate(self.db.thanksTemplate) and self.db.thanksTemplate or self.defaultThanksTemplate
        for index = 2, 4 do pool[index] = self.defaultThanksTemplates[index] end
    end
    self.db.thanksTemplates = pool
end

-- Templates belong to the actual player, while other preferences remain shared.
function FC:SelectThanksCharacter(root, shared, scope)
    if type(UnitGUID) ~= "function" then return nil end
    local ok, guid = pcall(UnitGUID, "player")
    if not ok or not self:IsPublic(guid) or type(guid) ~= "string" or not guid:match("^Player%-") then return nil end
    if root.buffMessagesByCharacterV1 ~= nil and type(root.buffMessagesByCharacterV1) ~= "table" then return nil end
    root.buffMessagesByCharacterV1 = root.buffMessagesByCharacterV1 or {}
    local key = scope .. "\n" .. guid
    local messages = root.buffMessagesByCharacterV1[key]
    if messages ~= nil and type(messages) ~= "table" then return nil end
    if not messages then
        messages = {thanksTemplate = shared.thanksTemplate}
        if type(shared.thanksTemplates) == "table" then
            messages.thanksTemplates = {}
            for i = 1, 4 do messages.thanksTemplates[i] = shared.thanksTemplates[i] end
        end
        if self.GetDefaultThanksTemplates then
            local racePool, raceKey = self:GetDefaultThanksTemplates()
            if raceKey then messages.thanksTemplates, messages.thanksTemplate = racePool, racePool[1] end
        end
        root.buffMessagesByCharacterV1[key] = messages
    end
    local function stock(pool, single)
        if type(pool) ~= "table" then return single == nil or single == self.defaultThanksTemplate end
        for i = 1, 4 do if pool[i] ~= self.defaultThanksTemplates[i] then return false end end
        return true
    end
    if not messages.thanksTemplatesCustomized and stock(messages.thanksTemplates, messages.thanksTemplate) and self.GetDefaultThanksTemplates then
        messages.thanksTemplates = self:GetDefaultThanksTemplates()
        messages.thanksTemplate = messages.thanksTemplates[1]
    end
    self.buffMessagesCharacterKey = key
    return setmetatable({}, {
        __index = function(_, field)
            if field == "thanksTemplate" or field == "thanksTemplates" or field == "thanksTemplatesCustomized" then return messages[field] end
            return shared[field]
        end,
        __newindex = function(_, field, value)
            if field == "thanksTemplate" or field == "thanksTemplates" or field == "thanksTemplatesCustomized" then messages[field] = value
            else shared[field] = value end
        end,
    })
end

function FC:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff70d6ffCommunicationTools Forever:|r " .. message)
end

function FC:IsPublic(value)
    return not issecretvalue or not issecretvalue(value)
end

function FC:StyleWindow(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    frame:SetBackdropColor(0.055, 0.075, 0.067, 0.80)
    frame:SetBackdropBorderColor(0.48, 0.53, 0.46, 0.50)
end

local button = CreateFrame("Button", "ForeverCommunicationsSendButton", UIParent, "UIPanelButtonTemplate")
button:SetSize(300, 32)
button:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
button:Hide()
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
function FC:BuffThanksAllowedHere()
    if self.db and self.db.thanksInInstances == true then return true end
    if not IsInInstance then return true end
    local ok, inside = pcall(IsInInstance)
    if not ok or not self:IsPublic(inside) then return false end
    return inside ~= true
end
function FC:SetThanksInInstances(enabled)
    self.db.thanksInInstances = enabled == true
    self:ClearQueue()
    if self.RefreshSettings then self:RefreshSettings() end
end
function FC:UpdateQueue()
    if #self.pending == 0 or not self:BuffThanksAllowedHere() or (InCombatLockdown and InCombatLockdown()) then button:Hide(); return end
    button:SetText("Send buff thanks (" .. #self.pending .. ")")
    button:Show()
end
function FC:ClearQueue()
    self.deliveryGeneration = (self.deliveryGeneration or 0) + 1
    self.pending = {}
    self.combatThanks = {}
    self.combatThanksDraining = nil
    self:UpdateQueue()
end
function FC:SetBuffThanksEnabled(enabled)
    self.db.enabled = enabled == true
    self:ClearQueue()
    if self.RefreshSettings then self:RefreshSettings() end
end
function FC:SetBuffThanksChannel(channel)
    if channel ~= "WHISPER" and channel ~= "SAY" then return end
    self.db.channel = channel
    self:ClearQueue()
    if self.RefreshSettings then self:RefreshSettings() end
end
local function send(message, channel, target)
    local api = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if not api then return false end
    return pcall(api, message, channel, nil, target)
end
button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then FC:ClearQueue(); return end
    if InCombatLockdown and InCombatLockdown() then return end
    if not FC:BuffThanksAllowedHere() then FC:ClearQueue(); return end
    local item = table.remove(FC.pending, 1)
    if item and GetTime() - item.time < 120 then
        if not send(item.message, item.channel, item.target) then
            FC:Print("Chat was blocked. Try again outside combat.")
        end
    end
    FC:UpdateQueue()
end)
local function buffThanksTyping(self)
    if self.IsConversationReplyFocused and self:IsConversationReplyFocused() then return true end
    local editor = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    return editor and editor:HasFocus()
end
function FC:DrainCombatThanks()
    if self.combatThanksDraining or not self.combatThanks or #self.combatThanks == 0 then return end
    local generation = self.deliveryGeneration or 0
    self.combatThanksDraining = true
    local function nextThanks()
        if generation ~= (self.deliveryGeneration or 0) then return end
        if not self.db.enabled or not self:BuffThanksAllowedHere() then self:ClearQueue(); return end
        if InCombatLockdown and InCombatLockdown() then self.combatThanksDraining = nil; return end
        if buffThanksTyping(self) then C_Timer.After(0.5, nextThanks); return end
        local item = table.remove(self.combatThanks, 1)
        if item then self:Deliver(item.message, item.target) end
        if #self.combatThanks > 0 then C_Timer.After(0.5, nextThanks)
        else self.combatThanksDraining = nil end
    end
    nextThanks()
end
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(_, event)
    local now = GetTime()
    if event == "PLAYER_REGEN_DISABLED" then
        for i = #FC.pending, 1, -1 do
            if now - FC.pending[i].time >= 120 then table.remove(FC.pending, i) end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Public thanks still require a click; give them a fresh window after combat.
        for _, item in ipairs(FC.pending) do item.time = now end
        FC:DrainCombatThanks()
    end
    FC:UpdateQueue()
end)
function FC:Deliver(message, target)
    if not self:BuffThanksAllowedHere() then return "cancelled" end
    if InCombatLockdown and InCombatLockdown() then
        self.combatThanks = self.combatThanks or {}
        for _, item in ipairs(self.combatThanks) do
            if item.message == message and item.target == target then return "queued" end
        end
        if #self.combatThanks >= 10 then table.remove(self.combatThanks, 1) end
        self.combatThanks[#self.combatThanks + 1] = {message = message, target = target}
        self:BuffThanksNote("Queued thanks until combat ends.")
        return "queued"
    end
    if self.db.channel == "WHISPER" then
        local generation, started = self.deliveryGeneration or 0, GetTime()
        local function focused()
            return buffThanksTyping(self)
        end
        local function deliverWhenReady()
            if generation ~= (self.deliveryGeneration or 0) or not self.db.enabled or self.db.channel ~= "WHISPER" then return "cancelled" end
            if InCombatLockdown and InCombatLockdown() then return self:Deliver(message, target) end
            if not self:BuffThanksAllowedHere() then return "cancelled" end
            if GetTime() - started >= 120 then
                self:BuffThanksNote("Expired queued thanks to " .. target .. " while typing."); return "expired"
            end
            if focused() then
                C_Timer.After(0.5, deliverWhenReady)
                return "queued"
            end
            if not send(message, "WHISPER", target) then
                self:Print("Whisper could not be sent.")
                self:BuffThanksNote("Whisper send request failed for " .. target .. ".")
                return "failed"
            end
            self:BuffThanksNote("Whisper send requested for " .. target .. "; delivery not yet confirmed.")
            return "requested"
        end
        return deliverWhenReady()
    end
    -- A real click provides the hardware event required by public chat.
    local now = GetTime()
    for i = #self.pending, 1, -1 do
        if now - self.pending[i].time >= 120 then table.remove(self.pending, i) end
    end
    if #self.pending >= 10 then table.remove(self.pending, 1) end
    self.pending[#self.pending + 1] = { message = message, channel = "SAY", time = now }
    self:UpdateQueue()
end

-- Forever characters share display realms across rulesets. Never use realm labels
-- as the boundary for sender lists, histories or learned membership.
function FC:GetForeverContextKey()
    local rules = Enum and Enum.GameRule
    local query = C_GameRules and C_GameRules.IsGameRuleActive
    if type(query) ~= "function" or type(UnitFactionGroup) ~= "function" or not rules then return nil end
    local values = {}
    for _, name in ipairs({"HardcoreRuleset", "RPRuleset", "PvPRuleset"}) do
        local id = rules[name]
        if not self:IsPublic(id) or type(id) ~= "number" then return nil end
        local ok, active = pcall(query, id)
        if not ok or not self:IsPublic(active) or type(active) ~= "boolean" then return nil end
        values[name] = active
    end
    local ok, faction = pcall(UnitFactionGroup, "player")
    if not ok or not self:IsPublic(faction) or (faction ~= "Alliance" and faction ~= "Horde") then return nil end
    local mode = values.HardcoreRuleset and "Hardcore"
        or (values.RPRuleset and values.PvPRuleset and "RP-PvP")
        or (values.RPRuleset and "RP") or (values.PvPRuleset and "PvP") or "PvE"
    return mode .. ":" .. faction
end
-- Only identity-bearing data belongs to a context. Preferences remain at the
-- original account root; legacy identity records there are preserved unassigned.
local contextFields = {
    extendedIgnore = {blacklist = true},
    filterGuild = {learned = true, learnedNames = true, imports = true, allowedMembers = true, removedGuilds = true},
    friendsList = {muted = true},
    whisperConversations = {history = true},
    doNotDisturb = {target = true},
}
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for k, v in pairs(value) do result[k] = copy(v) end
    return result
end
function FC:SelectForeverContext(root)
    local key = self:GetForeverContextKey()
    if not key or type(root) ~= "table" then return nil end
    if root.contextProfilesV1 ~= nil and type(root.contextProfilesV1) ~= "table" then return nil end
    if root.characterDataV2 ~= nil and type(root.characterDataV2) ~= "table" then return nil end
    local old = root.contextProfilesV1 and root.contextProfilesV1[key]
    if old ~= nil and type(old) ~= "table" then return nil end
    root.characterDataV2 = root.characterDataV2 or {}
    local data = root.characterDataV2[key]
    if data ~= nil and type(data) ~= "table" then return nil end
    if not data then
        data = {}
        for section, fields in pairs(contextFields) do
            data[section] = {}
            for field in pairs(fields) do
                if old and type(old[section]) == "table" then data[section][field] = copy(old[section][field]) end
            end
        end
        root.characterDataV2[key] = data
    end
    -- Retain original preferences. Fill only missing preferences from this
    -- context's 0.10.11 profile, never another context or legacy character data.
    -- Completion markers belong to the exclusion list that was actually copied.
    -- Importing a marker alone would suppress additions to an older root list.
    local exclusionMarkers = {buffHealingExclusionsAdded = true, buffRenewRegrowthExclusionsAdded = true}
    if old then
        local copiedExclusions = root.buffExclusions == nil
        for field, value in pairs(old) do
            if not contextFields[field] and root[field] == nil
                and (not exclusionMarkers[field] or copiedExclusions) then root[field] = copy(value) end
        end
    end
    -- Repair the 0.10.12-0.10.18 split-marker migration once. Only restore
    -- exclusions proven present in a preserved profile; never copy identity data.
    -- Later manual removals remain respected on subsequent logins.
    if not root.buffExclusionMarkerRepairV1 then
        if type(root.buffExclusions) == "table" and type(root.contextProfilesV1) == "table" then
            for _, previous in pairs(root.contextProfilesV1) do
                if type(previous) == "table" and type(previous.buffExclusions) == "table" then
                    for marker, entries in pairs({
                        buffHealingExclusionsAdded = {rejuvenation = "Rejuvenation", healing = "Healing"},
                        buffRenewRegrowthExclusionsAdded = {renew = "Renew", regrowth = "Regrowth"},
                    }) do
                        if root[marker] == true and previous[marker] == true then
                            for name, label in pairs(entries) do
                                if root.buffExclusions[name] == nil and previous.buffExclusions[name] ~= nil then
                                    root.buffExclusions[name] = label
                                end
                            end
                        end
                    end
                end
            end
        end
        root.buffExclusionMarkerRepairV1 = true
    end
    local sections = {}
    for section, fields in pairs(contextFields) do
        if type(root[section]) ~= "table" then root[section] = {} end
        if type(data[section]) ~= "table" then data[section] = {} end
        local shared, records = root[section], data[section]
        if old and type(old[section]) == "table" then
            for field, value in pairs(old[section]) do
                if not fields[field] and shared[field] == nil then shared[field] = copy(value) end
            end
        end
        sections[section] = setmetatable({}, {
            __index = function(_, field) if fields[field] then return records[field] end; return shared[field] end,
            __newindex = function(_, field, value) if fields[field] then records[field] = value else shared[field] = value end end,
        })
    end
    self.contextKey = key
    return setmetatable({}, {
        __index = function(_, field) if sections[field] then return sections[field] end; return root[field] end,
        __newindex = function(_, field, value) assert(not sections[field], "Cannot replace a context section"); root[field] = value end,
    })
end
local initialized, addonLoaded = false, false
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, name)
    if initialized then return end
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        addonLoaded = true
    elseif event ~= "PLAYER_ENTERING_WORLD" or not addonLoaded then return end
    if ForeverCommunicationsDB == nil then ForeverCommunicationsDB = {} end
    local profile = FC:SelectForeverContext(ForeverCommunicationsDB)
    if not profile then return end -- Retry on world entry; never assume PvE.
    profile = FC:SelectThanksCharacter(ForeverCommunicationsDB, profile, FC.contextKey)
    if not profile then return end -- Retry until the actual player GUID is public.
    FC.db = profile
    initialized = true
    for key, value in pairs(defaults) do
        if type(FC.db[key]) ~= type(value) then FC.db[key] = value end
    end
    if FC.db.channel ~= "WHISPER" and FC.db.channel ~= "SAY" then FC.db.channel = "WHISPER" end
    FC.db.cooldown = math.max(10, math.min(3600, FC.db.cooldown))
    if not FC:ValidateThanksTemplate(FC.db.thanksTemplate) then
        FC.db.thanksTemplate = FC.defaultThanksTemplate
    end
    FC.contextInitializationEvent = event
    FC:InitializeThanksTemplates()
    for _, module in ipairs(FC.modules) do module:Initialize() end
    FC:Print("Version " .. FC.version .. " loaded.")
    frame:UnregisterEvent("ADDON_LOADED")
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

SLASH_FOREVERCOMMUNICATIONS1 = "/ct"
SLASH_FOREVERCOMMUNICATIONS2 = "/forevercomms"
SLASH_FOREVERCOMMUNICATIONS3 = "/fc"
SlashCmdList.FOREVERCOMMUNICATIONS = function(input)
    if not FC.db then FC:Print("Waiting for a verified Forever ruleset and faction before loading settings."); return end
    local command, argument = input:match("^%s*(%S*)%s*(.-)%s*$")
    command, argument = command:lower(), argument:lower()
    if command == "" then
        FC:OpenSettings()
        return
    elseif command == "on" or command == "off" then
        FC:SetBuffThanksEnabled(command == "on")
    elseif command == "channel" and (argument == "say" or argument == "whisper") then
        FC:SetBuffThanksChannel(argument:upper())
    elseif command == "cooldown" and tonumber(argument) then
        FC.db.cooldown = math.max(10, math.min(3600, tonumber(argument)))
    elseif command == "clear" then
        FC:ClearQueue()
    elseif command == "debug" then
        FC.buffThanksDebug = argument ~= "off"
        FC:Print("Buff Thanks debug " .. (FC.buffThanksDebug and "on" or "off") .. ".")
        return
    elseif command == "whisperdiagnosis" then
        if FC.PrintWhisperDiagnosis then FC:PrintWhisperDiagnosis() else FC:Print("Whisper Conversations has not initialized.") end
        return
    elseif command == "diagnosis" then
        FC:Print("Buff Thanks recent decisions:")
        for _, message in ipairs(FC.buffThanksDiagnostics) do FC:Print(message) end
        return
    elseif command == "preview" then
        local message, reason = FC:FormatThanks("Arcane Intellect", "Exampleplayer")
        FC:Print(message and (message .. " (preview only)") or reason)
        return
    elseif command ~= "" and command ~= "status" then
        FC:Print("/ct opens settings; /ct on | off | channel whisper | channel say | cooldown 60 | clear | preview | status | debug on/off | diagnosis | whisperdiagnosis")
        return
    end
    FC:Print("Version " .. FC.version .. "; " .. (FC.db.enabled and "Enabled" or "Disabled") .. "; channel " .. FC.db.channel .. "; repeat cooldown " .. FC.db.cooldown .. " seconds.")
end
