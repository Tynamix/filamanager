# Early Pixel 9 NFC gate

**Date:** 2026-09-25

**Application source:** `origin/main` at `8c69fdd6be362f156505bbe8392b4cefe302a9c0`

**Gate status:** Passed as an early hardware viability gate on 2026-09-26. The product owner accepted the observed write/read and navigation path and declined a fixed ten-read quota. Release qualification records placement reliability and latency without a numeric trial quota in [ticket 27](../issues/27-qualify-play-delivered-mvp.md).

## Setup and controls

- Device: Pixel 9 (`tokay`), Android 17 / API 37. ADB reported NFC enabled.
- App: `de.vibesolutions.filamanager`, target SDK 36. The debug APK was built from the source above and installed with `adb install -r`, preserving app data.
- Android reported `filamanager.vibesolutions.de` as verified for the installed app and reported the local signing fingerprint as `0B:E1:82:51:F1:B4:4D:E3:50:86:C8:76:D3:02:A5:7B:49:9B:F7:A5:4A:B7:35:F4:DB:D0:5E:A4:D0:61:AB:6E`.
- The live `/.well-known/assetlinks.json` returned HTTP 200 with JSON content type. The live `/s` fallback redirected to `/s/` and then returned HTTP 200.
- `flutter build apk --debug`, `flutter analyze`, and `flutter test` passed before physical testing (18 tests).
- The production adapter is `NfcManagerService` using `nfc_manager` 4.2.1 and `nfc_manager_ndef` 1.1.0. It checks `Ndef.from(tag)`, writable state, and `maxSize` before a write.

A dedicated empty storage slot was created for the gate. Its reference is shown only as a redacted value (`https://filamanager.vibesolutions.de/s#v1.<redacted>`). The inventory hash baseline was taken after that creation and compared after the write, first foreground read, and later repeated detections. Tag UIDs, previous NDEF contents, full storage-slot identifiers, and unfiltered NFC logs are not retained here.

## Representative tag and placement

| Observation | Result |
| --- | --- |
| Advertised tag and form factor | Not supplied; the tag's protocol is NTAG215-compatible, but commercial identity is unverified. |
| Placement, material, nearby metal/electronics | Plastic bin; nearby metal/electronics and final mounting method not recorded. |
| Android technologies and best-supported tag type | `NfcA`, `MifareUltralight`, `Ndef`; NFC Forum Type 2, NXP NTAG215-compatible (`GET_VERSION` `00 04 04 02 01 00 11 03`). Commercial authenticity not established. |
| NDEF formatted, writable, usable capacity | Formatted; writable; 492 bytes, reported by the read-only tag inspection app on this Pixel 9. |
| Canonical URI write, independent read-back, one URI record | Passed. The production app reported “Tag registered”; Android's subsequent NFC dispatch decoded exactly one well-known URI record matching the gate slot's canonical reference. The read-only inspection app also reported one cached URI record with a 57-byte record payload. Identifier and prior tag contents are omitted. |
| Foreground scan opens the same read-only storage-slot context | Passed once with the production adapter. The UI displayed “NFC Gate” and “Empty”; the reader session closed after discovery. |
| Physical operating-system App Link scan opens that context | Android 17 logged repeated physical tag dispatches as a matched web link for FilaManager; the app displayed the gate slot context. Background and cold-state qualification remains in ticket 27. |
| Inventory document unchanged after NFC operations | Passed for the write, first foreground read, and later repeated detections. The app-local inventory SHA-256 stayed `f34e84038b87921bdc6ca0856340f7911ada89db44e9a767a58e8b953045016e`. Failure cases remain untested. |

The physical metadata came from the existing read-only NFC spike app. The production adapter checked NDEF support, writability, and capacity during the successful write; it does not expose the exact tag type or those values in a retained diagnostic. The revised early gate accepts this combined observation.

## Repeated observations

On the plastic bin, four distinct system-dispatched tag detections appear in the redacted diagnostic excerpt below from `23:22:53` through `23:23:05`, in addition to the earlier successful foreground scan. The user reported that read and write appeared to work. This was not a controlled latency study; no presentation-to-visible-context times are claimed. The product owner removed the former ten-attempt timing target from the early gate. The temporary screen recording was deleted after the run; no unredacted tag payload or hardware ID is retained here.

### Redacted Android diagnostic excerpt

Captured with `adb logcat -d -v time -s NfcService NfcDispatcher` on 2026-09-25. Payloads and hardware IDs are omitted. Each dispatch below reported the `NfcA`, `MifareUltralight`, and `Ndef` technologies, one well-known URI record, and “matched Web link - prompting user.” The payload bytes were decoded in memory and compared to the gate slot's canonical reference; the two checked dispatch records matched exactly.

| Local time | System event | Observation |
| --- | --- | --- |
| 23:13:39.739 | `NfcService: Tag detected` | Production write session held reader mode. |
| 23:13:39.962 | `NfcService: setReaderMode flags: 0` | Production write session ended. |
| 23:13:40.120 | `NfcDispatcher: dispatchTag` | Independent OS read after the write; canonical URI record. |
| 23:16:53.126 | `NfcService: Tag detected` | Explicit foreground read. |
| 23:16:53.198 | `NfcService: setReaderMode flags: 0` | Foreground read session ended. |
| 23:22:53.162–23:22:53.213 | Detection, dispatch, matched web link | Plastic-bin repeat attempt. |
| 23:23:02.445–23:23:02.546 | Detection, dispatch, matched web link | Plastic-bin repeat attempt. |
| 23:23:03.704–23:23:03.747 | Detection, dispatch, matched web link | Plastic-bin repeat attempt. |
| 23:23:04.968–23:23:05.023 | Detection, dispatch, matched web link | Plastic-bin repeat attempt. |

These timestamps measure detection-to-dispatch, not presentation-to-visible-context. Representative-placement reliability remains a release qualification check, without a fixed attempt count.

## Release qualification handoff

[Ticket 27](../issues/27-qualify-play-delivered-mvp.md) owns representative-placement reliability, cancellation, disabled NFC, read-only or unformatted tags, insufficient or incompatible tags where available, sacrificial interrupted write and retry, app restart, and alternative placement. It also owns the Android App Link state matrix and Play App Signing association. None of those cases is claimed as tested by this early gate. Any failure must avoid stale success, an unintended reference, and inventory mutation. Android 17 may require a tap on an open-link notification; locked, force-stopped, never-launched, and user-disabled states do not promise automatic launch.

## Decision

- Intended tag: Keep for continued development. One representative formatted, writable Type 2 tag accepted the production canonical write and was independently read back. Commercial identity and release failure cases remain unqualified.
- Representative plastic-bin placement: Keep for continued development based on observed physical detections; reconsider if release qualification finds it unreliable.
- NFC package: Keep `nfc_manager` 4.2.1 and `nfc_manager_ndef` 1.1.0 behind `NfcService`. Replace only if release qualification exposes a package-level blocker.
- Any replacement must stay behind the application-owned `NfcService` interface.

## Validation cleanup

The existing app-level integration suite was attempted on the Pixel 9 after the physical checks, but the display locked and the first test did not complete. The run was interrupted; this is not a passing integration result. Flutter's test cleanup removed the debug app package and its dedicated gate slot. The normal debug APK was rebuilt and reinstalled, and the single gate slot was restored with its original identity. The restored inventory document's SHA-256 exactly matched the pre-test value recorded above. The app started again and Android reported the host as verified. The phone's original 30-second display timeout was restored, and the temporary screen recording was removed.
