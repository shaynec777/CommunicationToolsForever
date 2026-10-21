# CommunicationTools Forever

A modular WoW: Forever addon with Buff Thanks, Extended Ignore, and Do Not Disturb. Buff Thanks thanks another player when a new helpful aura is applied to you:

> Thanks, Alex, for Arcane Intellect!

## Install

Copy the `CommunicationToolsForever` folder into your Forever client's `Interface/AddOns` directory, then restart the client or run `/reload`. The folder must directly contain `CommunicationToolsForever.toc`. Enable it in the character selection AddOns list. Interface 16001 targets the Forever beta; check ` /dump select(4, GetBuildInfo())` if your build marks it out of date.

## Configure

**Right-click the chat message area** (blank space or ordinary message text), or type `/ct`, to open the CommunicationTools Forever main tool menu. Right-clicking player names, item links, or chat tabs keeps their normal behavior. This shortcut also works in newly opened chat windows and pop-out whispers.

Upgrading from the old folder: remove `ForeverCommunications` from your client's `Interface/AddOns` after copying in `CommunicationToolsForever`, so only one copy loads. To keep existing preferences, exit WoW first, back up the old `WTF/Account/<account>/SavedVariables/ForeverCommunications.lua`, and copy it to `CommunicationToolsForever.lua` in the same SavedVariables directory. The saved-variable identifier inside the file remains compatible. Without that copy, the renamed addon starts with defaults.

The main menu follows HunterTools: a radio logo, version label, and separate tool cards. Each card has an **Enabled** checkbox and a **Configure** button. **Buff Thanks** opens its reply-channel and message-template page; **Extended Ignore** opens its blacklist page. Each page has **Back to tools**; the close button or Escape closes the window. Disabled tools remain configurable. Settings persist account-wide.

You can also use **Esc > Settings > AddOns > CommunicationTools Forever > Open CommunicationTools** to launch the menu.

Use `/ct` to open the settings panel. `/fc` and `/forevercomms` remain aliases. Subcommands are also available:

- `/ct channel whisper` — automatic whispers (default), addressed to the caster by full character name, including any surname, without an API realm suffix.
- `/ct channel say` — queue thanks for /say; click the on-screen button to send one message. Public chat can require a hardware event. Right-click to discard all queued thanks.
- `/ct on` or `/ct off` — enable or disable buff thanks.
- `/ct cooldown 60` — minimum seconds between thanks for the same caster and buff (10–3600; default 60).
- `/ct status` — show current settings.
- `/ct preview` — local example; sends nothing to anyone.
- `/ct clear` — discard queued messages.
- `/ct debug on` or `/ct debug off` — show or stop local buff decision diagnostics for this session.
- `/ct diagnosis` — show the last twelve distinct buff decisions (no messages sent).

### Custom thank-you text

Buff Thanks now provides a pool of **four configurable messages**, selected randomly for each thank-you. Your existing message becomes entry 1 on upgrade, with three default alternatives added. Edit the entries under **Buff Thanks > Configure** and click **Save messages**. Each nonblank entry must include `<buffname>` and `<buffername>`; blank entries are unused, and at least one must remain. Each entry has its own local preview. **Restore defaults** restores all four defaults.

Each used entry has an equal chance of selection; repeats are possible. Entries exceeding 255 bytes after real buff/player-name substitution are excluded from that selection. The pool works for whispers and /say and persists account-wide. `/ct preview` previews a random saved entry. Saving clears queued thanks so queued messages don't use obsolete wording.

Put `<buffname>` and `<buffername>` anywhere in each message, including in either order. Click **Save messages** (or press Enter in an entry). The live previews send nothing. For example:

> Much appreciated for <buffname>, my friend <buffername>!

Both labels are required so every thank-you names the buff and caster. Labels are case-sensitive. Templates are limited to 200 bytes; completed messages over WoW's 255-byte chat limit are skipped without truncating names. Plain text only; line breaks and chat formatting codes are rejected. **Restore defaults** immediately saves the four default messages. Saving or resetting clears queued thanks; preferences persist account-wide. `/ct preview` uses your saved wording.

Settings persist account-wide. Queued messages expire after two minutes and are capped at ten. Existing login/zone buffs, self buffs, NPC/pet buffs, stack changes, and refreshes of existing auras do not trigger thanks. Reapplied buffs can trigger after the cooldown. All new player-cast helpful auras qualify, including short combat buffs; there is no spell allowlist yet.

Buff Thanks does not exclude spells based on your class, spellbook, or ability to cast them. Another player's buff qualifies even if you can cast the same spell yourself. Only buffs actually cast by you are excluded as self buffs; the other timing and identity checks still apply.

### Extended Ignore

Enable or disable **Extended Ignore** independently in the **Tools** list. It defaults to enabled with an empty blacklist. **Ctrl+Shift+left-click** a character's linked name in chat to add that character. This shortcut is inactive when the tool is disabled. Normal chat-link behavior can still occur after adding the name.

Alternatively, choose **Extended Ignore > Configure** from the main menu, enter `Name` or `Name-Realm`, and click **Add to blacklist** or press Enter. A bare name means your current realm; matching ignores letter case and spaces in realm names. Use the full realm name for cross-realm characters. The paged list has a **Remove** button for each character.

Forever multi-part character names are supported, for example `Voljen Mindshaper` or `Voljen Mindshaper-RealmName`. Spaces between character-name parts are preserved, so a first name alone does not match a character with a surname.

The blacklist persists account-wide and is kept when the tool is disabled. It hides new incoming character messages from chat frames using Blizzard's message filters: say, yell, character whispers, emotes, guild/officer, party, raid, instance, public channels, and accessible character community messages. It also filters character AFK/DND replies and voice transcription where a matching character sender is supplied. Other realms' characters with the same name are unaffected.

This is a local display filter. It doesn't change Blizzard's ignore list, erase old messages, suppress chat bubbles or messages displayed directly by other addons, or match Battle.net account identities to character names. Client-restricted messages whose sender data cannot be read may bypass addon filters.

**Ignore notification:** blacklisted character whispers receive `[CT Ignore] You're on my ignore list. Your messages are not being read.` by default, at most once per sender per minute. In **Extended Ignore > Configure**, use **Enable auto-ignore reply** at the top to enable or disable notifications immediately. Edit the message below it and click **Save ignore reply** to save the text. Messages remain hidden. Automated CT messages, restricted data, self messages, and GM messages never trigger a notification. DND sends no additional reply or relay for a blacklisted sender. A global cap limits ignore replies to ten per ten seconds. Blizzard-native ignores may prevent whisper events from reaching the addon, in which case it cannot send a notification.

### Do Not Disturb

Open `/ct`, then **Do Not Disturb > Configure**. Enter your auto-response, optionally enable forwarding/referral and enter the other player's full name including their surname, then click **Save DND settings**. Enable the tool using its main-menu checkbox. DND and forwarding default to disabled; all settings persist account-wide.

- **Relay incoming whispers** sends the other player a copy marked `[CT Forward] From Sender Name: ...`. Long messages split into chat-sized chunks without splitting UTF-8 characters. Chat links and texture markup are converted to plain text.
- **Tell the sender to contact this player instead** appends `Please whisper Player Name.` to your auto-response without relaying the original message.
- **Hide incoming whispers** optionally hides them from chat while DND is enabled. This is off by default; GM messages are never hidden by this tool.

Auto-responses have a `[CT DND]` prefix and are sent at most once per sender per minute. Repeated original whispers can still be relayed. Automated DND/forward messages, self messages, the forwarding recipient, GM messages, and currently blacklisted senders do not trigger replies or relays. Outgoing DND messages share a limit of 20 per ten seconds; blocked or rate-limited sends produce a local notice. A maximum of 230 bytes is allowed for the response, and referrals must fit the full 255-byte message limit.

This tool handles character whispers only. It does not change Blizzard's `/dnd` status, handle Battle.net account messages, or queue messages while offline. Forever's chat restrictions still apply; restricted whisper data is skipped. Disabling DND preserves its configuration.

### Name Alerts

**Suppress popup in combat** is enabled by default. It prevents banners during combat and hides an existing banner when combat begins. Sound and local chat notices still follow their own settings. Disable this checkbox on the Name Alerts page if you want combat popups. The banner also has an X button for manual dismissal and expires after twelve seconds.

Use `/ct` > **Name Alerts > Configure** to select full-name, first-name, or surname matching. The tool starts enabled with sound and an on-screen banner. Public, group, and guild/officer/community chat are monitored by default; character whispers are optional. The tool does not send messages to other players.

Whole-word matching is the default, so `Ann!` matches Ann, but `banner` does not. Enable **Also match inside longer words** for substring matching. Matching uses the client's lowercase function and supports UTF-8 names; non-ASCII case folding depends on the client. Chat-link metadata, texture codes, and color codes are removed before matching.

Each alert plays the chosen sound option, displays a twelve-second banner if enabled, and identifies the channel in both the banner and local chat notice, including numbered public channels such as `2. Trade - English`, and records the sender and message. Alerts share a five-second cooldown. Own messages, Extended Ignore's blocked senders, automated CT responses, restricted messages, and whispers hidden by DND are excluded. Battle.net account messages and NPC/system messages are not monitored. **Test name alert** provides a local preview. All options save immediately, and the main-menu checkbox enables/disables the entire tool.

## Forever limitations

Forever can restrict aura and caster information. The addon skips secret values and unidentified casters; it cannot guarantee a thank-you for every buff. It uses the current `C_UnitAuras` API rather than restricted combat-log access. Casters resolve through the aura's source unit or, when no unit token is available, Forever's per-aura caster GUID lookup. The GUID fallback runs only when the client explicitly reports unrestricted aura access, and it excludes self, pet, and NPC casters. If that lookup errors, further attempts stop for the session; unavailable or restricted identities are skipped. Only timed buffs with a readable application time qualify; permanent or undated buffs are skipped. Automatic whispers remain subject to the client's chat restrictions. /say deliberately requires a click, including inside instances, for consistent behavior.

This version has not been tested inside the Forever client. Validate against your installed beta before relying on it.

Buff Thanks remains silent for the first five seconds after login, reload, or entering the world, while it builds a baseline of existing buffs. Newly synchronized buffs during that interval are also ignored. The addon never enumerates existing auras or calls GetAuraDataByIndex. It only processes incremental UNIT_AURA additions with a readable application time newer than its baseline. Full aura refreshes and recovery from restricted aura data reset the baseline without sending thanks. Late old buffs, permanent buffs, and buffs without a readable application time are skipped. Version 0.6.2 prints its loaded version in chat; /ct status also shows it.

## In-game acceptance checks

1. Run `/ct preview` and `/ct status`; confirm whisper is the default.
2. Have another player apply a new buff. Confirm one whisper includes their name and the actual buff name.
3. Refresh the buff, buff yourself, and reload with existing buffs. Confirm no extra thanks.
4. Remove and reapply the buff within the cooldown, then after it. Confirm only the latter triggers.
5. Select `/ct channel say`, receive a new buff, and click the button. Confirm the thank-you appears in /say. Test right-click dismissal and `/ct off`.
6. Test a cross-realm player and restricted combat contexts; confirm no Lua errors and no guessed caster names.
7. Open Settings > AddOns > CommunicationTools Forever. Disable buff thanks and receive a new buff; confirm no reply. Enable it, select each channel, and confirm the expected delivery. Reopen the panel and reload to check persistence. Confirm selecting one channel deselects the other, and changing settings discards pending /say messages.
8. Edit the message with both labels in either order, check the live preview, save, and receive a new buff in each channel. Confirm the real names replace the labels. Test missing labels, literal percent signs, repeated labels, reload persistence, and Restore default.
9. Add a cooperating player's character through Extended Ignore, then have them send a whisper, say, and party or channel message. Confirm new messages are hidden across chat windows, including a new whisper window. Disable the tool and confirm messages return; re-enable it and remove the name to confirm removal. Test Ctrl+Shift+left-click, duplicate adds, cross-realm names, paging, and reload persistence.
10. Right-click ordinary text or empty chat space; confirm CommunicationTools settings opens at the top. Confirm player-name and item-link menus and chat-tab right-click menus still work. Repeat in a newly opened chat window and a pop-out whisper.
11. Log in and `/reload` while already buffed, wait beyond five seconds, and confirm no thanks for existing buffs. Have another player apply a different buff afterward and confirm one thanks. Test Seal of the Crusader → Judgement → Righteous Fury and inspect BugSack for the actual error trace if its alert plays.
12. Configure and enable DND, then ask a cooperating player to whisper you. Check the custom response and one-minute reply cooldown. Test forwarding with another cooperating player, referral mode, optional hiding, blacklist exclusions, and disabling the tool. Confirm incoming forwarded messages do not bounce between two copies of the addon.

## Automated checks

`tests/test_addon.lua` loads all addon modules under Lua 5.1 with mocked WoW frames and APIs. It checks name matching, invalid input, duplicates, every registered filter, disabled behavior, modifier clicks, saved-list initialization, settings Add/Remove buttons, and thank-you template regressions. Run it with a Lua 5.1 interpreter from the repository root, or use `tests/run-lua.ps1 -LuaDll <path-to-compatible-lua5.1.dll>` in a matching-architecture PowerShell process. These tests do not replace the in-game checks above.

## Extend

`Core.lua` owns saved settings, commands, and delivery. `BuffThanks.lua` registers an independent module in the private addon namespace; `Settings.lua` adds the main tool menu and separate settings pages. Future communication modules can share `FC:Deliver` and add their own configuration. No global namespace is used beyond WoW's saved-variable, slash-command, and named-button registrations.

Tools register their name, description, `IsEnabled` getter and `SetEnabled` callback through `FC:RegisterTool` before the settings module initializes. The main menu builds an independent toggle and Configure button for each registered tool. Tools also provide a `settingsPage` key matching their dedicated page. The install folder is `CommunicationToolsForever`; the legacy saved-variable identifier remains unchanged.

## Acknowledgements

Thanks to **Fenty Od** for help with testing and ideas, and **Proba Croisus** for help with testing.

## Logo

`CommunicationToolsForever/Media/RadioLogo.png` is the full-resolution AI-generated source. `RadioLogo.tga` is the uncompressed 512×256 RGBA game texture, padded to preserve the artwork's proportions and transparency. The built-in image generation tool produced the logo; its prompt is saved in `Media/LogoPrompt.txt`.


## Whisper Conversations (next release)

Open `/ct`, enable **Whisper Conversations**, and choose **Configure**. Choose a tabbed window or a separate window per person. In tabbed mode, **Detach** moves a chat into its own window; **Attach to tabs** returns it. Drag windows to move them and use the bottom-right grip to resize. Enter or **Send** submits a reply. Closing a window keeps its history; **Open conversations** in settings restores access. Incoming messages do not switch tabs while you are typing a reply.

History persists in the existing account-wide saved variables across reloads/logouts, with 50, 100 (default), 250, or 500 messages per person and up to 40 recent people. The settings page includes a two-click **Clear all saved history** control. Normal chat whispers remain visible. Extended Ignore excludes blocked senders; DND hide suppresses automatic display. Combat suppression (enabled by default) records messages without opening windows. Disabling the tool hides its windows and pauses recording. Character whispers only; Battle.net conversations are not supported.

Buff Thanks settings include **Excluded buffs**, one exact localized buff name per line (case-insensitive). Click **Save excluded buffs** to apply. Cantation of Manifestation is excluded by default; delete it from the list to allow it again. Whisper windows default to compact sizes with 55% background opacity and remain resizable.
