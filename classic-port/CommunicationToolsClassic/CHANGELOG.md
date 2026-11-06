# CommunicationTools Classic 0.10.6 beta

## New in this update

- Align Forever and Classic on version 0.10.6. Both editions now share a version sequence while keeping their own addon folders and saved settings.

## Fixes and refinements

- Includes typing-safe automatic buff thanks: queued whispers wait while a chat or conversation reply box has focus. Stale queued requests are cancelled when the queue is cleared.
- No new gameplay changes in this synchronization release. Existing features and settings are retained; broader combat testing is still welcome.

# CommunicationTools Classic 0.10.5 beta

First public Classic Era release with five tools: Buff Thanks, Whisper Conversations, Extended Ignore, Do Not Disturb, and Name Alerts.

- Classic Name-Realm addressing with short character names in thank-you text.
- Combat-log buff detection, two-second delay, startup suppression, repeat cooldowns, optional message labels, and effect exclusions.
- Defer automatic buff whispers while typing without changing the draft.
- Tabbed or separate whisper windows, saved history, unread counts, deletion, saved positions, detached tiling, and opaque detached backgrounds.
- Independent Classic settings/history and addon folder.

Lua 5.1 tests cover startup, settings, realm identity, DND targets, buff-event filtering and typing-safe delivery. Buff thanks and whisper windows have in-game Classic confirmation; typing deferral has Forever in-game confirmation and Classic regression coverage. Broader Classic combat testing remains welcome.

Thanks to Fenty Od, Proba Croisus and Garok Shrike. MIT licensed.
