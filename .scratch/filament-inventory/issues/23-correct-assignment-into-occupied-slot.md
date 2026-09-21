# 23: Correct an assignment into an occupied slot

**What to build:** When physical reality disagrees with recorded occupancy, a hobbyist can deliberately assign the selected filament spool to an occupied compatible slot while making the recorded occupant Unlocated instead of inventing a swap.

**Blocked by:** 14: Check out a Stored filament spool; 15: Check in a Loaded filament spool; 16: Move a Stored filament spool between storage slots; 17: Move a Loaded filament spool between material slots; 18: Place an Unlocated filament spool.

**Status:** ready-for-agent

- [ ] Every normal movement workflow rejects an occupied destination and offers the separate Correct assignment workflow without mutating inventory first.
- [ ] The correction review clearly shows the selected filament spool, its recorded source, the destination, and the different recorded occupant that will become Unlocated.
- [ ] Leaving a material slot still requires confirmation or correction of remaining quantity.
- [ ] Confirmation atomically vacates the selected filament spool's recorded source, makes the destination occupant Unlocated, assigns the selected filament spool to the destination, and records all affected identities and before/after values in history.
- [ ] The displaced filament spool is not assigned to the selected spool's former source, so an implicit swap never occurs.
- [ ] Cancellation, stale occupancy, validation failure, or interruption commits no partial movement and leaves all records and history unchanged.
- [ ] Both filament-spool details, every affected place context, and search results update immediately and remain correct after restart.
