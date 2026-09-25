# 10: Pass the early Pixel 9 NFC gate

**What to build:** Evidence that the production NFC and App Link path works reliably with representative storage-slot tags and placement on the Pixel 9 before later inventory work depends on that hardware path.

**Blocked by:** 09: Reach a storage slot manually and through NFC.

**Status:** ready-for-agent

- [ ] The production adapter identifies the representative tag type, NDEF state, writable status, and usable capacity on the Pixel 9.
- [ ] The app writes the canonical storage-slot reference, reads it back, and opens the intended read-only storage-slot context through both foreground scanning and operating-system link delivery.
- [ ] Ten fresh reads in representative physical placement all succeed, normally within two seconds and never over five seconds.
- [ ] The physical matrix covers cancellation, NFC disabled, read-only NDEF, unformatted and insufficient or incompatible tags where available, interrupted write with a sacrificial tag, immediate retry, repeated scan, app restart, and alternative placement.
- [ ] Locked, unlocked, backgrounded, normally terminated, force-stopped, never-launched, offline, and user-disabled link-handling states are checked as the Android version permits, without promising behavior controlled by the operating system.
- [ ] No failure shows stale success, writes an unintended reference, or changes inventory; observed results and redacted diagnostics are retained as reproducible evidence.
- [ ] The gate records a clear keep-or-replace decision for the intended tags, physical placement, and NFC package, and any required replacement remains behind the existing application-owned interface.

## Comments

- 2026-09-25: The Pixel 9 production app wrote a canonical reference to a representative writable Type 2 tag, Android independently read the matching single URI record, an explicit foreground scan opened the same empty storage-slot context, and the local inventory hash stayed unchanged. Android reported the production App Link host as verified. The physical metadata and incomplete matrix are recorded in [the gate evidence](../research/pixel-9-nfc-gate.md). The controlled ten-read timing target and failure/state matrices remain open, so this ticket is not marked complete.
