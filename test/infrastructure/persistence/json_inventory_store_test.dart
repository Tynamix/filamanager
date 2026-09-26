import 'dart:convert';
import 'dart:io';

import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'creates the current schema and reopens it with a new store instance',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'filamanager-store-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final file = File('${temporaryDirectory.path}/inventory.json');

      final firstOpen = await JsonInventoryStore(file).open();
      final reopened = await JsonInventoryStore(file).open();

      expect(firstOpen.schemaVersion, JsonInventoryStore.currentSchemaVersion);
      expect(reopened.schemaVersion, JsonInventoryStore.currentSchemaVersion);
    },
  );

  test('save stamps the current schema on every persisted document', () async {
    final directory = await Directory.systemTemp.createTemp(
      'filamanager-schema-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/inventory.json');

    await JsonInventoryStore(file)
        .save(const InventoryDocument(schemaVersion: 1));

    final stored =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(stored['schemaVersion'], JsonInventoryStore.currentSchemaVersion);
  });

  test('opens a genuine v1 payload and upgrades it on the next save', () async {
    final directory = await Directory.systemTemp.createTemp(
      'filamanager-v1-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/inventory.json');
    const id = 'AbCdEfGhIjKlMnOpQrStUv';
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'storageSlots': [
          {'id': id, 'name': 'Shelf A'},
        ],
      }),
    );

    final store = JsonInventoryStore(file);
    final inventory = await store.open();
    expect(inventory.schemaVersion, JsonInventoryStore.currentSchemaVersion);
    expect(inventory.materialUnits, isEmpty);
    expect(inventory.storageSlots.single.id.value, id);
    expect(inventory.storageSlots.single.area, isNull);
    expect(inventory.storageSlots.single.archived, isFalse);
    expect(inventory.storageSlots.single.occupantId, isNull);

    await store.save(inventory);
    final upgraded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(upgraded['schemaVersion'], JsonInventoryStore.currentSchemaVersion);
    expect(upgraded['materialUnits'], isEmpty);
    expect((upgraded['storageSlots'] as List).single['id'], id);
  });
}
