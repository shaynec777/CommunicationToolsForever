local _, FC = ...
-- Race themes are starting templates, not fixed dialogue or quoted game text.
FC.raceThanksTemplates = {
    Human = {
        "For the Alliance, <buffername>! Thank you for <buffname>.",
        "May the Light guide you, <buffername>. Your <buffname> is most welcome.",
        "A fine kindness, <buffername>. Thanks for <buffname>!",
        "With <buffname>, I stand ready. My thanks, <buffername>.",
    },
    Dwarf = {
        "By my beard, <buffername>! Thanks for <buffname>.",
        "May your forge burn bright, <buffername>. Cheers for <buffname>!",
        "That deserves a toast, <buffername>. Thanks for <buffname>!",
        "Stone and steel! Your <buffname> will serve me well, <buffername>.",
    },
    NightElf = {
        "Elune light your path, <buffername>. Thank you for <buffname>.",
        "May the forest shelter you, <buffername>. Your <buffname> is most welcome.",
        "By the grace of the Moon Mother, thank you for <buffname>, <buffername>.",
        "May the stars watch over you, <buffername>. My thanks for <buffname>.",
    },
    Gnome = {
        "Excellent enhancement, <buffername>! Thanks for <buffname>.",
        "My calculations approve of <buffname>. Thank you, <buffername>!",
        "Another brilliant improvement! Thanks for <buffname>, <buffername>.",
        "With <buffname>, this experiment is ready. Much appreciated, <buffername>!",
    },
    Orc = {
        "Strength and honor, <buffername>! Thank you for <buffname>.",
        "Your <buffname> strengthens my arm, <buffername>. Lok'tar!",
        "May your battles bring glory, <buffername>. Thanks for <buffname>.",
        "For the Horde! Your <buffname> is welcome, <buffername>.",
    },
    Scourge = {
        "Even the dead appreciate <buffname>. My thanks, <buffername>.",
        "May your enemies meet a fitting end, <buffername>. Thanks for <buffname>.",
        "A useful gift for the road ahead. Thank you for <buffname>, <buffername>.",
        "Your <buffname> is a welcome advantage, <buffername>. Remember the Forsaken.",
    },
    Tauren = {
        "May the Earth Mother watch over you, <buffername>. Thank you for <buffname>.",
        "Walk with the wind, <buffername>. Your <buffname> is welcome.",
        "May your path be peaceful, <buffername>. Thanks for <buffname>.",
        "Your <buffname> strengthens our journey, <buffername>. My thanks.",
    },
    Troll = {
        "Da spirits smile on you, <buffername>. Thanks for <buffname>!",
        "May your hunt be good, <buffername>. Much thanks for <buffname>.",
        "A fine bit of mojo, <buffername>! Thanks for <buffname>.",
        "Your <buffname> will help on da road ahead. Stay strong, <buffername>!",
    },
    Skyborne = {
        "Clear skies and fair winds, <buffername>. Thank you for <buffname>.",
        "May the winds bear you safely, <buffername>. Your <buffname> is most welcome.",
        "With <buffname> at my back, I will soar higher. My thanks, <buffername>!",
        "May your wings never falter, <buffername>. Thank you for <buffname>.",
    },
    BloodElf = {
        "May the Sunwell shine upon you, <buffername>. Thank you for <buffname>.",
        "A fine gift of magic, <buffername>. Thanks for <buffname>!",
        "For Quel'Thalas! Thank you for <buffname>, <buffername>.",
        "Your generosity honors our people, <buffername>. My thanks for <buffname>.",
    },
    Draenei = {
        "May the Light embrace you, <buffername>. Thank you for <buffname>.",
        "A welcome blessing for our journey, <buffername>. Thanks for <buffname>!",
        "For our people and our allies! Thank you for <buffname>, <buffername>.",
        "Your kindness lights the road ahead, <buffername>. My thanks for <buffname>.",
    },
    Goblin = {
        "May your profits keep growing, <buffername>. Thank you for <buffname>.",
        "Now that is a good deal, <buffername>. Thanks for <buffname>!",
        "Consider this a sound investment! Thank you for <buffname>, <buffername>.",
        "You have an eye for a useful advantage, <buffername>. My thanks for <buffname>.",
    },
    Worgen = {
        "May your hunt be swift, <buffername>. Thank you for <buffname>.",
        "A welcome gift beneath these dark skies, <buffername>. Thanks for <buffname>!",
        "For Gilneas! Thank you for <buffname>, <buffername>.",
        "Your kindness will be remembered, <buffername>. My thanks for <buffname>.",
    },
    Pandaren = {
        "May your travels bring harmony, <buffername>. Thank you for <buffname>.",
        "A kindness worth sharing a brew over, <buffername>. Thanks for <buffname>!",
        "For good company and a safe journey! Thank you for <buffname>, <buffername>.",
        "You have brought balance to my day, <buffername>. My thanks for <buffname>.",
    },
    Nightborne = {
        "May the stars guide your path, <buffername>. Thank you for <buffname>.",
        "An elegant touch of magic, <buffername>. Thanks for <buffname>!",
        "For Suramar! Thank you for <buffname>, <buffername>.",
        "Your generosity is most gracious, <buffername>. My thanks for <buffname>.",
    },
    VoidElf = {
        "May your resolve hold against the whispers, <buffername>. Thank you for <buffname>.",
        "A welcome strength amid uncertainty, <buffername>. Thanks for <buffname>!",
        "For our future beyond the shadows! Thank you for <buffname>, <buffername>.",
        "Your kindness is a light in the dark, <buffername>. My thanks for <buffname>.",
    },
    HighmountainTauren = {
        "May the spirits guide your climb, <buffername>. Thank you for <buffname>.",
        "A welcome gift upon the mountain trail, <buffername>. Thanks for <buffname>!",
        "For the tribes of Highmountain! Thank you for <buffname>, <buffername>.",
        "Your generosity honors the mountain, <buffername>. My thanks for <buffname>.",
    },
    LightforgedDraenei = {
        "May the Light strengthen your resolve, <buffername>. Thank you for <buffname>.",
        "A blessing worthy of our cause, <buffername>. Thanks for <buffname>!",
        "For the Light! Thank you for <buffname>, <buffername>.",
        "Your gift strengthens our purpose, <buffername>. My thanks for <buffname>.",
    },
    DarkIronDwarf = {
        "May your forge burn ever brighter, <buffername>. Thank you for <buffname>.",
        "Now that will put some fire in my stride, <buffername>. Thanks for <buffname>!",
        "For the clan and the forge! Thank you for <buffname>, <buffername>.",
        "That is a gift worth raising a tankard to, <buffername>. My thanks for <buffname>.",
    },
    MagharOrc = {
        "May your ancestors guide you, <buffername>. Thank you for <buffname>.",
        "A strong gift for a hard road, <buffername>. Thanks for <buffname>!",
        "For clan and honor! Thank you for <buffname>, <buffername>.",
        "Your strength honors your clan, <buffername>. My thanks for <buffname>.",
    },
    ZandalariTroll = {
        "May the loa favor your path, <buffername>. Thank you for <buffname>.",
        "A gift worthy of a fine hunt, <buffername>. Thanks for <buffname>!",
        "For Zandalar! Thank you for <buffname>, <buffername>.",
        "Your generosity honors the loa, <buffername>. My thanks for <buffname>.",
    },
    KulTiran = {
        "May the tides carry you home, <buffername>. Thank you for <buffname>.",
        "A welcome gift before the next voyage, <buffername>. Thanks for <buffname>!",
        "For Kul Tiras! Thank you for <buffname>, <buffername>.",
        "That kindness deserves a round at the harbor, <buffername>. My thanks for <buffname>.",
    },
    Vulpera = {
        "May your caravan find safe roads, <buffername>. Thank you for <buffname>.",
        "That will come in handy on the trail, <buffername>. Thanks for <buffname>!",
        "For a full pack and a safe journey! Thank you for <buffname>, <buffername>.",
        "There is always room in my pack for a kindness, <buffername>. My thanks for <buffname>.",
    },
    Mechagnome = {
        "May your mechanisms run smoothly, <buffername>. Thank you for <buffname>.",
        "A most efficient enhancement, <buffername>. Thanks for <buffname>!",
        "For progress and precision! Thank you for <buffname>, <buffername>.",
        "My performance projections just improved, <buffername>. My thanks for <buffname>.",
    },
    Dracthyr = {
        "May your wings carry you safely, <buffername>. Thank you for <buffname>.",
        "A welcome gift for the skies ahead, <buffername>. Thanks for <buffname>!",
        "For a future of our own choosing! Thank you for <buffname>, <buffername>.",
        "Your kindness lends strength to my wings, <buffername>. My thanks for <buffname>.",
    },
    Earthen = {
        "May your purpose remain steadfast, <buffername>. Thank you for <buffname>.",
        "A gift as welcome as a steady forge, <buffername>. Thanks for <buffname>!",
        "For stone and kin! Thank you for <buffname>, <buffername>.",
        "Your kindness is worth remembering, <buffername>. My thanks for <buffname>.",
    },
    HighElf = {
        "May the stars shine on your path, <buffername>. Thank you for <buffname>.",
        "A graceful gift of magic, <buffername>. Thanks for <buffname>!",
        "For our people and our allies! Thank you for <buffname>, <buffername>.",
        "Your generosity is most welcome, <buffername>. My thanks for <buffname>.",
    },
}
local aliases = {undead = "Scourge", forsaken = "Scourge", highorderskyborne = "Skyborne", skyborne = "Skyborne"}
for key in pairs(FC.raceThanksTemplates) do aliases[key:lower()] = key end
function FC:GetDefaultThanksTemplates()
    local selected, selectedKey
    if type(UnitRace) == "function" then
        local ok, localized, token = pcall(UnitRace, "player")
        if ok then
            local candidates = {[1] = token, [2] = localized}
            for i = 1, 2 do
                local value = candidates[i]
                if self:IsPublic(value) and type(value) == "string" then
                    local key = aliases[value:lower():gsub("[^%a]", "")]
                    if key then selected, selectedKey = self.raceThanksTemplates[key], key; break end
                end
            end
        end
    end
    local result = {}
    for i = 1, 4 do result[i] = (selected or self.defaultThanksTemplates)[i] end
    return result, selectedKey
end
