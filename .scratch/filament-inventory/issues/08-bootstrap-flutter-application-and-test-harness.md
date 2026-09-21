# 08: Bootstrap the Flutter application and test harness

**What to build:** A production-shaped Flutter application that launches into the empty FilaManager navigation shell and gives every later inventory slice one shared, deterministic app-level test seam.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The Flutter application selects and uses the final Android application identity, builds and launches for the Android release target, and targets Android 16/API 36 or the higher level currently required for submission.
- [ ] Home, Spools, Places, and Archive are persistently reachable, with Scan home as the initial destination and sensible empty states throughout.
- [ ] Inventory persistence, NFC operations, and incoming-link delivery are exposed through application-owned boundaries and assembled by one production composition root.
- [ ] The local store has an explicit schema version and can be replaced by a temporary production-format store in tests without changing application behavior.
- [ ] The primary Flutter integration-test harness launches the real production app with a temporary store plus deterministic fake NFC and incoming-link adapters.
- [ ] Baseline smoke coverage proves launch, navigation, process restart with the temporary store, and injection of NFC/link events through the rendered application.
- [ ] Static analysis, formatting, unit tests, and integration tests have documented repeatable commands and pass from a clean checkout.
- [ ] The shell establishes accessible semantics, predictable back behavior, edge-to-edge layout, and an adaptive layout baseline without requiring an account or network connection.
