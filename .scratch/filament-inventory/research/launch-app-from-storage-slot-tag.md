# Launching FilaManager from a storage-slot tag

**Research date:** 2026-09-21

## Conclusion

FilaManager can open to the referenced storage slot when the app is backgrounded or not running, but the portable solution is a web link rather than an app-private NFC payload. Write one NFC Forum well-known URI record as the first NDEF record:

```text
https://<stable-owned-domain>/s#v1.<storage-slot-id>
```

Configure that URL as a verified **Android App Link** for the first release and as an iOS **Universal Link** for a future iOS release. Android 16 routes an HTTP(S) NFC record through `ACTION_VIEW`; Android 17 instead presents an “open link” notification that the user must act on. iOS background tag reading also presents a notification and launches or foregrounds the associated app only after the user taps it. Neither platform offers a cross-platform guarantee of a silent launch from a locked device. [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc), [Apple background tag reading](https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading)

This is platform-managed tag dispatch, not an app process scanning indefinitely in the background. It therefore does not conflict with the product's prohibition on background NFC scanning.

The URL fragment is important. It carries the stable local storage-slot identifier to the app, while URI rules remove the fragment before dereferencing the HTTPS resource. The static host therefore receives a request for `/s`, not the slot identifier. The identifier is not a secret—it remains visible to the phone, browser, anyone who reads the tag, and any copied tag—but no inventory record or server-side slot mapping is required. [RFC 3986, section 3.5](https://www.rfc-editor.org/rfc/rfc3986#section-3.5)

## Recommended NDEF contract

Use exactly one primary record:

- TNF: NFC Forum well-known
- RTD: URI (`U`)
- URI: `https://<stable-owned-domain>/s#v1.<storage-slot-id>`
- identifier: the existing stable, application-owned storage-slot identifier, encoded as an unpadded base64url value or another URL-safe opaque value

The version prefix leaves room to change parsing rules without changing the domain or route. The app must compare scheme, host, path, version, and identifier syntax strictly before looking up the identifier in its local database.

The URI record must be first. Android classifies a tag from the first NDEF record, and iOS background reading searches for a well-known URI record and uses the first URI when there is more than one. [Android NDEF dispatch](https://developer.android.com/develop/connectivity/nfc/nfc#ndef-disc), [Apple background tag reading](https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading)

Do not make an Android Application Record, a custom MIME record, an NFC external-type record, a hardware UID, or a custom URL scheme the canonical payload:

- MIME and external-type records can launch Android through NFC-specific intents, but do not give iOS its required universal-link background path.
- iOS background tag reading does not support arbitrary custom URL schemes; Apple directs apps to universal links.
- An Android Application Record is Android-only and couples every physical tag to the package name. It can send an absent app to Google Play, but adds no capability once a verified web link is used. [Android application records](https://developer.android.com/develop/connectivity/nfc/nfc#aar)
- Hardware tag identifiers are not the portable application identity and are unnecessary when multiple tags intentionally identify the same storage slot.

Every physical tag registered for one storage slot receives the same URI. Multiple tags therefore remain interchangeable without any physical-tag registry. Losing or copying one does not change the storage-slot identity.

## Behavior by platform and app state

| State | Android 16 / API 36 release target | Android 17 | Future iOS on a supported iPhone |
| --- | --- | --- | --- |
| App visible | A normal App Link intent can update the current Flutter route. If an explicit in-app NFC reader session is active, the foreground reader handles the tag directly. | Same, except a system “open link” notification is required for an HTTP(S) tag handled through background dispatch. | An explicit Core NFC reader session reads directly. Without one, background detection shows a notification that must be tapped. |
| App backgrounded | With the screen unlocked and link handling enabled, the verified App Link brings the activity forward. | The scan produces an “open link” notification; tapping it brings the app forward. | The scan produces a notification; tapping it brings the app forward. |
| Process terminated normally | With the screen unlocked, the verified App Link cold-starts the activity. Flutter receives the link as its initial route. | The notification/tap path cold-starts the activity. | The notification/tap path launches the app; iOS delivers the link through `NSUserActivity` during scene connection. |
| Device locked | Do not promise dispatch. Android says devices are usually looking for tags while the screen is unlocked. | Same. | If background reading detects the tag while locked, the system asks the user to unlock before delivering it. Background reading is unavailable before the first unlock after a restart. |
| App force-stopped or never launched | Do not promise launch. A normal process death is different from Android's stopped state. | Android explicitly does not dispatch NFC intents to an app in the stopped state; require one manual launch after installation and treat force-stop recovery as a physical-device test case. The exact interaction between this rule and Android 17's new `ACTION_VIEW` notification path should be validated on the Pixel. | Apple documents launch after the notification tap; validate force-quit behavior on the release OS because user universal-link choices can still cause a browser fallback. |
| App absent | The verified link falls back to the default browser and the `/s` landing page. | Same, after the system link interaction. | Safari opens the link after the notification tap. |

Android's tag dispatcher normally scans while the screen is unlocked and starts the most appropriate matching activity. Starting in Android 16, HTTP(S) NDEF records produce `ACTION_VIEW` rather than `ACTION_NDEF_DISCOVERED`. Starting in Android 17, that web-link path presents an explicit notification before sending `ACTION_VIEW`; `ACTION_TAG_DISCOVERED` is also deprecated. [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc)

On iPhone XS and later, background tag reading is system-owned and read-only. It operates when the iPhone is in use and the screen is illuminated. It is unavailable before the first unlock after restart, during a Core NFC reader session, while Wallet/Apple Pay or the camera is in use, and in Airplane Mode. A detected compatible tag produces a notification. Tapping the notification launches or foregrounds the app; a locked phone requires unlocking first. [Apple background tag reading](https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading), [Apple NFC human-interface guidance](https://developer.apple.com/design/human-interface-guidelines/nfc)

Universal links and App Links remain user-controlled. Android exposes both **Launch via NFC** for NFC dispatch and **Open supported links** for verified domains. Android 16 notifies the user the first time an app receives a matching NFC launch and lets the user disallow future launches. The app can inspect `NfcAdapter.isTagIntentAllowed()` and send `ACTION_CHANGE_TAG_INTENT_PREFERENCE` to the relevant Settings page for NFC-specific intent handling. [Android NFC app allowlist](https://developer.android.com/develop/connectivity/nfc/nfc#app-allowlist), [Android App Link user settings](https://developer.android.com/training/app-links/verify-applinks#request-user-associate-app-with-domain)

The Android reference describes the NFC preference in terms of `ACTION_NDEF_DISCOVERED`, `ACTION_TECH_DISCOVERED`, and `ACTION_TAG_DISCOVERED`; the recommended Android 16 web record uses `ACTION_VIEW`. AOSP's NFC dispatcher nevertheless applies its app-preference filtering while resolving the web intent. Treat both settings as user-visible escape hatches and validate their exact Pixel behavior rather than assuming either can be bypassed. [Android `NfcAdapter` source](https://android.googlesource.com/platform/frameworks/base/+/aml_ads_351420000/nfc/java/android/nfc/NfcAdapter.java), [AOSP NFC dispatcher](https://android.googlesource.com/platform/packages/apps/Nfc/+/41660cc3eda79d445e605666975547ca32b1bef4/src/com/android/nfc/NfcDispatcher.java)

## Native and hosting configuration

### Android first release

1. Keep the existing NFC declarations for explicit in-app reading: `android.permission.NFC` and optional `android.hardware.nfc` support.
2. Add an exported `ACTION_VIEW` intent filter with `DEFAULT`, `BROWSABLE`, `https`, the exact host, `/s`, and `android:autoVerify="true"`.
3. Host `https://<domain>/.well-known/assetlinks.json` with `application/json`, no redirect, the final Android application ID, and every required SHA-256 signing-certificate fingerprint. The production entry must use the Play App Signing certificate, which is usually not the local upload certificate.
4. Handle the incoming URL through Flutter's Router/deep-link path for both cold and warm launches. Flutter supports Android and iOS deep links and distinguishes initial-route delivery from links received while already running. [Flutter deep linking](https://docs.flutter.dev/ui/navigation/deep-linking)

Android requires the association file to be reachable over HTTPS without redirects. Domain verification needs internet access. Users can override which verified domains open in the app. [Android website association](https://developer.android.com/training/app-links/configure-assetlinks), [Android App Link verification](https://developer.android.com/training/app-links/verify-applinks)

For the API-36 MVP, the Android 17 NFC dispatch permission is not yet a target-SDK requirement. When FilaManager later targets an SDK greater than Android 16 (`BAKLAVA`), any activity that declares NFC-specific NDEF/TECH intent filters must be protected by `android.permission.DISPATCH_NFC_MESSAGE`. Do not place that permission blindly on a shared launcher/deep-link activity; the recommended web-tag route uses `ACTION_VIEW`. If a direct NFC-intent fallback is later added, isolate it behind a dedicated bridge activity and revalidate the manifest on API 37. Android 17 also refuses NFC-intent dispatch to apps in the stopped state. [Android 17 NFC requirements](https://developer.android.com/develop/connectivity/nfc/nfc#manifest)

### Future iOS release

1. Join the Apple Developer Program; Flutter's setup guide notes that personal development teams do not support the Associated Domains capability.
2. Add the Associated Domains capability and `applinks:<domain>` entitlement.
3. Host `https://<domain>/.well-known/apple-app-site-association` over HTTPS with a valid certificate and no redirect. Its `applinks` entry must identify the production Apple Team ID plus bundle ID and match the `/s` path. The filename has no extension.
4. Handle `NSUserActivityTypeBrowsingWeb` and extract the full `webpageURL`, including the fragment. Flutter's built-in deep-link handling can route cold and warm links; native scene handling is still the underlying delivery mechanism.
5. Independently keep the Near Field Communication Tag Reading capability and `NFCReaderUsageDescription` for the explicit foreground reader flow.

Apple retrieves the association file through its CDN after app installation. Apple says the CDN may take up to 24 hours to fetch a new file, and devices check periodically thereafter. The production host therefore has to remain public and stable. [Apple associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains), [Flutter iOS universal-link setup](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links)

### Static web fallback and local-only implications

Reliable cross-platform cold launch requires a stable owned domain and minimal public HTTPS hosting. It does **not** require an account, API, database, cloud inventory, or a server lookup. The host needs only:

- `/.well-known/assetlinks.json`;
- `/.well-known/apple-app-site-association`; and
- a static `/s` page explaining that FilaManager must be installed, then asking the user to rescan.

Serve the fallback without analytics, third-party resources, client-side scripts, or code that reads/transmits `location.hash`. Because the storage-slot identifier is in the fragment, the HTTP request does not contain it. Normal TLS/domain logs can still record that `/s` was visited, and the browser/OS can see the full scanned URL, so the payload must never be treated as confidential or authenticating.

If owning a stable public domain is unacceptable, an Android-only external/MIME NDEF record can launch the installed app without web association. That alternative gives up the same-tag future iOS behavior and has less useful app-absent behavior. It is therefore not the recommended durable tag format.

## Safety contract inside the app

Opening a deep link performs navigation only:

1. Validate the URL and parse the identifier.
2. Look up the storage slot in the local database.
3. Open a read-only storage-slot context screen, or show `Unknown tag` if the identifier is absent locally.
4. Require the already-agreed explicit workflow and final confirmation before any check-in, movement, correction, archival, or quantity change.

A scan is never a command. Replayed links, repeated scans, copied tags, browser opens, and duplicate platform deliveries must be idempotent and must not reserve a slot or alter inventory. If local data has been erased or not imported on a new phone, the URL cannot reconstruct the slot from the web: it correctly resolves as unknown until local data is restored or the tag is registered again.

## Validation gates

Before provisioning the real tag set:

- choose the long-lived production domain, Android application ID, and `/s` URL contract;
- publish both association files even if iOS ships later, so the physical payload need not change;
- verify `assetlinks.json` with the Play-installed signing certificate and inspect `adb shell pm get-app-links <package>`; on Android 17 use `adb shell am start --debug-link ...` when resolution fails;
- test a real tag on the Pixel 9 on Android 16 and Android 17 with the app visible, backgrounded, normally terminated, force-stopped, never launched after install, absent, and with **Launch via NFC** / **Open supported links** disabled;
- test locked and unlocked screens, NFC disabled, offline mode, repeated scans, malformed identifiers, an unknown local identifier, and the static browser fallback;
- on the future iOS target, wait for AASA propagation and test on the physical iPhone 17e with the app visible, backgrounded, terminated, force-quit, absent, locked, after reboot-before-first-unlock, and while a foreground Core NFC session is active; and
- verify in every state that reaching the slot screen changes no inventory until the user explicitly confirms a separate action.

Android provides commands for forcing and inspecting domain verification, but only a real NFC scan exercises NFC routing and the Android 16/17 system UI. Apple Core NFC requires compatible NFC hardware, so the complete iOS path likewise needs a physical phone. [Android App Link testing](https://developer.android.com/training/app-links/verify-applinks), [Apple Core NFC](https://developer.apple.com/documentation/corenfc)
