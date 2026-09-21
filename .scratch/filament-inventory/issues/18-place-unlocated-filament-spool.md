# 18: Place an Unlocated filament spool

**What to build:** A hobbyist who resolves a discrepancy can place an Unlocated filament spool into an unoccupied storage slot or material slot after reviewing the assignment.

**Blocked by:** 11: Manage active storage slots, material units, and material slots; 12: Register and find an Unlocated filament spool.

**Status:** ready-for-agent

- [ ] An empty storage-slot context and an empty material-slot context offer placement of eligible Unlocated filament spools.
- [ ] Placing into storage produces the Stored state, while placing into a material slot produces the Loaded state.
- [ ] The final review identifies the filament spool, its Unlocated starting state, and the chosen destination.
- [ ] Confirmation atomically assigns the destination, changes state, updates occupancy, and appends history without inventing a previous source.
- [ ] Occupied, archived, incompatible, cancelled, or interrupted placement leaves the filament spool Unlocated and inventory unchanged.
- [ ] Accepted placement is visible immediately in place context, search, and filament-spool details and remains correct after restart.
