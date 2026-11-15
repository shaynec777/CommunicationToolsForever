# CommunicationTools Classic 0.10.7 beta

## New in this update

- Add Filter Chat with saved keywords/phrases and independent chat-type switches.
- Add Filter Guild with per-entry Exact/Partial matching, click-driven /who scans, visible progress and cooldown controls, persistent learned members, clickable guild blacklists, and member exceptions.
- Add optional roster imports on a dedicated page with website copy/paste instructions and a direct blacklist button. Accept names and copied tables; importing activates the roster and guild filter.
- Add Friends List for available request approval/decline, friend removal, and local mute/unmute.
- Use scrolling Add/Enter list editors with individual delete buttons and retained typing focus.
- Fit all eight tools on the main menu; use rounded window borders with 80% background opacity.
- Credit Nefas Aeternum for help testing, alongside Fenty Od, Proba Croisus and Garok Shrike.

## Compatibility and validation

Guild scans send one /who query per click and observe the client cooldown. Large results require further clicks; offline characters require saved observations or optional roster imports. Character whisper conversations remain separate from Battle.net account chat.

Both editions passed their Lua 5.1 regression and package checks. In-game Forever checks confirmed word filters, guild scans/filtering, partial rules, guild removal, imported blacklist visibility, member exceptions, and declining a friend request. Other friend actions and wider Classic gameplay checks remain open for beta feedback.
