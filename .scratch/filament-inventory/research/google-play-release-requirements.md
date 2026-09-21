# Google Play release requirements for the local-first MVP

**Research date:** 2026-09-20

## Conclusion

The first public Android release is feasible without adding accounts, cloud services, analytics, advertising, or sensitive Android permissions. The release should be a signed Android App Bundle targeting Android 16 (API level 36), enrolled in Play App Signing, with NFC declared as an optional hardware feature because every workflow has a manual fallback.

The largest schedule risk is the developer account rather than the app. A personal account created after 13 November 2023 must complete a closed test with at least 12 continuously opted-in testers for 14 days and then obtain production access. A new personal account must also complete identity, contact, and physical Android-device verification. These account facts must be checked early, before planning a launch date.

## Mandatory technical requirements

### Release artifact, API level, and signing

- Set `targetSdk` to **36 or higher**. Since 31 August 2026, new mobile apps and app updates submitted to Google Play must target Android 16 (API level 36). Google describes a possible extension to 1 November 2026, but the MVP should not depend on an exception. [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- Publish a **signed Android App Bundle (`.aab`)**. New Play apps have been required to use the App Bundle format since August 2021. [Android App Bundle documentation](https://developer.android.com/guide/app-bundle)
- Use **Play App Signing**, which is required for new apps that publish App Bundles. Create and securely retain an upload key; Google manages the app-signing key and signs the device-specific APKs generated from the bundle. New apps are enrolled automatically when the first bundle is uploaded. [App Bundle and Play App Signing FAQ](https://developer.android.com/guide/app-bundle/faq), [Play App Signing setup](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)
- Choose the application ID/package name carefully and register the final one in Play Console. Package names identify apps and generally cannot be reused after distribution. Every uploaded release needs a unique, increasing `versionCode`. [Create and set up an app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en-GB), [Android versioning](https://developer.android.com/studio/publish/versioning)
- The final bundle must satisfy Play's **64-bit requirement**. If any 32-bit native ABI is shipped, its corresponding 64-bit ABI must also be shipped. [64-bit support requirement](https://developer.android.com/google/play/requirements/64-bit)
- The final bundle must support **16 KB memory page sizes** on 64-bit devices because the app targets API 36 and the Flutter bundle is expected to contain native libraries. Every bundled native dependency must be compliant; this is a property of the final artifact, not only the app's own source. Verify the uploaded bundle in Play Console and test in the Pixel 9's 16 KB mode or a 16 KB emulator. [16 KB compatibility requirement and test procedure](https://developer.android.com/guide/practices/page-sizes), [current Play technical requirements](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en)

### Android 16 runtime behavior

Targeting API 36 changes runtime behavior. The implementation and release tests must account for at least:

- edge-to-edge layout, for which the opt-out is disabled on Android 16;
- predictive-back behavior and supported back-navigation APIs; and
- adaptive layouts on displays of at least 600 dp, where orientation, aspect-ratio, and resizability restrictions are ignored by default.

The Android 16 behavior-change pages must be part of the release test plan even when Flutter handles most platform integration. [Changes for apps targeting Android 16](https://developer.android.com/about/versions/16/behavior-changes-16), [changes affecting all apps on Android 16](https://developer.android.com/about/versions/16/behavior-changes-all)

### NFC manifest and runtime configuration

Declare NFC access in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

`android.permission.NFC` is a normal, install-time permission, so Android does not show a dangerous-permission runtime prompt. It is not one of Play's high-risk permissions requiring a Permissions Declaration Form. The feature is deliberately optional because the product supports every operation through lists and search. The app must check at runtime whether an NFC adapter exists and is enabled, disable scan actions when it is unavailable, and keep manual workflows usable. Declaring `required="false"` prevents NFC hardware from becoming a Play device-filtering requirement. [NFC manifest guidance](https://developer.android.com/develop/connectivity/nfc/nfc), [`NFC` permission protection level](https://developer.android.com/reference/android/Manifest.permission#NFC), [optional hardware declarations](https://developer.android.com/guide/topics/manifest/uses-feature-element), [Play permissions declarations](https://support.google.com/googleplay/android-developer/answer/9214102?hl=en)

The MVP uses an explicit foreground scan session, so it does not need NFC intent filters for background launch. If a later release targets Android 17/API 37 and adds NFC intent dispatch, recheck the new `DISPATCH_NFC_MESSAGE` activity requirement in the NFC documentation.

## Mandatory developer-account and distribution requirements

### Account and developer verification

For a personal Play Console account:

- provide and verify the required legal identity, legal address, contact email, contact phone number, and public developer email; a government identity document may be required when the linked payments profile is not already verified; [required Play account information](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en), [developer identity verification](https://support.google.com/googleplay/android-developer/answer/10841920?hl=en)
- pay the one-time USD 25 Play Console registration fee; [Google Play access conditions](https://support.google.com/googleplay/android-developer/answer/14659200?hl=en)
- if Play Console shows the task for a new personal account, verify access to a non-rooted physical Android phone running Android 10 or later through the Play Console mobile app. The available Pixel 9 qualifies; [physical-device verification](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en)
- verify that the package name is registered to the verified developer identity. Play automatically registers a previously unseen package name when creating a new app, but a name already used outside Play can require proof of ownership of the existing private signing key. Google says every Play package must be registered by 30 September 2026. [Play package-name registration](https://support.google.com/googleplay/android-developer/answer/16984799?hl=en), [Android developer verification for Play](https://developer.android.com/developer-verification/guides/google-play-console)

### Testing tracks and production access

The account creation date controls the mandatory path:

- **Personal account created after 13 November 2023:** complete app setup, run a closed test with at least 12 testers continuously opted in for at least 14 days, then apply for production access and answer Google's questions about the app, test, tester engagement, and production readiness. Open testing and production remain unavailable until access is approved. [Personal-account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- **Older personal account:** the special 12-tester gate does not apply according to the current rule, but normal policy review still applies.

Internal testing is not mandatory and supports up to 100 testers, but it is the fastest first Play-delivered build and should precede the closed test. A release on a closed, open, or production track requires the applicable app setup and Data safety declarations; an app active only on internal testing is exempt from the public Data safety section. [Release tracks](https://support.google.com/googleplay/android-developer/answer/9859348?hl=en), [Data safety scope](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

## Mandatory privacy and Play Console disclosures

### Data safety for the planned MVP

Complete the Data safety form even if no user data is collected or shared. Google defines collection as transmitting data off the user's device; data processed only on-device does not count as collected. On the current product plan, the intended answers are **no user data collected** and **no user data shared**, provided that a final dependency and network audit confirms all of the following:

- the local database, NFC payloads, and inventory operations remain on-device;
- the app includes no analytics, crash-reporting, advertising, telemetry, remote logging, or other SDK that sends user or device data;
- export is an explicit user-initiated action to a destination the user chooses, which Google's form exempts from the definition of sharing when the transfer is reasonably expected; and
- no hidden network behavior is introduced by plugins or platform services.

The declaration must describe the final shipped app and every included SDK, not merely the app's own Dart code. It must be updated whenever those practices change. [Data safety definitions and requirements](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

Android Auto Backup is enabled by default and can upload local app files to the user's Google Drive. To preserve the product's plain-language **local-only** promise and make export/import the explicit backup mechanism, configure backup behavior deliberately before release: preferably disable cloud backup or exclude the inventory database with `android:dataExtractionRules` and the matching legacy backup rules. Device-to-device transfer behavior varies by Android version and manufacturer, so the privacy policy must accurately describe the selected behavior. [Android Auto Backup](https://developer.android.com/identity/data/autobackup)

### Privacy policy

Every app needs a privacy policy even if it accesses no personal or sensitive user data. It must be linked in the designated Play Console field and available as a link or text inside the app. The hosted document must be clearly labelled as a privacy policy, active, publicly accessible, non-geofenced, non-editable, and not a PDF. It must identify the app or the same developer entity shown in the store and cover data access/collection/use/sharing, security handling, retention/deletion, and a privacy contact method. For this MVP it should clearly say that inventory data is stored locally, explain export/import and Android backup behavior, and state whether the final build sends any diagnostics. [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en-GB)

Because the MVP has no accounts, Play's account-deletion requirement does not apply. Adding account creation later would require both an in-app deletion path and an external deletion-request resource.

### Other App content declarations

Complete every mandatory item shown under **Policy and programs > App content**. For the planned release, the expected declarations are:

- **Ads:** No, assuming no advertising or house-ad SDK is added.
- **App access/sign-in details:** All functionality is available without special access. Add reviewer notes explaining that NFC is optional and that the complete inventory workflow is available manually, so review is not blocked by possession of a prepared tag.
- **Target audience and content:** choose only the age groups the app is actually designed for. Do not select child age groups merely to widen availability, because that activates Families requirements.
- **Content rating:** complete the IARC questionnaire; unrated apps are not allowed on Play.
- **Health apps:** declare that the app has no health features.
- **Financial features:** declare that the app has no financial features.
- Complete any other universal yes/no forms Play Console presents, such as government-app, news-app, or advertising-ID declarations, with answers matching the final bundle and listing.

These declarations are reviewed with the app and must stay accurate. [Prepare an app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en), [target audience declaration](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en), [content ratings](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en), [Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en), [Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en)

### Store and release configuration

Before production, configure the app category, support contact, price, countries/regions, and main store listing. A support email is mandatory. The listing requires compliant text and assets, including an app icon, short description, feature graphic, and at least two screenshots; the listing and screenshots must accurately describe the shipped functionality. [App setup dashboard](https://support.google.com/googleplay/android-developer/answer/9859454?hl=en-GB), [store contact details](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en-GB), [store-listing asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-GB)

Price is a product choice, but Play requires it to be configured. A free first release fits the stated non-commercial MVP, and later in-app purchases remain possible. The irreversible constraint is that an app once offered for free cannot later be changed into a paid download under the same package name; changing to a paid download would require a new app/package. [App pricing rules](https://support.google.com/googleplay/android-developer/answer/6334373?hl=en-IN)

## Review expectations

The production submission receives a normal Google Play policy review. The app and listing must be complete, stable, non-misleading, and fully reviewable. For some accounts, review can take up to seven days or longer in exceptional cases, so the launch plan needs review margin rather than a same-day deadline. [Publishing and review timing](https://support.google.com/googleplay/android-developer/answer/9859751?hl=en), [publication guidance](https://support.google.com/googleplay/android-developer/answer/15191715?hl=en)

This MVP requests only the normal NFC permission, so it should not trigger a high-risk Permissions Declaration Form. That conclusion must be rechecked against the merged manifest of the release bundle because transitive Android plugins can add permissions.

## Recommended release path

1. Establish the personal Play account early; record its creation date and clear identity, contact, physical-device, and package-registration tasks.
2. Reserve the final package name in Play Console before distributing builds elsewhere under that name.
3. Upload a signed API-36 AAB to internal testing and inspect Play Console's bundle, manifest, device catalog, 64-bit, 16 KB, and pre-review results.
4. Test the Play-delivered build on the Pixel 9, including NFC unavailable/disabled states, manual fallback, edge-to-edge, predictive back, restore/backup behavior, import/export, and a 16 KB environment.
5. Audit the final dependency graph and merged manifest before completing Data safety and privacy disclosures.
6. If the personal-account date triggers the rule, run the 12-tester closed test for at least 14 continuous days, collect real feedback, and apply for production access.
7. Submit production through managed publishing so approval and public launch can be separated.

## Recheck immediately before release

These facts are time-sensitive and must be verified again on the intended submission date:

- the current target API deadline and any new Android behavior changes;
- the package-name registration status, especially after the 30 September 2026 enforcement date;
- whether the account is subject to the personal-account closed-test and device-verification gates;
- every item in Play Console's **Needs attention**, **Policy status**, and release error/pre-review panels;
- the final AAB's permissions, SDK data behavior, 64-bit ABIs, 16 KB compatibility, signing, and device availability;
- the Data safety answers and privacy policy against the exact production dependency set;
- new policy deadlines, including announced February 2027 technical-quality/optimization requirements and the applicability of the announced April 2027 credential-restoration requirement; [current Play technical-quality requirements](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en)
- store-listing, target-audience, content-rating, country, price, and review-access declarations; and
- current review lead times.

Google Play's dashboard is the final source of truth for account-specific tasks because the required forms and gates vary with account age, enabled SDKs, permissions, target audience, countries, and release date.
