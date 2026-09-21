# 17: Move a Loaded filament spool between material slots

**What to build:** A hobbyist can move a Loaded filament spool to another unoccupied material slot while confirming the remaining quantity that leaves its recorded source.

**Blocked by:** 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] A Loaded filament spool can select another active, unoccupied material slot in the same or a different material unit.
- [ ] The workflow requires confirmation or correction of the positive whole-gram remaining quantity.
- [ ] The final review identifies the filament spool, both material slots, and any quantity change.
- [ ] Confirmation atomically vacates the source, occupies the destination, preserves the Loaded state, persists the accepted quantity, and appends history.
- [ ] An occupied, archived, incompatible, or identical destination cannot be committed and leaves inventory unchanged.
- [ ] Moving a loaded material unit physically requires no inventory action because printer relationships are not represented.
- [ ] Cancellation and interruption remain mutation-free, and accepted changes survive restart.
