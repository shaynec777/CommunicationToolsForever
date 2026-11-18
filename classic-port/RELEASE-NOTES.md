# CommunicationTools Classic 0.10.9 beta

- Hold up to ten distinct buff thank-you messages during combat, then release whispers half a second apart after combat and typing finish.
- Keep public /say thanks click-to-send after combat. Clear pending thanks when disabled, cleared, the reply channel changes, or the player leaves the world.
- Add **Thank players in instances**, off by default. Enable it on the Buff Thanks page to allow thanks in dungeons, raids and other instances.
- Recheck the instance setting before delayed delivery; changing the option clears pending thanks.
- Keep Classic and Forever on version 0.10.9.

Both editions passed Lua 5.1 regression and package checks. Tests cover long fights, duplicate suppression, queue limits, paced draining, re-entering combat, typing, cancellation, public clicks and instance opt-in/out. Live confirmation of combat buffering and the new instance option remains pending.
