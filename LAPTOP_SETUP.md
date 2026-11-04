# CommunicationTools laptop setup

Clone https://github.com/shaynec777/CommunicationToolsForever and use main. Pull main before copying updates into WoW.

Copy the full edition folder into the matching laptop client Interface/AddOns folder:

- Forever: CommunicationToolsForever (interface 16001).
- Classic Era: classic-port/CommunicationToolsClassic (interface 11509).

Preserve folder names and include the Media subfolder. The .toc must sit directly inside its addon folder. Fully restart WoW after installing a new addon; open /ct. Read the edition README for its settings and commands. Keep only one copy of each addon enabled in each client.

Saved settings and whisper history are local to each game installation and are not stored in Git. Installing source does not migrate desktop settings or history to the laptop.

For development, tests/test_addon.lua runs the Forever suite; classic-port/tests/test_classic.lua runs the Classic suite. Both require Lua 5.1; the existing PowerShell test runners accept a matching Lua DLL path. Generated ZIPs live under releases and are ignored. No release publication is required to install the latest Git source.
