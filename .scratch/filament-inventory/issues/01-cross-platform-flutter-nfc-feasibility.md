# Can Flutter share the required NFC workflow across Android and iOS?

Type: research
Status: resolved

## Question

Can one Flutter/Dart implementation support foreground NFC reading and writing for application-owned identifiers on Android and iOS, and what portable constraints must the MVP accept?

## Answer

Yes. Flutter can share the foreground NFC/NDEF workflow through `nfc_manager` and `nfc_manager_ndef`. The portable contract uses preformatted, writable NDEF tags containing a small application-owned storage-slot identifier rather than relying on hardware UIDs.

Android and iOS still require different native project configuration and present different scan-session UX. Background scanning is not a portable MVP capability. The exact tags, physical placement, and cross-written payloads must be validated on real target devices before committing to the package and hardware combination.

Research: [Flutter NFC feasibility for storage-slot identification](../research/flutter-nfc-feasibility.md)
