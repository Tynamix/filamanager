# What local data and backup contract keeps the inventory recoverable?

Type: grilling
Status: resolved
Blocked by: 03

## Question

What information and invariants must the local data model preserve for filament spools, storage slots, storage areas, material units, material slots, state transitions, and archived records?

Define stable identities, required and optional spool attributes, uniqueness and occupancy constraints, history requirements, deletion rules, and the user-visible export/import contract. Decide how backup replacement, validation, schema versioning, corrupt files, and imports into a non-empty inventory should behave without introducing accounts or cloud synchronization.

## Answer

### Local inventory and authority

One installation manages exactly one local inventory. The current entity records
are the source of truth; the history supplements them and is not an
event-sourced reconstruction mechanism. The eventual specification may choose
the local persistence technology as long as it enforces this contract.

Filament spools, storage slots, material units, and material slots each have an
opaque, stable internal identity. An identity never changes or gets reused.
Storage areas are optional free-form labels on storage slots rather than
separate entities. They provide grouping without creating another hierarchy or
lifecycle.

The occupancy and state invariants resolved in [What are the complete spool
movement and recovery rules?](03-define-spool-movement-and-recovery-rules.md)
remain authoritative: an active filament spool is Stored, Loaded, or
Unlocated; a Stored or Loaded spool has exactly one compatible assignment; and
each storage slot or material slot has at most one occupant. Confirmed changes
update all affected records and history atomically.

### Filament-spool data

Every filament spool requires:

- a material type selected from suggestions or entered as a custom value;
- one representative filament color selected with a color picker and stored as
  a normalized `#RRGGBB` value, including for multicolored or transparent
  filament; and
- a positive remaining quantity in whole grams while active.

A spool label, manufacturer, product name, original nominal quantity, and notes
are optional. Diameter is not tracked. The app does not generate a visible
inventory number. When otherwise identical spools need to be distinguished,
the hobbyist is responsible for adding an optional spool label. Special visual
properties may likewise be described in the label or notes.

Spool labels need not be unique. Active material-unit names are unique;
material-slot names are unique within their material unit; and storage-slot
names are unique within their optional storage-area label. Uniqueness checks
ignore surrounding whitespace and letter case while preserving the chosen
display spelling. Archived records do not reserve visible names. Restoring an
archived storage slot or material unit is blocked until the hobbyist resolves
any active-name conflict; its internal identity never changes.

### History, archival, and deletion

Registration, movement, remaining-quantity changes, corrections, consumption,
retirement, and restoration append immutable history entries. Each entry
records its time, action, affected stable identities, and relevant before and
after values. Corrections create new entries rather than rewriting history, and
the history is not a general undo mechanism. Pure edits to descriptive fields
such as the spool label, filament color, manufacturer, product name, or notes
need preserve only the current value.

History is retained permanently, including for archived filament spools, and
is shown chronologically in the corresponding spool details. The MVP does not
need a global activity feed.

Domain records are never permanently deleted. Filament spools enter Consumed
or Retired; storage slots and material slots can be archived only while empty;
and material units can be archived only while all their slots are empty. An
accidentally registered spool is Retired rather than erased. Unused
storage-area labels disappear naturally because they are values, not records.

### Versioning and failure behavior

The local representation carries a schema version and supports forward app
updates through atomic migrations. A failed migration or unreadable local
store must preserve the previous data, block further inventory mutations, and
present a clear retry or diagnostic state. The app never silently clears or
recreates the inventory. A destructive reset requires explicit confirmation.

This contract does not choose a database, object store, or file format.

### Deferred backup contract

User-visible export, import, backup restoration, device transfer, merging, and
imports into non-empty inventories are not part of the MVP. They can follow the
four-week personal validation; their format and conflict semantics are
therefore deliberately undecided rather than constrained prematurely.
