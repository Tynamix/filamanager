# 09: Reach a storage slot manually and through NFC

**What to build:** A hobbyist can create one storage slot, open its read-only context manually, scan or link to that same context, and register interchangeable NFC shortcuts without any scan or tag write changing inventory.

**Blocked by:** 08: Bootstrap the Flutter application and test harness.

**Status:** ready-for-agent

- [ ] A hobbyist can create a named storage slot with an opaque stable identity, find it in Places, and reopen the same persisted record after an app restart.
- [ ] Manual selection, a foreground scan, and initial or subsequent Android App Link delivery all open the same read-only storage-slot context.
- [ ] Scans, links, repeated delivery, back navigation, and opening the context never reserve the slot, change occupancy, or append inventory history.
- [ ] The application validates the exact production HTTPS scheme, host, `/s` path, `v1` fragment prefix, and identifier syntax before performing local lookup.
- [ ] Foreign, blank, and malformed foreground-scan content is reported as Unknown tag, while a valid missing identity is reported as Unknown storage slot.
- [ ] From a selected storage slot, a hobbyist can register a compatible writable tag only after seeing that the complete NDEF message will be replaced and confirming the write.
- [ ] A successful write produces exactly one canonical NFC Forum URI record, permits any number of tags to reference the same storage slot, and changes no spool state, occupancy, or history.
- [ ] Unavailable or disabled NFC, cancellation, incompatible or unformatted tags, read-only or insufficient-capacity tags, interrupted I/O, and unexpected failures clearly state that inventory was unchanged and offer retry or manual navigation where useful.
- [ ] NFC is optional in Android configuration, manual navigation remains usable without hardware, and the pinned production packages stay behind the application-owned NFC boundary.
- [ ] The long-lived host and signing inputs needed with the final Android application ID for verified links are decided; the host serves Android association data and a safe `/s` browser fallback without inventory data, analytics, or server-side identifier lookup.
- [ ] App-level integration coverage exercises known, unknown, malformed, repeated, cancelled, unavailable, successful-write, and failed-write outcomes through the rendered UI using the fake adapters.
