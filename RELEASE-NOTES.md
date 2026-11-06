# CommunicationTools Forever 0.10.6 beta

## New in this update

- Align Forever and Classic on version 0.10.6. Both editions now share a version sequence while keeping their own addon folders and saved settings.

## Fixes and refinements

- Includes typing-safe automatic buff thanks: queued whispers wait while a chat or conversation reply box has focus. Stale queued requests are cancelled when the queue is cleared.
- No new gameplay changes in this synchronization release. Existing features and settings are retained; broader combat testing is still welcome.

# CommunicationTools Forever 0.10.4 beta

- Fix detached chat text and controls bleeding through other windows by separating window layers. Clicking a window brings its complete frame group forward.
- Open new detached conversations in tiled screen positions, avoiding open chats when space is available. Previously saved positions remain honored.
- Make detached windows opaque while keeping the tabbed window translucent.
- Allow thank-you messages with either <buffname>, <buffername>, both, or neither. Update settings instructions; plain messages such as "Thanks!" work.
- Credit Garok Shrike for suggestions, alongside Fenty Od and Proba Croisus.

Includes Whisper Conversations with tabbed/separate modes, detachable windows, saved history, unread counts, per-conversation deletion, saved positions, combat suppression, and separate settings. Buff thanks includes a two-second delay and configurable effect exclusions.

Lua 5.1 regression suites and package checks passed. In-game testing confirmed optional labels, saved positions, conversation deletion, and the improved detached window layout. Some combat and restricted-data behaviors still benefit from broader testing. Character whispers only; Battle.net chat is unsupported. /say thanks requires a click.

Thanks to Fenty Od for testing and ideas, Proba Croisus for testing, and Garok Shrike for suggestions. MIT licensed.
