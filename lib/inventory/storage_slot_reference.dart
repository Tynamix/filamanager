import 'package:filamanager/inventory/storage_slot_id.dart';

abstract final class StorageSlotReference {
  static const productionHost = 'filamanager.vibesolutions.de';
  static const path = '/s';
  static const _fragmentPrefix = 'v1.';

  static StorageSlotId? parse(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != productionHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path != path ||
        uri.hasQuery) {
      return null;
    }

    if (!uri.fragment.startsWith(_fragmentPrefix)) {
      return null;
    }
    return StorageSlotId.tryParse(
      uri.fragment.substring(_fragmentPrefix.length),
    );
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
