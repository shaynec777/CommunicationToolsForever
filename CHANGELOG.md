# 0.10.9 beta - November 18, 2026

- Add Thank players in instances, off by default, with checks before detecting and sending thanks and cancellation when the option changes.

- Buffer up to ten distinct buff thank-you messages during combat; drain whispers after combat and typing, with half-second spacing. Keep public thanks click-to-send and cancel pending messages on clear, disable, channel change or world exit.

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
