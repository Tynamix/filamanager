# 24: Archive and restore places safely

**What to build:** A hobbyist can hide unused storage slots, material slots, and material units and later restore them without stranding filament spools or changing stable identities.

**Blocked by:** 11: Manage active storage slots, material units, and material slots; 13: Register Stored and Loaded filament spools.

**Status:** ready-for-agent

- [ ] An empty storage slot or material slot can be archived and restored without changing its stable identity.
- [ ] An occupied storage slot or material slot cannot be archived and clearly identifies the blocking filament spool.
- [ ] A material unit can be archived only when all of its material slots are unoccupied.
- [ ] Archiving a material unit hides the unit and its slots without changing each material slot's individual archive state.
- [ ] Restoring a material unit reveals only material slots that were not individually archived.
- [ ] Archived records do not reserve active visible names, but restoration stops at an active-name conflict without renaming or changing either identity.
- [ ] Renaming and storage-area changes remain separate from occupancy, and no place can be permanently deleted.
- [ ] Accepted lifecycle changes and blocked outcomes remain correct after restart and are communicated accessibly without color-only cues.
