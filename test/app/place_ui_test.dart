import 'dart:ui' show Tristate;

import 'package:filamanager/app/app.dart';
import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/place_id.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_smoke_suite.dart';

void main() {
  testWidgets('storage-slot guidance and focus follow the guided sheet', (
    tester,
  ) async {
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: FakeInventoryStore(),
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Choose place type'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Storage slot'));
    await tester.pumpAndSettle();
    expect(find.text('Name this storage position.'), findsOneWidget);
    expect(find.text('Add a storage-area label if useful.'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('Create storage slot'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      'Shelf A',
    );
    final review = find.text('Review storage slot');
    await Scrollable.ensureVisible(tester.element(review), alignment: .6);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Create this storage slot?'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Add place')).flagsCollection.isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('material-unit guidance and focus follow the guided sheet', (
    tester,
  ) async {
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: FakeInventoryStore(),
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Material unit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Name the holder and every material slot.'),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.text('Create material unit'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.enterText(find.bySemanticsLabel('Material-unit name'), 'AMS');
    await tester.enterText(
      find.bySemanticsLabel('Material-slot name 1'),
      'Left',
    );
    final review = find.text('Review material unit');
    await Scrollable.ensureVisible(tester.element(review), alignment: .6);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Create this material unit?'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Add place')).flagsCollection.isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('place sheet completion focuses details and edit cancellation', (
    tester,
  ) async {
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: FakeInventoryStore(),
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage slot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      'Shelf A',
    );
    final review = find.text('Review storage slot');
    await Scrollable.ensureVisible(tester.element(review), alignment: .6);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create storage slot'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Shelf A')).flagsCollection.isFocused,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Edit storage slot'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Edit storage slot'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('place fields share the required and active-value hierarchy', (
    tester,
  ) async {
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: FakeInventoryStore(),
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage slot'));
    await tester.pumpAndSettle();

    expect(find.text('REQUIRED DETAILS'), findsOneWidget);
    expect(find.text('OPTIONAL DETAILS'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      'Shelf A',
    );
    final nameField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Storage-slot name',
      ),
    );
    expect(nameField.style?.color, const Color(0xFF18211B));
    expect(nameField.decoration?.labelStyle?.color, const Color(0xFF68736B));
  });

  testWidgets('name conflict is announced and leaves saved places unchanged', (
    tester,
  ) async {
    final store = FakeInventoryStore();
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: store,
      nfcService: nfc,
      incomingLinkService: links,
    );
    await app.createStorageSlot('Shelf A');
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage slot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      ' shelf a ',
    );
    await tester.tap(find.text('Review storage slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create storage slot'));
    await tester.pumpAndSettle();

    const error =
        'A storage slot with this name already exists in this storage area.';
    expect(find.text(error), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text(error)).flagsCollection.isLiveRegion,
      isTrue,
    );
    semantics.dispose();
    expect((await store.open()).storageSlots.map((slot) => slot.name), [
      'Shelf A',
    ]);
  });

  testWidgets('compact Places uses one add action with a place-type choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: FakeInventoryStore(),
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();

    final addPlace = find.widgetWithText(FilledButton, 'Add place');
    expect(addPlace, findsOneWidget);
    expect(find.text('Add storage slot'), findsNothing);
    expect(find.text('Add material unit'), findsNothing);

    for (final width in [320.0, 360.0, 420.0, 700.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpAndSettle();
      expect(addPlace, findsOneWidget);
      expect(tester.getSize(addPlace).width, greaterThan(270));
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(320, 800);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.4;
    await tester.pumpAndSettle();
    expect(addPlace, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(addPlace);
    await tester.pumpAndSettle();
    expect(find.text('Choose place type'), findsOneWidget);
    expect(find.text('Storage slot'), findsOneWidget);
    expect(find.text('Material unit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hobbyist can create and regroup a storage slot without NFC', (
    tester,
  ) async {
    final store = FakeInventoryStore();
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await tester.runAsync(
      () => AppDependencies.initialize(
        inventoryStore: store,
        nfcService: nfc,
        incomingLinkService: links,
      ),
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app!));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage slot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      'Shelf A',
    );
    await tester.enterText(find.bySemanticsLabel('Storage area'), 'Workshop');
    await tester.tap(find.text('Review storage slot'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () =>
          tester.tap(find.widgetWithText(FilledButton, 'Create storage slot')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.bySemanticsLabel('Place status: Active'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);

    await tester.tap(find.text('Edit storage slot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Storage-slot name'),
      'Shelf B',
    );
    await tester.enterText(find.bySemanticsLabel('Storage area'), '');
    await tester.tap(find.text('Review storage slot'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => tester.tap(find.widgetWithText(FilledButton, 'Save storage slot')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shelf B'), findsOneWidget);
    expect(find.text('Workshop'), findsNothing);
    expect(find.text('Storage slot saved'), findsOneWidget);
    expect((await store.open()).storageSlots.single.name, 'Shelf B');
    expect((await store.open()).storageSlots.single.area, isNull);
  });

  testWidgets('hobbyist can create and rename a material unit and its slots', (
    tester,
  ) async {
    final store = FakeInventoryStore();
    final nfc = FakeNfcService();
    final links = FakeIncomingLinkService();
    addTearDown(nfc.close);
    addTearDown(links.close);
    final app = await AppDependencies.initialize(
      inventoryStore: store,
      nfcService: nfc,
      incomingLinkService: links,
    );
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Material unit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Material-unit name'), 'AMS');
    await tester.enterText(
      find.bySemanticsLabel('Material-slot name 1'),
      'Left',
    );
    await tester.tap(find.text('Add material slot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Material-slot name 2'),
      'Right',
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Review material unit')),
      alignment: .6,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review material unit'));
    await tester.pumpAndSettle();
    expect(find.text('REVIEW MATERIAL UNIT'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Create material unit'));
    await tester.pumpAndSettle();
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Material slot · Active · Empty'), findsNWidgets(2));

    await tester.tap(find.text('Edit material unit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Material-unit name'),
      'AMS 2',
    );
    await tester.enterText(
      find.bySemanticsLabel('Material-slot name 2'),
      'Rear',
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Review material unit')),
      alignment: .6,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review material unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save material unit'));
    await tester.pumpAndSettle();
    expect(find.text('AMS 2'), findsOneWidget);
    expect(find.text('Rear'), findsOneWidget);
    expect((await store.open()).materialUnits.single.slots[1].name, 'Rear');
  });

  testWidgets('storage slots with case-varied area labels browse together', (
    tester,
  ) async {
    final store = _SeededInventoryStore(
      InventoryDocument(
        storageSlots: [
          StorageSlot(
            id: StorageSlotId.parse('AbCdEfGhIjKlMnOpQrStUv'),
            name: 'Shelf A',
            area: 'Workshop',
          ),
          StorageSlot(
            id: StorageSlotId.parse('ZyXwVuTsRqPoNmLkJiHgFe'),
            name: 'Shelf B',
            area: 'workshop',
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
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();

    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('workshop'), findsNothing);
    expect(find.text('Shelf A'), findsOneWidget);
    expect(find.text('Shelf B'), findsOneWidget);
  });

  testWidgets('active Places browsing hides archived places', (tester) async {
    final store = _SeededInventoryStore(
      InventoryDocument(
        storageSlots: [
          StorageSlot(
            id: StorageSlotId.parse('AbCdEfGhIjKlMnOpQrStUv'),
            name: 'Active shelf',
          ),
          StorageSlot(
            id: StorageSlotId.parse('ZyXwVuTsRqPoNmLkJiHgFe'),
            name: 'Archived shelf',
            archived: true,
          ),
        ],
        materialUnits: [
          MaterialUnit(
            id: PlaceId.parse('AaBbCcDdEeFfGgHhIiJjKk'),
            name: 'Archived holder',
            archived: true,
            slots: [
              MaterialSlot(
                id: PlaceId.parse('QqWwEeRrTtYyUuIiOoPpAa'),
                name: 'Slot 1',
              ),
            ],
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
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();

    expect(find.text('Active shelf'), findsOneWidget);
    expect(find.text('Archived shelf'), findsNothing);
    expect(find.text('Archived holder'), findsNothing);
  });

  testWidgets('material-unit browse count matches visible active slots', (
    tester,
  ) async {
    final store = _SeededInventoryStore(
      InventoryDocument(
        materialUnits: [
          MaterialUnit(
            id: PlaceId.parse('AaBbCcDdEeFfGgHhIiJjKk'),
            name: 'AMS',
            slots: [
              MaterialSlot(
                id: PlaceId.parse('AbCdEfGhIjKlMnOpQrStUv'),
                name: 'Left',
              ),
              MaterialSlot(
                id: PlaceId.parse('ZyXwVuTsRqPoNmLkJiHgFe'),
                name: 'Right',
                archived: true,
              ),
            ],
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
    await tester.pumpWidget(FilaManagerApp(dependencies: app));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();

    expect(find.text('1 material slot · Active'), findsOneWidget);
    await tester.tap(find.text('AMS'));
    await tester.pumpAndSettle();
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsNothing);
  });
}

final class _SeededInventoryStore implements InventoryStore {
  _SeededInventoryStore(this.inventory);
  InventoryDocument inventory;

  @override
  Future<InventoryDocument> open() async => inventory;

  @override
  Future<void> save(InventoryDocument inventory) async {
    this.inventory = inventory;
  }
}
