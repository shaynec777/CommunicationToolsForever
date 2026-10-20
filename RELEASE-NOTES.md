# CommunicationTools Forever 0.10.1 — Initial beta

## New in this release

- Four independent tools: Buff Thanks, Extended Ignore, Do Not Disturb, and Name Alerts.
- Four editable thank-you templates with random selection, real buff/caster labels, whisper or click-to-send /say delivery, repeat cooldowns, and startup suppression.
- Blacklist editing, Ctrl+Shift-click additions, and optional configurable ignore notifications.
- DND auto-response, relay/referral options, optional whisper hiding, and loop protection.
- Name matching by full name, first name, or surname; configurable chat groups, sound, channel-aware twelve-second banner, manual dismissal, and combat popup suppression.
- HunterTools-style main menu, tool toggles, individual settings pages, account-wide saved preferences, and original radio/microphone artwork.

## Fixes and refinements included

- Preserve Forever surnames in blacklist entries, whisper recipients, and thank-you text.
- Omit API realm labels from Forever whisper addresses.
- Avoid restricted aura enumeration and do not thank for pre-existing login/reload buffs.
- Recognize buffs from other players even when the recipient can cast the same spell.
- Exclude blacklisted senders and automated responses from DND relaying and name-alert noise.

## Validation and known limits

Lua 5.1 regression suites cover tool navigation, blacklist behavior, auto-replies, DND, names/surnames, buff startup handling and caster resolution, randomized templates, channel labels, and combat popup suppression. Package checks verify TOC references, addon-only ZIP root, CRC, and source/archive hashes.

In-game feedback confirmed buff thanks, blacklist filtering, and Ctrl+Shift-click additions. The newer tools and four-template editor require wider in-game validation. Forever beta restrictions can prevent identifying a buff caster or processing a whisper. Permanent/undated buffs are skipped; /say needs a click. Battle.net account chat is not supported.

Intermittent full-client `/reload` crashes were reported; the cause remains unconfirmed. Restart the client if affected and include a crash report with any issue.

Thanks to Fenty Od for testing and ideas, and Proba Croisus for testing.
