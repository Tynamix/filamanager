# Local inventory persistence

## Before the first Google Play build

Maintain one current, unversioned local inventory format. Its JSON document contains `storageSlots`, `materialUnits`, and `filamentSpools` collections. Format changes update this current shape, its app-level persistence tests, and the product specification. Pre-release snapshots have no compatibility migration contract.

Validate every required collection and record on open, including required record fields. Treat unknown fields at any level as incompatible so a later save cannot discard their data. Preserve unreadable or incompatible files byte-for-byte, block inventory mutations, and show the existing retry and diagnostic recovery state. Keep atomic file replacement for saves. Never silently reset an inventory or fill in a missing collection.

A complete file from the earlier pre-release version-3 implementation can be read because it has the current three collections. Its obsolete `schemaVersion` property has no authority and is omitted from the next save.

## First Google Play release gate

Before distributing the first Play build, freeze the published on-disk contract and decide how installed data will survive later app updates. Introduce a version identifier and tested, atomic migrations at that gate if subsequent builds must upgrade installed inventories. Document any reset or import policy explicitly before release. The versioning decision applies to the inventory file; NFC link payload versions remain a separate external contract.
