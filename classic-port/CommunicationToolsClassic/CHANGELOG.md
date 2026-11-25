# 0.10.18 - November 25, 2026

- Add four race-themed Buff Thanks messages for 27 recognized races, including Night Elf and High Order Skyborne. New profiles choose their race automatically; Restore defaults reloads that race set. Existing customized messages remain intact.
- Save Buff Thanks messages per character. Other general preferences stay shared; original account messages remain preserved.
- Separate Forever whisper histories, player-name lists, forwarding targets and guild membership records by verified ruleset and faction, including RP-PvP, while preserving shared settings, filter words and guild rules.
- Add Renew and Regrowth to healing exclusions and repair migrated exclusion lists without removing custom entries.
- Fix Forever whisper-name handling when display-realm APIs are unavailable. Preserve Classic's realm-qualified name handling.
- Add /ct whisperdiagnosis for session-only popup decisions without message text or sender names. /ct, /fc and /forevercomms open CommunicationTools.

# 0.10.17 - November 24, 2026

- Save Buff Thanks message templates per character using the public player GUID, retaining the Forever ruleset/faction boundary.
- Initialize each character from the preserved shared messages once; later edits affect only that character. Other preferences remain shared.
- Wait for a verified character identity before initialization and preserve safe world-entry buff handling in both editions.

# 0.10.16 - November 24, 2026

- Repair the Forever migration case where healing-exclusion completion flags were copied without their exclusion list, allowing Renew/Regrowth thanks again.
- Restore missing healing exclusions from preserved profiles once, retain custom exclusions, and respect later manual removals.
- Keep exclusion lists and completion flags together in future migrations. Classic remains behaviorally unchanged with the synchronized version.

# 0.10.15 - November 23, 2026

- Restore /ct at user request; CraftingTools will change its shortcut separately. /fc and /forevercomms remain available.
- Fix Forever whisper popups rejecting valid sender names when display-realm APIs return no value. Player-name matching now uses full names within the verified ruleset/faction context.
- Preserve scoped ignored names, friend mutes, guild imports and member exceptions by normalizing legacy realm suffixes during initialization.
- Classic retains realm-qualified name matching; both editions use version 0.10.15.

# 0.10.14 - November 23, 2026

- Use /comms to open CommunicationTools and /comms whisperdiagnosis for whisper popup diagnostics. Keep /fc and /forevercomms aliases.
- Stop claiming /ct, which CraftingTools also uses, and update the setup guides.

# 0.10.13 - November 23, 2026

- Add /ct whisperdiagnosis to report the last incoming-whisper decision and popup preferences without including message text or sender names.
- Diagnostic state is session-only; whisper filtering and popup preferences are unchanged.

# 0.10.12 - November 21, 2026

- Restore shared general settings, filter words and guild-name rules while preserving existing account preferences.
- Scope whisper histories, player-name lists, forwarding recipients and guild membership records by verified Forever ruleset and faction.
- Retain known 0.10.11 context records and preserve unassigned older records without guessing their context.

# 0.10.11 - November 21, 2026

- Forever settings, whisper histories and guild/member lists now use separate profiles for each verified ruleset and faction, including RP-PvP.
- Existing unassigned account data remains preserved; new profiles start with defaults rather than guessing its original context.
- Wait for native identity APIs when needed and retain safe buff startup behavior.
- Includes the Renew and Regrowth healing exclusions from 0.10.10.

# 0.10.10 - November 20, 2026

- Add Renew and Regrowth to Buff Thanks healing exclusions. Existing saved settings receive these entries once without losing custom exclusions.
- Correct the missing Renew exclusion reported in game; ordinary buffs remain eligible for thanks.

Classic and Forever passed Lua 5.1 regression tests and package checks, including existing-settings migration and suppression of these healing effects.

# 0.10.9 beta - November 18, 2026

- Hold up to ten distinct buff thank-you messages during combat, then release whispers half a second apart after combat and typing finish.
- Keep public /say thanks click-to-send after combat. Clear pending thanks when disabled, cleared, the reply channel changes, or the player leaves the world.
- Add **Thank players in instances**, off by default. Enable it on the Buff Thanks page to allow thanks in dungeons, raids and other instances.
- Recheck the instance setting before delayed delivery; changing the option clears pending thanks.
- Keep Classic and Forever on version 0.10.9.

Both editions passed Lua 5.1 regression and package checks. Tests cover long fights, duplicate suppression, queue limits, paced draining, re-entering combat, typing, cancellation, public clicks and instance opt-in/out. Live confirmation of combat buffering and the new instance option remains pending.

# 0.10.8 beta - November 17, 2026

- Exclude Rejuvenation and Healing from Buff Thanks by default, including existing saved settings.
- Apply the new exclusions once; later manual changes to the exclusion list are preserved across reloads.
- Keep Classic and Forever version numbers synchronized.

Both editions passed Lua 5.1 regression tests, including checks that these effects do not schedule thank-you messages while ordinary buffs remain eligible. Package checks verify version metadata, TOC references, ZIP integrity and source/archive equality.

# 0.10.7 beta - November 15, 2026

- Roster page imports now activate the guild filter and imported rosters, with a direct View guild blacklists button.

- Move roster importing to a dedicated page with a visible Import guild roster button atop Filter Guild, keeping the form above website instructions.

- Accept copied roster tables whose columns arrive as spaces or nonbreaking spaces, including multiword races and Guild master ranks; verified against the 16-name Grumpy Gamers sample.

- Parse copied guild roster titles, column headers and table rows into member names; support quoted roster blocks with line-ending backslashes.

- Match HunterTools window styling with rounded tooltip borders, inset backgrounds and 80% background opacity across settings, whisper windows and Name Alerts.

- Gray out all guild Scan buttons while waiting for results, during cooldown, in combat, or when scanning is unavailable; automatically re-enable them when ready.

- Fix Scan resurrecting unrelated deleted guild rules; scan only current entries and require explicit restore/re-add for deleted rules.

- Add exact-guild Scan buttons to the guild directory and prominent progress panels on both guild pages, with state, search counts and found-member counts.

- Add a Scan button beside each guild rule to search that guild independently, with guild-entry instructions updated to explain the workflow.

- Keep guild scans from opening Blizzard's Who window, restoring normal result handling after completion, timeout or cancellation; explain the per-request click requirement.

- Search every guild once before subdividing capped results, preventing large first-guild scans from delaying later entries; show the next guild in scan status.

- Let an explicit guild Scan restore and rediscover removed guilds, including emptied partial families, while preserving individual member exceptions.

- Explain the Scan step beside the guild-name entry box.

- Remove a partial guild filter when its last known matching guild is deleted from the directory; repair previously emptied families on reload and preserve restore behavior.

- Guild scanning, guild-message filtering, and partial guild-name rules reported working in-game by the user on November 15, 2026. Cross-session persistence and scan edge cases remain unconfirmed.

- Compact the main toolbox into two columns of four cards so all eight tools and credits fit without scrolling.

- Add delete buttons beside guilds in the member directory, with persistent exact-guild exemptions for partial rules and a restore control.

- Thank Nefas Aeternum for help with testing.

- Move Scan, its progress message, and View guild blacklists to the top of Filter Guild.

- Replace previous/next guild navigation with a clickable guild directory showing member counts and opening individual blacklists.

- Word filtering confirmed working in-game by the user on November 15, 2026.

- Make Exact / Partial guild-name matching independent for each blacklist entry, with existing global preferences migrated per entry.

- Add click-driven /who guild scans with a cooldown, capped-result level splitting, and saved name-based membership.
- Add per-guild member blacklists with persistent member exceptions and cleanup when a guild rule is removed.
- Add a copyable roster website link, step-by-step import guidance, and support for tab-separated roster rows.

- Persist learned guild memberships between sessions, refresh them on later sightings, and add a Forget learned guilds control.

- Standardize guild, ignored-player and excluded-buff editors with Add/Enter, persistent input focus, scrollbars, and individual delete buttons.
- Add optional case-insensitive partial guild-name matching, including imported rosters, for names such as Olympus and OLYMPUS IX.

- Add a visible draggable scrollbar, arrow controls and mouse-wheel scrolling to the Filter Chat term list.

- Keep focus in the Filter Chat input after adding a term so repeated typing and Enter works.

- Replace the Filter Chat text editor with a Words to trigger filter input, Add term button, paged term list, and individual delete buttons; changes save immediately.

- Add Friends List with pending request approval/decline, confirmed removal, and local friend mutes.
- Fix multiline filter editors with bordered scrollable viewports and compact chat-channel options.

- Fix startup and /ct settings access by removing the unsupported UNIT_GUILD_UPDATE event registration.

- Add Filter Chat with an account-wide keyword/phrase blacklist, case-insensitive matching, and channel selections including separate Trade and guild controls.
- Add Filter Guild with an exact-name guild blacklist and filtering for members identified from available players or recent sightings.
- Add optional guild roster imports, off by default, with paste instructions, replacement/removal controls, and recent in-game membership taking priority.

- Defer automatic buff-thank whispers while a chat or conversation reply editor has focus; cancel stale queued requests when the queue is cleared.
- Include the separate Classic Era source and laptop installation instructions in Git.

# Changelog

## 0.10.4 — 2026-10-21

- Fix detached chat layering, tile new windows, make detached backgrounds opaque, and thank Garok Shrike for suggestions. Includes optional thank-you labels from 0.10.3.

## 0.10.3 — 2026-10-21

- Allow thank-you templates with either label, both labels, or neither. Clarify settings-page guidance. Confirmed working in-game.

## 0.10.2 — 2026-10-21

- Save main and detached conversation positions; stagger new windows; add per-conversation deletion and fix settings/chat overlap.

- Add editable exact-name buff exclusions, with Cantation of Manifestation excluded by default.
- Make whisper windows smaller and their backgrounds translucent (55% opacity).

- Add Whisper Conversations with tabbed or separate windows, detachable/reattachable chats, reply boxes, unread counts, saved history, retention controls, and a dedicated settings page.

- Wait two seconds before delivering buff thanks. Pending thanks are cancelled when the tool is disabled or the player leaves the world.

## 0.10.1 — 2026-10-20

Initial public beta. Includes Buff Thanks with four randomized templates, Extended Ignore and notifications, Do Not Disturb with forwarding/referral, Name Alerts with channel labels and combat popup suppression, separate tool pages, and credits for Fenty Od and Proba Croisus.

Includes the development fixes for Forever surnames, whisper recipients, existing-buff suppression, restricted aura access, and same-class buffs. See RELEASE-NOTES.md for validation and limitations.
