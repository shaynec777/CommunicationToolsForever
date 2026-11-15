local addonPath = ... or "CommunicationToolsForever"
local keys = {"CreateFrame", "C_FriendList", "C_Timer", "GetTime", "InCombatLockdown", "UnitGUID", "GetGuildInfo", "UnitTokenFromGUID", "UnitNameUnmodified", "UnitName", "ChatFrameUtil", "ChatFrame_AddMessageEventFilter", "hooksecurefunc", "Enum", "LFGWhoListFrame", "WhoFrame"}
local saved = {}; for _, key in ipairs(keys) do saved[key] = _G[key] end
local secret, clock, combat = {}, 100, false
local requests, timers, routes, rows, total, listener = {}, {}, {}, {}, 0, nil
local FC = {modules = {}, db = {}}
function FC:IsPublic(value) return value ~= secret end
function FC:NormalizeBlacklistName(value)
    if not self:IsPublic(value) or type(value) ~= "string" or not value:find("%S") or value:find("[|%c%d]") then return nil end
    return value:lower()
end
function FC:RegisterTool() end
function FC:Print() end
GetTime = function() return clock end
InCombatLockdown = function() return combat end
C_Timer = {After = function(delay, fn) timers[#timers + 1] = fn end}
C_FriendList = {
    SendWho = function(query) requests[#requests + 1] = query end,
    SetWhoToUi = function(value) routes[#routes + 1] = value end,
    GetNumWhoResults = function() return #rows, total end,
    GetWhoInfo = function(index) return rows[index] end,
}
ChatFrameUtil = nil; ChatFrame_AddMessageEventFilter = nil; hooksecurefunc = nil
Enum = {SocialWhoOrigin = {Social = 1}}
CreateFrame = function()
    local f = {}
    function f:RegisterEvent(event) if event == "WHO_LIST_UPDATE" then listener = self end end
    function f:SetScript(event, fn) self[event] = fn end
    return f
end
local whoRegistered = true
LFGWhoListFrame = {
    IsEventRegistered = function() return whoRegistered end,
    UnregisterEvent = function(_, event) assert(event == "WHO_LIST_UPDATE"); whoRegistered = false end,
    RegisterEvent = function(_, event) assert(event == "WHO_LIST_UPDATE"); whoRegistered = true end,
}
WhoFrame = nil
UnitTokenFromGUID = nil; UnitGUID = nil; GetGuildInfo = nil; UnitNameUnmodified = nil; UnitName = nil
assert(loadfile(addonPath .. "/FilterGuild.lua"))("CommunicationToolsForever", FC)
FC.modules[1]:Initialize()
assert(FC:SetGuildFilterNames("Olympus\nOther Guild"))
assert(FC:SetGuildFilterPartial("Olympus", true))
assert(not FC:IsGuildFilterPartial("Other Guild") and not FC:GuildNameMatchesFilter("Other Guild II"), "Mixed exact and partial entries remain independent")
local scanButton = {SetEnabled = function(self, enabled) self.enabled = enabled end}
FC:RegisterGuildScanButton(scanButton)
assert(scanButton.enabled, "Scan starts enabled")
assert(FC:ScanNextGuild() and requests[1] == 'g-"Olympus" 1-60')
assert(not scanButton.enabled, "Scan grays out while waiting for results")
assert(not whoRegistered, "Blizzard Who result handler is suspended during scan")
assert(not FC:ScanNextGuild() and #requests == 1, "No overlapping searches")
rows = {{fullName = "Alice Raven", fullGuildName = "OLYMPUS IX"}, {fullName = "Some Stranger", fullGuildName = "Unrelated"}, secret, {fullName = secret, fullGuildName = "Olympus"}}
total = #rows
listener.OnEvent(listener, "WHO_LIST_UPDATE")
assert(not whoRegistered, "Do not reopen Who during result dispatch")
timers[#timers]()
assert(whoRegistered, "Restore ordinary Who handling next frame")
assert(routes[1] == true and routes[#routes] == false, "Restore /who routing")
assert(FC:IsGuildFiltered("Alice Raven", nil), "Who results identify players without GUIDs")
assert(not FC:IsGuildFiltered("Some Stranger", nil))
assert(FC.db.filterGuild.learnedNames["alice raven"].guild == "OLYMPUS IX", "Store actual guild, not partial rule")
assert(not FC:ScanNextGuild() and #requests == 1, "Five-second cooldown")
assert(not scanButton.enabled, "Scan stays gray during cooldown after result")
clock = clock + 5
FC:RefreshGuildScanButtons()
assert(scanButton.enabled, "Scan re-enables when cooldown ends")
assert(FC:ScanNextGuild() and requests[2] == 'g-"Other Guild" 1-60')
rows = {{fullName = "Bob Stone", fullGuildName = "Other Guild"}, {fullName = "Wrong Member", fullGuildName = "Other Guild II"}}; total = 2
listener.OnEvent(listener, "WHO_LIST_UPDATE")
timers[#timers]()
assert(FC:IsGuildFiltered("Bob Stone", nil))
assert(not FC:IsGuildFiltered("Wrong Member", nil), "Exact scan does not learn partial-only matches")
local reloaded = {modules = {}, db = FC.db, IsPublic = FC.IsPublic, NormalizeBlacklistName = FC.NormalizeBlacklistName, RegisterTool = FC.RegisterTool, Print = FC.Print}
assert(loadfile(addonPath .. "/FilterGuild.lua"))("CommunicationToolsForever", reloaded)
reloaded.modules[1]:Initialize()
assert(reloaded:IsGuildFiltered("Alice Raven", nil), "Who names survive reload")
assert(FC:RemoveGuildBlacklistMember("OLYMPUS IX", "Alice Raven"))
assert(not FC:IsGuildFiltered("Alice Raven", nil), "Removing member creates persistent exception")
local groups = FC:GetGuildMemberBlacklists()
for _, group in ipairs(groups) do for _, name in ipairs(group.members) do assert(name ~= "Alice Raven") end end
FC:RestoreGuildBlacklistMembers("OLYMPUS IX")
assert(FC:IsGuildFiltered("Alice Raven", nil))
assert(FC:ImportGuildRoster("Olympus II", "Character\tClass\tRace\tLevel\tGuild rank\nCarol Woods\tMage\tHuman\t60\t4\nDave Forest\tHunter\tDwarf\t50\t4"))
assert(FC.db.filterGuild.imports["olympus ii"].count == 2, "Website table rows use the Character column")
assert(FC:AddGuildFilterName("Olympus IX"))
FC:RemoveGuildFilterName("Olympus")
assert(FC:IsGuildFiltered("Alice Raven", nil), "Overlapping rule keeps covered members")
assert(not FC.db.filterGuild.imports["olympus ii"], "Removing guild rule clears uncovered imports")
FC:RemoveGuildFilterName("Olympus IX")
assert(not FC:IsGuildFiltered("Alice Raven", nil) and not FC.db.filterGuild.learnedNames["alice raven"], "Removing final rule clears saved membership")
FC:SetGuildFilterNames("Olympus"); FC:SetGuildFilterPartial("Olympus", true); FC:ResetGuildScan(); clock = clock + 5
assert(FC:ScanNextGuild())
rows = {}; for i = 1, 50 do rows[i] = {fullName = "Alice Raven", fullGuildName = "Olympus IX"} end; total = 120
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
local prior = #requests
assert(#requests == prior, "Receiving results never sends another protected request")
clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Olympus" 1-30', "Split capped ranges")
rows, total = {}, 0; FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Olympus" 31-60')
local timedOut = timers[#timers]
clock = clock + 16; timedOut()
assert(whoRegistered, "Restore Who handling on timeout")
local lastQuery = requests[#requests]
assert(FC:ScanNextGuild() and requests[#requests] == lastQuery, "Timeout retries same range")
local pendingTimer = timers[#timers]
FC:ResetGuildScan(); pendingTimer()
clock = clock + 5; combat = true; prior = #requests
assert(not FC:ScanNextGuild() and #requests == prior, "Never query in combat")
assert(not scanButton.enabled, "Scan is disabled during combat")
combat = false; FC.db.filterGuild.enabled = false
assert(not FC:ScanNextGuild()); FC.db.filterGuild.enabled = true
FC:SetGuildFilterNames('bad"query'); FC:ResetGuildScan()
assert(not FC:ScanNextGuild(), "Reject query syntax injection")
FC:SetGuildFilterNames("Olympus"); FC:SetGuildFilterPartial("Olympus", true); FC:ResetGuildScan(); clock = clock + 5
C_FriendList.SendWho = function() error("restricted") end
assert(not FC:ScanNextGuild(), "Handle API failure")
assert(whoRegistered, "Restore Who handling on send failure")
C_FriendList.SendWho = function(query) requests[#requests + 1] = query end
clock = clock + 5; assert(FC:ScanNextGuild())
FC.db.filterGuild.learned["Player-1"] = {guild = "Old Guild", name = "alice raven", displayName = "Alice Raven"}
rows, total = {{fullName = "Alice Raven", fullGuildName = "Olympus IX"}}, 1
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
assert(FC.db.filterGuild.learned["Player-1"].guild == "Olympus IX", "Scan updates linked GUID membership")
UnitTokenFromGUID = function() return "target" end; UnitGUID = function() return "Player-1" end
GetGuildInfo = function() return nil end; UnitNameUnmodified = function() return "Alice", "Raven" end
assert(not FC:IsGuildFiltered("Alice Raven", "Player-1"), "Guild departure supersedes scan")
UnitTokenFromGUID = nil
assert(not FC:IsGuildFiltered("Alice Raven", nil), "Updated membership applies to name-only lookups")
FC:ForgetLearnedGuilds()
assert(next(FC.db.filterGuild.learnedNames) == nil)
FC:SetGuildFilterNames("Olympus"); FC:SetGuildFilterPartial("Olympus", true)
FC:AddGuildBlacklistMember("Olympus IX", "Alice Raven")
FC:AddGuildBlacklistMember("Olympus II", "Bob Stone")
assert(FC:RemoveGuildBlacklist("Olympus IX"))
assert(not FC:IsGuildFiltered("Alice Raven", nil) and FC:IsGuildFiltered("Bob Stone", nil), "Remove actual guild without removing broad rule")
assert(not FC:GuildNameMatchesFilter("OLYMPUS IX") and FC:GuildNameMatchesFilter("Olympus II"))
assert(not FC.db.filterGuild.learnedNames["alice raven"])
FC.db.filterGuild.learnedNames["alice raven"] = {guild = "Olympus IX", name = "Alice Raven"}
assert(not FC:IsGuildFiltered("Alice Raven", nil), "Removed guild stays exempt if observed again")
local persisted = {modules = {}, db = FC.db, IsPublic = FC.IsPublic, NormalizeBlacklistName = FC.NormalizeBlacklistName, RegisterTool = FC.RegisterTool, Print = FC.Print}
assert(loadfile(addonPath .. "/FilterGuild.lua"))("CommunicationToolsForever", persisted)
persisted.modules[1]:Initialize()
assert(not persisted:GuildNameMatchesFilter("Olympus IX"), "Guild removal persists")
FC:RestoreRemovedGuilds()
assert(FC:GuildNameMatchesFilter("Olympus IX"))
FC:SetGuildFilterNames("Grumpy\namici"); FC:SetGuildFilterPartial("Grumpy", true); FC:SetGuildFilterPartial("amici", true)
FC:ResetGuildScan(); clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Grumpy" 1-60')
rows = {}; for i = 1, 50 do rows[i] = {fullName = "Grumpy Member", fullGuildName = "Grumpy Gamers"} end; total = 120
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end; clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"amici" 1-60', "Each guild gets an initial scan before capped ranges are subdivided")
rows, total = {{fullName = "Amici Member", fullGuildName = "Vox Amici"}}, 1
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
assert(FC:IsGuildFiltered("Amici Member", nil), "Second partial guild is discovered after capped first guild")
clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Grumpy" 1-30')
FC:ResetGuildScan()
FC:SetGuildFilterNames("Grumpy\nKeep Guild"); FC:SetGuildFilterPartial("Grumpy", true)
FC:AddGuildBlacklistMember("Grumpy Gamers", "Alice Raven")
FC:AddGuildBlacklistMember("Grumpy Raiders", "Bob Stone")
FC:RemoveGuildBlacklist("Grumpy Gamers")
assert(FC:IsGuildFilterPartial("Grumpy"), "Keep partial rule while another matching guild remains")
FC:RemoveGuildBlacklist("Grumpy Raiders")
assert(#FC.db.filterGuild.guilds == 1 and FC.db.filterGuild.guilds[1] == "Keep Guild", "Remove partial rule when its final matching guild is removed")
FC:RestoreRemovedGuilds()
assert(FC:IsGuildFilterPartial("Grumpy"), "Restore removed guilds restores pruned partial rules")
local repaired = {modules = {}, db = {filterGuild = {guilds = {"Grumpy"}, partialGuilds = {grumpy = true}, removedGuilds = {old = {name = "Grumpy Gamers"}}}},
    IsPublic = FC.IsPublic, NormalizeBlacklistName = FC.NormalizeBlacklistName, RegisterTool = FC.RegisterTool, Print = FC.Print}
assert(loadfile(addonPath .. "/FilterGuild.lua"))("CommunicationToolsForever", repaired)
repaired.modules[1]:Initialize()
assert(#repaired.db.filterGuild.guilds == 0, "Repair previously removed families on reload")
repaired:RestoreRemovedGuilds()
assert(repaired:IsGuildFilterPartial("Grumpy"))
FC:SetGuildFilterNames("Rescan Guild")
FC:AddGuildBlacklistMember("Rescan Guild", "Found Again")
FC:RemoveGuildBlacklist("Rescan Guild")
assert(#FC.db.filterGuild.guilds == 0)
clock = clock + 5
assert(not FC:ScanNextGuild() and #FC.db.filterGuild.guilds == 0, "Scan cannot resurrect deleted exact rule")
assert(FC:AddGuildFilterName("Rescan Guild"))
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Rescan Guild" 1-60')
rows, total = {{fullName = "Found Again", fullGuildName = "Rescan Guild"}}, 1
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
assert(FC:IsGuildFiltered("Found Again", nil), "Explicit scan rediscovers removed guild members")
FC:SetGuildFilterNames("Family"); FC:SetGuildFilterPartial("Family", true)
FC:AddGuildBlacklistMember("Family II", "Family Member")
FC:RemoveGuildBlacklistMember("Family II", "Allowed Member")
FC:RemoveGuildBlacklist("Family II")
assert(#FC.db.filterGuild.guilds == 0)
clock = clock + 5
assert(not FC:ScanNextGuild() and #FC.db.filterGuild.guilds == 0, "Scan cannot resurrect deleted partial family")
assert(FC:AddGuildFilterName("Family")); FC:SetGuildFilterPartial("Family", true)
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Family" 1-60')
rows, total = {{fullName = "Family Member", fullGuildName = "Family II"}}, 1
FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
assert(FC:IsGuildFiltered("Family Member", nil))
FC:RemoveGuildBlacklistMember("Family II", "Family Member")
clock = clock + 5; assert(FC:ScanNextGuild()); FC:ReceiveGuildScanResults(); if timers[#timers] then timers[#timers]() end
assert(not FC:IsGuildFiltered("Family Member", nil), "Per-member exceptions still survive scans")
FC:SetGuildFilterNames("Unrelated Removed")
FC:AddGuildBlacklistMember("Unrelated Removed", "Other Player")
FC:RemoveGuildBlacklist("Unrelated Removed")
FC:SetGuildFilterNames("Grumpy\namici"); FC:SetGuildFilterPartial("amici", true)
FC:ResetGuildScan(); clock = clock + 5
assert(FC:ScanNextGuild("amici") and requests[#requests] == 'g-"amici" 1-60', "Per-entry scan targets selected guild instead of first entry")
assert(FC.db.filterGuild.removedGuilds["unrelated removed"], "Per-entry scan does not restore unrelated removed guilds")
rows = {}; for i = 1, 50 do rows[i] = {fullName = "Amici Member", fullGuildName = "Vox Amici"} end; total = 100
FC:ReceiveGuildScanResults(); timers[#timers](); clock = clock + 5
assert(FC:ScanNextGuild("amici") and requests[#requests] == 'g-"amici" 1-30', "Repeated per-entry clicks continue only that guild's subdivisions")
rows, total = {}, 0; FC:ReceiveGuildScanResults(); timers[#timers](); clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"Grumpy" 1-60', "Top Scan switches back to full-list queue")
FC:ResetGuildScan()
FC:SetGuildFilterNames("amici"); FC:SetGuildFilterPartial("amici", true)
FC:ResetGuildScan(); clock = clock + 5
assert(FC:ScanNextGuild("Vox Amici", true) and requests[#requests] == 'g-"Vox Amici" 1-60', "Directory scan targets actual guild even when covered only by a partial rule")
assert(FC:GetGuildScanProgress().pending and FC:GetGuildScanProgress().phase == "SEARCHING...")
rows, total = {{fullName = "Right Member", fullGuildName = "Vox Amici"}, {fullName = "Other Member", fullGuildName = "Vox Amici II"}}, 2
FC:ReceiveGuildScanResults(); timers[#timers]()
assert(FC:IsGuildFiltered("Right Member", nil) and not FC:IsGuildFiltered("Other Member", nil), "Actual-guild scan matches exactly")
assert(FC:GetGuildScanProgress().phase == "SCAN COMPLETE" and FC:GetGuildScanProgress().found == 1)
FC:SetGuildFilterNames("Olympus"); FC:SetGuildFilterPartial("Olympus", true)
FC:AddGuildBlacklistMember("Olympus IX", "Old Member")
FC:RemoveGuildBlacklist("Olympus IX")
assert(FC:AddGuildFilterName("grumpy")); FC:SetGuildFilterPartial("grumpy", true)
clock = clock + 5
assert(FC:ScanNextGuild() and requests[#requests] == 'g-"grumpy" 1-60')
assert(#FC.db.filterGuild.guilds == 1 and FC.db.filterGuild.guilds[1] == "grumpy", "Scanning Grumpy never re-adds previously deleted Olympus")
assert(FC.db.filterGuild.removedGuilds["olympus ix"], "Unrelated removed family stays removed")
FC:ResetGuildScan()
local grumpyRoster = [[Grumpy Gamers roster
Character	Class	Race	Level	Guild rank
Soulex Wildheart	Druid	Night Elf	40	1
Big Crispoz	Shaman	Dwarf	38	3
Benie Gesserit	Warlock	Human	36	Guild master
Craen Eisencrag	Shaman	Dwarf	35	4
Marris Histor	Priest	Human	24	3
Vimba Kett	Warrior	Human	24	4
Tristos Pally	Paladin	Human	23	4
Scuddy Dunk	Mage	Gnome	17	1
Varidiun Vanhammer	Paladin	Human	17	3
Pi Alot	Mage	High Order Skyborne	16	1
Cheezit Please	Hunter	Human	15	4
Soultard Bearfoot	Hunter	Human	14	4
Angry Crispyz	Warrior	Human	10	4
Bush Microtink	Warrior	Gnome	8	1
Hunng Lo	Warrior	Human	6	4
Mands Lemule	Warlock	Human	1	4
]]
assert(FC:ImportGuildRoster("Grumpy Gamers", grumpyRoster))
local imported = FC.db.filterGuild.imports["grumpy gamers"]
assert(imported.count == 16 and imported.members["soulex wildheart"] and imported.members["mands lemule"])
assert(not imported.members["grumpy gamers roster"] and not imported.members["character"], "Roster heading and table headers are never imported as names")
assert(imported.labels["benie gesserit"] == "Benie Gesserit" and imported.labels["pi alot"] == "Pi Alot")
local quotedRoster = '"' .. grumpyRoster:gsub("\n", "\\\n") .. '"'
assert(FC:ImportGuildRoster("Grumpy Gamers", quotedRoster))
assert(FC.db.filterGuild.imports["grumpy gamers"].count == 16, "Quoted roster with trailing line backslashes imports correctly")
assert(FC:ImportGuildRoster("Grumpy Gamers", grumpyRoster:gsub("\t", "  ")))
local spaced = FC.db.filterGuild.imports["grumpy gamers"]
assert(spaced.count == 16 and spaced.labels["soulex wildheart"] == "Soulex Wildheart")
assert(spaced.labels["benie gesserit"] == "Benie Gesserit" and spaced.labels["pi alot"] == "Pi Alot", "Space-separated rows handle multiword race and Guild master rank")
assert(FC:ImportGuildRoster("Grumpy Gamers", grumpyRoster:gsub("\t", "\194\160")))
assert(FC.db.filterGuild.imports["grumpy gamers"].count == 16, "Browser nonbreaking-space separators work")
assert(FC:ImportGuildRoster("Test Guild", "Some Warrior Warrior Human 50 4"))
assert(FC.db.filterGuild.imports["test guild"].labels["some warrior"] == "Some Warrior", "Character surname can also be a class word")
assert(not FC:ImportGuildRoster("Grumpy Gamers", "Invalid Row 123"))
assert(FC.db.filterGuild.imports["grumpy gamers"].count == 16, "Invalid replacement preserves existing roster")
local migrated = {modules = {}, db = {filterGuild = {guilds = {"Olympus", "Exact Guild"}, partialNames = true, partialGuilds = {["exact guild"] = false}}},
    IsPublic = FC.IsPublic, NormalizeBlacklistName = FC.NormalizeBlacklistName, RegisterTool = FC.RegisterTool, Print = FC.Print}
assert(loadfile(addonPath .. "/FilterGuild.lua"))("CommunicationToolsForever", migrated)
migrated.modules[1]:Initialize()
assert(migrated:IsGuildFilterPartial("Olympus") and not migrated:IsGuildFilterPartial("Exact Guild"), "Migrate legacy partial mode per existing entry")
assert(migrated.db.filterGuild.partialNames == nil)
assert(migrated:AddGuildFilterName("New Guild") and not migrated:IsGuildFilterPartial("New Guild"), "New entries default to exact")
for _, key in ipairs(keys) do _G[key] = saved[key] end
print("PASS: click-driven guild scans, throttling, level splits, timeout/retry, persistence, guild/member removal, exceptions and website table imports")
