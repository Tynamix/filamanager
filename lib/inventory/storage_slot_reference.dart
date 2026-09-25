abstract final class StorageSlotReference {
  static const productionHost = 'filamanager.vibesolutions.de';
  static const path = '/s';
  static final _fragmentPattern = RegExp(r'^v1\.([A-Za-z0-9_-]{22})$');

  static String? parse(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != productionHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path != path ||
        uri.hasQuery) {
      return null;
    }

    return _fragmentPattern.firstMatch(uri.fragment)?.group(1);
  }

  static Uri forStorageSlotId(String storageSlotId) {
    if (!_isValidIdentifier(storageSlotId)) {
      throw ArgumentError.value(
        storageSlotId,
        'storageSlotId',
        'must be a 22-character unpadded base64url value',
      );
    }

    return Uri(
      scheme: 'https',
      host: productionHost,
      path: path,
      fragment: 'v1.$storageSlotId',
    );
  }

  static bool _isValidIdentifier(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value);
  }
}
