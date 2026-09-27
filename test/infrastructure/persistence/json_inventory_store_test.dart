import 'dart:convert';
import 'dart:io';

import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a current inventory and reopens it', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'filamanager-store-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final file = File('${temporaryDirectory.path}/inventory.json');

    final firstOpen = await JsonInventoryStore(file).open();
    final reopened = await JsonInventoryStore(file).open();
    final stored =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    expect(firstOpen.storageSlots, isEmpty);
    expect(reopened.materialUnits, isEmpty);
    expect(reopened.filamentSpools, isEmpty);
    expect(
      stored.keys,
      containsAll(['storageSlots', 'materialUnits', 'filamentSpools']),
    );
    expect(stored.containsKey('schemaVersion'), isFalse);
  });
}
