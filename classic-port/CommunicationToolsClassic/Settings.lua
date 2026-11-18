local addonName, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module

-- A single-line InputBoxTemplate draws a narrow border even when its text is multiline.
-- Keep the border and viewport separate so long lists stay inside the editor.
function FC:CreateListEditor(parent, x, y, width, height, maxBytes)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetPoint("TOPLEFT", x, y)
    border:SetSize(width, height)
    border:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    border:SetBackdropColor(0.025, 0.035, 0.03, 1)
    border:SetBackdropBorderColor(0.45, 0.48, 0.37, 1)
    local scroll = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local editor = CreateFrame("EditBox", nil, scroll)
    editor:SetMultiLine(true)
    editor:SetAutoFocus(false)
    editor:SetFontObject(GameFontHighlight)
    editor:SetJustifyH("LEFT")
    editor:SetJustifyV("TOP")
    editor:SetWidth(width - 40)
    editor:SetHeight(height - 16)
    editor:SetMaxBytes(maxBytes)
    scroll:SetScrollChild(editor)
    editor.listEditorBorder, editor.listEditorScroll = border, scroll
    editor:SetScript("OnTextChanged", function(self)
        local _, size = self:GetFont()
        self:SetHeight(math.max(height - 16, (self:GetNumLines() or 1) * ((size or 14) + 2) + 16))
        if not self:HasFocus() then scroll:SetVerticalScroll(0) end
    end)
    editor:SetScript("OnCursorChanged", function(_, _, cursorY, _, cursorHeight)
        local offset, viewport = scroll:GetVerticalScroll(), scroll:GetHeight()
        if type(offset) ~= "number" or type(viewport) ~= "number" then return end
        local top = -cursorY
        if top < offset then scroll:SetVerticalScroll(math.max(0, top))
        elseif top + cursorHeight > offset + viewport then scroll:SetVerticalScroll(math.max(0, top + cursorHeight - viewport)) end
    end)
    border:EnableMouse(true)
    border:SetScript("OnMouseDown", function() editor:SetFocus() end)
    scroll:SetScript("OnMouseDown", function() editor:SetFocus() end)
    editor:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return editor
end

function FC:CreateEntryEditor(parent, label, config)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", 0, config.top or 0)
    panel:SetSize(480, 430)
    local function text(value, font, x, y, width)
        local region = panel:CreateFontString(nil, "ARTWORK", font)
        region:SetPoint("TOPLEFT", x, y); region:SetWidth(width or 440); region:SetJustifyH("LEFT"); region:SetText(value)
        return region
    end
    text(config.caption, "GameFontNormal", 20, -8, 440)
    text(config.help or "Add one entry at a time. Press Enter to keep adding; use the mouse wheel or scrollbar to browse. Use \195\151 to delete. Changes save immediately.", "GameFontHighlightSmall", 20, -38, 440)
    local refresh
    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", 24, -86)
    input:SetSize(310, 30)
    input:SetAutoFocus(false)
    input:SetMaxBytes(config.maxBytes or 4000)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local add = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    add:SetPoint("LEFT", input, "RIGHT", 12, 0)
    add:SetSize(100, 28)
    add:SetText(config.addLabel or "Add")
    local status = text("", "GameFontHighlightSmall", 20, -128, 440)
    local function addTerm()
        local ok, reason = config.Add(input:GetText())
        if ok then input:SetText("") end
        input:SetFocus()
        status:SetText(reason or (ok and "Saved." or "Unable to save."))
        refresh()
    end
    input:SetScript("OnEnterPressed", addTerm)
    add:SetScript("OnClick", addTerm)
    local countLabel = text("", "GameFontNormal", 20, -164, 440)
    local list = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    list:SetPoint("TOPLEFT", 20, -190)
    list:SetSize(425, 200)
    list:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    list:SetBackdropColor(0.025, 0.035, 0.03, 1)
    list:SetBackdropBorderColor(0.3, 0.35, 0.29, 1)
    local empty = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", 12, -12)
    empty:SetText(config.emptyText or "No entries added.")
    local rows, offset, pageSize = {}, 0, 6
    local updatingScroll = false
    for index = 1, pageSize do
        local row = {}
        row.label = list:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.label:SetPoint("TOPLEFT", 12, -14 - (index - 1) * 30)
        row.label:SetWidth(config.Scan and 196 or (config.GetMode and 255 or 327))
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row.remove = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
        row.remove:SetPoint("TOPRIGHT", -36, -8 - (index - 1) * 30)
        row.remove:SetSize(28, 26)
        row.remove:SetText("\195\151")
        row.remove:SetScript("OnClick", function()
            if row.keyword then
                local _, reason = config.Remove(row.keyword)
                status:SetText(reason or "Removed.")
                refresh()
            end
        end)
        row.remove:SetScript("OnEnter", function(self)
            if GameTooltip and row.keyword then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete: " .. row.keyword)
                GameTooltip:Show()
            end
        end)
        row.remove:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        if config.GetMode then
            row.mode = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
            row.mode:SetPoint("TOPRIGHT", -70, -8 - (index - 1) * 30)
            row.mode:SetSize(70, 26)
            row.mode:SetScript("OnClick", function()
                if row.keyword then config.SetMode(row.keyword, not config.GetMode(row.keyword)); refresh() end
            end)
        end
        if config.Scan then
            row.scan = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
            row.scan:SetPoint("TOPRIGHT", -148, -8 - (index - 1) * 30)
            row.scan:SetSize(56, 26); row.scan:SetText("Scan")
            row.scan:SetScript("OnClick", function() if row.keyword then config.Scan(row.keyword) end end)
            if config.ScanButtonCreated then config.ScanButtonCreated(row.scan, row) end
        end
        rows[index] = row
    end
    local scrollbar = CreateFrame("Slider", nil, list, "BackdropTemplate")
    scrollbar:SetPoint("TOPRIGHT", -8, -32)
    scrollbar:SetSize(16, 136)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValueStep(1)
    scrollbar:SetObeyStepOnDrag(true)
    scrollbar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    scrollbar:SetBackdropColor(0.13, 0.16, 0.13, 1)
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollbar:GetThumbTexture():SetSize(20, 28)
    scrollbar:SetScript("OnValueChanged", function(_, value)
        if updatingScroll then return end
        offset = math.floor(value + 0.5)
        refresh()
    end)
    local up = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
    up:SetPoint("TOPRIGHT", -5, -5)
    up:SetSize(22, 24)
    up:SetText("^")
    local down = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
    down:SetPoint("BOTTOMRIGHT", -5, 5)
    down:SetSize(22, 24)
    down:SetText("v")
    local function scrollBy(delta) offset = offset + delta; refresh() end
    up:SetScript("OnClick", function() scrollBy(-1) end)
    down:SetScript("OnClick", function() scrollBy(1) end)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta) scrollBy(-delta) end)
    refresh = function()
        local keywords = config.GetEntries()
        local maxOffset = math.max(0, #keywords - pageSize)
        offset = math.max(0, math.min(offset, maxOffset))
        countLabel:SetText((config.countLabel or "Entries") .. ": " .. #keywords)
        updatingScroll = true
        scrollbar:SetMinMaxValues(0, maxOffset)
        scrollbar:SetValue(offset)
        scrollbar:SetEnabled(maxOffset > 0)
        updatingScroll = false
        empty:SetShown(#keywords == 0)
        for index, row in ipairs(rows) do
            row.keyword = keywords[offset + index]
            row.label:SetText(row.keyword or "")
            row.remove:SetShown(row.keyword ~= nil)
            if row.scan then row.scan:SetShown(row.keyword ~= nil) end
            if row.mode then
                row.mode:SetShown(row.keyword ~= nil)
                row.mode:SetText(row.keyword and config.GetMode(row.keyword) and "Partial" or "Exact")
            end
        end
        up:SetEnabled(offset > 0)
        down:SetEnabled(offset < maxOffset)
    end
    refresh()
    return {input = input, add = add, rows = rows, scrollbar = scrollbar, list = list, Refresh = refresh}
end

function module:Initialize()
    local function label(parent, value, font, x, y, width)
        local region = parent:CreateFontString(nil, "ARTWORK", font)
        region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        region:SetWidth(width or 500)
        region:SetJustifyH("LEFT")
        region:SetText(value)
        return region
    end
    local pages = {}
    FC.settingsPages = pages
    local function page(key, title, width, height)
        local root = CreateFrame("Frame", "CommunicationToolsClassicPage" .. key, UIParent, "BackdropTemplate")
        root:SetSize(width, height)
        root:SetPoint("CENTER")
        root:SetFrameStrata("DIALOG")
        root:SetClampedToScreen(true)
        root:EnableMouse(true)
        FC:StyleWindow(root)
        root:Hide()
        if UISpecialFrames then table.insert(UISpecialFrames, "CommunicationToolsClassicPage" .. key) end
        local close = CreateFrame("Button", nil, root, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        label(root, title, "GameFontNormalLarge", 24, -24, width - 60)
        local scroll = CreateFrame("ScrollFrame", nil, root, key ~= "main" and "UIPanelScrollFrameTemplate" or nil)
        scroll:SetPoint("TOPLEFT", 16, -64)
        scroll:SetPoint("BOTTOMRIGHT", -38, key == "main" and 20 or 64)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(width - 60, height - 90)
        scroll:SetScrollChild(content)
        scroll:SetScript("OnSizeChanged", function(_, contentWidth) content:SetWidth(contentWidth) end)
        local result = { root = root, scroll = scroll, content = content, width = width, height = height }
        pages[key] = result
        if key ~= "main" then
            local back = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
            back:SetSize(160, 28)
            back:SetPoint("BOTTOM", 0, 22)
            back:SetText(key == "guildImport" and "Back to Filter Guild" or "Back to tools")
            back:SetScript("OnClick", function()
                if key == "guildImport" then FC:ShowSettingsPage("filterGuild") else FC:OpenSettings() end
            end)
        end
        return result
    end
    function FC:ShowSettingsPage(key)
        local selected = pages[key]
        if not selected then return end
        for _, entry in pairs(pages) do entry.root:Hide() end
        selected.scroll:SetVerticalScroll(0)
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if type(width) == "number" and type(height) == "number" then
            selected.root:SetScale(math.min(1, (width - 30) / selected.width, (height - 30) / selected.height))
        end
        self.currentSettingsPage = key
        self:RefreshSettings()
        selected.root:Show()
    end
    function FC:OpenSettings() self:ShowSettingsPage("main") end

    local main = page("main", "CommunicationTools Classic", 760, 244 + math.ceil(#FC.tools / 2) * 120)
    local buff = page("buffThanks", "Buff Thanks settings", 550, 660)
    local ignore = page("extendedIgnore", "Extended Ignore settings", 550, 660)
    local dnd = page("doNotDisturb", "Do Not Disturb settings", 550, 660)
    local mentions = page("nameAlerts", "Name Alerts settings", 550, 660)
    local conversations = page("whisperConversations", "Whisper Conversations settings", 550, 660)
    local filterChat = page("filterChat", "Filter Chat settings", 550, 660)
    local filterGuild = page("filterGuild", "Filter Guild settings", 550, 660)
    local guildImport = page("guildImport", "Import guild roster", 550, 660)
    local guildMembers = page("guildMembers", "Guild member blacklists", 550, 660)
    local guildRoster = page("guildRoster", "Guild member blacklist", 550, 660)
    local friendsList = page("friendsList", "Friends List", 550, 660)
    local logo = main.content:CreateTexture(nil, "ARTWORK")
    logo:SetSize(130, 65)
    logo:SetPoint("TOPLEFT", 12, 0)
    logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\RadioLogo.tga")
    label(main.content, "Your communication toolbox", "GameFontNormalLarge", 160, -8, 510)
    label(main.content, "Version " .. FC.version, "GameFontHighlightSmall", 160, -34, 510)
    label(main.content, "Enable the tools you want. Open a card to adjust its details.", "GameFontHighlight", 20, -80, 660)

    local function makeCheckbox(parent, value, x, y)
        local control = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        control:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        control:SetSize(28, 28)
        local caption = control:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        caption:SetPoint("LEFT", control, "RIGHT", 4, 0)
        caption:SetText(value)
        return control
    end

    local controls = {}
    for index, tool in ipairs(FC.tools) do
        local card = CreateFrame("Frame", nil, main.content, "BackdropTemplate")
        card:SetSize(336, 110)
        card:SetPoint("TOPLEFT", 12 + ((index - 1) % 2) * 348, -110 - math.floor((index - 1) / 2) * 120)
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        card:SetBackdropColor(0.075, 0.105, 0.10, 1)
        card:SetBackdropBorderColor(0.23, 0.29, 0.24, 1)
        label(card, tool.name, "GameFontNormalLarge", 16, -12, 300)
        label(card, tool.description, "GameFontHighlightSmall", 16, -38, 300)
        local control = makeCheckbox(card, "Enabled", 10, -78)
        control:SetScript("OnClick", function(self) tool.SetEnabled(self:GetChecked()) end)
        controls[#controls + 1] = { control = control, tool = tool }
        local configure = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        configure:SetSize(138, 28)
        configure:SetPoint("BOTTOMRIGHT", -14, 12)
        configure:SetText("Configure")
        configure:SetScript("OnClick", function() FC:ShowSettingsPage(tool.settingsPage) end)
        controls[#controls].configure = configure
    end
    FC.toolMenuControls = controls
    label(main.content, "Thanks to Fenty Od for testing and ideas, Proba Croisus and Nefas Aeternum for testing, and Garok Shrike for suggestions.", "GameFontHighlightSmall",
        20, -120 - math.ceil(#FC.tools / 2) * 120, 660)
    main.content:SetHeight(160 + math.ceil(#FC.tools / 2) * 120)
    local panel = buff.content
    local function text(value, font, x, y, width) return label(panel, value, font, x, y, width) end
    local function checkbox(value, y) return makeCheckbox(panel, value, 16, y) end
    local y = 0
    text("Buff Thanks: reply channel (choose one)", "GameFontNormal", 16, y - 8)
    local whisper = checkbox("Whisper", y - 30)
    local say = checkbox("/say", y - 64)
    local instances = makeCheckbox(panel, "Thank players in instances", 180, y - 30)
    instances:SetScript("OnClick", function(self) FC:SetThanksInInstances(self:GetChecked()) end)
    text("Whispers wait until combat and typing finish. For /say, click the on-screen button after combat to send each thank-you.",
        "GameFontHighlightSmall", 20, y - 108, 440)
    text("Changes take effect immediately and are saved account-wide. Changing either setting clears queued thanks.",
        "GameFontHighlightSmall", 20, y - 156, 440)
    text("Random thank-you messages", "GameFontNormal", 20, -210)
    text("Use any wording, even just \"Thanks!\". Labels are optional: <buffname> inserts the buff; <buffername> inserts the player. Use either, both, or neither. One nonblank message is picked randomly. Leave unused boxes blank; keep at least one. Limit: 200 bytes each, 255 after substitution.",
        "GameFontHighlightSmall", 20, -238, 440)
    local templates, previews = {}, {}
    for index = 1, 4 do
        local top = -314 - (index - 1) * 128
        text("Message " .. index, "GameFontNormal", 20, top, 440)
        local editor = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        editor:SetSize(430, 30)
        editor:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, top - 24)
        editor:SetAutoFocus(false)
        editor:SetMaxBytes(200)
        templates[index] = editor
        previews[index] = text("", "GameFontHighlightSmall", 20, top - 64, 440)
    end
    local feedback = text("", "GameFontHighlightSmall", 20, -848, 440)
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetSize(130, 26)
    save:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -900)
    save:SetText("Save messages")
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 26)
    reset:SetPoint("LEFT", save, "RIGHT", 12, 0)
    reset:SetText("Restore defaults")
    local function updatePreview()
        local count, problem = 0, nil
        for index, editor in ipairs(templates) do
            local draft = editor:GetText()
            if draft:find("%S") then
                count = count + 1
                local valid, reason = FC:ValidateThanksTemplate(draft)
                local message, lengthError = FC:FormatThanks("Arcane Intellect", "Exampleplayer", draft)
                previews[index]:SetText(valid and ("Preview: " .. (message or lengthError)) or reason)
                if not valid then problem = "Message " .. index .. ": " .. reason end
            else previews[index]:SetText("Unused (skipped)") end
        end
        if count == 0 then problem = "Keep at least one nonblank message." end
        save:SetEnabled(problem == nil)
        feedback:SetText(problem or "Click Save messages to apply your changes.")
    end
    local function saveTemplate()
        local drafts = {}
        for index, editor in ipairs(templates) do drafts[index] = editor:GetText() end
        local success, reason = FC:SetThanksTemplates(drafts)
        if success then
            for _, editor in ipairs(templates) do editor:ClearFocus() end
            feedback:SetText("Message pool saved.")
        else
            feedback:SetText(reason)
        end
    end
    save:SetScript("OnClick", saveTemplate)
    for index, editor in ipairs(templates) do
        editor:SetScript("OnTextChanged", updatePreview)
        editor:SetScript("OnEnterPressed", saveTemplate)
        editor:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            self:SetText(FC.db.thanksTemplates[index] or "")
        end)
    end
    reset:SetScript("OnClick", function()
        for _, editor in ipairs(templates) do editor:ClearFocus() end
        FC:SetThanksTemplates(FC.defaultThanksTemplates)
        feedback:SetText("Default message pool restored.")
    end)
    local exclusionEditor = FC:CreateEntryEditor(panel, text, {
        top = -960, caption = "Buffs excluded from thanks", addLabel = "Add buff",
        help = "Enter an exact buff name to prevent it from triggering thanks. Press Enter to keep adding. Scroll to browse; × removes an exclusion. Changes save immediately.",
        GetEntries = function()
            local names = {}; for _, name in pairs(FC.db.buffExclusions or {}) do names[#names + 1] = name end
            table.sort(names); return names
        end,
        Add = function(value) return FC:AddBuffExclusion(value) end,
        Remove = function(value) return FC:RemoveBuffExclusion(value) end,
    })
    FC.buffExclusionEditor = exclusionEditor
    exclusionEditor.input.isBuffExclusions = true
    panel:SetHeight(1410)
    local function ignoreText(value, font, x, y, width) return label(ignore.content, value, font, x, y, width) end
    ignore.content:SetHeight(FC:BuildExtendedIgnoreSettings(ignore.content, -8, ignoreText))
    local function dndText(value, font, x, y, width) return label(dnd.content, value, font, x, y, width) end
    dnd.content:SetHeight(FC:BuildDNDSettings(dnd.content, dndText))
    local function mentionsText(value, font, x, y, width) return label(mentions.content, value, font, x, y, width) end
    mentions.content:SetHeight(FC:BuildNameAlertsSettings(mentions.content, mentionsText))

    local function conversationText(value, font, x, y, width) return label(conversations.content, value, font, x, y, width) end
    conversations.content:SetHeight(FC:BuildWhisperConversationSettings(conversations.content, conversationText))

    local function filterText(value, font, x, y, width) return label(filterChat.content, value, font, x, y, width) end
    filterChat.content:SetHeight(FC:BuildFilterChatSettings(filterChat.content, filterText))

    local function guildText(value, font, x, y, width) return label(filterGuild.content, value, font, x, y, width) end
    filterGuild.content:SetHeight(FC:BuildFilterGuildSettings(filterGuild.content, guildText))
    local function guildImportText(value, font, x, y, width) return label(guildImport.content, value, font, x, y, width) end
    guildImport.content:SetHeight(FC:BuildGuildImportSettings(guildImport.content, guildImportText))

    local function guildMemberText(value, font, x, y, width) return label(guildMembers.content, value, font, x, y, width) end
    guildMembers.content:SetHeight(FC:BuildGuildMembersSettings(guildMembers.content, guildMemberText))
    local function guildRosterText(value, font, x, y, width) return label(guildRoster.content, value, font, x, y, width) end
    guildRoster.content:SetHeight(FC:BuildGuildRosterSettings(guildRoster.content, guildRosterText))

    local function friendsText(value, font, x, y, width) return label(friendsList.content, value, font, x, y, width) end
    friendsList.content:SetHeight(FC:BuildFriendsListSettings(friendsList.content, friendsText))

    function FC:RefreshSettings()
        for _, entry in ipairs(controls) do
            entry.control:SetChecked(entry.tool.IsEnabled())
        end
        whisper:SetChecked(self.db.channel == "WHISPER")
        say:SetChecked(self.db.channel == "SAY")
        instances:SetChecked(self.db.thanksInInstances == true)
        for index, editor in ipairs(templates) do
            if not editor:HasFocus() then editor:SetText(self.db.thanksTemplates[index] or "") end
        end
        exclusionEditor.Refresh()
        self:RefreshFriendsListSettings()
        self:RefreshGuildMembersSettings()
        self:RefreshFilterGuildSettings()
        self:RefreshGuildImportSettings()
        self:RefreshFilterChatSettings()
        self:RefreshBlacklist()
        self:RefreshIgnoreReplySettings()
        self:RefreshDNDSettings()
        self:RefreshNameAlertsSettings()
        self:RefreshWhisperConversationSettings()
    end
    -- Always re-check the chosen option, even when clicking the selected channel.
    whisper:SetScript("OnClick", function() FC:SetBuffThanksChannel("WHISPER") end)
    say:SetScript("OnClick", function() FC:SetBuffThanksChannel("SAY") end)
    for _, entry in pairs(pages) do entry.root:SetScript("OnShow", function() FC:RefreshSettings() end) end
    FC:RefreshSettings()

    local container = CreateFrame("Frame")
    container.name = "CommunicationTools Classic"
    label(container, "CommunicationTools Classic", "GameFontNormalLarge", 20, -20, 440)
    label(container, "Open the tool menu to enable tools or visit their individual settings pages.", "GameFontHighlight", 20, -60, 440)
    local launch = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    launch:SetSize(240, 30)
    launch:SetPoint("TOPLEFT", 20, -110)
    launch:SetText("Open CommunicationTools")
    launch:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel.Hide then SettingsPanel:Hide() end
        FC:OpenSettings()
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(container, container.name)
        Settings.RegisterAddOnCategory(category)
        FC.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(container)
        FC.legacySettingsPanel = container
    else
        FC:Print("This client does not expose a supported settings panel API.")
    end
end
