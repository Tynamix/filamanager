# 22: Correct remaining quantity or mark a filament spool Unlocated

**What to build:** A hobbyist can repair a wrong quantity or explicitly record that a Stored or Loaded filament spool can no longer be found, without disguising either correction as an ordinary move.

**Blocked by:** 13: Register Stored and Loaded filament spools; 19: Consume an active filament spool and browse Archive.

**Status:** ready-for-agent

- [ ] Any active filament spool can receive a positive whole-gram remaining-quantity correction without changing its state or assignment.
- [ ] Entering zero opens the established explicit consumption confirmation and never stores an active zero-gram filament spool.
- [ ] A Stored or Loaded filament spool can be explicitly marked Unlocated after a review that identifies the assignment to be vacated.
- [ ] Each confirmed correction atomically updates current state, quantity or occupancy as applicable, and appends meaningful before/after history.
- [ ] Marking a filament spool Unlocated does not assign it elsewhere, delete it, or hide the unresolved discrepancy from active browsing.
- [ ] Cancellation, validation failure, or interruption leaves state, quantity, occupancy, and history unchanged.
- [ ] Accepted corrections are reflected immediately throughout the app and survive restart.
