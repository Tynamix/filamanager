# 29: Keep the pre-Play inventory format unversioned

**What to build:** During development before the first Google Play release, keep one current local inventory format without schema-version metadata or compatibility migrations. Establish this as the rule for future persistence changes.

**Status:** completed

- [x] New inventory files and subsequent saves contain the current storage-slot, material-unit, and filament-spool collections without a schema-version field.
- [x] The app opens the current unversioned format, preserves valid records and history across restart, and accepts an existing complete version-3-shaped file without relying on its obsolete version marker.
- [x] Incomplete or unreadable old local files retain their bytes and enter the existing recovery flow; no inventory is silently cleared or partially reconstructed.
- [x] Remove pre-release migration branches and schema-version fields from the in-memory inventory document.
- [x] Record the pre-Play rule for future agents and update the product spec and pending persistence ticket. Set the first Play build as the gate for establishing the published upgrade contract.

## Comments

- 2026-09-27: The earlier requirement for pre-release schema versions and v1/v2 migrations is superseded by the user's decision to keep local persistence unversioned until the first Play release.
