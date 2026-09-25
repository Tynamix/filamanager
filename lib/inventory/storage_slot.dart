import 'package:filamanager/inventory/storage_slot_id.dart';

final class StorageSlot {
  const StorageSlot({required this.id, required this.name});

  final StorageSlotId id;
  final String name;

  Map<String, Object> toJson() => <String, Object>{
    'id': id.value,
    'name': name,
  };

  static StorageSlot fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Invalid storage slot.');
    }

    return StorageSlot(id: StorageSlotId.parse(id), name: name);
  }
}
