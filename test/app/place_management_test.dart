import 'dart:io';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_smoke_suite.dart';

void main() {
  test(
    'storage slots use an optional area and reject duplicate active names',
    () async {
      final directory = await Directory.systemTemp.createTemp('places-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/inventory.json');
      final nfc = FakeNfcService();
      final links = FakeIncomingLinkService();
      addTearDown(nfc.close);
      addTearDown(links.close);
      final ids = [
        'AbCdEfGhIjKlMnOpQrStUv',
        'ZyXwVuTsRqPoNmLkJiHgFe',
        'AaBbCcDdEeFfGgHhIiJjKk',
      ].iterator;
      final app = await AppDependencies.initialize(
        inventoryStore: JsonInventoryStore(file),
        nfcService: nfc,
        incomingLinkService: links,
        storageSlotIdGenerator: () {
          ids.moveNext();
          return StorageSlotId.parse(ids.current);
        },
      );

      final shelf = await app.createStorageSlot(
        '  Shelf 01  ',
        area: '  Workshop  ',
      );
      expect(shelf.name, 'Shelf 01');
      expect(shelf.area, 'Workshop');
      await expectLater(
        app.createStorageSlot('sHeLf 01', area: ' workshop '),
        throwsA(isA<PlaceValidationException>()),
      );
      expect(app.inventory.storageSlots, hasLength(1));
      final other = await app.createStorageSlot('SHELF 01', area: 'Basement');
      expect(other.area, 'Basement');

      final reopened = await JsonInventoryStore(file).open();
      expect(reopened.storageSlots.map((slot) => slot.name), [
        'Shelf 01',
        'SHELF 01',
      ]);
      expect(reopened.storageSlots.map((slot) => slot.area), [
        'Workshop',
        'Basement',
      ]);
    },
  );

  test(
    'renaming and regrouping a storage slot keeps identity and occupancy',
    () async {
      final directory = await Directory.systemTemp.createTemp('places-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/inventory.json');
      final store = JsonInventoryStore(file);
      final id = StorageSlotId.parse('AbCdEfGhIjKlMnOpQrStUv');
      await store.save(
        InventoryDocument(
          schemaVersion: 1,
          storageSlots: [
            StorageSlot(
              id: id,
              name: 'Shelf A',
              area: 'Workshop',
              occupantId: 'spool-1',
            ),
          ],
        ),
      );
      final nfc = FakeNfcService();
      final links = FakeIncomingLinkService();
      addTearDown(nfc.close);
      addTearDown(links.close);
      final app = await AppDependencies.initialize(
        inventoryStore: store,
        nfcService: nfc,
        incomingLinkService: links,
      );

      final renamed = await app.renameStorageSlot(id, ' Shelf B ', area: null);
      expect(renamed.id, id);
      expect(renamed.name, 'Shelf B');
      expect(renamed.area, isNull);
      expect(renamed.occupantId, 'spool-1');
      final reopened = await JsonInventoryStore(file).open();
      expect(reopened.storageSlots.single.id, id);
      expect(reopened.storageSlots.single.occupantId, 'spool-1');
      expect(reopened.storageSlots.single.area, isNull);
    },
  );

  test('material units contain named slots with scoped active names', () async {
    final directory = await Directory.systemTemp.createTemp('places-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/inventory.json');
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: JsonInventoryStore(file),
      nfcService: nfc,
      incomingLinkService: links,
    );

    final unit = await app.createMaterialUnit('  AMS  ', [' Left ', 'Right']);
    expect(unit.name, 'AMS');
    expect(unit.slots.map((slot) => slot.name), ['Left', 'Right']);
    await expectLater(
      app.createMaterialUnit('ams', ['Single']),
      throwsA(isA<PlaceValidationException>()),
    );
    await expectLater(
      app.createMaterialUnit('Holder', ['Single', ' single ']),
      throwsA(isA<PlaceValidationException>()),
    );
    await expectLater(
      app.createMaterialUnit('Holder', []),
      throwsA(isA<PlaceValidationException>()),
    );
    final holder = await app.createMaterialUnit('Holder', ['Single']);
    expect(holder.slots.single.name, 'Single');
    expect((await JsonInventoryStore(file).open()).materialUnits, hasLength(2));
  });

  test('renaming a material unit and its slots keeps their identities and occupants', () async {
    final directory = await Directory.systemTemp.createTemp('places-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/inventory.json');
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: JsonInventoryStore(file),
      nfcService: nfc,
      incomingLinkService: links,
    );
    final unit = await app.createMaterialUnit('AMS', ['A', 'B']);

    await expectLater(
      app.renameMaterialUnit(
        unit.id,
        'AMS 2',
        slotNames: {unit.slots[0].id: 'B'},
      ),
      throwsA(isA<PlaceValidationException>()),
    );
    expect(
      (await JsonInventoryStore(file).open()).materialUnits.single.name,
      'AMS',
    );
    final renamed = await app.renameMaterialUnit(
      unit.id,
      ' AMS 2 ',
      slotNames: {unit.slots[0].id: 'Left'},
    );
    expect(renamed.id, unit.id);
    expect(
      renamed.slots.map((slot) => slot.id),
      unit.slots.map((slot) => slot.id),
    );
    expect(renamed.slots.map((slot) => slot.name), ['Left', 'B']);
    final reopened = (await JsonInventoryStore(
      file,
    ).open()).materialUnits.single;
    expect(reopened.name, 'AMS 2');
    expect(reopened.slots.map((slot) => slot.name), ['Left', 'B']);
  });

  test('archived storage slots do not compete for active names', () async {
    final directory = await Directory.systemTemp.createTemp('places-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/inventory.json');
    final archivedId = StorageSlotId.parse('AbCdEfGhIjKlMnOpQrStUv');
    final activeId = StorageSlotId.parse('ZyXwVuTsRqPoNmLkJiHgFe');
    final store = JsonInventoryStore(file);
    await store.save(
      InventoryDocument(
        schemaVersion: JsonInventoryStore.currentSchemaVersion,
        storageSlots: [
          StorageSlot(
            id: archivedId,
            name: 'Old',
            area: 'Workshop',
            archived: true,
          ),
          StorageSlot(id: activeId, name: 'Shelf', area: 'Workshop'),
        ],
      ),
    );
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: store,
      nfcService: nfc,
      incomingLinkService: links,
    );

    final renamed = await app.renameStorageSlot(
      archivedId,
      'Shelf',
      area: 'Workshop',
    );
    expect(renamed.archived, isTrue);
    expect(renamed.name, 'Shelf');
    expect((await JsonInventoryStore(file).open()).storageSlots, hasLength(2));
  });
}
