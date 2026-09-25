import 'package:filamanager/inventory/storage_slot.dart';

abstract interface class InventoryStore {
  Future<InventoryDocument> open();

  Future<void> save(InventoryDocument inventory);
}

final class InventoryDocument {
  const InventoryDocument({
    required this.schemaVersion,
    this.storageSlots = const [],
  });

  final int schemaVersion;
  final List<StorageSlot> storageSlots;

  InventoryDocument copyWith({List<StorageSlot>? storageSlots}) {
    return InventoryDocument(
      schemaVersion: schemaVersion,
      storageSlots: storageSlots ?? this.storageSlots,
    );
  }
}
