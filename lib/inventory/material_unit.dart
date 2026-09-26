import 'package:filamanager/inventory/place_id.dart';

final class MaterialSlot {
  const MaterialSlot({
    required this.id,
    required this.name,
    this.archived = false,
    this.occupantId,
  });

  final PlaceId id;
  final String name;
  final bool archived;
  final String? occupantId;

  MaterialSlot renamed(String name) => MaterialSlot(
    id: id,
    name: name,
    archived: archived,
    occupantId: occupantId,
  );

  Map<String, Object> toJson() {
    final json = <String, Object>{
      'id': id.value,
      'name': name,
      'archived': archived,
    };
    if (occupantId != null) json['occupantId'] = occupantId!;
    return json;
  }

  static MaterialSlot fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final archived = json['archived'] ?? false;
    final occupantId = json['occupantId'];
    if (id is! String ||
        name is! String ||
        archived is! bool ||
        (occupantId != null && occupantId is! String)) {
      throw const FormatException('Invalid material slot.');
    }
    return MaterialSlot(
      id: PlaceId.parse(id),
      name: name,
      archived: archived,
      occupantId: occupantId as String?,
    );
  }
}

final class MaterialUnit {
  const MaterialUnit({
    required this.id,
    required this.name,
    required this.slots,
    this.archived = false,
  });

  final PlaceId id;
  final String name;
  final List<MaterialSlot> slots;
  final bool archived;

  Iterable<MaterialSlot> get activeSlots =>
      slots.where((slot) => !slot.archived);

  MaterialUnit renamed(String name, List<MaterialSlot> slots) =>
      MaterialUnit(id: id, name: name, slots: slots, archived: archived);

  Map<String, Object> toJson() => {
    'id': id.value,
    'name': name,
    'archived': archived,
    'slots': [for (final slot in slots) slot.toJson()],
  };

  static MaterialUnit fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final archived = json['archived'] ?? false;
    final slots = json['slots'];
    if (id is! String ||
        name is! String ||
        archived is! bool ||
        slots is! List ||
        slots.isEmpty) {
      throw const FormatException('Invalid material unit.');
    }
    return MaterialUnit(
      id: PlaceId.parse(id),
      name: name,
      archived: archived,
      slots: [
        for (final slot in slots)
          if (slot is Map<String, dynamic>)
            MaterialSlot.fromJson(slot)
          else
            throw const FormatException('Invalid material slot entry.'),
      ],
    );
  }
}
