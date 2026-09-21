# Do the existing NFC tags work reliably on both target phones?

Type: prototype
Status: resolved
Blocked by: 01

## Question

Using a throwaway Flutter spike on the Pixel 9 and iPhone 17e, can the existing ISO 14443-3A tags support the agreed storage-slot workflow reliably enough to keep them?

The spike must identify the exact tag model and NDEF state; write an application-owned storage-slot identifier on each platform; read each platform's payload on the other; and exercise cancellation, NFC-disabled, read-only, unformatted, interrupted, and repeated-scan cases. It must use representative physical tag placement and decide whether to keep or replace the tags, Flutter NFC package, or placement approach.

## Comments

- Throwaway hardware spike and guided test protocol prepared at [NFC tag spike](../prototypes/nfc-tag-spike/README.md). Awaiting the Pixel 9, iPhone 17e, and physical-tag results before resolution.
- Flutter 3.47.5, Android SDK 36.1, Xcode 27.0, and CocoaPods 1.17.0 are configured. The spike passes `flutter analyze`, builds and launches on Android, and completes an unsigned physical-device iOS build. No physical target phone is connected yet.
- Pixel 9 inspection captured in [NFC tag spike results](../prototypes/nfc-tag-spike/test-results.md): Android 17 reports a writable 492-byte Type 2 tag whose `GET_VERSION` is NTAG215-compatible. Existing non-FilaManager payloads are redacted; write and reliability tests remain pending.

## Answer

Proceed on an explicit, provisional assumption that the intended storage-slot
workflow will work with preformatted, writable NFC Forum Type 2 tags and the
`nfc_manager` 4.2.1 / `nfc_manager_ndef` 1.1.0 baseline. The Pixel 9 has already
shown that the Flutter spike can discover and inspect a compatible writable tag;
the intended inventory tags, cross-platform writes, repeated scans, failure
cases, and representative physical placement remain unvalidated.

This assumption does not make NFC mandatory or proven. The specification must:

- keep every operation fully available without NFC;
- use an application-owned NDEF storage-slot identifier, never the hardware UID;
- require explicit confirmation before an NFC-initiated inventory mutation;
- isolate the NFC package behind an application-owned interface; and
- treat real-tag and placement qualification as an early implementation gate.

If the recovered inventory tags are unformatted, read-only, too small, or
unreliable in the intended placement, replace them with preformatted writable
Type 2 tags. If the package fails on target hardware, replace the package behind
the interface. Validate the Pixel workflow before enabling NFC in the first
Android release and validate iPhone interoperability before relying on NFC in a
future iOS release.

This is a conscious acceptance of hardware-validation risk, not evidence that
the existing tags or both target phones have passed the original test matrix.
