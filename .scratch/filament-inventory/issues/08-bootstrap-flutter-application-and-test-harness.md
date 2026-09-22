# 08: Bootstrap the Flutter application and test harness

**What to build:** A production-shaped Flutter application that launches into the empty FilaManager navigation shell and gives every later inventory slice one shared, deterministic app-level test seam.

**Blocked by:** None (can start immediately).

**Status:** completed

- [x] The Flutter application selects and uses the final Android application identity, builds and launches for the Android release target, and targets Android 16/API 36 or the higher level currently required for submission.
- [x] Home, Spools, Places, and Archive are persistently reachable, with Scan home as the initial destination and sensible empty states throughout.
- [x] Inventory persistence, NFC operations, and incoming-link delivery are exposed through application-owned boundaries and assembled by one production composition root.
- [x] The local store has an explicit schema version and can be replaced by a temporary production-format store in tests without changing application behavior.
- [x] The primary Flutter integration-test harness launches the real production app with a temporary store plus deterministic fake NFC and incoming-link adapters.
- [x] Baseline smoke coverage proves launch, navigation, process restart with the temporary store, and injection of NFC/link events through the rendered application.
- [x] Static analysis, formatting, unit tests, and integration tests have documented repeatable commands and pass from a clean checkout.
- [x] The shell establishes accessible semantics, predictable back behavior, edge-to-edge layout, and an adaptive layout baseline without requiring an account or network connection.

## Comments

- Implemented on 2026-09-22 with Android application ID `de.vibesolutions.filamanager` and target SDK 36.
- The shared smoke suite passed locally and through `integration_test` on the physical Pixel 9. The production entry point also built, installed, and launched on that device.
- Production NFC reading/writing, App Link routing, storage-slot-reference validation, and read-only storage-slot context remain ticket 09. Migration and unreadable-store recovery remain ticket 25.
- The production shell follows the visual language of Variant A on branch `prototype/scan-first-experience`; `docs/agents/ui.md` makes that reference normative for later UI slices.
