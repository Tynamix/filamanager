# 20: Retire an active filament spool

**What to build:** A hobbyist can deliberately remove a damaged, lost, deliberately discarded, or mistakenly registered filament spool from active inventory without erasing its record.

**Blocked by:** 13: Register Stored and Loaded filament spools; 19: Consume an active filament spool and browse Archive.

**Status:** ready-for-agent

- [ ] Retire is available for Stored, Loaded, and Unlocated filament spools and requires a reason covering the supported retirement situations.
- [ ] The final review shows the reason, last known positive quantity, current state, and any assignment that will be vacated.
- [ ] Confirmation atomically vacates any assignment, preserves the positive remaining quantity, changes the state to Retired, and appends history.
- [ ] An accidentally registered filament spool can be Retired but cannot be permanently deleted.
- [ ] The Retired filament spool leaves active browsing and appears in Archive with its details, retirement reason, quantity, and history intact.
- [ ] Cancellation, invalid input, and interruption leave the active filament spool and any occupied slot unchanged.
- [ ] Accepted retirement and the freed place survive restart.
