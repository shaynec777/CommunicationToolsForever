local FC = ...
local oldRace, oldGUID = UnitRace, UnitGUID
UnitRace = function() return "Night Elf", "NightElf" end
UnitGUID = function() return "Player-RaceTestOne" end
local pool, key = FC:GetDefaultThanksTemplates()
assert(key == "NightElf" and pool[1]:find("Elune", 1, true))
pool[1] = "Changed copy"
assert(FC:GetDefaultThanksTemplates()[1] ~= "Changed copy", "Preset copies are independent")
local root = {thanksTemplates = {"Old account custom", "", "", ""}, thanksTemplate = "Old account custom"}
local elf = FC:SelectThanksCharacter(root, root, "TestScope")
assert(elf.thanksTemplates[1]:find("Elune", 1, true), "New toon selects race preset")
elf.thanksTemplates = {"My custom elf message", "", "", ""}
UnitRace = function() return "High Order Skyborne", "HighOrderSkyborne" end
UnitGUID = function() return "Player-RaceTestTwo" end
local sky = FC:SelectThanksCharacter(root, root, "TestScope")
assert(sky.thanksTemplates[1]:find("Clear skies", 1, true), "Skyborne aliases choose sky preset")
assert(root.thanksTemplate == "Old account custom", "Original account messages preserved")
UnitGUID = function() return "Player-RaceTestOne" end
assert(FC:SelectThanksCharacter(root, root, "TestScope").thanksTemplates[1] == "My custom elf message", "Existing customized toon is never overwritten")
UnitRace = function() return "Unknown race", "UnknownRace" end
local generic, unknown = FC:GetDefaultThanksTemplates()
assert(not unknown and generic[1] == FC.defaultThanksTemplates[1])
UnitRace = function() error("not available") end
assert(FC:GetDefaultThanksTemplates()[1] == FC.defaultThanksTemplates[1])
UnitRace = nil
assert(FC:GetDefaultThanksTemplates()[1] == FC.defaultThanksTemplates[1])
local count = 0
for _, messages in pairs(FC.raceThanksTemplates) do
    count = count + 1
    assert(#messages == 4)
    for _, message in ipairs(messages) do
        assert(FC:ValidateThanksTemplate(message))
        assert(message:find("<buffname>", 1, true) and message:find("<buffername>", 1, true))
        assert(FC:FormatThanks("Power Word: Fortitude", "Example Player", message))
    end
end
assert(count >= 27)
UnitRace, UnitGUID = oldRace, oldGUID
print("PASS: racial presets, Skyborne aliases, per-toon defaults, custom preservation and safe fallback")
