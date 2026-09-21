# Filament Inventory

This context describes the physical filament inventory managed by an individual 3D-printing hobbyist.

## Language

**Hobbyist**:
A single person who owns and manages filament spools for personal 3D printing.
_Avoid_: 3D printer, operator

**Filament spool**:
A distinct physical spool of filament whose remaining quantity and current location are tracked independently, including when another roll has identical material properties.
_Avoid_: Filament, inventory entry

**Material type**:
The user-chosen material classification of a filament spool, selected from suggestions or entered as a custom value.
_Avoid_: Material record, material catalog

**Filament color**:
The single representative display color recorded for a filament spool, including when its physical appearance is multicolored or transparent.
_Avoid_: Color name, color catalog

**Spool label**:
An optional user-chosen name that distinguishes a filament spool when its material properties and location are insufficient.
_Avoid_: Inventory number, required name

**Stored**:
The state of a filament spool that occupies a storage slot and is not assigned to a material slot.
_Avoid_: Checked in, available

**Loaded**:
The state of a filament spool that is assigned to a material slot, regardless of whether its material unit is connected to a printer.
_Avoid_: In use, checked out, removed

**Unlocated**:
The active state of a filament spool that is assigned to neither a storage slot nor a material slot because its physical location is unknown or its recorded assignment requires correction.
_Avoid_: In transit

**Active filament spool**:
A filament spool in the Stored, Loaded, or Unlocated state.
_Avoid_: Unarchived spool

**Check out**:
The transition of a filament spool from Stored to Loaded by vacating its storage slot and assigning it to an unoccupied material slot.

**Check in**:
The transition of a filament spool from Loaded to Stored by recording its current remaining quantity and assigning it to an unoccupied storage slot.

**Place**:
The transition of an Unlocated filament spool to Stored or Loaded by assigning it to an unoccupied storage slot or material slot.

**Correct assignment**:
A corrective transition that makes a filament spool's recorded assignment match reality. If the destination has a different recorded occupant, that occupant becomes Unlocated; an implicit swap never occurs.

**Remaining quantity**:
The estimated or weighed net quantity of filament remaining on a filament spool, expressed in grams. It is positive for an active filament spool and zero for a Consumed filament spool.

**Storage slot**:
A permanent storage position that can contain at most one filament spool and may carry an optional storage-area label. Its identity and recorded occupancy do not depend on the availability of an NFC tag. It can be archived only while unoccupied and can later be restored.
_Avoid_: NFC tag, container

**Storage-slot tag**:
A physical NFC tag containing the stable application-owned identifier of one storage slot. A storage slot may have any number of interchangeable storage-slot tags; individual physical tags are not tracked. They provide scan shortcuts but are not the storage slot's identity and are never required for an inventory operation.
_Avoid_: Storage slot, source of truth

**Register tag**:
Write a storage slot's stable identifier to a compatible, writable NFC tag after explicit confirmation. Registration never changes spool state or slot occupancy.

**Unknown tag**:
A scanned NFC tag that does not contain a valid FilaManager storage-slot reference. It can be reported only during an explicit in-app scan and cannot launch FilaManager by itself.

**Unknown storage slot**:
The result of opening a valid FilaManager storage-slot reference whose identifier does not exist in the local inventory. It identifies no usable destination until the tag is registered again or the matching local data is restored.

**Storage area**:
An optional free-form label used to group storage slots without introducing a nested location hierarchy.
_Avoid_: Location tree, folder

**Consumed**:
The archived state of a filament spool with no usable filament remaining and a remaining quantity of zero. Entering this state vacates any assigned slot.

**Retired**:
The archived state of a filament spool that is no longer tracked because it was damaged, lost, or deliberately removed from inventory. Entering this state preserves its last known remaining quantity and vacates any assigned slot.

**Restore**:
The corrective transition of a Consumed or Retired filament spool to Unlocated after mistaken archival. Restoration never reclaims the spool's former slot automatically.

**Material unit**:
A named physical holder or feeder that has one or more material slots, such as an automatic material system or a single-spool holder. Its connection to a printer is not part of the inventory. It can be archived only while all of its material slots are unoccupied and can later be restored.
_Avoid_: Printer, AMS as the generic term

**Material slot**:
A named position in exactly one material unit that can contain at most one filament spool. It can be archived only while unoccupied and can later be restored.
_Avoid_: Feed, AMS slot
