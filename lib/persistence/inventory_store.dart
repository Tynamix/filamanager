import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/storage_slot.dart';

abstract interface class InventoryStore {
  Future<InventoryDocument> open();

  Future<void> save(InventoryDocument inventory);
}

final class InventoryDocument {
  const InventoryDocument({
    required this.schemaVersion,
    this.storageSlots = const [],
    this.materialUnits = const [],
  });

  final int schemaVersion;
  final List<StorageSlot> storageSlots;
  final List<MaterialUnit> materialUnits;

  InventoryDocument copyWith({
    List<StorageSlot>? storageSlots,
    List<MaterialUnit>? materialUnits,
  }) {
    return InventoryDocument(
      schemaVersion: schemaVersion,
      storageSlots: storageSlots ?? this.storageSlots,
      materialUnits: materialUnits ?? this.materialUnits,
    );
  }
}
