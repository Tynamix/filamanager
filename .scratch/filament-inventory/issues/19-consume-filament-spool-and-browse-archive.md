# 19: Consume an active filament spool and browse Archive

**What to build:** A hobbyist can explicitly record that any active filament spool has been consumed, release its place, and retain the complete record in Archive.

**Blocked by:** 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] Consume is available for Stored, Loaded, and Unlocated filament spools and always requires a complete review and explicit confirmation.
- [ ] Confirmation atomically records zero grams, vacates any storage slot or material slot, changes the state to Consumed, and appends history with relevant before/after values.
- [ ] A Consumed filament spool disappears from active browsing and becomes available in Archive without losing its details or chronological history.
- [ ] Entering zero in an active quantity workflow routes to an explicit consumption confirmation instead of persisting an active zero-gram filament spool.
- [ ] Cancellation, back navigation, and interruption leave state, quantity, occupancy, and history unchanged.
- [ ] Freed place contexts and Archive update immediately and remain correct after restart.
- [ ] Success and unchanged-state failure feedback are announced accessibly and do not rely on color alone.
