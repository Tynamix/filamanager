final class StorageSlot {
  const StorageSlot({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object> toJson() => <String, Object>{'id': id, 'name': name};

  static StorageSlot fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Invalid storage slot.');
    }

    return StorageSlot(id: id, name: name);
  }
}
