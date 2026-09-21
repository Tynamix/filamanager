# Is the scan-first inventory experience clear in real use?

Type: prototype
Status: resolved
Blocked by: 02, 03

## Question

Does a rough interactive prototype make the complete MVP understandable and efficient for the hobbyist on a phone?

Test occupied- and empty-storage-slot scans, confirmation before mutations, check-out to material-unit slots, check-in with remaining quantity, new-spool registration, manual search and browsing, archived spools, and representative error recovery. The prototype must answer which navigation and feedback model to carry into the specification, not become production code.

## Comments

- A throwaway interactive prototype compared Scan home, Guided tasks, and Inventory map on the same in-memory inventory.
- Live hobbyist feedback selected Variant A, Scan home, as the clearest overall model.
- Prototype source captured outside the production line on Git branch `prototype/scan-first-experience` at commit `c2fec925e05f451dd5e729a07eeb6058a3e84e4d`.

## Answer

Use Variant A, **Scan home**, as the MVP navigation and feedback model.

The home screen makes scanning a storage-slot tag the strongest entry point,
while a searchable active-spool list and persistent Home, Spools, Places, and
Archive navigation keep every operation available without NFC. A valid scan
opens the storage slot as a read-only context. An occupied storage slot leads
with its filament spool and check-out action; an empty storage slot leads with
check-in, placement of an Unlocated spool, and new-spool registration.

Multi-step operations use a focused guided sheet inside that navigation model:
choose the spool or destination, enter any required remaining quantity, review
the complete change, and confirm it explicitly. Cancelling, scanning, or
leaving an unfinished sheet changes nothing. Occupied destinations remain
blocked until the hobbyist deliberately chooses the separate assignment-
correction path and sees which filament spool will become Unlocated.

After a confirmed mutation, show a concise success message and immediately
update the visible slot or spool context. Errors must say that inventory was
not changed and offer a manual or retry path. These messages must not rely on
color alone; production controls need semantic labels, usable touch targets,
screen-reader announcements, and deliberate focus movement when a sheet opens
or closes.

The Guided tasks home and Inventory map dashboard are not primary navigation
for the MVP. Their useful ideas survive only within Scan home: staged action
steps, occupancy summaries where relevant, and visible recovery guidance. The
variant switcher, Scenario lab, and full prototype-state inspector are test
instrumentation and do not enter the product specification.
