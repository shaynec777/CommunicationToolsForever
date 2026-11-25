# Forever data scope

General preferences remain in ForeverCommunicationsDB at the original account root: tool toggles, channel choices, filter words, guild-name matching rules and window preferences.

Character identity records live in characterDataV2, keyed by native ruleset and faction. These are whisper histories (including recipient drafts and conversation positions), extended-ignore names, friend mutes, DND forwarding targets, learned guild membership, imported rosters, member exceptions and removed-guild records. These contexts are shared by characters in the same ruleset and faction.

Original root preferences take priority during migration. Missing preferences can be recovered from the active 0.10.11 context. Identity records from that verified context are copied into its matching new context. Original root identity records and 0.10.11 profiles remain preserved; unassigned root records are not silently attributed to the current login. The addon waits for verified native rule flags and faction before initializing; display realm names never select a context.

Classic continues using its independent existing database.

Forever canonical player-name keys omit legacy realm suffixes inside each verified context. Name normalization never queries display-realm APIs. Scoped legacy names are normalized on module initialization; Classic keeps its realm-qualified keys.

Buff Thanks templates are an exception to shared preferences: buffMessagesByCharacterV1 stores each public player GUID separately (plus the verified context on Forever). New toons start with their race preset when recognized, with preserved shared templates as a fallback. Existing custom toon messages remain intact; original account templates are retained. Untouched generic messages adopt race presets. Restore defaults selects the current race. Other Buff Thanks settings remain shared. A missing/restricted GUID defers initialization until world entry rather than attributing messages to another toon.
