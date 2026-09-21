# 14: Check out a Stored filament spool

**What to build:** A hobbyist can start from an occupied storage-slot context and check out its filament spool to an unoccupied material slot after reviewing the complete change.

**Blocked by:** 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] An occupied storage-slot context leads with its filament spool and the check-out action.
- [ ] Check out permits selection of an active, unoccupied material slot and excludes incompatible or unavailable destinations.
- [ ] A complete final review identifies the filament spool, source storage slot, and destination material slot before confirmation.
- [ ] Confirmation atomically vacates the storage slot, occupies the material slot, changes the filament spool from Stored to Loaded, and appends meaningful before/after history.
- [ ] Check out does not change the remaining quantity.
- [ ] An occupied destination is blocked without inventing a swap or modifying inventory.
- [ ] Cancellation, back navigation, validation failure, or disposal before confirmation leaves current state and history unchanged.
- [ ] The updated storage-slot, material-slot, and filament-spool contexts appear immediately, survive restart, and include an accessible success announcement.
