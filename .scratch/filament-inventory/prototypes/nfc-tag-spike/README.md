# NFC tag spike

> Throwaway prototype. Do not reuse this code as the production NFC layer.

This spike gathers the physical evidence needed to answer whether the existing
ISO 14443-3A tags, `nfc_manager`, and the intended storage-slot placement work
reliably on the Pixel 9 and iPhone 17e.

## Safety

- A write replaces the complete NDEF message on the scanned tag.
- Use only test tags whose current contents may be erased.
- The spike deliberately cannot make a tag read-only; NFC locking is permanent.
- Use a sacrificial tag for the interrupted-write test because it may be left
  corrupted.
- Hardware IDs are displayed only to compare scans. They are not the proposed
  storage-slot identity.

## Run

Install the current stable Flutter SDK and the native Android/iOS toolchains.
From this directory, connect one target phone and run:

```sh
./run.sh
```

Pass Flutter device arguments when more than one device is connected:

```sh
./run.sh -d <device-id>
```

The first run generates an ignored Flutter app in `app/`, pins
`nfc_manager` 4.2.1 and `nfc_manager_ndef` 1.1.0, and applies the Android NFC
declarations and iOS NFC entitlement. For iOS, open
`app/ios/Runner.xcworkspace` once if Flutter asks for signing: select the
development team and keep the **Near Field Communication Tag Reading**
capability enabled. Run only on physical phones; simulators cannot perform the
test.

## Test protocol

Copy `test-results-template.md` to `test-results.md`, then fill it in. Keep the
same physical tag and representative storage-slot placement unless a row asks
for a special tag or condition.

1. On each phone, tap **Inspect tag** and copy the report. Record the advertised
   model/part number from the tag packaging or purchase record as well; the
   `GET_VERSION` result can support but cannot prove authenticity.
2. On Pixel 9, write `slot-android-a`. Read it three times on iPhone 17e.
3. On iPhone 17e, write `slot-ios-b`. Read it three times on Pixel 9.
4. In the intended physical placement, perform ten fresh **Read slot ID**
   sessions on each phone. Record successes, typical time, worst time, and the
   phone/tag orientation.
5. Exercise cancellation on both phones. On Pixel 9, also disable NFC and run
   **Check NFC**. iOS has no user-facing NFC-off toggle, so mark that case not
   applicable there.
6. Scan a known read-only NDEF tag and an unformatted tag on both phones. Do not
   lock a reusable tag just to create the read-only fixture.
7. With a sacrificial tag, start a write and remove the phone/tag during I/O.
   Record the error and whether the next inspect/read still detects the tag.
8. Repeat the ten-read sequence in any alternative placement that is physically
   plausible if the representative placement fails or feels awkward.

## Provisional decision rule

Keep the existing tag and placement only if both phones:

- identify an NDEF-formatted tag with enough capacity and writable state;
- read the other phone's written storage-slot identifier without corruption;
- complete all ten representative-placement reads, normally within two seconds
  and never over five seconds;
- report cancellation, disabled/unavailable NFC, read-only, unformatted, and
  interrupted operations without showing stale success or writing an unintended
  identifier.

Any failed cross-platform write/read means replace either the tag model or
package. Placement-only failures call for changing placement before hardware.
An unformatted-tag failure is acceptable only if the inventory standardizes on
preformatted NDEF tags and gives the hobbyist a clear replacement path.
