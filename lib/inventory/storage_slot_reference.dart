import 'package:filamanager/inventory/storage_slot_id.dart';

abstract final class StorageSlotReference {
  static const productionHost = 'filamanager.vibesolutions.de';
  static const path = '/s';
  static final _fragmentPattern = RegExp(r'^v1\.([A-Za-z0-9_-]{22})$');

  static StorageSlotId? parse(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != productionHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path != path ||
        uri.hasQuery) {
      return null;
    }

    final value = _fragmentPattern.firstMatch(uri.fragment)?.group(1);
    return value == null ? null : StorageSlotId.tryParse(value);
  }

  static Uri forStorageSlot(StorageSlotId storageSlotId) {
    return Uri(
      scheme: 'https',
      host: productionHost,
      path: path,
      fragment: 'v1.${storageSlotId.value}',
    );
  }
}
