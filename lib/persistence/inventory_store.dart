import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/filament_spool.dart';
import 'package:filamanager/inventory/storage_slot.dart';

abstract interface class InventoryStore {
  Future<InventoryDocument> open();

  Future<void> save(InventoryDocument inventory);
}

final class InventoryDocument {
  const InventoryDocument({
    this.storageSlots = const [],
    this.materialUnits = const [],
    this.filamentSpools = const [],
  });

  final List<StorageSlot> storageSlots;
  final List<MaterialUnit> materialUnits;
  final List<FilamentSpool> filamentSpools;

  InventoryDocument copyWith({
    List<StorageSlot>? storageSlots,
    List<MaterialUnit>? materialUnits,
    List<FilamentSpool>? filamentSpools,
  }) {
    return InventoryDocument(
      storageSlots: storageSlots ?? this.storageSlots,
      materialUnits: materialUnits ?? this.materialUnits,
      filamentSpools: filamentSpools ?? this.filamentSpools,
    );
  }
}
