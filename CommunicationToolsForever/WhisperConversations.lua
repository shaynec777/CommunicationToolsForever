local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local settings, history, main, active
local detached, tabButtons = {}, {}
local tabOffset = 0
local MAX_CONVERSATIONS = 40

local function nameOf(value)
    local key, full = FC:NormalizeBlacklistName(value)
    if not key then return end
    local name = full:match("^([^%-]+)")
    return (strlower or string.lower)(name), name
end
local function clean(value)
    return value:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", "[icon]"):gsub("|A.-|a", "[icon]"):gsub("[%c]", " "):gsub("|", "")
end
local function ordered()
    local keys = {}
    for key in pairs(history) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
        if history[a].updated == history[b].updated then return a < b end
        return history[a].updated > history[b].updated
    end)
    return keys
end
local function label(parent, text, x, y, width)
    local font = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    font:SetPoint("TOPLEFT", x, y)
    font:SetWidth(width)
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end
local function button(parent, text, width, x, y, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function visible(key)
    return (detached[key] and detached[key]:IsShown()) or (active == key and main and main:IsShown())
end
local function render(window, key)
    window.messages:Clear()
    local conversation = history[key]
    if not conversation then return end
    window.title:SetText(conversation.name)
    for _, entry in ipairs(conversation.messages) do
        local stamp = date and date("%H:%M", entry.time) or ""
        window.messages:AddMessage("[" .. stamp .. "] " .. (entry.outgoing and "You" or conversation.name) .. ": " .. entry.text,
            entry.outgoing and 0.65 or 1, entry.outgoing and 0.85 or 0.7, 1)
    end
    window.messages:ScrollToBottom()
end
function FC:RefreshWhisperTabs()
    if not main then return end
    local keys = ordered()
    tabOffset = math.max(0, math.min(tabOffset, math.max(0, #keys - 6)))
    for index, b in ipairs(tabButtons) do
        local key = keys[tabOffset + index]
        b.key = key
        b.deleteButton.key = key
        if key then
            local c = history[key]
            b:SetText((key == active and "> " or "") .. c.name .. ((c.unread or 0) > 0 and " (" .. c.unread .. ")" or ""))
            b:Show(); b.deleteButton:Show()
        else b:Hide(); b.deleteButton:Hide() end
    end
end
function FC:SendConversationWhisper(key, message)
    local c = history[key]
    if not settings.enabled or not c or FC:IsBlacklisted(c.name) then return false end
    if type(message) ~= "string" or not message:find("%S") or #message > 255 or message:find("[%c|]") then
        self:Print("Use a plain-text whisper of 1-255 bytes."); return false
    end
    local api = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if not api then return false end
    local ok = pcall(api, message, "WHISPER", nil, c.name)
    if not ok then self:Print("Whisper could not be submitted. Your draft is still in the reply box.") end
    -- Only CHAT_MSG_WHISPER_INFORM records outgoing messages, avoiding duplicate echoes.
    return ok
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000
end
function FC:SaveWhisperWindowPosition(key, window)
    if key and not history[key] then return end
    local x, y = window:GetCenter()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    if finite(x) and finite(y) and finite(width) and finite(height) then
        local position = {x = x - width / 2, y = y - height / 2}
        if key then history[key].position = position else settings.position = position end
    end
end
local function placeDetached(window, key)
    local saved = history[key] and history[key].position
    local x, y = 40, -40
    if type(saved) == "table" and finite(saved.x) and finite(saved.y) then
        x, y = saved.x, saved.y
    else
        -- Reserve a different cascade slot from every currently open chat.
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if finite(width) and finite(height) then
            for attempt = 0, 39 do
                x, y = 40 + (attempt % 8) * 32, -40 - (attempt % 8) * 32 + math.floor(attempt / 8) * 40
                x = math.max(-width / 2 + 180, math.min(width / 2 - 180, x))
                y = math.max(-height / 2 + 140, math.min(height / 2 - 140, y))
                local occupied = false
                for otherKey, other in pairs(detached) do
                    if otherKey ~= key and other:IsShown() then
                        local ox, oy = other:GetCenter()
                        if finite(ox) and finite(oy) and math.abs(ox - width / 2 - x) < 28
                            and math.abs(oy - height / 2 - y) < 28 then occupied = true; break end
                    end
                end
                if not occupied then break end
            end
        end
    end
    window:ClearAllPoints()
    window:SetPoint("CENTER", UIParent, "CENTER", x, y)
end
local function windowFor(key)
    local w = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    w:SetSize(key and 360 or 540, 280)
    local saved = not key and settings.position
    if type(saved) == "table" and finite(saved.x) and finite(saved.y) then
        w:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    else
        w:SetPoint("CENTER", UIParent, "CENTER", key and 40 or 0, key and -40 or 0)
    end
    w:SetFrameStrata("HIGH")
    w:SetClampedToScreen(true)
    w:SetMovable(true)
    w:EnableMouse(true)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", function(self) self:StartMoving() end)
    w:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); FC:SaveWhisperWindowPosition(key, self) end)
    w:SetResizable(true)
    if w.SetResizeBounds then w:SetResizeBounds(key and 320 or 500, 260, 1100, 800) end
    w:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24})
    w:SetBackdropColor(0.035, 0.047, 0.044, 0.55)
    w.title = label(w, "Whisper Conversations", 20, -16, key and 250 or 430)
    local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        if key and history[key] then history[key].draft = w.reply:GetText() end
        w:Hide()
    end)
    local left = key and 16 or 176
    local messages = CreateFrame("ScrollingMessageFrame", nil, w)
    messages:SetPoint("TOPLEFT", left, -66)
    messages:SetPoint("BOTTOMRIGHT", -16, 52)
    messages:SetFontObject(GameFontHighlight)
    messages:SetJustifyH("LEFT")
    messages:SetFading(false)
    messages:SetMaxLines(500)
    messages:EnableMouseWheel(true)
    messages:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    w.messages = messages
    local reply = CreateFrame("EditBox", nil, w, "InputBoxTemplate")
    reply:SetPoint("BOTTOMLEFT", left + 4, 24)
    reply:SetPoint("BOTTOMRIGHT", -84, 24)
    reply:SetHeight(28)
    reply:SetAutoFocus(false)
    reply:SetMaxBytes(255)
    w.reply = reply
    local function send()
        if FC:SendConversationWhisper(key or active, reply:GetText()) then reply:SetText(""); reply:ClearFocus() end
    end
    reply:SetScript("OnEnterPressed", send)
    reply:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local sendButton = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    sendButton:SetSize(60, 26)
    sendButton:SetPoint("BOTTOMRIGHT", -18, 24)
    sendButton:SetText("Send")
    sendButton:SetScript("OnClick", send)
    local grip = CreateFrame("Button", nil, w)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown", function() w:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() w:StopMovingOrSizing(); FC:SaveWhisperWindowPosition(key, w) end)
    if key then
        button(w, "Attach to tabs", 130, 20, -43, function()
            w:Hide(); FC:OpenWhisperConversation(key, true)
        end)
    else
        button(w, "Detach", 80, 176, -36, function()
            if active then FC:DetachWhisperConversation(active) end
        end)
        button(w, "Settings", 80, 262, -36, function() FC:ShowSettingsPage("whisperConversations") end)
        for i = 1, 6 do
            local b = button(w, "", 122, 16, -66 - (i - 1) * 25, function(self)
                if self.key then FC:OpenWhisperConversation(self.key) end
            end)
            b.deleteButton = button(w, "X", 24, 142, -66 - (i - 1) * 25, function(self)
                if self.key then FC:DeleteWhisperConversation(self.key) end
            end)
            b.deleteButton:SetScript("OnEnter", function(self)
                if GameTooltip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Delete this conversation and its saved history")
                    GameTooltip:Show()
                end
            end)
            b.deleteButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            tabButtons[i] = b
        end
        button(w, "Previous", 72, 16, -36, function() tabOffset = tabOffset - 6; FC:RefreshWhisperTabs() end)
        button(w, "Next", 72, 94, -36, function() tabOffset = tabOffset + 6; FC:RefreshWhisperTabs() end)
    end
    w:Hide()
    return w
end
function FC:OpenWhisperConversationsFromSettings()
    if not settings.enabled then self:Print("Enable Whisper Conversations on the tool menu first."); return end
    for _, page in pairs(self.settingsPages or {}) do page.root:Hide() end
    self.currentSettingsPage = nil
    self:OpenWhisperConversation()
end
function FC:OpenWhisperConversation(key, attach)
    if not settings.enabled then self:Print("Enable Whisper Conversations on the tool menu first."); return end
    key = key or ordered()[1]
    if key and history[key] and self:IsBlacklisted(history[key].name) then return end
    if key and settings.mode == "separate" and not attach then
        if detached[key] and detached[key]:IsShown() then
            history[key].unread = 0; render(detached[key], key); self:RefreshWhisperTabs()
        else self:DetachWhisperConversation(key) end
        return
    end
    if attach and key and detached[key] then
        history[key].draft = detached[key].reply:GetText()
        detached[key]:Hide(); detached[key].attached = true
    end
    if key and detached[key] and not detached[key].attached and not attach then
        if not detached[key]:IsShown() then placeDetached(detached[key], key) end
    detached[key].attached = false
    detached[key]:Show(); history[key].unread = 0; render(detached[key], key)
    else
        if not main then main = windowFor() end
        if active and history[active] then history[active].draft = main.reply:GetText() end
        active = key
        main.reply:SetText(key and history[key] and history[key].draft or "")
        main:Show()
        main.messages:Clear()
        if key and history[key] then history[key].unread = 0; render(main, key)
        else main.title:SetText("Whisper Conversations â€” no saved messages") end
    end
    self:RefreshWhisperTabs()
end
function FC:DetachWhisperConversation(key)
    if not history[key] or not settings.enabled then return end
    if not detached[key] then detached[key] = windowFor(key) end
    if main and active == key then
        history[key].draft = main.reply:GetText()
        main.reply:SetText(""); active = nil; main.messages:Clear(); main.title:SetText("Whisper Conversations")
    end
    if not detached[key]:IsShown() then detached[key].reply:SetText(history[key].draft or "") end
    if not detached[key]:IsShown() then placeDetached(detached[key], key) end
    detached[key].attached = false
    detached[key]:Show(); history[key].unread = 0
    render(detached[key], key); self:RefreshWhisperTabs()
end
function FC:SetWhisperConversationsEnabled(value)
    settings.enabled = value == true
    if not settings.enabled then
        if main then main:Hide() end
        for _, w in pairs(detached) do w:Hide() end
    end
    if self.RefreshSettings then self:RefreshSettings() end
end
function FC:SetWhisperConversationMode(mode)
    if mode ~= "tabbed" and mode ~= "separate" then return end
    if active and main and history[active] then history[active].draft = main.reply:GetText() end
    if main then main:Hide() end
    for key, w in pairs(detached) do
        if history[key] then history[key].draft = w.reply:GetText() end
        w:Hide(); w.attached = mode == "tabbed"
    end
    settings.mode = mode
    if self.RefreshWhisperConversationSettings then self:RefreshWhisperConversationSettings() end
end
function FC:DeleteWhisperConversation(key)
    if not key or not history[key] then return end
    history[key] = nil
    if detached[key] then
        detached[key].reply:SetText("")
        detached[key].messages:Clear()
        detached[key]:Hide()
    end
    if active == key then
        active = nil
        if main then
            main.reply:SetText("")
            main.messages:Clear()
            main.title:SetText("Whisper Conversations — no conversation selected")
            local nextKey = ordered()[1]
            if nextKey and main:IsShown() then self:OpenWhisperConversation(nextKey, true) end
        end
    end
    self:RefreshWhisperTabs()
end
function FC:ClearWhisperHistory()
    for key in pairs(history) do history[key] = nil end
    active = nil
    if main then main.reply:SetText(""); main.messages:Clear(); main.title:SetText("Whisper Conversations") end
    for _, w in pairs(detached) do w.reply:SetText(""); w:Hide() end
    self:RefreshWhisperTabs()
end
local function prune(protectedKey)
    for _, c in pairs(history) do
        while #c.messages > settings.limit do table.remove(c.messages, 1) end
    end
    local keys = ordered()
    local remaining = #keys
    for i = #keys, 1, -1 do
        if remaining <= MAX_CONVERSATIONS then break end
        local key = keys[i]
        if key ~= protectedKey then
            if detached[key] then detached[key]:Hide(); detached[key] = nil end
            if active == key then active = nil; if main then main.messages:Clear(); main.reply:SetText("") end end
            history[key] = nil
            remaining = remaining - 1
        end
    end
end
function FC:RecordConversationWhisper(event, message, author, flags)
    if not settings.enabled or not self:IsPublic(message) or not self:IsPublic(author) or not self:IsPublic(flags)
        or type(message) ~= "string" or type(author) ~= "string" or flags == "GM" or self:IsBlacklisted(author) then return end
    local key, name = nameOf(author)
    if not key then return end
    local outgoing = event == "CHAT_MSG_WHISPER_INFORM"
    local c = history[key] or {name = name, messages = {}, unread = 0}
    history[key] = c
    c.updated = time()
    c.messages[#c.messages + 1] = {text = clean(message):sub(1, 2048), time = c.updated, outgoing = outgoing}
    local dnd = self.db.doNotDisturb
    local hidden = dnd and dnd.enabled and dnd.hide
    if not outgoing and not visible(key) then c.unread = math.min(999, (c.unread or 0) + 1) end
    prune(key)
    if hidden and not outgoing then self:RefreshWhisperTabs(); return end
    if not outgoing and not visible(key) and settings.autoOpen and not hidden
        and not (main and main:IsShown() and main.reply:HasFocus())
        and not (settings.suppressInCombat and InCombatLockdown and InCombatLockdown()) then
        self:OpenWhisperConversation(key)
    elseif visible(key) then
        c.unread = 0
        if detached[key] and detached[key]:IsShown() then render(detached[key], key) end
        if active == key and main and main:IsShown() then render(main, key) end
    end
    self:RefreshWhisperTabs()
end
function FC:BuildWhisperConversationSettings(panel, text)
    text("Tabbed character whispers with detachable windows. History is saved on this computer across reloads and logouts. Normal chat whispers remain available.", "GameFontHighlightSmall", 20, -8, 440)
    local checks = {}
    for i, item in ipairs({{"autoOpen", "Open conversations on incoming whispers"}, {"suppressInCombat", "Do not open windows in combat"}}) do
        local key = item[1]
        local c = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 16, -80 - (i - 1) * 40); c:SetSize(28, 28)
        label(c, item[2], 34, -6, 400)
        c:SetScript("OnClick", function(self) settings[key] = self:GetChecked() == true end)
        checks[key] = c
    end
    local modes = {}
    for i, item in ipairs({{"tabbed", "Tabbed window (individual chats can detach)"}, {"separate", "Separate window for each person"}}) do
        local mode = item[1]
        local c = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 16, -175 - (i - 1) * 36); c:SetSize(28, 28)
        label(c, item[2], 34, -6, 400)
        c:SetScript("OnClick", function() FC:SetWhisperConversationMode(mode) end)
        modes[mode] = c
    end
    text("Messages saved per person (maximum 40 recent people)", "GameFontNormal", 20, -270, 440)
    for i, limit in ipairs({50, 100, 250, 500}) do
        button(panel, tostring(limit), 90, 20 + (i - 1) * 105, -300, function()
            settings.limit = limit; prune(); FC:RefreshWhisperConversationSettings()
            if active and main then render(main, active) end
            for key, w in pairs(detached) do if history[key] then render(w, key) end end
        end)
    end
    local retention = text("", "GameFontHighlightSmall", 20, -338, 440)
    button(panel, "Open conversations", 200, 20, -375, function() FC:OpenWhisperConversationsFromSettings() end)
    local clear = button(panel, "Clear all saved history", 200, 20, -420, function(self)
        if self.confirmUntil and GetTime() < self.confirmUntil then
            FC:ClearWhisperHistory(); self.confirmUntil = nil; self:SetText("Clear all saved history")
        else self.confirmUntil = GetTime() + 5; self:SetText("Click again to clear") end
    end)
    panel:SetScript("OnHide", function() clear.confirmUntil = nil; clear:SetText("Clear all saved history") end)
    text("Drag a window to move it; drag its bottom-right corner to resize. Use Detach or Attach to tabs to move a conversation. Closing a window keeps its history. Reply with Enter or Send. Scroll over messages to read older entries.", "GameFontHighlightSmall", 20, -480, 440)
    text("Ignored players are excluded. DND's hide option suppresses automatic opening. Combat suppression keeps recording history without opening windows. Battle.net whispers are not supported. Disabling this tool pauses recording and hides its windows.", "GameFontHighlightSmall", 20, -570, 440)
    function FC:RefreshWhisperConversationSettings()
        for key, c in pairs(checks) do c:SetChecked(settings[key]) end
        for mode, c in pairs(modes) do c:SetChecked(settings.mode == mode) end
        retention:SetText("Currently saving " .. settings.limit .. " messages per person.")
    end
    self:RefreshWhisperConversationSettings()
    return 700
end
function module:Initialize()
    if type(FC.db.whisperConversations) ~= "table" then FC.db.whisperConversations = {} end
    settings = FC.db.whisperConversations
    for _, key in ipairs({"enabled", "autoOpen", "suppressInCombat"}) do if type(settings[key]) ~= "boolean" then settings[key] = true end end
    if settings.mode ~= "tabbed" and settings.mode ~= "separate" then settings.mode = "tabbed" end
    if settings.limit ~= 50 and settings.limit ~= 100 and settings.limit ~= 250 and settings.limit ~= 500 then settings.limit = 100 end
    if type(settings.history) ~= "table" then settings.history = {} end
    history = settings.history
    -- Validate saved data before using it in frames or sorting it.
    for key, c in pairs(history) do
        if type(c) ~= "table" or type(c.name) ~= "string" or nameOf(c.name) ~= key or type(c.messages) ~= "table" then history[key] = nil
        else
            c.updated = type(c.updated) == "number" and c.updated or 0
            c.unread = type(c.unread) == "number" and math.max(0, math.min(999, c.unread)) or 0
            c.draft = nil
            local valid = {}
            for _, entry in ipairs(c.messages) do
                if type(entry) == "table" and type(entry.text) == "string" and type(entry.time) == "number" then
                    valid[#valid + 1] = {text = clean(entry.text):sub(1, 2048), time = entry.time, outgoing = entry.outgoing == true}
                end
            end
            c.messages = valid
        end
    end
    prune()
    FC:RegisterTool({name = "Whisper Conversations", settingsPage = "whisperConversations",
        description = "Tabbed whispers, detachable windows, and saved history.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(value) FC:SetWhisperConversationsEnabled(value) end})
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_WHISPER")
    listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    listener:SetScript("OnEvent", function(_, event, message, author, _, _, _, flags)
        FC:RecordConversationWhisper(event, message, author, flags)
    end)
end
