# 12: Register and find an Unlocated filament spool

**What to build:** A hobbyist can register an independently tracked filament spool whose physical location is not yet recorded, find it quickly, inspect it, and correct its descriptive details.

**Blocked by:** 10: Pass the early Pixel 9 NFC gate.

**Status:** ready-for-agent

- [ ] Registration requires a suggested or custom material type, one representative filament color, and a positive remaining quantity expressed in whole grams.
- [ ] Registration accepts an optional spool label, manufacturer, product name, original nominal quantity, and notes without requiring or generating a visible inventory number.
- [ ] The stored filament color is normalized as `#RRGGBB`, including when the physical material is transparent or multicolored.
- [ ] Confirming registration creates one filament spool with a stable identity, the Unlocated state, no assignment, and an immutable registration history entry in one atomic transaction.
- [ ] Cancelling, leaving the workflow, or submitting invalid data creates no filament spool and no history.
- [ ] The Spools area supports browsing and searching active filament spools and makes a spool's state, assignment, material data, and remaining quantity quickly visible.
- [ ] Filament-spool details show chronological operational history and allow descriptive fields to be edited without adding operational-history noise.
- [ ] The record and its history survive restart, and semantic labels and non-color cues make registration, search, details, validation, and success understandable with assistive technology.
