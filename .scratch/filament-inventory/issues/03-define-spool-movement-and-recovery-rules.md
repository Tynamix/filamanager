# What are the complete spool movement and recovery rules?

Type: grilling
Status: resolved
Blocked by: 07

## Question

What exact state transitions and corrective actions govern storage slots, filament spools, printers, and material slots across the full inventory lifecycle?

Resolve the happy paths for registering, checking out, checking in, consuming, and retiring a spool. Stress-test occupied destinations, unknown or duplicate tags, lost tags, interrupted actions, incorrect assignments, manual operation without NFC, correction of remaining quantity, and recovery from inventory that no longer matches reality. Preserve the agreed rule that scans open a confirmed action rather than mutating inventory immediately.

## Answer

### State and location model

A filament spool is either active or archived. An active spool is in exactly one
of these states:

- `Stored`: assigned to exactly one storage slot;
- `Loaded`: assigned to exactly one material slot; or
- `Unlocated`: assigned to no slot because its physical location is unknown or
  its recorded assignment requires correction.

`Consumed` and `Retired` are archived states and never occupy a slot. Every
storage slot and material slot contains at most one spool. A material slot
belongs to exactly one material unit, such as an automatic material system or a
single-spool holder. Printers and the attachment of material units to printers
are not part of the inventory model; physically moving a loaded material unit
therefore requires no inventory action.

### Registration and normal movement

Registering a spool requires its identity and material data plus a positive
remaining quantity in whole grams. The same confirmed operation may leave it
Unlocated or assign it to an unoccupied storage slot or material slot.

The normal movement graph is:

- `Unlocated -> Stored` or `Unlocated -> Loaded`: place;
- `Stored -> Loaded`: check out;
- `Loaded -> Stored`: check in;
- `Stored -> Stored`: change storage slot; and
- `Loaded -> Loaded`: change material slot.

A normal move requires an unoccupied destination, vacates the source, and
assigns the destination atomically. Leaving a material slot requires the
hobbyist to confirm or update the remaining quantity. A pure storage move does
not change it. Moving a Stored or Loaded spool to Unlocated is available only
as an explicit correction, not as a normal movement.

### Quantity, archival, and restoration

An active spool always has a positive remaining quantity. It can be corrected
without moving the spool. Entering zero does not silently persist an active
zero-gram spool; it opens an explicit consumption confirmation. `Consume` can
start from any active state, records zero grams, vacates any occupied slot, and
enters `Consumed`.

`Retire` can also start from any active state. It records why the spool was
damaged, lost, or deliberately removed, preserves the last known quantity,
vacates any occupied slot, and enters `Retired`. That historical quantity may
be corrected without restoring the spool.

Mistaken archival is reversible only through `Restore`. Restoration always
ends in `Unlocated` and never reclaims the former slot. Restoring a Consumed
spool requires a new positive quantity; restoring a Retired spool confirms or
corrects its positive quantity.

### Conflicts and recovery

Normal movement to an occupied destination is blocked, and no implicit swap
occurs. `Correct assignment` is the explicit exception: after showing both
affected spools and receiving confirmation, it atomically vacates the selected
spool's recorded source, changes the destination's recorded occupant to
Unlocated, and assigns the selected spool to the destination. Two such
corrections can represent a real-world swap without inventing a swap rule.

No separate bulk-audit mode is required for the MVP. Inventory drift is
repaired with composable actions: mark a missing spool Unlocated, correct a
found spool's assignment, register an unknown physical spool, correct its
quantity, retire a spool that is gone, or restore one archived by mistake.
Unlocated spools remain visible as unresolved discrepancies.

Storage slots and material slots can be archived only while unoccupied. A
material unit can be archived only while all its slots are unoccupied; doing
so hides the unit and its slots without changing each slot's individual
archive status. Restoring the unit restores the visibility of slots that were
not individually archived. Locations are archived rather than permanently
deleted, and renaming or changing a storage-area label never changes
occupancy.

### NFC and confirmation

A storage slot may have zero or more interchangeable physical tags. Every tag
contains the same stable storage-slot identifier; individual tags are not
inventoried and duplicate physical tags for one slot are valid aliases.
Registering a tag explicitly writes the selected slot's identifier and changes
no spool state or occupancy. A lost tag needs no inventory repair, and another
tag may be registered with the same identifier.

The canonical NDEF payload is one well-known HTTPS URI record of the form
`https://<stable-owned-domain-or-subdomain>/s#v1.<storage-slot-id>`, configured
as an Android App Link and a future iOS Universal Link. The static public host
contains platform association files and a fallback page but no account, API,
cloud inventory, or server-side identifier mapping.

On Android 16, scanning a valid FilaManager tag while the device is unlocked
can cold-start or foreground the app. Android 17 requires an open-link
notification and user tap; a future iOS release likewise uses a notification
and tap. Locked devices, force-stopped apps, and user-disabled link handling
may require manual launch. A foreign, blank, or malformed tag cannot launch
FilaManager. A syntactically valid FilaManager link whose identifier is absent
from local data opens `Unknown storage slot`.

Every scan or deep link only navigates to a read-only local slot context. It
never reserves a slot or changes inventory. Every operation remains available
without NFC and commits atomically only after its final in-app confirmation.
Cancellation, repeated delivery, app termination, an interrupted NFC session,
or a failed tag write leaves inventory unchanged.

Research: [Launching FilaManager from a storage-slot tag](../research/launch-app-from-storage-slot-tag.md)
