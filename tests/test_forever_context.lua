local names = {"UnitGUID", "CreateFrame", "UIParent", "SlashCmdList", "Enum", "C_GameRules", "UnitFactionGroup", "GetRealmName", "GetNormalizedRealmName", "ForeverCommunicationsDB", "SLASH_FOREVERCOMMUNICATIONS1", "SLASH_FOREVERCOMMUNICATIONS2", "SLASH_FOREVERCOMMUNICATIONS3"}
local saved = {}; for _, k in ipairs(names) do saved[k] = _G[k] end
local frames = {}
CreateFrame = function()
 local f = {events = {}, scripts = {}}
 setmetatable(f, {__index = function() return function() end end})
 function f:RegisterEvent(e) self.events[e] = true end
 function f:SetScript(e, fn) self.scripts[e] = fn end
 frames[#frames + 1] = f; return f
end
UIParent, SlashCmdList = {}, {}
Enum = {GameRule = {HardcoreRuleset = 1, RPRuleset = 2, PvPRuleset = 3}}
local flags, faction = {}, "Alliance"
local function rules(id) return flags[id] == true end
C_GameRules = nil
UnitFactionGroup = function() return faction end
GetRealmName = function() error("Never use display realms to select a profile") end
GetNormalizedRealmName = GetRealmName
local legacy = {enabled = false, whisperConversations = {history = {old = {name = "Old Sender"}}}, filterGuild = {imports = {old = {name = "Old Guild"}}}}
ForeverCommunicationsDB = legacy
UnitGUID = function() return "Player-TestOwner" end
local FC = {}
assert(loadfile("CommunicationToolsForever/Core.lua"))("ContextTest", FC)
FC.Print = function() end
local loader
for _, f in ipairs(frames) do if f.events.ADDON_LOADED then loader = f end end
loader.scripts.OnEvent(loader, "ADDON_LOADED", "ContextTest")
assert(FC.db == nil and legacy.contextProfilesV1 == nil, "Unknown identity must not initialize or assume PvE")
C_GameRules = {IsGameRuleActive = rules}
flags[2], flags[3] = true, true
loader.scripts.OnEvent(loader, "PLAYER_ENTERING_WORLD")
assert(FC.contextKey == "RP-PvP:Alliance" and legacy.characterDataV2[FC.contextKey])
assert(FC.db.enabled == false and FC.db.whisperConversations.history == nil and FC.db.filterGuild.imports == nil, "Original preferences restored; ambiguous character data remains unassigned")
assert(legacy.enabled == false and legacy.whisperConversations.history.old.name == "Old Sender" and legacy.filterGuild.imports.old.name == "Old Guild", "Preserve original legacy records")
FC.db.whisperConversations.history = {sender = "RP-PvP sender"}
FC.db.cooldown = 123
FC.db.filterGuild.guilds = {"Shared rule"}
local rpPvp = FC.db
flags[2], flags[3] = false, false
local normal = FC:SelectForeverContext(legacy)
assert(FC.contextKey == "PvE:Alliance" and normal ~= rpPvp and normal.whisperConversations.history == nil)
assert(normal.cooldown == 123 and normal.filterGuild.guilds[1] == "Shared rule", "Preferences and guild rules shared")
normal.whisperConversations.history = {sender = "Normal sender"}
normal.channel = "SAY"
flags[2] = true
local rp = FC:SelectForeverContext(legacy); assert(FC.contextKey == "RP:Alliance" and rp ~= rpPvp)
flags[3] = true; faction = "Horde"
local horde = FC:SelectForeverContext(legacy); assert(FC.contextKey == "RP-PvP:Horde" and horde ~= rpPvp and horde.whisperConversations.history == nil)
faction = "Alliance"
local returned = FC:SelectForeverContext(legacy)
assert(returned.whisperConversations.history.sender == "RP-PvP sender" and returned.channel == "SAY", "Restore scoped history and retain shared preferences")
returned.filterGuild.learnedNames = {alice = {guild = "Scoped"}}
returned.friendsList.muted = {alice = true}
returned.extendedIgnore.blacklist = {alice = "Alice"}
returned.doNotDisturb.target = "Alice"
faction = "Horde"
local other = FC:SelectForeverContext(legacy)
assert(other.filterGuild.learnedNames == nil and other.friendsList.muted == nil and other.extendedIgnore.blacklist == nil and other.doNotDisturb.target == nil, "Identity-bearing records isolated")
faction = "Alliance"
local migratedRoot = {enabled = false, contextProfilesV1 = {["RP-PvP:Alliance"] = {enabled = true, cooldown = 77, whisperConversations = {enabled = false, history = {sender = "Known"}}, filterGuild = {imports = {guild = {count = 1}}}}}}
local migrated = FC:SelectForeverContext(migratedRoot)
assert(migrated.enabled == false and migrated.cooldown == 77 and migrated.whisperConversations.enabled == false, "Existing settings win; missing preferences recovered from active 0.10.11 profile")
assert(migrated.whisperConversations.history.sender == "Known" and migrated.filterGuild.imports.guild.count == 1, "Known 0.10.11 context records retained")
migrated.whisperConversations.history.sender = "Updated"
assert(migratedRoot.contextProfilesV1["RP-PvP:Alliance"].whisperConversations.history.sender == "Known", "Original migration source preserved")
flags[1] = true; assert(FC:GetForeverContextKey() == "Hardcore:Alliance")
flags = {[3] = true}; assert(FC:GetForeverContextKey() == "PvP:Alliance")
faction = "Neutral"; assert(not FC:SelectForeverContext({}))
faction = "Alliance"; C_GameRules.IsGameRuleActive = function() return nil end
local unresolved = {}; assert(not FC:SelectForeverContext(unresolved) and next(unresolved) == nil)
C_GameRules.IsGameRuleActive = function() error("not ready") end
assert(not FC:GetForeverContextKey())
C_GameRules.IsGameRuleActive = function() return "false" end
assert(not FC:GetForeverContextKey(), "Nonboolean rule data is not PvE")
C_GameRules.IsGameRuleActive = rules; Enum.GameRule.RPRuleset = nil
assert(not FC:GetForeverContextKey(), "Missing rule enums are not PvE")
Enum.GameRule.RPRuleset = 2
local malformed = {contextProfilesV1 = "preserve"}
assert(not FC:SelectForeverContext(malformed) and malformed.contextProfilesV1 == "preserve")
-- Existing root preferences and completion markers must migrate as one unit.
local affected = {
    buffExclusions = {custom = "Custom", rejuvenation = "Rejuvenation"},
    buffRenewRegrowthExclusionsAdded = true,
    contextProfilesV1 = {["RP-PvP:Alliance"] = {
        buffRenewRegrowthExclusionsAdded = true,
        buffExclusions = {renew = "Renew", regrowth = "Regrowth"},
    }},
}
flags = {[2] = true, [3] = true}; faction = "Alliance"
local repaired = FC:SelectForeverContext(affected)
assert(repaired.buffExclusions.renew == "Renew" and repaired.buffExclusions.regrowth == "Regrowth" and repaired.buffExclusions.custom == "Custom", "Repair split completion markers without losing custom exclusions")
repaired.buffExclusions.renew = nil
FC:SelectForeverContext(affected)
assert(affected.buffExclusions.renew == nil, "Repair runs once; later manual removals remain respected")
local olderRoot = {buffExclusions = {custom = "Custom"}, contextProfilesV1 = affected.contextProfilesV1}
FC:SelectForeverContext(olderRoot)
assert(olderRoot.buffRenewRegrowthExclusionsAdded == nil, "Never import a completion flag without its exclusion list")
local emptyRoot = {contextProfilesV1 = affected.contextProfilesV1}
FC:SelectForeverContext(emptyRoot)
assert(emptyRoot.buffRenewRegrowthExclusionsAdded == true and emptyRoot.buffExclusions.renew == "Renew", "Copy missing list and its completion markers together")
local account = {thanksTemplate = "Original <buffname>", thanksTemplates = {"Original <buffname>", "", "", ""}, channel = "WHISPER"}
local first = FC:SelectThanksCharacter(account, account, "PvE:Alliance")
first.thanksTemplates[1] = "Toon A <buffname>"
first.thanksTemplate = "Toon A <buffname>"
UnitGUID = function() return "Player-SecondOwner" end
local second = FC:SelectThanksCharacter(account, account, "PvE:Alliance")
assert(second.thanksTemplates[1] == "Original <buffname>", "New toon inherits original shared templates, not another toon's edits")
second.thanksTemplate = "Toon B <buffname>"
second.channel = "SAY"
UnitGUID = function() return "Player-TestOwner" end
local back = FC:SelectThanksCharacter(account, account, "PvE:Alliance")
assert(back.thanksTemplates[1] == "Toon A <buffname>" and back.channel == "SAY", "Toon templates persist while general preferences remain shared")
local otherScope = FC:SelectThanksCharacter(account, account, "RP-PvP:Alliance")
assert(otherScope.thanksTemplate == "Original <buffname>", "Ruleset identity boundary retained")
assert(account.thanksTemplate == "Original <buffname>" and account.thanksTemplates[1] == "Original <buffname>", "Original templates preserved")
UnitGUID = function() return nil end
local unknown = {}
assert(not FC:SelectThanksCharacter(unknown, unknown, "Classic") and next(unknown) == nil, "Unknown player never writes to a guessed toon")
UnitGUID = function() error("restricted") end
assert(not FC:SelectThanksCharacter({}, {}, "Classic"))
print("PASS: per-toon buff templates, shared preferences, legacy preservation and missing GUID guard")
for _, k in ipairs(names) do _G[k] = saved[k] end
print("PASS: shared preferences, context-only character data, migration, RP-PvP and preserved legacy records")
