# 25: Prove persistence and recovery across the complete inventory

**What to build:** A hobbyist can trust that every confirmed inventory action survives interruption as one coherent change and that storage failures never silently replace prior inventory with an empty one.

**Blocked by:** 21: Restore and repair archived filament spools; 22: Correct remaining quantity or mark a filament spool Unlocated; 23: Correct an assignment into an occupied slot; 24: Archive and restore places safely.

**Status:** ready-for-agent

- [ ] App-level tests run every confirmed registration, movement, correction, archival, restoration, and place-lifecycle action against a temporary production-format store and verify current records plus immutable history after restart.
- [ ] Tests verify the state and assignment cardinality of every filament-spool state, at-most-one occupancy, active quantity rules, visible-name uniqueness, and the absence of archived occupants.
- [ ] Multi-record operations and their history commit atomically; injected interruption before commit leaves no partial occupancy, quantity, state, or history.
- [ ] Drafts, scans, link deliveries, review screens, cancellation, invalid input, NFC failures, and forced UI disposal before confirmation are verified to leave inventory unchanged.
- [ ] Representative prior schema versions migrate atomically while retaining stable identities, current state, occupancy, descriptive data, and history.
- [ ] A failed migration or unreadable store preserves the prior bytes, blocks inventory mutations, does not create an empty inventory, and presents retry and useful diagnostic recovery.
- [ ] A destructive local reset is separate from retry and diagnostics, requires explicit confirmation, and never occurs automatically.
- [ ] The full deterministic app-level suite passes without depending on widget structure, state-management calls, database layout, NFC-package internals, or network access.
