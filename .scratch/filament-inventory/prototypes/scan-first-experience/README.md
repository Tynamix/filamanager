# Scan-first inventory experience prototype

This is a throwaway, dependency-free phone UI prototype for the wayfinding
ticket [Is the scan-first inventory experience clear in real use?](../../issues/05-validate-scan-first-inventory-experience.md).
It compares three navigation and feedback models on one route:

- `?variant=A` — **Scan home**: the scanned storage slot becomes the main context.
- `?variant=B` — **Guided tasks**: the hobbyist chooses an intention, then follows a staged flow.
- `?variant=C` — **Inventory map**: locations and occupancy stay visible while actions happen.

All variants share one in-memory inventory so switching variants does not reset
the current test. Nothing is persisted or connected to NFC.

## Run

From this directory:

```sh
./run.sh
```

Then open <http://127.0.0.1:4173/?variant=A> and use the floating arrows to
switch variants. The page is responsive, but a narrow browser window best
represents the target phone.

## Evaluation route

Use **Scenario lab** to start each representative situation:

1. Scan occupied `Shelf A · 1`, check its spool out to an empty material slot,
   and verify that nothing changes before the final confirmation.
2. Scan empty `Shelf A · 2`, check in a loaded spool, enter its remaining
   quantity, and confirm the destination.
3. From that same empty slot, register a new spool or place an Unlocated spool.
4. Find a spool without scanning by searching or browsing.
5. Open Archive and restore a Consumed spool; it must become Unlocated rather
   than reclaiming its former slot.
6. Exercise unknown-tag, NFC-unavailable, interrupted-action, and occupied-
   destination recovery.

After trying all three variants, answer:

- Which variant makes the next safe action most obvious?
- Which feedback best explains what changed and what did not?
- Which parts, if any, should be combined into the specification?

