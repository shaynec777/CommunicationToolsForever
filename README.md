# CommunicationTools Forever

A communication toolbox for World of Warcraft: Forever, for every class.

Open `/ct` or right-click ordinary text or blank space in your chat window. Each tool has its own enable checkbox and Configure page, inspired by HunterTools Forever.

## New in this release

- **Buff Thanks:** thank another player using their full character name and the buff they gave you. Choose automatic whispers or a click-to-send /say message. Configure up to four messages using `<buffname>` and `<buffername>`; a nonblank message is selected randomly each time.
- **Extended Ignore:** hide incoming character chat and whispers from your saved blacklist. Ctrl+Shift+left-click a linked chat name to add it, or enter a full name on the settings page. Optionally send an editable ignore notification, limited to once per sender per minute.
- **Do Not Disturb:** send a configurable whisper auto-response, optionally relay incoming whispers to another player or refer the sender to that player. Includes optional incoming-whisper hiding and automatic-response loop protection.
- **Name Alerts:** notice mentions of your full name, first name, or surname in selected chat types. Choose whole-word or substring matching, sound, and a banner showing the channel and sender. Banners last twelve seconds, have a close button, and can be suppressed in combat.
- A vintage radio-and-microphone logo, a main tool menu, and separate settings pages. Preferences are saved account-wide.

## Fixes and compatibility

Forever names include surnames. Whisper recipients use the full character name without a realm suffix. Buff Thanks excludes your own casts, but does not exclude spells you can cast yourself. Existing login/reload buffs do not generate thanks: startup events are ignored for five seconds, and older or undated buffs are skipped. Restricted aura enumeration is not used.

## Installation

Extract the `CommunicationToolsForever` folder from the ZIP into your Forever client's `Interface/AddOns` folder. The `.toc` file must sit directly inside that folder. Fully restart the game when installing a new addon. Use `/ct` to open the menu.

For updates, replace the existing addon files and restart or reload the game. If you previously installed the development folder `ForeverCommunications`, remove that old addon copy so only one runs. For saved-settings migration, see USER-GUIDE.md in the source repository.

Buff Thanks, Extended Ignore, and Name Alerts start enabled. Do Not Disturb starts disabled. Each tool can be enabled or disabled independently.

## Forever beta limits and testing

This initial release targets Forever 1.60.1 (interface 16001) and is published as a **beta**.

Forever may withhold aura, caster, or whisper data. If information is restricted or a caster cannot be identified, the addon skips that action. Permanent or undated buffs do not generate thanks. /say requires clicking the send button. Character whispers are supported; Battle.net account chat is not. Addon chat remains subject to Blizzard's restrictions.

Extended Ignore filters local chat display; it does not replace Blizzard's ignore list or hide chat bubbles. Native ignores can prevent incoming whisper events from reaching the addon, so an ignore notification may not be possible. DND does not change Blizzard's native `/dnd` status. Automatic replies have cooldowns and rate limits.

In-game feedback confirmed buff thanks, including paladin buffs after surname fixes, blacklist filtering, and Ctrl+Shift-click additions. The remaining tools, four-message pool, layout, and combat options have automated regression coverage and need broader in-game testing.

If something does not work, please report the addon version, tool, steps taken, and any BugSack error. For skipped buff thanks, `/ct diagnosis` displays the recent decisions; `/ct debug on` enables live local diagnostics.

## Credits

Created with OpenAI Codex under the author's direction and in-game testing. The radio-and-microphone logo is original AI-generated project artwork. Menu organization was inspired by HunterTools Forever.

Thanks to **Fenty Od** for testing and ideas, and **Proba Croisus** for help with testing.

MIT licensed. No Blizzard affiliation or endorsement is implied.
