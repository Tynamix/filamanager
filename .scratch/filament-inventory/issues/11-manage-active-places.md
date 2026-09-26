# 11: Manage active storage slots, material units, and material slots

**What to build:** A hobbyist can represent and organize every active storage position and material holder manually, independently of NFC and without accidentally changing occupancy.

**Blocked by:** 10: Pass the early Pixel 9 NFC gate.

**Status:** completed

- [x] A hobbyist can create, browse, and rename storage slots, including adding, changing, or removing the optional storage-area label.
- [x] A hobbyist can create, browse, and rename a material unit with one or more named material slots, including a single-spool holder.
- [x] Active material-unit names, material-slot names within a material unit, and storage-slot names within an optional storage-area label obey the specified uniqueness scopes.
- [x] Name comparison trims surrounding whitespace and ignores letter case while preserving the chosen display spelling.
- [x] Empty, invalid, or conflicting names are rejected with clear feedback and leave persisted places unchanged.
- [x] Place details show active/archive status and occupancy without representing printers or a material unit's physical connection to a printer.
- [x] Renaming a place or changing a storage-area label preserves its stable identity and cannot move a filament spool or alter occupancy.
- [x] Accepted changes persist across restart and the complete workflow remains available without NFC.

## Answer

Storage slots and material units with named material slots can be created, browsed, and renamed manually. Name validation enforces the active scopes before an atomic local save. The versioned inventory store reads existing version-1 storage slots and saves the expanded model in version 2. Place identities and occupancy fields survive descriptive edits.

## Comments

- 2026-09-26: Pixel 9 review found that separate Add storage slot and Add material unit buttons used different visual weights and stacked awkwardly on the phone. Use one Add place action, followed by an equally styled place-type choice, and record reusable action-hierarchy and compact-layout rules in `docs/agents/ui.md`.
