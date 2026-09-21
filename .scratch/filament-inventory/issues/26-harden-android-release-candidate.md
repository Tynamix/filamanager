# 26: Harden the Android release candidate

**What to build:** A release candidate that preserves the completed inventory behavior while meeting the Android, accessibility, privacy, offline, and artifact requirements of the first public release.

**Blocked by:** 25: Prove persistence and recovery across the complete inventory.

**Status:** ready-for-agent

- [ ] Primary controls and messages have semantic labels and usable touch targets; state, occupancy, validation, success, and failure never rely on color alone.
- [ ] Guided sheets move focus deliberately on open and close, and important success or unchanged-state failure feedback is announced to screen readers.
- [ ] A screen-reader walkthrough covers registration, navigation, searching, movement, recovery, NFC feedback, Archive, and place management on the release device.
- [ ] Enforced edge-to-edge layout, predictive back, and adaptive layouts at widths of at least 600 dp work without fixed orientation, aspect-ratio, or resizability assumptions.
- [ ] The complete app works offline without an account and contains no advertising, analytics, telemetry, remote crash reporting, remote logging, or inventory-upload behavior.
- [ ] Android cloud backup is disabled or explicitly excludes the inventory store and equivalent sensitive local data, consistent with the public privacy policy and in-app policy access.
- [ ] The final dependency graph, merged manifest, permissions, and observed network behavior support the claimed local-only behavior.
- [ ] A signed Android App Bundle uses a monotonically increasing version code and satisfies the current target API, 64-bit, and 16 KB memory-page requirements, including native transitive dependencies.
- [ ] The upload key is retained securely and all automated tests, static analysis, and release-build checks pass.
