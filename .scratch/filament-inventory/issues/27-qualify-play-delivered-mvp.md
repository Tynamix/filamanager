# 27: Qualify the Play-delivered MVP

**What to build:** An internally distributed Google Play build whose signing, declarations, App Links, NFC behavior, device support, and account gates have been verified against the actual release artifact.

**Blocked by:** 26: Harden the Android release candidate.

**Status:** ready-for-agent

- [ ] Current target API, Google Play policies, account-specific Console tasks, package registration, review lead times, and warnings are rechecked against current primary sources immediately before submission.
- [ ] Developer identity, contact, physical-device, and package-name verification required by the account are complete.
- [ ] The bundle is enrolled in Play App Signing and the production association file contains every required signing-certificate fingerprint, including the Play App Signing certificate.
- [ ] The internal-test upload is inspected for its merged manifest, permissions, signing, supported devices, 64-bit binaries, 16 KB compatibility, and automated pre-review results.
- [ ] The Play-installed build passes the complete manual and NFC workflows on the Pixel 9, including foreground scans, tag writes, verified App Links, cold and warm delivery, failure feedback, offline operation, adaptive layout, predictive back, and disabled backup behavior.
- [ ] Representative storage-slot tags in their intended placement remain reliably readable; record observed attempts and latency without a fixed ten-read quota, and change the tag or placement if unreliable.
- [ ] Physical NFC recovery covers cancellation, NFC disabled, read-only NDEF, unformatted and insufficient or incompatible tags where available, an interrupted sacrificial write, immediate retry, repeated scan, app restart, and alternative placement. Failures show no stale success, unintended reference, or inventory mutation.
- [ ] App Link qualification records unlocked, locked, foreground, background, normal termination, force-stop, never-launched, offline, and user-disabled handling where Android permits, without promising operating-system-controlled behavior.
- [ ] The Play-installed app safely handles malformed and unknown local identifiers, repeated delivery, and read-only navigation; an app-absent device reaches the safe `/s` browser fallback.
- [ ] Observed network behavior and the shipped dependency graph support accurate Data safety and privacy-policy declarations.
- [ ] Content rating, target audience, ads, app access, health, financial, support contact, store listing, countries, and the release-time price choice match the final product.
- [ ] If the account is subject to the personal-account production-access rule, at least 12 testers remain continuously opted into the required closed test for at least 14 days and production access is obtained.
- [ ] Managed publishing is configured so production rollout remains an explicit later decision.
