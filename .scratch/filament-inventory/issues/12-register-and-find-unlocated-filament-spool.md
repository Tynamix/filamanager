# 12: Register and find an Unlocated filament spool

**What to build:** A hobbyist can register an independently tracked filament spool whose physical location is not yet recorded, find it quickly, inspect it, and correct its descriptive details.

**Blocked by:** 10: Pass the early Pixel 9 NFC gate.

**Status:** completed

- [x] Registration requires a suggested or custom material type, one representative filament color, and a positive remaining quantity expressed in whole grams.
- [x] Registration accepts an optional spool label, manufacturer, product name, original nominal quantity, and notes without requiring or generating a visible inventory number.
- [x] The stored filament color is normalized as `#RRGGBB`, including when the physical material is transparent or multicolored.
- [x] Confirming registration creates one filament spool with a stable identity, the Unlocated state, no assignment, and an immutable registration history entry in one atomic transaction.
- [x] Cancelling, leaving the workflow, or submitting invalid data creates no filament spool and no history.
- [x] The Spools area supports browsing and searching active filament spools and makes a spool's state, assignment, material data, and remaining quantity quickly visible.
- [x] Filament-spool details show chronological operational history and allow descriptive fields to be edited without adding operational-history noise.
- [x] The record and its history survive restart, and semantic labels and non-color cues make registration, search, details, validation, and success understandable with assistive technology.

## Comments

- 2026-09-27: Pixel 9 emulator feedback found that a separate color-picker row disconnected the action from its field, presets alone did not support arbitrary colors, muted entered values resembled disabled inputs, and required versus optional fields were hard to distinguish. The shared form-field and color-selection rules are recorded in `docs/agents/ui.md` for future guided forms.
- 2026-09-27: Rebasing onto the completed Places work exposed two historical schema-v2 shapes: Places data without `filamentSpools` and spool data without `materialUnits`. Schema v3 accepts and migrates either v2 shape while requiring all three collections in new v3 documents; migration coverage preserves both records and registration history.
