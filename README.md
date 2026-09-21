# FilaManager

FilaManager is a local-first Flutter application for tracking filament spools,
storage slots, and material slots. Android is the first release target. The
application ID is `de.vibesolutions.filamanager` and the Android build targets
API 36.

The current increment provides the production application shell, a versioned
local inventory store, and application-owned NFC and incoming-link boundaries.
Inventory, NFC, and link behavior is added through those boundaries in later
increments.

## Prerequisites

- Flutter 3.47.5 or a compatible stable release
- Android SDK 36 or newer
- An Android device or emulator for integration tests and launch checks

Install dependencies after a clean checkout:

```sh
flutter pub get
```

## Quality checks

Check formatting without modifying files:

```sh
dart format --output=none --set-exit-if-changed lib test integration_test
```

Run static analysis and the complete unit/widget test suite:

```sh
flutter analyze
flutter test
```

Run the app-level integration suite on a connected Android target. Replace
`DEVICE_ID` with an ID shown by `flutter devices`:

```sh
flutter test integration_test/app_smoke_test.dart -d DEVICE_ID
```

Build and launch the Android application:

```sh
flutter build apk --debug
flutter run -d DEVICE_ID
```

The integration harness uses the real versioned JSON inventory store in a
temporary directory and deterministic application-owned NFC and incoming-link
adapters. This keeps the rendered application behavior identical while making
external events repeatable.
