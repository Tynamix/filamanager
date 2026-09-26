import 'dart:convert';
import 'dart:io';

import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/persistence/inventory_store.dart';

final class JsonInventoryStore implements InventoryStore {
  JsonInventoryStore(this.file);

  static const currentSchemaVersion = 2;

  final File file;
  Future<InventoryDocument>? _opening;

  @override
  Future<InventoryDocument> open() => _opening ??= _open();

  Future<InventoryDocument> _open() async {
    if (!await file.exists()) {
      await _createEmptyStore();
    }

    final contents = await file.readAsString();
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Inventory store must contain a JSON object.',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int ||
        (schemaVersion != 1 && schemaVersion != currentSchemaVersion)) {
      throw FormatException('Unsupported inventory schema: $schemaVersion');
    }

    final storageSlotsJson = decoded['storageSlots'] ?? const <Object>[];
    if (storageSlotsJson is! List) {
      throw const FormatException('Inventory storage slots must be a list.');
    }
    final materialUnitsJson = decoded['materialUnits'] ?? const <Object>[];
    if (materialUnitsJson is! List) {
      throw const FormatException('Inventory material units must be a list.');
    }

    return InventoryDocument(
      schemaVersion: currentSchemaVersion,
      storageSlots: [
        for (final storageSlotJson in storageSlotsJson)
          if (storageSlotJson is Map<String, dynamic>)
            StorageSlot.fromJson(storageSlotJson)
          else
            throw const FormatException('Invalid storage slot entry.'),
      ],
      materialUnits: [
        for (final unitJson in materialUnitsJson)
          if (unitJson is Map<String, dynamic>)
            MaterialUnit.fromJson(unitJson)
          else
            throw const FormatException('Invalid material unit entry.'),
      ],
    );
  }

  @override
  Future<void> save(InventoryDocument inventory) async {
    await file.parent.create(recursive: true);
    final temporaryFile = File('${file.path}.tmp');
    final contents = jsonEncode(<String, Object>{
      'schemaVersion': inventory.schemaVersion,
      'storageSlots': [
        for (final storageSlot in inventory.storageSlots) storageSlot.toJson(),
      ],
      'materialUnits': [
        for (final unit in inventory.materialUnits) unit.toJson(),
      ],
    });
    await temporaryFile.writeAsString(contents, flush: true);
    await temporaryFile.rename(file.path);
  }

  Future<void> _createEmptyStore() async {
    await save(const InventoryDocument(schemaVersion: currentSchemaVersion));
  }
}
