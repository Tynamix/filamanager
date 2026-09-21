# Flutter NFC feasibility for storage-slot identification

**Research date:** 2026-09-20

## Conclusion

Yes. A Flutter app can implement the MVP's foreground NFC read/write flow once in Dart and run it on both Android and iOS. The portable intersection is an **NDEF-formatted, writable NFC tag** containing a small app-owned storage-slot identifier. A plugin can hide the Kotlin/Swift bridge; this does not eliminate platform project configuration or the different scan UX and lifecycle rules.

For a first implementation, use `nfc_manager` with its `nfc_manager_ndef` abstraction, and validate it with real Android and iPhone hardware before committing the broader app architecture. Keep all NFC access behind a small application-owned Dart interface so another plugin can be substituted if hardware testing exposes a blocker.

## Practical cross-platform path

Android recommends NDEF where possible because it has the broadest framework support, and Apple Core NFC reads NDEF tags of NFC Forum Types 1 through 5 and writes to tags whose NDEF status is `readWrite`. [`nfc_manager` exposes one Dart session API](https://pub.dev/documentation/nfc_manager/latest/nfc_manager/NfcManager-class.html), while [`nfc_manager_ndef` supplies a cross-platform `Ndef` abstraction](https://pub.dev/packages/nfc_manager_ndef). This is enough for a shared flow:

1. Check NFC availability.
2. Start a foreground reader session.
3. Discover a tag.
4. Convert it to the cross-platform NDEF abstraction.
5. Read or write a small identifier record.
6. Stop the session and handle cancellation/errors.

This is one Dart implementation, not separate Android and iOS features. Platform-specific branches remain appropriate for user-facing session messages, availability errors, and optional features that are not in the common subset.

For an identification-only hardware spike, use a small random storage-slot identifier in an NDEF record rather than relying on the tag's hardware ID. Android documents that some tags expose a stable UID, some generate a random ID on every discovery, and some expose no ID at all. An NDEF payload is therefore the more portable application-level identity. The identifier must not be treated as an authentication secret. [Android `Tag.getId()` documentation](https://developer.android.com/reference/android/nfc/Tag#getId())

Common NFC Forum Type 2 tags are sufficient for this payload. For example, NXP documents NTAG213/215/216 as Type 2 and NDEF-capable, with 144/504/888 bytes of user memory respectively. The smallest capacity is already ample for an opaque identifier. [NXP NTAG21x product documentation](https://www.nxp.com/products/NTAG213_215_216)

Buy tags that are already NDEF-formatted. Android exposes `NdefFormatable`, but Core NFC exposes NDEF status/read/write operations and no equivalent general formatting API. A tag that is physically writable but not NDEF-formatted can therefore be prepared on Android yet fail the shared iOS path. [Android NFC technology APIs](https://developer.android.com/reference/android/nfc/tech/package-summary), [Apple `NFCNDEFTag`](https://developer.apple.com/documentation/corenfc/nfcndeftag)

## Platform differences that remain

| Area | Android | iOS | MVP implication |
| --- | --- | --- | --- |
| Foreground read/write | Supported through NFC reader APIs and NDEF. | Supported through Core NFC reader sessions and writable NDEF tags. | Use an explicit in-app scan action on both platforms. |
| Session UX | The app can use foreground reader/dispatch behavior. | An active session shows Apple's system NFC sheet; Apple documents a 60-second maximum session. | Do not design around silent, indefinite scanning. |
| Background discovery | Android can dispatch NFC intents, subject to OS and manifest rules. | Background reading is read-only, requires an NDEF URI, shows a notification, and hands data to the app only after user interaction; supported on iPhone XS and later. | Background launch is not a portable MVP contract. |
| Blank/unformatted tags | Android can format compatible tags through `NdefFormatable`. | Core NFC has no matching formatting operation. | Standardize on preformatted NDEF tags. |
| Hardware identifier | May be stable, random per scan, or absent. | Identifiers exist on protocol-specific tag interfaces, not as the common NDEF contract. | Put the roll identifier in NDEF. |
| Hardware/testing | NFC hardware is optional across Android devices. | Requires a compatible physical iPhone; Core NFC is unavailable to app extensions. | Check availability at runtime and test on physical devices. |

Sources: [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc), [Android advanced NFC](https://developer.android.com/develop/connectivity/nfc/advanced-nfc), [Apple Core NFC overview](https://developer.apple.com/documentation/corenfc), [Apple NDEF reader/writer sample](https://developer.apple.com/documentation/corenfc/building-an-nfc-tag-reader-app), [Apple background tag reading](https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading), [Apple Core NFC enhancements](https://developer.apple.com/videos/play/wwdc2019/715/)

## Native setup still required

For a basic foreground session, the recommended packages avoid custom Kotlin or Swift NFC implementation, but the generated platform projects still need configuration:

- **Android:** declare `android.permission.NFC`; decide whether `android.hardware.nfc` is required for store filtering; check availability at runtime. Android 16 adds a user-controlled NFC intent allowlist, and Android 17 adds dispatch requirements and deprecates `ACTION_TAG_DISCOVERED`, which matters if background/intent launch is added later. [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc)
- **iOS:** enable the Near Field Communication Tag Reading capability, include the reader-session entitlement, and add `NFCReaderUsageDescription` to `Info.plist`. Extra ISO 7816 AID or FeliCa declarations are needed only if those protocols are polled; a Type 2 NDEF-only MVP should avoid them. [Apple's setup instructions](https://developer.apple.com/documentation/corenfc/building-an-nfc-tag-reader-app), [`nfc_manager` setup](https://github.com/okadan/flutter-nfc-manager#setup)

Background launch would add materially different platform work: Android intent filters/activity lifecycle handling versus iOS associated domains, universal links, and `NSUserActivity`. It should not be assumed to come “for free” from the common reader/writer abstraction.

## Package options as of 2026-09-20

### 1. `nfc_manager` 4.2.1 + `nfc_manager_ndef` 1.1.0 — recommended baseline

- Supports Android and iOS, exposes a shared session API, and provides a dedicated cross-platform NDEF layer.
- `nfc_manager` 4.2.1 was published five months before this review by the verified `okadan.net` publisher; the package has a long release history and substantially more adoption than newer alternatives. [`nfc_manager` versions](https://pub.dev/packages/nfc_manager/versions), [publisher page](https://pub.dev/publishers/okadan.net/packages)
- Risk: the 4.x design splits common NDEF operations into another package while retaining separate platform-specific tag APIs. Pin compatible versions, wrap the dependency, and test upgrades against real tags. Recent publication is evidence of activity, not a maintenance guarantee.

### 2. `flutter_nfc_kit` 3.6.2 — credible alternative

- One API supports polling and NDEF read/write on Android and iOS. Its own example recommends polling for consistent cross-platform interaction. [`flutter_nfc_kit` API](https://pub.dev/documentation/flutter_nfc_kit/latest/flutter_nfc_kit/FlutterNfcKit-class.html), [example](https://pub.dev/packages/flutter_nfc_kit/example)
- Version 3.6.2 was published eight months before this review; its repository was updated in 2026. [`flutter_nfc_kit` versions](https://pub.dev/packages/flutter_nfc_kit/versions), [repository](https://github.com/nfcim/flutter_nfc_kit)
- Risks: several options and advanced operations are explicitly platform-specific; event streaming is Android-only. Its NDEF codec dependency describes itself as under active development and subject to breaking changes or malfunction. It also imposes Android toolchain floors (API 24, Java 17, Gradle 8.9, AGP 8.7) that should be checked against the eventual Flutter project. [`flutter_nfc_kit` setup](https://github.com/nfcim/flutter_nfc_kit#setup), [`ndef` package notice](https://pub.dev/packages/ndef)

### 3. `nfc_util` 3.3.0 — promising, but too new for the default choice

- It exposes shared reader-session and NDEF APIs, explicit platform libraries, fakes for tests, and current Android 16/17 handling. [`nfc_util` package](https://pub.dev/packages/nfc_util)
- Risks: it was published only about three weeks before this review, has very low adoption, uses an unverified uploader, and requires Flutter 3.44, Android API 24, and iOS 15.6. Its breadth is attractive, but the project has less field history than the two alternatives.

`nfc_flutter` 0.0.1 also claims Android/iOS NDEF read/write, but a first release with negligible adoption is not a prudent baseline when established choices exist. [`nfc_flutter`](https://pub.dev/packages/nfc_flutter)

## Recommended feasibility spike

Before making a product or architecture decision, prove the common path on one real iPhone and at least two Android models:

- Write an application-generated identifier on Android and read it on iOS.
- Write a different identifier on iOS and read it on Android.
- Repeat reads and writes, including cancellation, NFC disabled/unavailable, read-only tag, unformatted tag, undersized payload, and moving the phone away during I/O.
- Use the exact tag model and physical label form intended for storage slots; antenna size, phone antenna position, nearby metal, and placement can affect the experience even when the protocol is compatible.

Passing that spike is sufficient evidence that Flutter can share the MVP NFC feature. Background scanning, raw tag protocols, password protection, and hardware-UID-based identity are separate decisions and are not prerequisites for the foreground inventory workflow.
