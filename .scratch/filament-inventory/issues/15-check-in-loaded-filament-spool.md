# 15: Check in a Loaded filament spool

**What to build:** A hobbyist can start from an empty storage-slot context and check in a Loaded filament spool after confirming how much material remains.

**Blocked by:** 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] An empty storage-slot context offers check in and lists eligible Loaded filament spools.
- [ ] The guided workflow requires confirmation or correction of the positive whole-gram remaining quantity before review.
- [ ] The final review identifies the filament spool, source material slot, destination storage slot, and before/after quantity.
- [ ] Confirmation atomically vacates the material slot, occupies the storage slot, changes the filament spool from Loaded to Stored, persists the accepted quantity, and appends history.
- [ ] An occupied or archived destination is blocked and cannot alter inventory.
- [ ] Cancellation, back navigation, invalid quantity, or disposal before confirmation leaves quantity, state, occupancy, and history unchanged.
- [ ] The affected contexts update immediately and remain correct after restart, with accessible focus movement and success or failure feedback.
