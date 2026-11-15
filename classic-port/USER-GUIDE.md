# CommunicationTools Classic 0.10.7

Open `/ct` or right-click chat text or blank space. Each of the eight tools has its own enable switch and Configure button. Settings are account-wide and separate from Forever.

Classic names use Name-Realm; a bare name uses your current realm. Buff Thanks uses Classic combat-log events and keeps realm names out of the message text.

## Filter Chat

Enter a keyword or phrase in Words to trigger filter, then press Enter or Add term. Enter keeps focus for the next term. Scroll the list and use x to delete. Matching ignores case and includes matches inside longer words. Choose which chat types to filter; for example, enable Trade and disable Guild.

## Filter Guild

Enter a guild name, press Add guild or Enter, and choose Exact or Partial beside that entry. Click its Scan button to search that rule, or the top Scan button to work through all current rules. Each click sends one /who query; wait while buttons are gray, then click again if searches remain. The progress panel shows the active search and remaining work. Large results are split into level ranges. Only online characters returned by /who can be found this way.

Open Guild blacklists to choose an actual guild and view its saved members. Scanned and observed memberships persist between sessions. Use x beside a member to allow that character through the guild filter, including after another scan. Restore removed names reverses these exceptions. Other player and word filters still apply.

Use x beside a guild to remove it and its saved member list. Other guilds covered by a partial rule remain filtered. Scans can rediscover removed guilds covered by current rules; scanning never re-adds a deleted rule. Restore removed guilds or explicitly add a guild name again when needed.

## Optional website roster imports

1. Click Import guild roster at the top of Filter Guild settings.
2. Copy the website link shown on that page into a browser. Choose the correct region, enter the guild name and click Find guild.
3. Copy the roster Character column, or the roster rows with their class/race/level/rank columns. Do not include unrelated page text. Gather all desired pages into one draft.
4. Enter the full guild name and paste the roster into Roster names / table rows. Use Name-Realm when characters are on another realm.
5. Click Import / replace roster. This enables imported rosters and activates filtering for that guild. Click View guild blacklists to see the names.

Imports are saved snapshots, not automatic website connections. Re-import the same guild to replace its roster, or enter its name and click Remove this guild's import. Turning off Use imported guild rosters keeps the saved data. Live observed membership takes precedence over an import. Imports are optional; scanning and observed membership work without them.

## Friends List

Approve or decline available friend requests, remove friends using the confirmation button, and mute or unmute friends locally. Muting keeps the friendship and hides incoming messages; it does not block the person on Battle.net. Request types and controls depend on the client APIs available.

## Other tools

Buff Thanks supports four randomized templates, optional <buffname>/<buffername> labels, a two-second delay, repeat cooldowns, and a scrolling exclusion list. Automatic whispers wait while typing; public /say uses a send button.

Extended Ignore supports typed names or Ctrl+Shift+click on a linked name, with optional editable ignore notifications. Do Not Disturb supports a custom reply, forwarding or referral, and incoming whisper hiding. Name Alerts supports channel choices, sound, a dismissible banner and combat suppression. Whisper Conversations supports tabbed/separate windows, saved history, detachable chats, unread counts, deletion and saved positions. It handles character whispers rather than Battle.net account conversations.
