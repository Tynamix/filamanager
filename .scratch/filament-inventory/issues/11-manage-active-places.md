# 11: Manage active storage slots, material units, and material slots

**What to build:** A hobbyist can represent and organize every active storage position and material holder manually, independently of NFC and without accidentally changing occupancy.

**Blocked by:** 10: Pass the early Pixel 9 NFC gate.

**Status:** ready-for-agent

- [ ] A hobbyist can create, browse, and rename storage slots, including adding, changing, or removing the optional storage-area label.
- [ ] A hobbyist can create, browse, and rename a material unit with one or more named material slots, including a single-spool holder.
- [ ] Active material-unit names, material-slot names within a material unit, and storage-slot names within an optional storage-area label obey the specified uniqueness scopes.
- [ ] Name comparison trims surrounding whitespace and ignores letter case while preserving the chosen display spelling.
- [ ] Empty, invalid, or conflicting names are rejected with clear feedback and leave persisted places unchanged.
- [ ] Place details show active/archive status and occupancy without representing printers or a material unit's physical connection to a printer.
- [ ] Renaming a place or changing a storage-area label preserves its stable identity and cannot move a filament spool or alter occupancy.
- [ ] Accepted changes persist across restart and the complete workflow remains available without NFC.
