# 10: Pass the early Pixel 9 NFC gate

**What to build:** An early Pixel 9 hardware viability decision for the production NFC and App Link path before later inventory work depends on it. Full release qualification is ticket 27.

**Blocked by:** 09: Reach a storage slot manually and through NFC.

**Status:** completed

- [x] Pixel 9 inspection records the representative tag technology, NDEF state, writability, and usable capacity; the production adapter accepts and writes the tag.
- [x] The production app writes one canonical storage-slot URI record, which Android independently reads back as the intended reference.
- [x] A foreground scan and physical Android web-link dispatch open the same read-only storage-slot context without changing inventory.
- [x] The production App Link host verifies for the locally signed build and serves its association file and safe browser fallback.
- [x] Redacted observations support a keep-or-replace decision for the tag, plastic-bin placement, and NFC package. Unmeasured release cases are assigned to ticket 27.

## Answer

The early Pixel 9 NFC gate passes for continuing inventory development. The representative Type 2 tag, plastic-bin placement, and pinned NFC packages can be kept provisionally. [The evidence](../research/pixel-9-nfc-gate.md) distinguishes observed success from deferred release qualification.

## Comments

- 2026-09-25: The Pixel 9 production app wrote a canonical reference to a representative writable Type 2 tag, Android independently read the matching single URI record, an explicit foreground scan opened the same empty storage-slot context, and the local inventory hash stayed unchanged. Android reported the production App Link host as verified. The physical metadata and incomplete matrix are recorded in [the gate evidence](../research/pixel-9-nfc-gate.md). The controlled ten-read timing target and failure/state matrices remain open, so this ticket is not marked complete.
- 2026-09-26: The product owner accepted the observed write/read and navigation path as sufficient for this early gate and explicitly declined a fixed ten-read quota. Ticket 27 records representative-placement reliability and latency without a numeric trial quota. Special-tag, recovery, placement, and platform-state checks move to that Play-delivered release qualification; they must not be described as passed here.
