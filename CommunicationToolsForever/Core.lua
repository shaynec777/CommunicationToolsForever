local addonName, FC = ...
FC.version = "0.10.1"
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
local defaults = { enabled = true, channel = "WHISPER", cooldown = 60,
    thanksTemplate = FC.defaultThanksTemplate }

function FC:ValidateThanksTemplate(template)
    if type(template) ~= "string" or #template > 200 then
        return false, "Use a template of at most 200 bytes."
    end
    if template:find("[%c|]") then return false, "Use plain text without line breaks or chat formatting codes." end
    if not template:find("<buffname>", 1, true) or not template:find("<buffername>", 1, true) then
        return false, "Include both <buffname> and <buffername>."
    end
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

function FC:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff70d6ffCommunicationTools Forever:|r " .. message)
end

function FC:IsPublic(value)
    return not issecretvalue or not issecretvalue(value)
end

local button = CreateFrame("Button", "ForeverCommunicationsSendButton", UIParent, "UIPanelButtonTemplate")
button:SetSize(300, 32)
button:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
button:Hide()
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
function FC:UpdateQueue()
    if #self.pending == 0 then button:Hide(); return end
    button:SetText("Send buff thanks (" .. #self.pending .. ")")
    button:Show()
end
function FC:ClearQueue()
    self.pending = {}
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
    local item = table.remove(FC.pending, 1)
    if item and GetTime() - item.time < 120 then
        if not send(item.message, item.channel, item.target) then
            FC:Print("Chat was blocked. Try again outside combat.")
        end
    end
    FC:UpdateQueue()
end)
function FC:Deliver(message, target)
    if self.db.channel == "WHISPER" then
        if not send(message, "WHISPER", target) then self:Print("Whisper could not be sent.") end
        return
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if name ~= addonName then return end
    if type(ForeverCommunicationsDB) ~= "table" then ForeverCommunicationsDB = {} end
    FC.db = ForeverCommunicationsDB
    for key, value in pairs(defaults) do
        if type(FC.db[key]) ~= type(value) then FC.db[key] = value end
    end
    if FC.db.channel ~= "WHISPER" and FC.db.channel ~= "SAY" then FC.db.channel = "WHISPER" end
    FC.db.cooldown = math.max(10, math.min(3600, FC.db.cooldown))
    if not FC:ValidateThanksTemplate(FC.db.thanksTemplate) then
        FC.db.thanksTemplate = FC.defaultThanksTemplate
    end
    FC:InitializeThanksTemplates()
    for _, module in ipairs(FC.modules) do module:Initialize() end
    FC:Print("Version " .. FC.version .. " loaded.")
    frame:UnregisterEvent(event)
end)

SLASH_FOREVERCOMMUNICATIONS1 = "/ct"
SLASH_FOREVERCOMMUNICATIONS2 = "/forevercomms"
SLASH_FOREVERCOMMUNICATIONS3 = "/fc"
SlashCmdList.FOREVERCOMMUNICATIONS = function(input)
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
    elseif command == "diagnosis" then
        FC:Print("Buff Thanks recent decisions:")
        for _, message in ipairs(FC.buffThanksDiagnostics) do FC:Print(message) end
        return
    elseif command == "preview" then
        local message, reason = FC:FormatThanks("Arcane Intellect", "Exampleplayer")
        FC:Print(message and (message .. " (preview only)") or reason)
        return
    elseif command ~= "" and command ~= "status" then
        FC:Print("/ct opens settings; /ct on | off | channel whisper | channel say | cooldown 60 | clear | preview | status | debug on/off | diagnosis")
        return
    end
    FC:Print("Version " .. FC.version .. "; " .. (FC.db.enabled and "Enabled" or "Disabled") .. "; channel " .. FC.db.channel .. "; repeat cooldown " .. FC.db.cooldown .. " seconds.")
end
