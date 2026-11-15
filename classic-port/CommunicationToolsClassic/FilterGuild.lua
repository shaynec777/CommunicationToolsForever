local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module

local function lower(value) return (strlower or string.lower)(value) end
local function parse(value)
    if type(value) ~= "string" or #value > 4000 then return nil, "Use at most 4000 bytes." end
    local entries, seen = {}, {}
    for line in value:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            if line:find("[%c|]") then return nil, "Use plain text without chat formatting codes." end
            local key = lower(line)
            if not seen[key] then entries[#entries + 1] = line; seen[key] = true end
        end
    end
    return entries
end

function FC:SetGuildFilterNames(value)
    local entries, reason = parse(value)
    if not entries then return false, reason end
    self.db.filterGuild.guilds = entries
    local modes = {}
    for _, name in ipairs(entries) do modes[lower(name)] = self.db.filterGuild.partialGuilds and self.db.filterGuild.partialGuilds[lower(name)] == true or nil end
    self.db.filterGuild.partialGuilds = modes
    return true, "Guild blacklist saved."
end

function FC:IsGuildFilterPartial(name)
    return self.db.filterGuild.partialGuilds[lower(name)] == true
end
function FC:SetGuildFilterPartial(name, partial)
    for _, entry in ipairs(self.db.filterGuild.guilds) do
        if lower(entry) == lower(name) then
            self.db.filterGuild.partialGuilds[lower(entry)] = partial == true or nil
            if self.ResetGuildScan then self:ResetGuildScan() end
            return true
        end
    end
    return false
end
local function matchesGuild(guild, term, partial)
    local body, key = lower(guild), lower(term)
    return body == key or (partial and body:find(key, 1, true) ~= nil)
end

function FC:AddGuildFilterName(value)
    if not self:IsPublic(value) or type(value) ~= "string" or value:find("[%c|]") then return false, "Enter one guild name or part of a name." end
    value = value:match("^%s*(.-)%s*$")
    if value == "" then return false, "Enter a guild name or part of a name." end
    local entries = {}
    for _, name in ipairs(self.db.filterGuild.guilds) do
        if lower(name) == lower(value) then
            if self.db.filterGuild.removedGuilds[lower(value)] then
                self.db.filterGuild.removedGuilds[lower(value)] = nil
                return true, "Guild filtering restored: " .. value
            end
            return false, "That entry is already listed."
        end
        entries[#entries + 1] = name
    end
    entries[#entries + 1] = value
    local ok, reason = self:SetGuildFilterNames(table.concat(entries, "\n"))
    if ok then self.db.filterGuild.removedGuilds[lower(value)] = nil end
    return ok, ok and ("Added: " .. value) or reason
end
function FC:RemoveGuildFilterName(value)
    for index, name in ipairs(self.db.filterGuild.guilds) do
        if name == value then
            local wasPartial = self:IsGuildFilterPartial(name)
            table.remove(self.db.filterGuild.guilds, index)
            self.db.filterGuild.partialGuilds[lower(name)] = nil
            local function uncovered(guild)
                local matchesRemoved = matchesGuild(guild, name, wasPartial)
                return matchesRemoved and not self:GuildNameMatchesFilter(guild)
            end
            for key, entry in pairs(self.db.filterGuild.learned) do if uncovered(entry.guild) then self.db.filterGuild.learned[key] = nil end end
            for key, entry in pairs(self.db.filterGuild.learnedNames) do if uncovered(entry.guild) then self.db.filterGuild.learnedNames[key] = nil end end
            for key, roster in pairs(self.db.filterGuild.imports) do if uncovered(roster.name) then self.db.filterGuild.imports[key] = nil end end
            for key in pairs(self.db.filterGuild.allowedMembers) do local guild = key:match("^(.-)\n"); if guild and uncovered(guild) then self.db.filterGuild.allowedMembers[key] = nil end end
            if self.ResetGuildScan then self:ResetGuildScan() end
            return true, "Removed guild filter and its uncovered member lists: " .. name
        end
    end
    return false, "Entry no longer listed."
end
function FC:GuildNameMatchesFilter(name)
    if not self:IsPublic(name) or type(name) ~= "string" or name == "" then return false end
    if self.db.filterGuild.removedGuilds[lower(name)] then return false end
    for _, entry in ipairs(self.db.filterGuild.guilds) do
        if matchesGuild(name, entry, self:IsGuildFilterPartial(entry)) then return true end
    end
    return false
end

local function importGuildKey(value)
    local entries = parse(value)
    if not entries or #entries ~= 1 then return nil end
    return lower(entries[1]), entries[1]
end

local rosterClasses = {"warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"}
local function rosterCharacterColumn(line)
    local first = line:match("^([^\t]+)\t")
    if first then return first end
    -- Browsers and edit boxes can turn copied table tabs into spaces. Locate the
    -- class column and numeric level/rank tail instead of splitting a full name.
    for _, class in ipairs(rosterClasses) do
        local character, race, level, rank = line:lower():match("^(.*)%s+" .. class .. "%s+(.+)%s+(%d+)%s+(.+)$")
        if character and tonumber(level) > 0 and (rank:match("^%d+$") or rank == "guild master" or rank:match("^rank%s+%d+$")) then
            return line:sub(1, #character):match("^%s*(.-)%s*$")
        end
    end
    return line
end

function FC:ImportGuildRoster(guild, roster, activate)
    local key, name = importGuildKey(guild)
    if not key then return false, "Enter one full guild name." end
    if type(roster) ~= "string" or #roster > 160000 then return false, "Use at most 160000 bytes of character names." end
    local names, labels, count = {}, {}, 0
    roster = roster:gsub("\194\160", " "):match("^%s*(.-)%s*$")
    if roster:sub(1, 1) == '"' and roster:sub(-1) == '"' then roster = roster:sub(2, -2) end
    for line in roster:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        -- Also accept line-ending backslashes from a roster pasted into a quoted chat block.
        line = line:gsub("\\%s*$", "")
        if line ~= "" then
            local firstColumn = line:match("^([^\t]+)\t")
            local heading = lower(line) == lower(name) .. " roster"
            local header = (firstColumn and (lower(firstColumn) == "character" or lower(firstColumn) == "name"))
                or lower(line):gsub("%s+", " ") == "character class race level guild rank"
            if not header and not heading then
                local name = rosterCharacterColumn(line)
                local member = self:NormalizeBlacklistName(name)
                if not member then return false, "Paste character names (Name-Realm) or copied roster rows (tabs or spaces). Keep the guild roster title/header, but remove other page text." end
                if not names[member] then names[member] = true; labels[member] = name; count = count + 1 end
                if count > 1000 then return false, "Import at most 1000 characters per guild." end
            end
        end
    end
    if count == 0 then return false, "Paste at least one full character name." end
    if activate then
        if not self:GuildNameMatchesFilter(name) then
            local ok, reason = self:AddGuildFilterName(name)
            if not ok then return false, reason end
        end
        self.db.filterGuild.useImports = true
    end
    self.db.filterGuild.imports[key] = {name = name, members = names, labels = labels, count = count}
    if activate then return true, "Imported " .. count .. " characters for " .. name .. ". Active in Guild blacklists." end
    return true, "Imported " .. count .. " characters for " .. name .. ". Enable imported rosters and blacklist this guild to use them."
end

function FC:RemoveImportedGuildRoster(guild)
    local key = importGuildKey(guild)
    if not key or not self.db.filterGuild.imports[key] then return false, "No imported roster for that guild." end
    self.db.filterGuild.imports[key] = nil
    return true, "Imported roster removed."
end

local function publicString(value) return FC:IsPublic(value) and type(value) == "string" and value ~= "" end
local function unitName(unit)
    return FC:ClassicCharacterName(unit)
end
local function remember(unit, author)
    if not GetGuildInfo or not UnitGUID then return end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or not publicString(guid) then return end
    local success, guild = pcall(GetGuildInfo, unit)
    if not success or not FC:IsPublic(guild) then return end
    -- A public nil is a current guildless observation; replace old membership.
    if guild ~= nil and type(guild) ~= "string" then return end
    local verified, current = pcall(UnitGUID, unit)
    if not verified or not publicString(current) or current ~= guid then return end
    local learned = FC.db.filterGuild.learned
    local name = publicString(author) and author or unitName(unit)
    local key = name and FC:NormalizeBlacklistName(name)
    learned[guid] = {guild = guild or "", name = key, displayName = name}
    if key then FC.db.filterGuild.learnedNames[key] = {guild = guild or "", name = name} end
    return learned[guid]
end
function FC:IsGuildFiltered(author, guid)
    local settings = self.db and self.db.filterGuild
    if not settings or not settings.enabled or #settings.guilds == 0 or not self:IsPublic(guid) then return false end
    local entry
    if publicString(guid) and UnitTokenFromGUID then
        local ok, unit = pcall(UnitTokenFromGUID, guid)
        if ok and publicString(unit) and UnitGUID then
            local success, current = pcall(UnitGUID, unit)
            if success and publicString(current) and current == guid then entry = remember(unit, author) end
        end
    end
    entry = entry or (publicString(guid) and settings.learned[guid])
    local member = publicString(author) and self:NormalizeBlacklistName(author)
    if entry and member then entry.name = member end
    entry = entry or (member and settings.learnedNames[member])
    if entry then
        -- Observed membership takes precedence over imported snapshots until a new observation replaces it.
        return not self:IsGuildMemberAllowed(member, guid, entry.guild) and self:GuildNameMatchesFilter(entry.guild)
    end
    if settings.useImports and publicString(author) then
        local member = self:NormalizeBlacklistName(author)
        if member then
            for _, roster in pairs(settings.imports) do
                if self:GuildNameMatchesFilter(roster.name) and roster.members[member] and not self:IsGuildMemberAllowed(member, guid, roster.name) then return true end
            end
        end
    end
    return false
end

function FC:IsGuildMemberAllowed(member, guid, guild)
    local prefix = lower(guild) .. "\n"
    local exceptions = self.db.filterGuild.allowedMembers
    return (member and exceptions[prefix .. member] == true) or (publicString(guid) and exceptions[prefix .. "guid:" .. guid] == true) or false
end
function FC:AddGuildBlacklistMember(guild, name)
    local key = self:NormalizeBlacklistName(name)
    if not key or not guild or not self:GuildNameMatchesFilter(guild) then return false, "Select a blacklisted guild and enter a full character name." end
    self.db.filterGuild.learnedNames[key] = {guild = guild, name = name}
    self.db.filterGuild.allowedMembers[lower(guild) .. "\n" .. key] = nil
    return true, "Added: " .. name
end
function FC:RemoveGuildBlacklistMember(guild, name)
    local key = name:match("^Player%-") and ("guid:" .. name) or self:NormalizeBlacklistName(name)
    if not key or not guild then return false, "Member unavailable." end
    self.db.filterGuild.allowedMembers[lower(guild) .. "\n" .. key] = true
    return true, "Allowed through this guild filter: " .. name
end
function FC:RestoreGuildBlacklistMembers(guild)
    if not guild then return end
    local prefix = lower(guild) .. "\n"
    for key in pairs(self.db.filterGuild.allowedMembers) do
        if key:sub(1, #prefix) == prefix then self.db.filterGuild.allowedMembers[key] = nil end
    end
end
function FC:GetGuildMemberBlacklists()
    local settings, candidates, groups = self.db.filterGuild, {}, {}
    for key, entry in pairs(settings.learnedNames) do candidates[key] = {guild = entry.guild, name = entry.name or key, member = key} end
    for guid, entry in pairs(settings.learned) do
        candidates[entry.name or ("guid:" .. guid)] = {guild = entry.guild, name = entry.displayName or entry.name or guid, member = entry.name, guid = guid}
    end
    if settings.useImports then
        for _, roster in pairs(settings.imports) do
            for key in pairs(roster.members) do if not candidates[key] then candidates[key] = {guild = roster.name, name = roster.labels and roster.labels[key] or key, member = key} end end
        end
    end
    for _, entry in pairs(candidates) do
        if self:GuildNameMatchesFilter(entry.guild) and not self:IsGuildMemberAllowed(entry.member, entry.guid, entry.guild) then
            local key = lower(entry.guild)
            groups[key] = groups[key] or {guild = entry.guild, members = {}}
            local members = groups[key].members
            members[#members + 1] = entry.name
        end
    end
    for _, guild in ipairs(settings.guilds) do
        if not self:IsGuildFilterPartial(guild) and self:GuildNameMatchesFilter(guild) then groups[lower(guild)] = groups[lower(guild)] or {guild = guild, members = {}} end
    end
    local result = {}
    for _, group in pairs(groups) do table.sort(group.members); result[#result + 1] = group end
    table.sort(result, function(a, b) return lower(a.guild) < lower(b.guild) end)
    return result
end
function FC:PruneEmptyPartialGuildFilters(preferredGuild)
    local settings = self.db.filterGuild
    local remaining = self:GetGuildMemberDirectory()
    for index = #settings.guilds, 1, -1 do
        local rule = settings.guilds[index]
        if self:IsGuildFilterPartial(rule) then
            local removed
            for _, entry in pairs(settings.removedGuilds) do
                if matchesGuild(entry.name, rule, true) then
                    removed = entry
                    if preferredGuild and lower(entry.name) == lower(preferredGuild) then break end
                end
            end
            local stillCovered = false
            for _, group in ipairs(remaining) do
                if matchesGuild(group.guild, rule, true) then stillCovered = true; break end
            end
            if removed and not stillCovered then
                removed.restoreRules = removed.restoreRules or {}
                removed.restoreRules[rule] = true
                table.remove(settings.guilds, index)
                settings.partialGuilds[lower(rule)] = nil
            end
        end
    end
end

function FC:RemoveGuildBlacklist(guild)
    if not self:IsPublic(guild) or type(guild) ~= "string" or guild == "" then return false end
    local settings, key, hadExact = self.db.filterGuild, lower(guild), false
    for index = #settings.guilds, 1, -1 do
        local entry = settings.guilds[index]
        if lower(entry) == key and not self:IsGuildFilterPartial(entry) then
            table.remove(settings.guilds, index); settings.partialGuilds[key] = nil; hadExact = true
        end
    end
    -- Keep a broad partial rule intact, but exempt this actual guild from it.
    settings.removedGuilds[key] = {name = guild, restoreExact = hadExact}
    for id, entry in pairs(settings.learned) do if lower(entry.guild) == key then settings.learned[id] = nil end end
    for name, entry in pairs(settings.learnedNames) do if lower(entry.guild) == key then settings.learnedNames[name] = nil end end
    for id, roster in pairs(settings.imports) do if lower(roster.name) == key then settings.imports[id] = nil end end
    local prefix = key .. "\n"
    for id in pairs(settings.allowedMembers) do if id:sub(1, #prefix) == prefix then settings.allowedMembers[id] = nil end end
    if self.selectedGuildBlacklist and lower(self.selectedGuildBlacklist) == key then self.selectedGuildBlacklist = nil end
    self:PruneEmptyPartialGuildFilters(guild)
    if self.ResetGuildScan then self:ResetGuildScan() end
    if self.RefreshGuildMembersSettings then self:RefreshGuildMembersSettings() end
    return true
end
function FC:RestoreRemovedGuilds(onlyRule)
    local removed, saved = {}, self.db.filterGuild.removedGuilds
    for key, entry in pairs(saved) do
        if not onlyRule or matchesGuild(entry.name, onlyRule, self:IsGuildFilterPartial(onlyRule)) or (entry.restoreRules and entry.restoreRules[onlyRule]) then
            removed[key] = entry; saved[key] = nil
        end
    end
    if not next(removed) then return end
    for _, entry in pairs(removed) do
        if entry.restoreExact then self:AddGuildFilterName(entry.name) end
        for rule in pairs(entry.restoreRules or {}) do
            if not onlyRule or lower(rule) == lower(onlyRule) then
                self:AddGuildFilterName(rule)
                self:SetGuildFilterPartial(rule, true)
            end
        end
    end
    if self.ResetGuildScan then self:ResetGuildScan() end
    if self.RefreshGuildMembersSettings then self:RefreshGuildMembersSettings() end
end

function FC:GetGuildMemberDirectory()
    local groups = self:GetGuildMemberBlacklists()
    local seen = {}; for _, group in ipairs(groups) do seen[lower(group.guild)] = true end
    for key in pairs(self.db.filterGuild.allowedMembers) do
        local guild = key:match("^(.-)\n")
        if guild and not seen[guild] and self:GuildNameMatchesFilter(guild) then
            groups[#groups + 1] = {guild = guild, members = {}}; seen[guild] = true
        end
    end
    table.sort(groups, function(a,b) return lower(a.guild) < lower(b.guild) end)
    return groups
end
function FC:OpenGuildMemberBlacklist(guild)
    self.selectedGuildBlacklist = guild
    self:ShowSettingsPage("guildRoster")
end
function FC:CreateGuildScanProgress(panel, y)
    local box = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 20, y); box:SetSize(425, 82)
    box:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    box:SetBackdropColor(0.045, 0.09, 0.085, 1); box:SetBackdropBorderColor(0.35, 0.7, 0.55, 1)
    local function label(font, x, top, width)
        local value = box:CreateFontString(nil, "ARTWORK", font)
        value:SetPoint("TOPLEFT", x, top); value:SetWidth(width); value:SetJustifyH("LEFT")
        return value
    end
    local phase = label("GameFontNormal", 10, -8, 210)
    local stats = label("GameFontHighlightSmall", 224, -10, 190)
    local detail = label("GameFontHighlightSmall", 10, -30, 402)
    detail:SetMaxLines(2)
    local bar = CreateFrame("StatusBar", nil, box)
    bar:SetPoint("BOTTOMLEFT", 10, 8); bar:SetSize(405, 10)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); bar:SetMinMaxValues(0, 1)
    local function refresh()
        FC:RefreshGuildScanButtons()
        local state = FC:GetGuildScanProgress()
        phase:SetText(state.phase)
        stats:SetText(state.completed .. " done / " .. state.remaining .. " left / " .. state.found .. " found")
        detail:SetText(state.message)
        bar:SetValue(state.value)
        if state.pending then bar:SetStatusBarColor(1, 0.72, 0.18, 1) else bar:SetStatusBarColor(0.2, 0.8, 0.5, 1) end
    end
    box:SetScript("OnShow", refresh)
    box:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.25 then self.elapsed = 0; refresh() end
    end)
    box:EnableMouse(true)
    box:SetScript("OnEnter", function(self)
        if GameTooltip then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(FC:GetGuildScanProgress().message, nil, nil, nil, nil, true); GameTooltip:Show() end
    end)
    box:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.guildScanProgressWidgets = self.guildScanProgressWidgets or {}
    self.guildScanProgressWidgets[#self.guildScanProgressWidgets + 1] = refresh
    refresh()
    return box
end

function FC:BuildGuildMembersSettings(panel, text)
    text("Click a guild to open its blacklist, or Scan beside it to search that specific guild. The x removes the guild and its saved list. Other guilds covered by a partial rule stay filtered. Scroll to see more guilds.", "GameFontHighlightSmall", 20, -8, 440)
    local restore = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    restore:SetPoint("TOPLEFT", 20, -78); restore:SetSize(220, 28); restore:SetText("Restore removed guilds")
    restore:SetScript("OnClick", function() FC:RestoreRemovedGuilds() end)
    local scanAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    scanAll:SetPoint("TOPLEFT", 252, -78); scanAll:SetSize(100, 28); scanAll:SetText("Scan")
    scanAll:SetScript("OnClick", function() FC:ScanNextGuild() end)
    self:RegisterGuildScanButton(scanAll)
    self:CreateGuildScanProgress(panel, -122)
    local empty = text("", "GameFontNormal", 20, -220, 440)
    local buttons = {}
    self.guildDirectoryButtons = buttons
    function FC:RefreshGuildMembersSettings()
        local groups = self:GetGuildMemberDirectory()
        restore:SetEnabled(next(self.db.filterGuild.removedGuilds) ~= nil)
        empty:SetText(#groups == 0 and "No guilds found yet. Add a filter, run Scan or import a roster." or (#groups .. " guilds - click a guild below"))
        for index, group in ipairs(groups) do
            local button = buttons[index]
            if not button then
                button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
                button:SetPoint("TOPLEFT", 20, -252 - (index - 1) * 44)
                button:SetSize(303, 36)
                button:SetScript("OnClick", function(self) FC:OpenGuildMemberBlacklist(self.guildName) end)
                local scanGuild = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
                scanGuild:SetPoint("LEFT", button, "RIGHT", 8, 0); scanGuild:SetSize(70, 32); scanGuild:SetText("Scan")
                scanGuild:SetScript("OnClick", function() if button.guildName then FC:ScanNextGuild(button.guildName, true) end end)
                button.scan = scanGuild
                self:RegisterGuildScanButton(scanGuild, function() return button.guildName ~= nil and FC:GuildNameMatchesFilter(button.guildName) end)
                local remove = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
                remove:SetPoint("LEFT", scanGuild, "RIGHT", 8, 0)
                remove:SetSize(34, 32); remove:SetText("\195\151")
                remove:SetScript("OnClick", function() if button.guildName then FC:RemoveGuildBlacklist(button.guildName) end end)
                button.remove = remove
                buttons[index] = button
            end
            button.guildName = group.guild
            button:SetText(group.guild .. " (" .. #group.members .. " members)")
            button:Show(); button.remove:Show(); button.scan:Show()
        end
        for index = #groups + 1, #buttons do buttons[index].guildName = nil; buttons[index]:Hide(); buttons[index].remove:Hide(); buttons[index].scan:Hide() end
        panel:SetHeight(math.max(200, 284 + #groups * 44))
        if self.RefreshGuildRosterSettings then self:RefreshGuildRosterSettings() end
    end
    self:RefreshGuildMembersSettings()
    return math.max(200, 284 + #self:GetGuildMemberDirectory() * 44)
end
function FC:BuildGuildRosterSettings(panel, text)
    local heading = text("", "GameFontNormalLarge", 20, -8, 440)
    local back = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    back:SetPoint("TOPLEFT", 20, -42); back:SetSize(200, 28); back:SetText("Back to guild list")
    back:SetScript("OnClick", function() FC:ShowSettingsPage("guildMembers") end)
    local editor = self:CreateEntryEditor(panel, text, {
        top = -92, caption = "Guild member blacklist", addLabel = "Add member",
        help = "Add a full character name if needed. Scroll to browse. The x beside a name allows it through this guild filter, even after another scan. Other word/player filters still apply.",
        GetEntries = function()
            for _, group in ipairs(FC:GetGuildMemberDirectory()) do
                if lower(group.guild) == lower(FC.selectedGuildBlacklist or "") then return group.members end
            end
            return {}
        end,
        Add = function(value) return FC:AddGuildBlacklistMember(FC.selectedGuildBlacklist, value) end,
        Remove = function(value) return FC:RemoveGuildBlacklistMember(FC.selectedGuildBlacklist, value) end,
    })
    self.guildMembersEditor = editor
    local restore = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    restore:SetPoint("TOPLEFT", 20, -532); restore:SetSize(220, 28); restore:SetText("Restore removed names")
    restore:SetScript("OnClick", function() FC:RestoreGuildBlacklistMembers(FC.selectedGuildBlacklist); FC:RefreshGuildMembersSettings() end)
    function FC:RefreshGuildRosterSettings()
        heading:SetText(self.selectedGuildBlacklist or "Select a guild from the guild list")
        editor.Refresh()
    end
    self:RefreshGuildRosterSettings()
    return 590
end

function FC:ForgetLearnedGuilds()
    self.db.filterGuild.learned = {}
    self.db.filterGuild.learnedNames = {}
    if self.ResetGuildScan then self:ResetGuildScan() end
    if self.RefreshFilterGuildSettings then self:RefreshFilterGuildSettings() end
end

local scan = {queue = {}, completed = 0, found = 0, seen = {}, lastSent = -100, status = "Click Scan to find online members of blacklisted guilds."}
local routing, changingRoute, sendingWho = false, false, false
function FC:CanGuildScan()
    local settings, api = self.db and self.db.filterGuild, C_FriendList
    if not settings or not settings.enabled or #settings.guilds == 0 then return false end
    if not api or not api.SendWho or not api.GetWhoInfo or not api.GetNumWhoResults then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    local now = GetTime()
    if scan.pending and now - scan.pending.started < 15 then return false end
    return now - scan.lastSent >= 5
end
function FC:RegisterGuildScanButton(button, available)
    self.guildScanButtons = self.guildScanButtons or {}
    self.guildScanButtons[#self.guildScanButtons + 1] = {button = button, available = available}
    self:RefreshGuildScanButtons()
end
function FC:RefreshGuildScanButtons()
    local ready = self:CanGuildScan()
    for _, entry in ipairs(self.guildScanButtons or {}) do
        entry.button:SetEnabled(ready and (not entry.available or entry.available()) == true)
    end
end
function FC:GetGuildScanProgress()
    local remaining, completed = #scan.queue, scan.completed
    local wait = math.max(0, math.ceil(scan.lastSent + 5 - GetTime()))
    local phase = scan.pending and "SEARCHING..." or (remaining > 0 and (wait > 0 and ("WAIT " .. wait .. " SECONDS") or "CLICK SCAN TO CONTINUE") or (completed > 0 and "SCAN COMPLETE" or "READY TO SCAN"))
    local total = completed + remaining
    return {phase = phase, completed = completed, remaining = remaining, found = scan.found, pending = scan.pending ~= nil,
        message = scan.status, value = total > 0 and math.max(scan.pending and 0.03 or 0, completed / total) or 0}
end
local function route(value)
    if C_FriendList and C_FriendList.SetWhoToUi then
        changingRoute = true
        pcall(C_FriendList.SetWhoToUi, value)
        changingRoute = false
    end
end
local function silenceWhoWindow(pending)
    pending.suspendedWhoFrames = {}
    local seen = {}
    for _, name in ipairs({"LFGWhoListFrame", "WhoFrame"}) do
        local frame = _G[name]
        if frame and not seen[frame] and frame.IsEventRegistered and frame.UnregisterEvent then
            seen[frame] = true
            local ok, registered = pcall(frame.IsEventRegistered, frame, "WHO_LIST_UPDATE")
            if ok and registered then
                local success = pcall(frame.UnregisterEvent, frame, "WHO_LIST_UPDATE")
                if success then pending.suspendedWhoFrames[#pending.suspendedWhoFrames + 1] = frame end
            end
        end
    end
end
local function restoreRoute(afterResult)
    local pending = scan.pending
    if not pending then return end
    route(pending.previousRoute)
    local frames = pending.suspendedWhoFrames or {}
    pending.suspendedWhoFrames = nil
    local function restoreFrames()
        for _, frame in ipairs(frames) do pcall(frame.RegisterEvent, frame, "WHO_LIST_UPDATE") end
    end
    -- Restore after event dispatch, so Blizzard cannot consume this scan's result and open Who.
    if afterResult and C_Timer and C_Timer.After then C_Timer.After(0, restoreFrames) else restoreFrames() end
end
local function scanNote(value)
    scan.status = value
    FC:RefreshGuildScanButtons()
    if FC.RefreshFilterGuildSettings then FC:RefreshFilterGuildSettings() end
    if FC.currentSettingsPage == "guildMembers" and FC.RefreshGuildMembersSettings then FC:RefreshGuildMembersSettings() end
    for _, refresh in ipairs(FC.guildScanProgressWidgets or {}) do refresh() end
end
function FC:ResetGuildScan()
    restoreRoute()
    scan.pending, scan.queue, scan.signature = nil, {}, nil
    local first = FC.db.filterGuild.guilds[1]
    scanNote(first and ("Ready. Click Scan to search " .. first .. ".") or "Scan reset. Add a guild or click Scan to restore removed guilds.")
end
function FC:ScanNextGuild(onlyGuild, exactActualGuild)
    local settings = self.db.filterGuild
    if not settings.enabled then scanNote("Enable Filter Guild before scanning."); return false end
    if InCombatLockdown and InCombatLockdown() then scanNote("Scan outside combat."); return false end
    local api = C_FriendList
    if not api or not api.SendWho or not api.GetWhoInfo or not api.GetNumWhoResults then scanNote("This client does not expose /who searches."); return false end
    local now = GetTime()
    if scan.pending then
        if now - scan.pending.started < 15 then scanNote("Waiting for /who results. Please wait before clicking again."); return false end
        restoreRoute(); scan.pending = nil
    end
    if now - scan.lastSent < 5 then scanNote("Wait " .. math.ceil(5 - (now - scan.lastSent)) .. " seconds before the next search."); return false end
    -- Rediscover members only under currently active rules. A scan must never resurrect deleted rules.
    for key, removed in pairs(settings.removedGuilds) do
        local inScope = not onlyGuild or matchesGuild(removed.name, onlyGuild, not exactActualGuild and self:IsGuildFilterPartial(onlyGuild))
        if inScope then
            for _, rule in ipairs(settings.guilds) do
                if matchesGuild(removed.name, rule, self:IsGuildFilterPartial(rule)) then settings.removedGuilds[key] = nil; break end
            end
        end
    end
    local signatures = {}
    for _, guild in ipairs(settings.guilds) do signatures[#signatures + 1] = guild .. tostring(self:IsGuildFilterPartial(guild)) end
    local signature = table.concat(signatures, "\n") .. "\nScope:" .. (onlyGuild and lower(onlyGuild) or "all") .. tostring(exactActualGuild == true)
    if scan.signature ~= signature or #scan.queue == 0 then
        scan.queue, scan.completed, scan.found, scan.seen = {}, 0, 0, {}
        for _, guild in ipairs(settings.guilds) do
            if not exactActualGuild and (not onlyGuild or lower(guild) == lower(onlyGuild)) then
                if #guild > 200 or guild:find('["\\]') then scanNote("Scan names must be at most 200 bytes without quotes or backslashes."); return false end
                scan.queue[#scan.queue + 1] = {guild = guild, partial = self:IsGuildFilterPartial(guild), low = 1, high = 60}
            end
        end
        if exactActualGuild then
            if not onlyGuild or not self:GuildNameMatchesFilter(onlyGuild) then scanNote("That guild is no longer blacklisted."); return false end
            if #onlyGuild > 200 or onlyGuild:find('["\\]') then scanNote("Guild name cannot be used in a /who query."); return false end
            scan.queue[1] = {guild = onlyGuild, partial = false, low = 1, high = 60}
        end
        scan.signature = signature
    end
    local task = scan.queue[1]
    if not task then scanNote(onlyGuild and "That guild entry is no longer listed." or "Add at least one guild name before scanning."); return false end
    local query = 'g-"' .. task.guild .. '" ' .. task.low .. '-' .. task.high
    local pending = {task = task, started = now, previousRoute = routing}
    scan.pending = pending
    silenceWhoWindow(pending)
    route(true)
    local origin = Enum and Enum.SocialWhoOrigin and Enum.SocialWhoOrigin.Social
    sendingWho = true
    local ok = pcall(api.SendWho, query, origin)
    sendingWho = false
    scan.lastSent = now
    if not ok then restoreRoute(); scan.pending = nil; scanNote("Search could not be sent. Try clicking Scan outside combat."); return false end
    scanNote("Searching " .. task.guild .. " (levels " .. task.low .. "-" .. task.high .. ")...")
    if C_Timer and C_Timer.After then
        C_Timer.After(15, function()
            if scan.pending ~= pending then return end
            restoreRoute(); scan.pending = nil
            scanNote("No /who response for " .. task.guild .. " yet. Click Scan to retry.")
        end)
    end
    return true
end
function FC:ReceiveGuildScanResults()
    local pending, api = scan.pending, C_FriendList
    if not pending or not api then return end
    local ok, count, total = pcall(api.GetNumWhoResults)
    if not ok or not self:IsPublic(count) or type(count) ~= "number" or count < 0 then return end
    local task, found = pending.task, 0
    for index = 1, math.min(count, 1000) do
        local success, info = pcall(api.GetWhoInfo, index)
        if success and self:IsPublic(info) and type(info) == "table" and publicString(info.fullName)
            and self:IsPublic(info.fullGuildName) and type(info.fullGuildName) == "string" and #info.fullGuildName <= 160 then
            local guild = info.fullGuildName
            -- Learn only actual returned guild names matching the requested term, never the search term itself.
            if guild ~= "" and matchesGuild(guild, task.guild, task.partial) and self:GuildNameMatchesFilter(guild) then
                local key = self:NormalizeBlacklistName(info.fullName)
                if key and not guild:find("[%c|]") then
                    self.db.filterGuild.learnedNames[key] = {guild = guild, name = info.fullName}
                    for _, entry in pairs(self.db.filterGuild.learned) do if entry.name == key then entry.guild = guild end end
                    if not scan.seen[key] then scan.seen[key] = true; found = found + 1 end
                end
            end
        end
    end
    restoreRoute(true); scan.pending = nil
    table.remove(scan.queue, 1)
    scan.completed, scan.found = scan.completed + 1, scan.found + found
    local capped = count >= 50 or (self:IsPublic(total) and type(total) == "number" and total > count)
    if capped and task.low < task.high then
        local middle = math.floor((task.low + task.high) / 2)
        table.insert(scan.queue, {guild = task.guild, partial = task.partial, low = task.low, high = middle})
        table.insert(scan.queue, {guild = task.guild, partial = task.partial, low = middle + 1, high = task.high})
    end
    local nextTask = scan.queue[1]
    local progress = not nextTask and "Scan complete." or ("Next: " .. nextTask.guild .. " (" .. nextTask.low .. "-" .. nextTask.high .. "). " .. #scan.queue .. " searches left; click Scan.")
    if capped and task.low == task.high then progress = progress .. " This level reached the /who limit; some members may be missing." end
    scanNote(task.guild .. ": " .. count .. " returned, +" .. found .. " found. " .. progress)
end

function FC:BuildFilterGuildSettings(panel, text)
    local editor = self:CreateEntryEditor(panel, text, {
        top = -140, caption = "Guild names to filter", addLabel = "Add guild", countLabel = "Guild filters",
        help = "Enter a guild and press Add guild or Enter. Choose Exact or Partial, then click Scan beside that guild to find members. Wait for results and five seconds between clicks; click its Scan again if searches remain.",
        GetEntries = function() return FC.db.filterGuild.guilds end,
        GetMode = function(name) return FC:IsGuildFilterPartial(name) end,
        Scan = function(name) FC:ScanNextGuild(name) end,
        ScanButtonCreated = function(button, row)
            FC:RegisterGuildScanButton(button, function() return row.keyword ~= nil end)
        end,
        SetMode = function(name, partial) FC:SetGuildFilterPartial(name, partial) end,
        Add = function(value) return FC:AddGuildFilterName(value) end,
        Remove = function(value) return FC:RemoveGuildFilterName(value) end,
    })
    self.guildFilterEditor = editor
    text("Choose Exact or Partial beside each guild. Partial Olympus matches OLYMPUS IX, Olympus II and New Olympus; other entries can remain exact. Choices save immediately and apply to scanning, sightings and imports.", "GameFontHighlightSmall", 20, -550, 440)
    local learnedNote = text("", "GameFontHighlightSmall", 20, -626, 440)
    local forget = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    forget:SetPoint("TOPLEFT", 20, -704); forget:SetSize(200, 28)
    forget:SetText("Forget learned guilds")
    forget:SetScript("OnClick", function() FC:ForgetLearnedGuilds() end)
    local scanButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    scanButton:SetPoint("TOPLEFT", 20, -8); scanButton:SetSize(80, 28); scanButton:SetText("Scan")
    scanButton:SetScript("OnClick", function() FC:ScanNextGuild() end)
    self:RegisterGuildScanButton(scanButton)
    self:CreateGuildScanProgress(panel, -44)
    text("WoW requires a new click for each /who request; one click cannot run a delayed scan of every guild. Wait five seconds between clicks. Scans keep the Who window closed and save results here. A new Scan can rediscover removed guilds.", "GameFontHighlightSmall", 20, -754, 440)
    local membersButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    membersButton:SetPoint("TOPLEFT", 110, -8); membersButton:SetSize(158, 28); membersButton:SetText("Guild blacklists")
    membersButton:SetScript("OnClick", function() FC:ShowSettingsPage("guildMembers") end)
    local importPage = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importPage:SetPoint("TOPLEFT", 278, -8); importPage:SetSize(166, 28); importPage:SetText("Import guild roster")
    importPage:SetScript("OnClick", function() FC:ShowSettingsPage("guildImport") end)
    function FC:RefreshFilterGuildSettings()
        editor.Refresh()
        local count = 0
        for _ in pairs(self.db.filterGuild.learned) do count = count + 1 end
        for _ in pairs(self.db.filterGuild.learnedNames) do count = count + 1 end
        learnedNote:SetText("Learned records: " .. count .. ". Membership is saved between sessions until WoW provides newer information. Guild changes or leaving a guild update the record when observed. Unknown players stay visible.")
    end
    self:RefreshFilterGuildSettings()
    return 830
end

function FC:BuildGuildImportSettings(panel, text)
    text("Import a guild roster (optional)", "GameFontNormal", 20, -8, 440)
    local useImports = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    useImports:SetPoint("TOPLEFT", 16, -38)
    useImports:SetSize(28, 28)
    local caption = useImports:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    caption:SetPoint("LEFT", useImports, "RIGHT", 4, 0)
    caption:SetText("Use imported guild rosters")
    useImports:SetChecked(self.db.filterGuild.useImports)
    useImports:SetScript("OnClick", function(self) FC.db.filterGuild.useImports = self:GetChecked() == true end)
    text("Full guild name (importing activates this guild filter)", "GameFontNormal", 20, -86, 440)
    local guildInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    guildInput:SetPoint("TOPLEFT", 24, -112)
    guildInput:SetSize(425, 28)
    guildInput:SetAutoFocus(false)
    guildInput:SetMaxBytes(160)
    text("Roster names / table rows", "GameFontNormal", 20, -158, 440)
    local rosterInput = self:CreateListEditor(panel, 20, -188, 425, 190, 160000)
    for _, input in ipairs({guildInput, rosterInput}) do input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end) end
    local importButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importButton:SetPoint("TOPLEFT", 20, -402)
    importButton:SetSize(200, 28)
    importButton:SetText("Import / replace roster")
    local removeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    removeButton:SetPoint("LEFT", importButton, "RIGHT", 12, 0)
    removeButton:SetSize(200, 28)
    removeButton:SetText("Remove this guild's import")
    local importStatus = text("", "GameFontHighlightSmall", 20, -448, 440)
    local view = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    view:SetPoint("TOPLEFT", 20, -484)
    view:SetSize(200, 28)
    view:SetText("View guild blacklists")
    view:SetScript("OnClick", function() FC:ShowSettingsPage("guildMembers") end)
    local summary = text("", "GameFontHighlightSmall", 20, -520, 440)
    local function updateSummary()
        local guilds, members = 0, 0
        for _, roster in pairs(FC.db.filterGuild.imports) do guilds = guilds + 1; members = members + roster.count end
        summary:SetText("Saved imports: " .. guilds .. " guilds, " .. members .. " characters. Enter a guild name above to replace or remove its import.")
    end
    importButton:SetScript("OnClick", function()
        local ok, reason = FC:ImportGuildRoster(guildInput:GetText(), rosterInput:GetText(), true)
        importStatus:SetText(reason)
        if ok then rosterInput:SetText(""); rosterInput:ClearFocus(); guildInput:ClearFocus(); FC:RefreshSettings() end
    end)
    removeButton:SetScript("OnClick", function()
        local _, reason = FC:RemoveImportedGuildRoster(guildInput:GetText())
        importStatus:SetText(reason)
        updateSummary()
    end)
    updateSummary()
    function FC:RefreshGuildImportSettings()
        useImports:SetChecked(self.db.filterGuild.useImports)
        updateSummary()
    end
    self:RefreshGuildImportSettings()
    text("How to import from a website", "GameFontNormal", 20, -594, 440)
    text("1. Copy the website link below (click it, then Ctrl+C) and open it in your browser. Choose your region, enter the full guild name and click Find guild.", "GameFontHighlightSmall", 20, -624, 440)
    local website = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    website:SetPoint("TOPLEFT", 24, -694); website:SetSize(425, 28); website:SetAutoFocus(false)
    website:SetText("https://hyjal.cc/armory/guild")
    website:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    website:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    website:SetScript("OnEditFocusLost", function(self) self:SetText("https://hyjal.cc/armory/guild") end)
    text("2. On the guild roster, copy full names from the Character column, including -Realm when needed. The guild roster title and column header are skipped. Table rows separated by tabs or spaces also work; only character names are imported. Copy every roster page you want included, pasting successive pages on new lines before importing. Do not copy the entire webpage.", "GameFontHighlightSmall", 20, -744, 440)
    text("3. Back here, enter the exact guild name in Full guild name. Paste the names into Roster names / table rows, then click Import / replace roster. The guild must match your blacklist (including partial-name rules).", "GameFontHighlightSmall", 20, -844, 440)
    text("4. Enable Use imported guild rosters. Imports are optional snapshots, saved account-wide. Importing the same guild replaces its previous roster; collect all desired pages before clicking. Learned in-game membership takes priority. Re-import when the roster changes.", "GameFontHighlightSmall", 20, -934, 440)
    return 1030
end

function module:Initialize()
    if type(FC.db.filterGuild) ~= "table" then FC.db.filterGuild = {} end
    local settings = FC.db.filterGuild
    if type(settings.enabled) ~= "boolean" then settings.enabled = true end
    if type(settings.useImports) ~= "boolean" then settings.useImports = false end
    local removed = {}
    if type(settings.removedGuilds) == "table" then
        for _, entry in pairs(settings.removedGuilds) do
            if type(entry) == "table" and type(entry.name) == "string" and #entry.name <= 160 and not entry.name:find("[%c|]") then
                local rules = {}
                if type(entry.restoreRules) == "table" then
                    for rule, enabled in pairs(entry.restoreRules) do
                        if type(rule) == "string" and #rule <= 200 and rule:find("%S") and not rule:find("[%c|]") and enabled == true then rules[rule] = true end
                    end
                end
                removed[lower(entry.name)] = {name = entry.name, restoreExact = entry.restoreExact == true, restoreRules = rules}
            end
        end
    end
    settings.removedGuilds = removed
    local learned = {}
    if type(settings.learned) == "table" then
        for guid, entry in pairs(settings.learned) do
            if type(guid) == "string" and #guid <= 160 and guid:match("^Player%-")
                and type(entry) == "table" and type(entry.guild) == "string" and #entry.guild <= 160 and not entry.guild:find("[%c|]") then
                learned[guid] = {guild = entry.guild, name = type(entry.name) == "string" and FC:NormalizeBlacklistName(entry.name) or nil, displayName = type(entry.displayName) == "string" and entry.displayName or nil}
            end
        end
    end
    settings.learned = learned
    local exceptions = {}
    if type(settings.allowedMembers) == "table" then
        for key, value in pairs(settings.allowedMembers) do if type(key) == "string" and #key <= 500 and key:find("\n",1,true) and value == true then exceptions[key] = true end end
    end
    settings.allowedMembers = exceptions
    local names = {}
    if type(settings.learnedNames) == "table" then
        for name, entry in pairs(settings.learnedNames) do
            local key = FC:NormalizeBlacklistName(name)
            if key and type(entry) == "table" and type(entry.guild) == "string" and #entry.guild <= 160 and not entry.guild:find("[%c|]") then names[key] = {guild = entry.guild, name = type(entry.name) == "string" and entry.name or nil} end
        end
    end
    settings.learnedNames = names
    local imports = {}
    if type(settings.imports) == "table" then
        for _, roster in pairs(settings.imports) do
            if type(roster) == "table" and type(roster.members) == "table" then
                local key, name = importGuildKey(roster.name)
                if key then
                    local members, labels, count = {}, {}, 0
                    for member, included in pairs(roster.members) do
                        local normalized = included == true and FC:NormalizeBlacklistName(member)
                        if normalized and not members[normalized] and count < 1000 then
                            members[normalized] = true; count = count + 1
                            local label = type(roster.labels) == "table" and roster.labels[member]
                            if type(label) == "string" and FC:NormalizeBlacklistName(label) == normalized then labels[normalized] = label end
                        end
                    end
                    imports[key] = {name = name, members = members, labels = labels, count = count}
                end
            end
        end
    end
    settings.imports = imports
    local valid = {}
    if type(settings.guilds) == "table" then
        for _, value in ipairs(settings.guilds) do
            if type(value) == "string" then valid[#valid + 1] = value end
        end
    end
    settings.guilds = parse(table.concat(valid, "\n")) or {}
    local modes = {}
    for _, guild in ipairs(settings.guilds) do
        local previous = type(settings.partialGuilds) == "table" and settings.partialGuilds[lower(guild)]
        if previous == true or (previous == nil and settings.partialNames == true) then modes[lower(guild)] = true end
    end
    settings.partialGuilds, settings.partialNames = modes, nil
    FC:PruneEmptyPartialGuildFilters()
    FC:RegisterTool({
        name = "Filter Guild", settingsPage = "filterGuild",
        description = "Hide messages from members of blacklisted guilds.",
        IsEnabled = function() return settings.enabled end,
        SetEnabled = function(enabled)
            settings.enabled = enabled == true
            if FC.RefreshSettings then FC:RefreshSettings() end
        end,
    })
    local observer = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD"}) do observer:RegisterEvent(event) end
    observer:SetScript("OnEvent", function(_, event, unit)
        if not settings.enabled or #settings.guilds == 0 then return end
        if event == "PLAYER_TARGET_CHANGED" then remember("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then remember("mouseover")
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            if publicString(unit) then remember(unit) end
        else
            remember("player"); remember("target"); remember("mouseover")
            for index = 1, 4 do remember("party" .. index) end
            for index = 1, 40 do remember("raid" .. index) end
        end
    end)
    local who = CreateFrame("Frame")
    local registered = pcall(who.RegisterEvent, who, "WHO_LIST_UPDATE")
    if registered then who:SetScript("OnEvent", function() FC:ReceiveGuildScanResults() end) end
    if hooksecurefunc and C_FriendList and C_FriendList.SendWho then
        hooksecurefunc(C_FriendList, "SendWho", function()
            if sendingWho or not scan.pending then return end
            restoreRoute(); scan.pending = nil
            scanNote("Scan paused for another /who search. Click Scan to retry afterward.")
        end)
    end
    if hooksecurefunc and C_FriendList and C_FriendList.SetWhoToUi then
        hooksecurefunc(C_FriendList, "SetWhoToUi", function(value)
            if not changingRoute then
                routing = value == true
                if scan.pending then scan.pending.previousRoute = routing end
            end
        end)
    end
    local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if not addFilter then FC:Print("Filter Guild: this client does not expose chat message filters."); return end
    local function filter(_, event, message, author, language, channelName, target, flags, channelID, channelIndex, channelBase, languageID, lineID, guid) return FC:IsGuildFiltered(author, guid) end
    local events = {
        "SAY", "YELL", "WHISPER", "EMOTE", "TEXT_EMOTE", "GUILD", "OFFICER",
        "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING",
        "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "CHANNEL", "COMMUNITIES_CHANNEL",
        "BATTLEGROUND", "BATTLEGROUND_LEADER", "AFK", "DND", "GUILD_DISCORD", "VOICE_TEXT",
    }
    for _, event in ipairs(events) do addFilter("CHAT_MSG_" .. event, filter) end
end
