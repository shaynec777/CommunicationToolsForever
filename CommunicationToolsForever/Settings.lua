local addonName, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module

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
        local root = CreateFrame("Frame", "CommunicationToolsForeverPage" .. key, UIParent, "BackdropTemplate")
        root:SetSize(width, height)
        root:SetPoint("CENTER")
        root:SetFrameStrata("DIALOG")
        root:SetClampedToScreen(true)
        root:EnableMouse(true)
        root:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 })
        root:SetBackdropColor(0.035, 0.047, 0.044, 1)
        root:SetBackdropBorderColor(0.64, 0.65, 0.49, 1)
        root:Hide()
        if UISpecialFrames then table.insert(UISpecialFrames, "CommunicationToolsForeverPage" .. key) end
        local close = CreateFrame("Button", nil, root, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        label(root, title, "GameFontNormalLarge", 24, -24, width - 60)
        local scroll = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
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
            back:SetText("Back to tools")
            back:SetScript("OnClick", function() FC:OpenSettings() end)
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

    local main = page("main", "CommunicationTools Forever", 760, math.min(812, 314 + math.ceil(#FC.tools / 2) * 166))
    local buff = page("buffThanks", "Buff Thanks settings", 550, 660)
    local ignore = page("extendedIgnore", "Extended Ignore settings", 550, 660)
    local dnd = page("doNotDisturb", "Do Not Disturb settings", 550, 660)
    local mentions = page("nameAlerts", "Name Alerts settings", 550, 660)
    local conversations = page("whisperConversations", "Whisper Conversations settings", 550, 660)
    local logo = main.content:CreateTexture(nil, "ARTWORK")
    logo:SetSize(220, 110)
    logo:SetPoint("TOPLEFT", 12, 0)
    logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\RadioLogo.tga")
    label(main.content, "Your communication toolbox", "GameFontNormalLarge", 250, -20, 430)
    label(main.content, "Version " .. FC.version, "GameFontHighlightSmall", 250, -50, 430)
    label(main.content, "Enable the tools you want. Open a card to adjust its details.", "GameFontHighlight", 20, -130, 660)

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
        card:SetSize(336, 150)
        card:SetPoint("TOPLEFT", 12 + ((index - 1) % 2) * 348, -166 - math.floor((index - 1) / 2) * 166)
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        card:SetBackdropColor(0.075, 0.105, 0.10, 1)
        card:SetBackdropBorderColor(0.23, 0.29, 0.24, 1)
        label(card, tool.name, "GameFontNormalLarge", 16, -16, 300)
        label(card, tool.description, "GameFontHighlightSmall", 16, -46, 300)
        local control = makeCheckbox(card, "Enabled", 10, -108)
        control:SetScript("OnClick", function(self) tool.SetEnabled(self:GetChecked()) end)
        controls[#controls + 1] = { control = control, tool = tool }
        local configure = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        configure:SetSize(138, 28)
        configure:SetPoint("BOTTOMRIGHT", -14, 14)
        configure:SetText("Configure")
        configure:SetScript("OnClick", function() FC:ShowSettingsPage(tool.settingsPage) end)
        controls[#controls].configure = configure
    end
    FC.toolMenuControls = controls
    label(main.content, "Thanks to Fenty Od for testing and ideas, and Proba Croisus for testing.", "GameFontHighlightSmall",
        20, -184 - math.ceil(#FC.tools / 2) * 166, 660)
    main.content:SetHeight(224 + math.ceil(#FC.tools / 2) * 166)
    local panel = buff.content
    local function text(value, font, x, y, width) return label(panel, value, font, x, y, width) end
    local function checkbox(value, y) return makeCheckbox(panel, value, 16, y) end
    local y = 0
    text("Buff Thanks: reply channel (choose one)", "GameFontNormal", 16, y - 8)
    local whisper = checkbox("Whisper", y - 30)
    local say = checkbox("/say", y - 64)
    text("Whispers are sent automatically. For /say, click the on-screen button to send each thank-you.",
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
    text("Excluded buffs (one exact buff name per line)", "GameFontNormal", 20, -960, 440)
    text("These effects never trigger thanks. Remove a name to allow it again.", "GameFontHighlightSmall", 20, -986, 440)
    local exclusions = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    exclusions:SetPoint("TOPLEFT", 24, -1020)
    exclusions:SetSize(425, 110)
    exclusions.isBuffExclusions = true
    exclusions:SetMultiLine(true)
    exclusions:SetAutoFocus(false)
    exclusions:SetMaxBytes(4000)
    exclusions:SetText(FC:GetBuffExclusionsText())
    exclusions:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local saveExclusions = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveExclusions:SetPoint("TOPLEFT", 20, -1140)
    saveExclusions:SetSize(180, 28)
    saveExclusions:SetText("Save excluded buffs")
    local exclusionStatus = text("", "GameFontHighlightSmall", 20, -1180, 440)
    saveExclusions:SetScript("OnClick", function()
        local ok, reason = FC:SetBuffExclusions(exclusions:GetText())
        exclusionStatus:SetText(ok and "Excluded buffs saved." or reason)
        if ok then exclusions:ClearFocus() end
    end)
    panel:SetHeight(1230)
    local function ignoreText(value, font, x, y, width) return label(ignore.content, value, font, x, y, width) end
    ignore.content:SetHeight(FC:BuildExtendedIgnoreSettings(ignore.content, -8, ignoreText))
    local function dndText(value, font, x, y, width) return label(dnd.content, value, font, x, y, width) end
    dnd.content:SetHeight(FC:BuildDNDSettings(dnd.content, dndText))
    local function mentionsText(value, font, x, y, width) return label(mentions.content, value, font, x, y, width) end
    mentions.content:SetHeight(FC:BuildNameAlertsSettings(mentions.content, mentionsText))

    local function conversationText(value, font, x, y, width) return label(conversations.content, value, font, x, y, width) end
    conversations.content:SetHeight(FC:BuildWhisperConversationSettings(conversations.content, conversationText))

    function FC:RefreshSettings()
        for _, entry in ipairs(controls) do
            entry.control:SetChecked(entry.tool.IsEnabled())
        end
        whisper:SetChecked(self.db.channel == "WHISPER")
        say:SetChecked(self.db.channel == "SAY")
        for index, editor in ipairs(templates) do
            if not editor:HasFocus() then editor:SetText(self.db.thanksTemplates[index] or "") end
        end
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
    container.name = "CommunicationTools Forever"
    label(container, "CommunicationTools Forever", "GameFontNormalLarge", 20, -20, 440)
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
