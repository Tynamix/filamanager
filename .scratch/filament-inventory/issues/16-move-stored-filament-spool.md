# 16: Move a Stored filament spool between storage slots

**What to build:** A hobbyist can reorganize storage by moving a Stored filament spool to another unoccupied storage slot without accidentally changing its quantity.

**Blocked by:** 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] A Stored filament spool can select another active, unoccupied storage slot as its destination.
- [ ] The final review identifies the filament spool and both storage slots and shows that remaining quantity will not change.
- [ ] Confirmation atomically vacates the source, occupies the destination, preserves the Stored state and quantity, and appends history.
- [ ] An occupied, archived, incompatible, or identical destination cannot be committed and leaves inventory unchanged.
- [ ] Cancellation or interruption before confirmation changes neither occupancy nor history.
- [ ] Source, destination, search results, and filament-spool details update immediately and remain consistent after restart.
