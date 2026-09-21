# Chart the Filament Inventory MVP

Type: wayfinder:map
Status: resolved

## Destination

A decision-complete foundation from which `/to-spec` can produce a buildable Flutter MVP specification for a personal filament-inventory app and its first Android Play Store release.

## Notes

- Write every repository artifact in English; conversation with the user may remain in German.
- This map produces decisions, not production code. Use `/to-spec` after the map is clear.
- Read the root `CONTEXT.md` before working a ticket. Grilling tickets also use `grilling` and `domain-modeling`; prototype tickets use `prototype`; research tickets use `research` and primary sources.
- The initial user is an individual hobbyist. The product starts as a personal tool and may later be published for other hobbyists, without an initial commercial requirement.
- The core loop is: find a spool, check it out to a material-unit slot, use it, record its remaining quantity, and check it into a tagged storage slot.
- A valid FilaManager storage-slot tag may launch or foreground the app and navigate to its storage slot, but never mutates inventory without confirmation. Every operation must also be available without NFC.
- Flutter is the shared Android/iOS codebase. Android and the Google Play Store are the first release target; an iOS App Store release is not required for the MVP.
- Data is local-first without a mandatory account. The MVP persists one inventory locally; user-visible export, import, and device-loss recovery are deferred.
- Test hardware: Pixel 9, iPhone 17e, and existing tags identified so far only as ISO 14443-3A.
- The MVP is validated when four weeks of personal use keep the digital inventory aligned with reality and any spool's location, state, and remaining quantity can be found within ten seconds.

## Decisions so far

- [Can Flutter share the required NFC workflow across Android and iOS?](issues/01-cross-platform-flutter-nfc-feasibility.md): Yes—shared foreground NDEF read/write is feasible, subject to native setup and real-device validation.
- [Do the existing NFC tags work reliably on both target phones?](issues/02-validate-existing-nfc-tags-on-target-phones.md): Proceed on a provisional Type-2/NDEF assumption and defer real-tag, placement, and iPhone qualification to explicit implementation gates.
- [What must the first Google Play release disclose and configure?](issues/06-determine-google-play-release-requirements.md): Ship an API-36 signed App Bundle with optional NFC, local-only disclosures, and account-specific verification and testing gates, then recheck current rules before release.
- [Can a storage-slot tag open FilaManager when the app is not running?](issues/07-launch-app-from-storage-slot-tag.md): Use one HTTPS URI record backed by Android App Links and future iOS Universal Links; platform interaction gates launch, and the app only opens a local read-only slot context.
- [What are the complete spool movement and recovery rules?](issues/03-define-spool-movement-and-recovery-rules.md): Active spools are Stored, Loaded, or Unlocated; confirmed atomic movements and explicit corrections preserve exclusive slot occupancy while NFC tags remain optional aliases.
- [What local data and backup contract keeps the inventory recoverable?](issues/04-define-local-inventory-and-backup-contract.md): Keep one identity-stable local inventory with atomic state changes and durable per-spool history; defer user-visible backup and transfer beyond the MVP.
- [Is the scan-first inventory experience clear in real use?](issues/05-validate-scan-first-inventory-experience.md): Use Scan home with read-only slot contexts, equal manual access, guided confirmed mutations, and explicit unchanged-state recovery feedback.

## Not yet specified

- None.

## Out of scope

- Mandatory user accounts, cloud synchronization, and shared multi-user inventories
- Background NFC scanning
- Printer, slicer, or G-code integrations and automatic consumption calculation
- Purchasing, pricing, marketplace, humidity, drying, statistics, and consumption analytics
- An iOS App Store release for the first MVP
- User-visible export, import, backup restoration, and device transfer, deferred until after personal MVP validation
- Production implementation, which starts only after this map is collapsed through `/to-spec` and `/to-tickets`
