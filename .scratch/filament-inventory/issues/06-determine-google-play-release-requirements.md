# What must the first Google Play release disclose and configure?

Type: research
Status: resolved

## Question

According to current first-party Android and Google Play documentation, what requirements affect the first public release of this local-first Flutter app?

Cover target API and app-bundle requirements, NFC permission and hardware declarations, runtime behavior, Data safety and privacy disclosures for a local-only app, privacy-policy expectations, signing, testing tracks, personal-developer-account constraints, and any current review or device-verification requirements. Separate mandatory requirements from recommendations and identify facts that must be rechecked immediately before release.

## Answer

The first release must target Android 16/API 36, ship as a signed Android App Bundle through Play App Signing, and pass 64-bit and 16 KB page-size checks. Declare the normal `NFC` permission and NFC hardware as optional, then keep the manual workflow available when NFC is absent or disabled. API-36 edge-to-edge, predictive-back, and adaptive-layout behavior must be tested.

Play requires an accurate Data safety form and privacy policy even when the app sends no data. The planned `no data collected or shared` answer is valid only after auditing the final bundle and SDKs and explicitly deciding Android cloud-backup behavior. Complete the remaining listing and App content declarations with the final app behavior.

The account is the main conditional gate: complete identity, contact, physical-device, and package-name verification; if the personal account was created after 13 November 2023, run a closed test with at least 12 continuously opted-in testers for 14 days and obtain production access. Internal testing first, disabling automatic cloud backup to preserve the local-only promise, and using managed publishing are recommended. Recheck Play Console, target API, package registration, final-bundle compatibility, disclosures, upcoming policy deadlines, and review lead times immediately before release.

Research: [Google Play release requirements for the local-first MVP](../research/google-play-release-requirements.md)
