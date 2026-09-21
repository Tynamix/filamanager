# NFC tag spike results

## Test setup

- Date:
- Tester:
- Flutter version:
- Pixel 9 Android version:
- iPhone 17e iOS version:
- Advertised tag manufacturer and model:
- Tag purchase/source reference:
- Tag form factor and antenna dimensions:
- Representative storage-slot material and placement:
- Nearby metal or electronics:

## Inspection

### Pixel 9

Paste the copied report here.

### iPhone 17e

Paste the copied report here.

### Identification conclusion

- Exact or best-supported tag model:
- NDEF state:
- Capacity:
- Writable:
- Confidence and remaining ambiguity:

## Cross-platform payload

| Check | Result | Notes |
| --- | --- | --- |
| Pixel writes `slot-android-a` |  |  |
| iPhone reads `slot-android-a` three times |  |  |
| iPhone writes `slot-ios-b` |  |  |
| Pixel reads `slot-ios-b` three times |  |  |

## Representative-placement repetition

| Device | Successful reads / 10 | Typical time | Worst time | Orientation and feel |
| --- | ---: | ---: | ---: | --- |
| Pixel 9 |  |  |  |  |
| iPhone 17e |  |  |  |  |

## Failure and recovery cases

| Case | Pixel 9 | iPhone 17e | Safe and understandable? |
| --- | --- | --- | --- |
| User cancellation |  |  |  |
| NFC disabled/unavailable |  | Not applicable: no NFC toggle |  |
| Known read-only NDEF tag |  |  |  |
| Unformatted tag |  |  |  |
| Interrupted write on sacrificial tag |  |  |  |
| Immediate retry after interruption |  |  |  |
| Repeated scan of same tag |  |  |  |

## Placement alternatives

Record only if the representative placement was unreliable or awkward.

| Placement | Device | Successful reads / 10 | Typical time | Worst time | Notes |
| --- | --- | ---: | ---: | ---: | --- |
|  |  |  |  |  |  |

## Tester reaction

- Did the scan target and phone orientation feel obvious?
- Were the native iOS sheet and Android in-app state understandable?
- Was recovery from cancellation or failure obvious?
- What felt slow, fragile, or surprising?

## Decision

- Tag: keep / replace / investigate
- Package: keep `nfc_manager` / replace / investigate
- Placement: keep / change / investigate
- Constraints to carry into the MVP specification:
- Evidence still missing:
