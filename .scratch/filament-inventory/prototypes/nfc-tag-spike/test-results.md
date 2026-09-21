# NFC tag spike results

Status: hardware testing deferred by planning decision

## Test setup

- Date: 2026-09-20
- Tester: Hobbyist
- Flutter version: 3.47.5
- Pixel 9 Android version: 17
- iPhone 17e iOS version: Not tested; device unavailable
- Advertised tag manufacturer and model: Not yet supplied
- Tag purchase/source reference: Not yet supplied
- Tag form factor and antenna dimensions: Not yet supplied
- Representative storage-slot material and placement: Not yet tested
- Nearby metal or electronics: Not yet supplied

## Inspection

### Pixel 9

- NFC availability: enabled
- Protocol: NFC-A / ISO 14443-3A
- NDEF state: formatted NFC Forum Type 2
- NDEF capacity: 492 bytes
- Writable: yes
- Can be made read-only: yes; the spike does not expose that irreversible action
- Android technologies: `NfcA`, `MifareUltralight`, `Ndef`
- ATQA: `44 00`
- SAK: `0x0`
- Android-reported MIFARE type: `ultralightC`
- `GET_VERSION`: `00 04 04 02 01 00 11 03`
- Best-supported model: NXP NTAG215-compatible
- Existing NDEF records: two non-FilaManager records; arbitrary payloads are redacted

The existing payload included a secret-looking webhook URL. It is intentionally
omitted from this artifact. The spike was changed after this observation so that
non-FilaManager payloads are no longer displayed or copied.

### iPhone 17e

Pending.

### Identification conclusion

- Exact or best-supported tag model: NXP NTAG215-compatible; authenticity not proven
- NDEF state: formatted Type 2 with two existing records
- Capacity: 492 bytes
- Writable: yes
- Confidence and remaining ambiguity: The protocol response and capacity strongly
  support NTAG215 compatibility. Packaging or purchase information is still needed
  to establish the advertised manufacturer and exact commercial product.

## Cross-platform payload

| Check | Result | Notes |
| --- | --- | --- |
| Pixel writes `slot-android-a` | Pending permission | Writing replaces the existing NDEF message. |
| iPhone reads `slot-android-a` three times | Pending | iPhone unavailable. |
| iPhone writes `slot-ios-b` | Pending | iPhone unavailable. |
| Pixel reads `slot-ios-b` three times | Pending | iPhone unavailable. |

## Representative-placement repetition

| Device | Successful reads / 10 | Typical time | Worst time | Orientation and feel |
| --- | ---: | ---: | ---: | --- |
| Pixel 9 | Pending |  |  |  |
| iPhone 17e | Pending |  |  |  |

## Failure and recovery cases

| Case | Pixel 9 | iPhone 17e | Safe and understandable? |
| --- | --- | --- | --- |
| User cancellation | Pending | Pending |  |
| NFC disabled/unavailable | Pending | Not applicable: no NFC toggle |  |
| Known read-only NDEF tag | Pending | Pending |  |
| Unformatted tag | Pending | Pending |  |
| Interrupted write on sacrificial tag | Pending | Pending |  |
| Immediate retry after interruption | Pending | Pending |  |
| Repeated scan of same tag | Pending | Pending |  |

## Placement alternatives

Pending representative-placement results.

## Tester reaction

Pending.

## Decision

- Tag: provisionally keep if the intended tags are preformatted, writable Type 2;
  otherwise replace them
- Package: provisionally keep `nfc_manager` behind an application-owned interface
- Placement: assume workable and validate with the real storage setup early in
  implementation
- Constraints to carry into the MVP specification: NFC stays optional; every
  operation has a manual path; scans require confirmation before mutation; use an
  application-owned NDEF identifier rather than a hardware UID
- Evidence still missing: Pixel write/read and recovery matrix, representative
  placement repetition, tag provenance, and all iPhone interoperability checks;
  these checks are explicit implementation gates rather than planning blockers
