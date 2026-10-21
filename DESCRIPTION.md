# CommunicationTools Forever

A communication toolbox for World of Warcraft: Forever, for every class.

Open `/ct` or right-click ordinary text or blank space in your chat window. Each tool has its own enable checkbox and Configure page, inspired by HunterTools Forever.

## Tools

- **Buff Thanks:** thank another player using their full character name and the buff they gave you. Choose automatic whispers or a click-to-send /say message. Configure up to four messages with optional `<buffname>` and `<buffername>` labels (either, both, or neither); a nonblank message is selected randomly each time. Thanks wait two seconds; an editable exclusion list skips unwanted effects.
- **Whisper Conversations:** tabbed or separate windows with saved history, detachable chats, unread counts, reply boxes, per-conversation deletion, saved positions, compact windows, opaque detached backgrounds, and automatic tiling for new chats. Configure history limits and suppress automatic opening in combat.
- **Extended Ignore:** hide incoming character chat and whispers from your saved blacklist. Ctrl+Shift+left-click a linked chat name to add it, or enter a full name on the settings page. Optionally send an editable ignore notification, limited to once per sender per minute.
- **Do Not Disturb:** send a configurable whisper auto-response, optionally relay incoming whispers to another player or refer the sender to that player. Includes optional incoming-whisper hiding and automatic-response loop protection.
- **Name Alerts:** notice mentions of your full name, first name, or surname in selected chat types. Choose whole-word or substring matching, sound, and a banner showing the channel and sender. Banners last twelve seconds, have a close button, and can be suppressed in combat.
- A vintage radio-and-microphone logo, a main tool menu, and separate settings pages. Preferences are saved account-wide.

## Installation

Extract the `CommunicationToolsForever` folder from the ZIP into your Forever client's `Interface/AddOns` folder. The `.toc` file must sit directly inside that folder. Fully restart the game when installing a new addon. Use `/ct` to open the menu.

For updates, replace the existing addon files and restart or reload the game. If you previously installed the development folder `ForeverCommunications`, remove that old addon copy so only one runs. For saved-settings migration, see USER-GUIDE.md in the source repository.

Buff Thanks, Extended Ignore, Name Alerts, and Whisper Conversations start enabled. Do Not Disturb starts disabled. Each tool can be enabled or disabled independently.

## Compatibility

Designed for World of Warcraft: Forever 1.60.1. Character whispers are supported; Battle.net account conversations are not. Whisper history and tool preferences are saved locally, account-wide. Public /say thanks are sent using the on-screen send button.

## Credits

Created with OpenAI Codex under the author's direction and in-game testing. The radio-and-microphone logo is original AI-generated project artwork. Menu organization was inspired by HunterTools Forever.

Thanks to **Fenty Od** for testing and ideas, **Proba Croisus** for help with testing, and **Garok Shrike** for suggestions.

MIT licensed. No Blizzard affiliation or endorsement is implied.
