#!/usr/bin/env bash

set -euo pipefail

prototype_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_dir="$prototype_dir/app"

if ! command -v flutter >/dev/null 2>&1; then
  printf '%s\n' \
    'Flutter is required but was not found on PATH.' \
    'Install the current stable Flutter SDK, then run this command again.' \
    'Setup guide: https://docs.flutter.dev/get-started/install'
  exit 1
fi

if [[ ! -f "$app_dir/pubspec.yaml" ]]; then
  flutter create \
    --platforms=android,ios \
    --org app.filamanager \
    --project-name nfc_tag_spike \
    "$app_dir"
fi

cp "$prototype_dir/lib/main.dart" "$app_dir/lib/main.dart"

manifest="$app_dir/android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.NFC' "$manifest"; then
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.NFC" />\n    <uses-feature android:name="android.hardware.nfc" android:required="false" />#' "$manifest"
fi

info_plist="$app_dir/ios/Runner/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :NFCReaderUsageDescription string Scan and update filament storage slots.' "$info_plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c 'Set :NFCReaderUsageDescription Scan and update filament storage slots.' "$info_plist"

cp "$prototype_dir/Runner.entitlements" "$app_dir/ios/Runner/Runner.entitlements"

for config in Debug Release; do
  xcconfig="$app_dir/ios/Flutter/$config.xcconfig"
  if ! grep -q '^CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements$' "$xcconfig"; then
    printf '\n%s\n' 'CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements' >> "$xcconfig"
  fi
done

(
  cd "$app_dir"
  flutter pub add nfc_manager:4.2.1 nfc_manager_ndef:1.1.0
  flutter run "$@"
)
