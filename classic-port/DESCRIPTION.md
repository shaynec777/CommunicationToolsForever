**Too much politics in your chat channels? Too many Murloc movie titles? CommunicationTools can filter those out so you'll never have to see them again!**

# CommunicationTools Classic

## New in this update - 0.10.9 beta

Buff Thanks now holds messages during combat and releases whispers afterward, once typing finishes. The new Thank players in instances option defaults to off; enable it on the Buff Thanks page to allow thanks in dungeons and raids. Classic and Forever share version 0.10.9.

A configurable communication toolbox for World of Warcraft Classic Era. Open `/ct` or right-click ordinary text or blank space in chat. Enable each tool independently from the main menu and configure it on its own settings page.

## Tools

- **Buff Thanks:** thank another player for a new buff. Choose automatic whispers or click-to-send /say. Configure up to four randomized messages with optional `<buffname>` and `<buffername>` labels, repeat cooldowns, a two-second delay, and buff exclusions. Thanks wait until you finish typing in a chat reply box.
- **Whisper Conversations:** tabbed or separate windows, detachable chats, saved history, unread counts, reply boxes, individual conversation deletion, and saved window positions. New detached windows tile into available space. Configure automatic opening, combat suppression, and history limits.
- **Extended Ignore:** filter character chat and whispers from your blacklist. Ctrl+Shift+click a linked name to add it, or type a name in settings. Optional configurable ignore notifications.
- **Do Not Disturb:** customizable whisper replies, optional forwarding or referral to another player, and optional incoming-whisper hiding.
- **Name Alerts:** notifications when your character name is mentioned in chosen channels, with sound and a dismissible popup showing the channel. Configure name matching and combat popup suppression.

- **Filter Chat:** hide messages containing your keywords or phrases, with separate switches for Trade, Guild, group chat, whispers and other chat types.
- **Filter Guild:** exact or partial matching for each guild entry, click-driven /who scans, saved memberships between sessions, per-guild member lists and individual member exceptions. Optional website roster imports have a dedicated page and activate the imported guild filter.
- **Friends List:** approve or decline available friend requests, remove friends, and locally mute or unmute friends without removing them.

## Guild filtering and imports

Enter a guild name in Filter Guild, press Add guild or Enter, choose Exact or Partial beside that entry, then click its Scan button. The top Scan works through current rules. Each click sends one /who query; wait while buttons are gray, then click again if searches remain. Open Guild blacklists to choose an actual guild and browse saved members. Use x beside a member to allow that character through the guild filter, including after another scan.

For an optional roster, click Import guild roster at the top of Filter Guild settings. Copy the website link shown there into a browser, choose your region, enter the full guild name and click Find guild. Copy the Character column or roster table rows. Back in the addon, enter the full guild name, paste the roster and click Import / replace roster. This activates the imported guild filter. Click View guild blacklists to see its members. Imports are saved snapshots; repeat the import to refresh a roster.

Scans discover online players returned by /who; saved observations and optional imports supplement that coverage. Memberships persist between sessions. A partial rule such as Olympus matches guild names containing that text. Removing a guild clears its saved member list; other guilds covered by a partial rule remain filtered.

## Install and configure

Extract `CommunicationToolsClassic` into Classic Era's `Interface/AddOns` folder. Restart the game for a new installation, then open `/ct`. Buff Thanks, Whisper Conversations, Extended Ignore, Name Alerts, Filter Chat, Filter Guild, and Friends List start enabled; Do Not Disturb starts disabled.

Designed for **Classic Era 1.15.9**, interface 11509. Addressing uses Name-Realm; thank-you text uses the character name. Character whispers are supported; Battle.net account conversations are not. History and preferences are saved locally, account-wide, separately from CommunicationTools Forever. Public /say thanks use an on-screen send button.

## Credits

Thanks to **Fenty Od** for testing and ideas, **Proba Croisus** and **Nefas Aeternum** for testing, and **Garok Shrike** for suggestions. Created with OpenAI Codex under the author's direction. Original AI-generated radio-and-microphone artwork; menu organization inspired by HunterTools Forever.

MIT licensed. No Blizzard affiliation or endorsement is implied.
