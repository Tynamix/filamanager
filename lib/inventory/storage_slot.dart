import 'package:filamanager/inventory/storage_slot_id.dart';

final class StorageSlot {
  const StorageSlot({
    required this.id,
    required this.name,
    this.area,
    this.archived = false,
    this.occupantId,
  });

  final StorageSlotId id;
  final String name;
  final String? area;
  final bool archived;
  final String? occupantId;

  StorageSlot copyWith({required String name, String? area}) => StorageSlot(
    id: id,
    name: name,
    area: area,
    archived: archived,
    occupantId: occupantId,
  );

  Map<String, Object> toJson() {
    final json = <String, Object>{
      'id': id.value,
      'name': name,
      'archived': archived,
    };
    if (area != null) json['area'] = area!;
    if (occupantId != null) json['occupantId'] = occupantId!;
    return json;
  }

  static StorageSlot fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final area = json['area'];
    final archived = json['archived'];
    final occupantId = json['occupantId'];
    if (id is! String ||
        name is! String ||
        (area != null && area is! String) ||
        archived is! bool ||
        (occupantId != null && occupantId is! String)) {
      throw const FormatException('Invalid storage slot.');
    }

    return StorageSlot(
      id: StorageSlotId.parse(id),
      name: name,
      area: area as String?,
      archived: archived,
      occupantId: occupantId as String?,
    );
  }
}
