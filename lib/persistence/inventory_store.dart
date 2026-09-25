abstract interface class InventoryStore {
  Future<InventoryDocument> open();
}

final class InventoryDocument {
  const InventoryDocument({required this.schemaVersion});

  final int schemaVersion;
}
