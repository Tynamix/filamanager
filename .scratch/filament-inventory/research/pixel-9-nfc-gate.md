# Early Pixel 9 NFC gate

**Date:** 2026-09-25

**Application source:** `origin/main` at `8c69fdd6be362f156505bbe8392b4cefe302a9c0`

**Gate status:** Not passed yet. The core write/read path worked on the representative tag, but the required controlled ten-read timing run and failure/state matrices were not completed.

## Setup and controls

- Device: Pixel 9 (`tokay`), Android 17 / API 37. ADB reported NFC enabled.
- App: `de.vibesolutions.filamanager`, target SDK 36. The debug APK was built from the source above and installed with `adb install -r`, preserving app data.
- Android reported `filamanager.vibesolutions.de` as verified for the installed app and reported the local signing fingerprint as `0B:E1:82:51:F1:B4:4D:E3:50:86:C8:76:D3:02:A5:7B:49:9B:F7:A5:4A:B7:35:F4:DB:D0:5E:A4:D0:61:AB:6E`.
- The live `/.well-known/assetlinks.json` returned HTTP 200 with JSON content type. The live `/s` fallback redirected to `/s/` and then returned HTTP 200.
- `flutter build apk --debug`, `flutter analyze`, and `flutter test` passed before physical testing (18 tests).
- The production adapter is `NfcManagerService` using `nfc_manager` 4.2.1 and `nfc_manager_ndef` 1.1.0. It checks `Ndef.from(tag)`, writable state, and `maxSize` before a write. The physical tests below must still establish what the representative tags actually report.

Use a dedicated empty storage slot for this gate. Record its reference only as a redacted value (`https://filamanager.vibesolutions.de/s#v1.<redacted>`). Compare a hash of the local inventory document immediately before and after each scan, link, cancellation, and failed write. The one expected inventory change is creating the test storage slot; take the baseline afterward. Never retain tag UIDs, previous NDEF contents, full storage-slot identifiers, or unfiltered NFC logs in this document.

## Representative tag and placement

| Observation | Result |
| --- | --- |
| Advertised tag and form factor | Not supplied; the tag's protocol is NTAG215-compatible, but commercial identity is unverified. |
| Placement, material, nearby metal/electronics | Plastic bin; nearby metal/electronics and final mounting method not recorded. |
| Android technologies and best-supported tag type | `NfcA`, `MifareUltralight`, `Ndef`; NFC Forum Type 2, NXP NTAG215-compatible (`GET_VERSION` `00 04 04 02 01 00 11 03`). Commercial authenticity not established. |
| NDEF formatted, writable, usable capacity | Formatted; writable; 492 bytes, reported by the read-only tag inspection app on this Pixel 9. |
| Canonical URI write, independent read-back, one URI record | Passed. The production app reported “Tag registered”; Android's subsequent NFC dispatch decoded exactly one well-known URI record matching the gate slot's canonical reference. The read-only inspection app also reported one cached URI record with a 57-byte record payload. Identifier and prior tag contents are omitted. |
| Foreground scan opens the same read-only storage-slot context | Passed once with the production adapter. The UI displayed “NFC Gate” and “Empty”; the reader session closed after discovery. |
| Physical operating-system App Link scan opens that context | Android 17 logged repeated physical tag dispatches as a matched web link for FilaManager; the app displayed the gate slot context. A clean background/cold-state matrix remains pending. |
| Inventory document unchanged after NFC operations | Passed for the write, first foreground read, and the later repeated-scan attempt. The app-local inventory SHA-256 stayed `f34e84038b87921bdc6ca0856340f7911ada89db44e9a767a58e8b953045016e`. Failure cases remain untested. |

The physical metadata came from the existing read-only NFC spike app. The production adapter checks NDEF support, writability, and capacity while writing, but it does not expose the exact tag type or those values in a retained diagnostic. That part of ticket 10 remains open.

## Ten fresh reads in representative placement

For each attempt, end the prior NFC session or move the phone away until discovery has ceased, then make a fresh approach in the intended position. Measure from presentation at the tag to the visible destination, using a video or synchronized event/UI timestamps. Count an attempt as successful only if the correct read-only storage-slot context appears. Record each elapsed time, including failures; do not replace a failed attempt with a retry.

| Attempt | Result | Elapsed time | Notes |
| ---: | --- | ---: | --- |
| 1 | Pending |  |  |
| 2 | Pending |  |  |
| 3 | Pending |  |  |
| 4 | Pending |  |  |
| 5 | Pending |  |  |
| 6 | Pending |  |  |
| 7 | Pending |  |  |
| 8 | Pending |  |  |
| 9 | Pending |  |  |
| 10 | Pending |  |  |

**Pass target:** 10/10 successful; normally within two seconds and none over five seconds.

A continuous attempt was made on the plastic bin. Four distinct system-dispatched tag detections appear in the redacted diagnostic excerpt below from `23:22:53` through `23:23:05`, in addition to the earlier successful foreground scan. The user reported that read and write appeared to work. The run did not establish ten controlled fresh attempts or presentation-to-visible-context times, so it cannot be counted as a pass. The temporary screen recording was deleted after the run; no unredacted tag payload or hardware ID is retained here.

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

These timestamps measure detection-to-dispatch, not presentation-to-visible-context. They therefore do not establish the two-second or five-second user-visible targets.

## Failure and recovery matrix

| Case | Observed result | Inventory unchanged? |
| --- | --- | --- |
| Cancel foreground scan | Pending | Pending |
| NFC disabled | Pending | Pending |
| Read-only NDEF tag | Pending, if available | Pending |
| Unformatted tag | Pending, if available | Pending |
| Insufficient-capacity or incompatible tag | Pending, if available | Pending |
| Interrupt write on a sacrificial tag | Pending | Pending |
| Immediate retry after interruption | Pending | Pending |
| Repeat scan of the same tag | Pending | Pending |
| Restart app and scan | Pending | Pending |
| Alternative placement | Pending | Pending |

Any failed or cancelled operation must show no stale success, never write another slot's reference, and leave inventory unchanged. An interrupted write may leave the sacrificial tag itself in an indeterminate state; read it independently before retrying or replacing it.

## Android App Link state matrix

Test real physical NFC dispatch where Android permits it. Record what the platform did separately from what the app displayed. Android 17 may show a notification that needs a tap before delivery. Locked, force-stopped, never-launched, and user-disabled states do not promise automatic launch.

| State | Observed result | Correct read-only context when delivered? |
| --- | --- | --- |
| Unlocked, app visible | Pending | Pending |
| Backgrounded | Pending | Pending |
| Normally terminated | Pending | Pending |
| Locked | Pending | Pending |
| Force-stopped | Pending | Pending |
| Never launched after install | Pending | Pending |
| Offline | Pending | Pending |
| User-disabled link or NFC handling | Pending | Pending |

## Decision

- Intended tag: Keep provisionally for development. One representative formatted, writable Type 2 tag accepted the production canonical write and was independently read back. Its advertised product identity and failure matrix remain unqualified.
- Representative plastic-bin placement: Keep provisionally; the measured ten-read target has not been met.
- NFC package: Keep `nfc_manager` 4.2.1 and `nfc_manager_ndef` 1.1.0 behind `NfcService` for continued development. Replace only if the remaining physical matrix exposes a package-level blocker. This is not a release qualification decision.
- Any replacement must stay behind the application-owned `NfcService` interface.

## Validation cleanup

The existing app-level integration suite was attempted on the Pixel 9 after the physical checks, but the display locked and the first test did not complete. The run was interrupted; this is not a passing integration result. Flutter's test cleanup removed the debug app package and its dedicated gate slot. The normal debug APK was rebuilt and reinstalled, and the single gate slot was restored with its original identity. The restored inventory document's SHA-256 exactly matched the pre-test value recorded above. The app started again and Android reported the host as verified. The phone's original 30-second display timeout was restored, and the temporary screen recording was removed.
