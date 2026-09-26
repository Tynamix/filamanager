import 'dart:convert';
import 'dart:math';

import 'package:filamanager/inventory/filament_spool.dart';
import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/place_id.dart';
import 'package:filamanager/inventory/place_name.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';

final class AppDependencies {
  AppDependencies._({
    required this.inventoryStore,
    required this.inventory,
    required this.nfcService,
    required this.incomingLinkService,
    required this.initialIncomingLink,
    required this._storageSlotIdGenerator,
    required this._spoolIdGenerator,
  });

  final InventoryStore inventoryStore;
  InventoryDocument inventory;
  final NfcService nfcService;
  final IncomingLinkService incomingLinkService;
  final Uri? initialIncomingLink;
  final StorageSlotId Function() _storageSlotIdGenerator;
  final FilamentSpoolId Function() _spoolIdGenerator;

  Future<StorageSlot> createStorageSlot(String name, {String? area}) async {
    final displayName = _validName(name, 'Storage-slot name');
    final displayArea = _optionalArea(area);
    if (_hasActiveStorageName(displayName, displayArea)) {
      throw const PlaceValidationException(
        'A storage slot with this name already exists in this storage area.',
      );
    }
    final storageSlot = StorageSlot(
      id: _storageSlotIdGenerator(),
      name: displayName,
      area: displayArea,
    );
    final updatedInventory = inventory.copyWith(
      storageSlots: [...inventory.storageSlots, storageSlot],
    );
    await _saveInventory(updatedInventory);
    return storageSlot;
  }

  Future<StorageSlot> renameStorageSlot(
    StorageSlotId id,
    String name, {
    String? area,
  }) async {
    final displayName = _validName(name, 'Storage-slot name');
    final displayArea = _optionalArea(area);
    final index = inventory.storageSlots.indexWhere((slot) => slot.id == id);
    if (index < 0) {
      throw const PlaceValidationException('Storage slot no longer exists.');
    }
    if (!inventory.storageSlots[index].archived &&
        _hasActiveStorageName(displayName, displayArea, except: id)) {
      throw const PlaceValidationException(
        'A storage slot with this name already exists in this storage area.',
      );
    }
    final renamed = inventory.storageSlots[index].copyWith(
      name: displayName,
      area: displayArea,
    );
    final slots = [...inventory.storageSlots];
    slots[index] = renamed;
    final updatedInventory = inventory.copyWith(storageSlots: slots);
    await _saveInventory(updatedInventory);
    return renamed;
  }

  Future<MaterialUnit> createMaterialUnit(
    String name,
    List<String> slotNames,
  ) async {
    final displayName = _validName(name, 'Material-unit name');
    if (slotNames.isEmpty) {
      throw const PlaceValidationException('Add at least one material slot.');
    }
    if (_hasActiveMaterialUnitName(displayName)) {
      throw const PlaceValidationException(
        'A material unit with this name already exists.',
      );
    }
    final names = slotNames
        .map((slot) => _validName(slot, 'Material-slot name'))
        .toList();
    if (names.map(placeNameKey).toSet().length != names.length) {
      throw const PlaceValidationException(
        'Material-slot names must be unique within the material unit.',
      );
    }
    final unit = MaterialUnit(
      id: PlaceId.parse(_newOpaqueId().value),
      name: displayName,
      slots: [
        for (final slotName in names)
          MaterialSlot(id: PlaceId.parse(_newOpaqueId().value), name: slotName),
      ],
    );
    final updatedInventory = inventory.copyWith(
      materialUnits: [...inventory.materialUnits, unit],
    );
    await _saveInventory(updatedInventory);
    return unit;
  }

  Future<MaterialUnit> renameMaterialUnit(
    PlaceId id,
    String name, {
    Map<PlaceId, String> slotNames = const {},
  }) async {
    final displayName = _validName(name, 'Material-unit name');
    final index = inventory.materialUnits.indexWhere((unit) => unit.id == id);
    if (index < 0) {
      throw const PlaceValidationException('Material unit no longer exists.');
    }
    if (!inventory.materialUnits[index].archived &&
        _hasActiveMaterialUnitName(displayName, except: id)) {
      throw const PlaceValidationException(
        'A material unit with this name already exists.',
      );
    }
    final original = inventory.materialUnits[index];
    if (slotNames.keys.any(
      (slotId) => !original.slots.any((slot) => slot.id == slotId),
    )) {
      throw const PlaceValidationException('Material slot no longer exists.');
    }
    final slots = [
      for (final slot in original.slots)
        slot.renamed(
          _validName(slotNames[slot.id] ?? slot.name, 'Material-slot name'),
        ),
    ];
    final activeNames = [
      for (final slot in slots)
        if (!slot.archived) placeNameKey(slot.name),
    ];
    if (activeNames.toSet().length != activeNames.length) {
      throw const PlaceValidationException(
        'Material-slot names must be unique within the material unit.',
      );
    }
    final renamed = original.renamed(displayName, slots);
    final units = [...inventory.materialUnits];
    units[index] = renamed;
    final updatedInventory = inventory.copyWith(materialUnits: units);
    await _saveInventory(updatedInventory);
    return renamed;
  }

  Future<void> _saveInventory(InventoryDocument updated) async {
    await inventoryStore.save(updated);
    inventory = updated;
  }

  bool _hasActiveStorageName(
    String name,
    String? area, {
    StorageSlotId? except,
  }) {
    final nameKey = placeNameKey(name);
    final areaKey = placeNameKey(area ?? '');
    return inventory.storageSlots.any(
      (slot) =>
          !slot.archived &&
          slot.id != except &&
          placeNameKey(slot.name) == nameKey &&
          placeNameKey(slot.area ?? '') == areaKey,
    );
  }

  bool _hasActiveMaterialUnitName(String name, {PlaceId? except}) {
    final nameKey = placeNameKey(name);
    return inventory.materialUnits.any(
      (unit) =>
          !unit.archived &&
          unit.id != except &&
          placeNameKey(unit.name) == nameKey,
    );
  }

  static String _validName(String value, String label) {
    final name = value.trim();
    if (name.isEmpty) {
      throw PlaceValidationException('$label is required.');
    }
    if (name.runes.length > 80 ||
        name.runes.any((rune) => rune < 32 || (rune >= 127 && rune <= 159))) {
      throw PlaceValidationException(
        '$label must be at most 80 characters without control characters.',
      );
    }
    return name;
  }

  static String? _optionalArea(String? area) {
    if (area == null || area.trim().isEmpty) return null;
    return _validName(area, 'Storage area');
  }

  Future<FilamentSpool> registerUnlocatedSpool(
    SpoolRegistration registration,
  ) async {
    FilamentSpoolId? newId;
    for (var attempt = 0; attempt < 32; attempt++) {
      final candidate = _spoolIdGenerator();
      if (!inventory.filamentSpools.any((spool) => spool.id == candidate)) {
        newId = candidate;
        break;
      }
    }
    if (newId == null) {
      throw StateError('Could not create a unique filament-spool identity.');
    }
    final spool = FilamentSpool.registerUnlocated(
      id: newId,
      registration: registration,
      occurredAt: DateTime.now().toUtc(),
    );
    final updatedInventory = inventory.copyWith(
      filamentSpools: [...inventory.filamentSpools, spool],
    );
    await _saveInventory(updatedInventory);
    return spool;
  }

  Future<FilamentSpool> editSpoolDetails(
    FilamentSpoolId id,
    SpoolDescription description,
  ) async {
    final index = inventory.filamentSpools.indexWhere(
      (spool) => spool.id == id,
    );
    if (index < 0) {
      throw StateError('Filament spool no longer exists.');
    }
    final updatedSpool = inventory.filamentSpools[index].withDescription(
      description,
    );
    final updatedSpools = [...inventory.filamentSpools];
    updatedSpools[index] = updatedSpool;
    final updatedInventory = inventory.copyWith(filamentSpools: updatedSpools);
    await _saveInventory(updatedInventory);
    return updatedSpool;
  }

  static StorageSlotId _newOpaqueId() {
    return StorageSlotId.parse(_newOpaqueToken());
  }

  static FilamentSpoolId _newSpoolId() {
    return FilamentSpoolId.parse(_newOpaqueToken());
  }

  static String _newOpaqueToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Future<AppDependencies> initialize({
    required InventoryStore inventoryStore,
    required NfcService nfcService,
    required IncomingLinkService incomingLinkService,
    StorageSlotId Function() storageSlotIdGenerator = _newOpaqueId,
    FilamentSpoolId Function()? spoolIdGenerator,
  }) async {
    final inventory = await inventoryStore.open();
    final initialIncomingLink = await incomingLinkService.takeInitialLink();

    return AppDependencies._(
      inventoryStore: inventoryStore,
      inventory: inventory,
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
      initialIncomingLink: initialIncomingLink,
      storageSlotIdGenerator: storageSlotIdGenerator,
      spoolIdGenerator: spoolIdGenerator ?? _newSpoolId,
    );
  }
}

final class PlaceValidationException implements Exception {
  const PlaceValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}
