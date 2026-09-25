import 'dart:io';

import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
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
}
