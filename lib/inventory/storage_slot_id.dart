final class StorageSlotId {
  const StorageSlotId._(this.value);

  static final _syntax = RegExp(r'^[A-Za-z0-9_-]{22}$');

  final String value;

  factory StorageSlotId.parse(String value) {
    final identity = tryParse(value);
    if (identity == null) {
      throw FormatException('Invalid storage-slot identity: $value');
    }
    return identity;
  }

  static StorageSlotId? tryParse(String value) {
    return _syntax.hasMatch(value) ? StorageSlotId._(value) : null;
  }

  @override
  bool operator ==(Object other) {
    return other is StorageSlotId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
