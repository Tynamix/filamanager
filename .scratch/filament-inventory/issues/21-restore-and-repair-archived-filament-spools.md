# 21: Restore and repair archived filament spools

**What to build:** A hobbyist can recover from mistaken consumption or retirement without silently reclaiming an old assignment or rewriting history.

**Blocked by:** 19: Consume an active filament spool and browse Archive; 20: Retire an active filament spool.

**Status:** ready-for-agent

- [ ] Restoring a Consumed filament spool requires a new positive whole-gram remaining quantity.
- [ ] Restoring a Retired filament spool requires confirmation or correction of its positive whole-gram remaining quantity.
- [ ] Every restored filament spool becomes Unlocated and never reclaims its former storage slot or material slot automatically.
- [ ] Restoration appends immutable history that preserves the archived transition and records the new state and quantity.
- [ ] A Retired filament spool's historical remaining quantity can be corrected without restoring it, with an appended correction entry.
- [ ] Invalid input, cancellation, or interruption changes neither the archived record nor current occupancy.
- [ ] Archive, active browsing, filament-spool details, and history update immediately after confirmation and remain correct after restart.
