# 13: Register Stored and Loaded filament spools

**What to build:** A hobbyist can register a new filament spool directly into its real unoccupied storage slot or material slot and immediately see consistent occupancy everywhere.

**Blocked by:** 11: Manage active storage slots, material units, and material slots; 12: Register and find an Unlocated filament spool.

**Status:** ready-for-agent

- [ ] Registration can start from the normal manual workflow and from a relevant empty place context.
- [ ] A storage-slot destination creates a Stored filament spool assigned to exactly that slot; a material-slot destination creates a Loaded filament spool assigned to exactly that slot.
- [ ] Only active, compatible, unoccupied destinations can be selected, and each slot can have at most one recorded occupant.
- [ ] The final review shows all filament-spool data, initial state, and destination before confirmation.
- [ ] Confirmation creates the filament spool, assigns the destination, updates occupancy, and appends registration history atomically.
- [ ] Occupied, archived, invalid, cancelled, or interrupted registration leaves filament spools, occupancy, and history unchanged and explains that nothing changed.
- [ ] Place context, active-spool browsing, filament-spool details, and search reflect the accepted registration immediately and after restart.
