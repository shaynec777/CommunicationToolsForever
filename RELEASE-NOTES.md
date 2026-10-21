# CommunicationTools Forever 0.10.2 beta

- Add Whisper Conversations with tabbed or separate windows, detachable chats, reply boxes, unread counts, and saved history.
- Add its own settings page with automatic opening, combat suppression, history limits, and clear-history controls.
- Save the tabbed window position and each person's detached position across reloads and logouts. New detached chats cascade away from open windows.
- Add a delete button beside each conversation tab to remove that person's saved conversation.
- Use compact, resizable whisper windows with translucent backgrounds. Opening conversations closes settings; dialogs remain above chats.
- Preserve drafts when switching or attaching chats, and avoid switching recipients while typing.
- Respect Extended Ignore and DND hiding; support full Forever surnames without realm suffixes.
- Delay buff thanks by two seconds and add an editable buff exclusion list, excluding Cantation of Manifestation by default.

Lua 5.1 regression tests passed, including saved-history reloads, window modes, replies, deletion, positions, startup suppression, and tool integration. In-game testing confirmed whisper conversations, individual and tabbed window positions, and conversation deletion. Latest dialog-layering fixes and exclusion controls have automated coverage; broader in-game testing remains welcome.

History is stored locally in account-wide saved variables, bounded to 40 people with configurable message limits. Character whispers only; Battle.net chat is unsupported. Forever restrictions can prevent identifying a caster or processing a whisper. /say thanks requires a click.

Thanks to Fenty Od for testing and ideas, and Proba Croisus for testing. MIT licensed.
