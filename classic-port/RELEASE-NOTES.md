# CommunicationTools Classic 0.10.8 beta

- Exclude Rejuvenation and Healing from Buff Thanks by default, including existing saved settings.
- Apply the new exclusions once; later manual changes to the exclusion list are preserved across reloads.
- Keep Classic and Forever version numbers synchronized.

Both editions passed Lua 5.1 regression tests, including checks that these effects do not schedule thank-you messages while ordinary buffs remain eligible. Package checks verify version metadata, TOC references, ZIP integrity and source/archive equality.
