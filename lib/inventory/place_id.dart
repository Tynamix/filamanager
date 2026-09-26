import 'package:filamanager/inventory/storage_slot_id.dart';

final class PlaceId {
  const PlaceId._(this.value);

  final String value;

  factory PlaceId.parse(String value) {
    StorageSlotId.parse(value);
    return PlaceId._(value);
  }

  @override
  bool operator ==(Object other) => other is PlaceId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
