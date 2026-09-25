import 'dart:async';
import 'dart:io';

import 'package:filamanager/app/app.dart';
import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _storageSlotId = 'AbCdEfGhIjKlMnOpQrStUv';
const _storageSlotUri =
    'https://filamanager.vibesolutions.de/s#v1.$_storageSlotId';

void appSmokeSuite({bool useProductionStore = false}) {
  late Directory temporaryDirectory;
  late InventoryStore Function() inventoryStoreFactory;
  late FakeNfcService nfcService;
  late FakeIncomingLinkService incomingLinkService;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'filamanager-app-test-',
    );
    nfcService = FakeNfcService();
    incomingLinkService = FakeIncomingLinkService();
    if (useProductionStore) {
      inventoryStoreFactory = () =>
          JsonInventoryStore(File('${temporaryDirectory.path}/inventory.json'));
    } else {
      final inventoryStore = FakeInventoryStore();
      inventoryStoreFactory = () => inventoryStore;
    }
  });

  tearDown(() async {
    await nfcService.close();
    await incomingLinkService.close();
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  testWidgets('launches Scan home and reaches every empty inventory area', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Spools'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Spools'));
    await _pumpInteraction(tester);
    expect(find.text('No active filament spools yet'), findsOneWidget);

    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    expect(find.text('No storage slots or material units yet'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await _pumpInteraction(tester);
    expect(find.text('No consumed or retired filament spools'), findsOneWidget);
  });

  testWidgets('renders injected NFC and incoming-link events', (tester) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    nfcService.emit(
      NfcUriPayloadRead(
        Uri.parse('https://example.invalid/s#v1.storage-slot-id'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('NFC input received'), findsOneWidget);

    incomingLinkService.emit(
      Uri.parse('https://example.invalid/s#v1.storage-slot-id'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Incoming link received'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);
  });

  testWidgets('does not classify a malformed incoming link as a tag', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    incomingLinkService.emit(
      Uri.parse('https://example.invalid/s#v1.$_storageSlotId'),
    );
    await _pumpInteraction(tester);

    expect(find.text('Invalid storage-slot link'), findsOneWidget);
    expect(find.text('Unknown tag'), findsNothing);
    expect(find.text('No inventory changes were made.'), findsWidgets);
  });

  testWidgets('reopens the same production-format store after restart', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    expect(find.text('No storage slots or material units yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpInteraction(tester);
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
  });

  testWidgets('creates and reopens a persisted storage slot manually', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('READ-ONLY STORAGE-SLOT CONTEXT'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpInteraction(tester);
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Shelf A · 01'));
    await _pumpInteraction(tester);

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('READ-ONLY STORAGE-SLOT CONTEXT'), findsOneWidget);
  });

  testWidgets('opens the same storage-slot context from NFC and a link', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);
    nfcService.emit(NfcUriPayloadRead(Uri.parse(_storageSlotUri)));
    await _pumpInteraction(tester);

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('READ-ONLY STORAGE-SLOT CONTEXT'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);
    incomingLinkService.emit(Uri.parse(_storageSlotUri));
    await _pumpInteraction(tester);

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('READ-ONLY STORAGE-SLOT CONTEXT'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('distinguishes malformed tags from a missing storage slot', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    const malformedContents = [
      '',
      'not a URI',
      'http://filamanager.vibesolutions.de/s#v1.$_storageSlotId',
      'https://example.invalid/s#v1.$_storageSlotId',
      'https://filamanager.vibesolutions.de/other#v1.$_storageSlotId',
      'https://filamanager.vibesolutions.de/s#v2.$_storageSlotId',
      'https://filamanager.vibesolutions.de/s#v1.invalid!',
    ];
    for (final content in malformedContents) {
      nfcService.emit(NfcContentRead(content));
      await _pumpInteraction(tester);
      expect(find.text('Unknown tag'), findsOneWidget);
      expect(find.text('No inventory changes were made.'), findsWidgets);
      await tester.binding.handlePopRoute();
      await _pumpInteraction(tester);
    }

    nfcService.emit(const NfcTagRejected(NfcTagFailureKind.incompatible));
    await _pumpInteraction(tester);
    expect(find.text('Incompatible NFC tag'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);

    nfcService.emit(const NfcTagRejected(NfcTagFailureKind.unformatted));
    await _pumpInteraction(tester);
    expect(find.text('Tag is not NDEF-formatted'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);

    nfcService.emit(
      const NfcContentRead(
        'https://filamanager.vibesolutions.de/s#v1.ZyXwVuTsRqPoNmLkJiHgFe',
      ),
    );
    await _pumpInteraction(tester);

    expect(find.text('Unknown storage slot'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);
  });

  testWidgets('handles initial, repeated, and back link delivery safely', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpInteraction(tester);
    incomingLinkService.initialLink = Uri.parse(_storageSlotUri);
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('READ-ONLY STORAGE-SLOT CONTEXT'), findsOneWidget);

    incomingLinkService
      ..emit(Uri.parse(_storageSlotUri))
      ..emit(Uri.parse(_storageSlotUri));
    await _pumpInteraction(tester);
    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);
    expect(find.text('Places'), findsWidgets);
    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('Storage slot · Empty'), findsOneWidget);
  });

  testWidgets('confirms and registers a canonical storage-slot tag', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    await tester.tap(find.text('Register NFC tag'));
    await _pumpInteraction(tester);
    expect(
      find.text('The complete NDEF message will be replaced.'),
      findsOneWidget,
    );
    expect(find.text(_storageSlotUri), findsOneWidget);
    expect(nfcService.writeRequests, isEmpty);

    await tester.tap(find.text('Replace and register'));
    await tester.pumpAndSettle();

    expect(find.text('Tag registered'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);
    expect(nfcService.writeRequests, [Uri.parse(_storageSlotUri)]);
    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('keeps inventory safe across unavailable and failed NFC', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    nfcService.availabilityState = NfcAvailability.disabled;
    await tester.tap(find.text('Register NFC tag'));
    await _pumpInteraction(tester);
    expect(find.text('NFC is disabled'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsOneWidget);
    expect(nfcService.writeRequests, isEmpty);

    nfcService.availabilityState = NfcAvailability.available;
    nfcService.nextWriteResult = const NfcWriteCancelled();
    await tester.tap(find.text('Register NFC tag'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Replace and register'));
    await tester.pumpAndSettle();
    expect(find.text('Tag registration cancelled'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);

    const failures = <(NfcWriteFailureKind, String)>[
      (NfcWriteFailureKind.incompatible, 'Incompatible NFC tag'),
      (NfcWriteFailureKind.unformatted, 'Tag is not NDEF-formatted'),
      (NfcWriteFailureKind.readOnly, 'Tag is read-only'),
      (
        NfcWriteFailureKind.insufficientCapacity,
        'Tag does not have enough capacity',
      ),
      (NfcWriteFailureKind.interrupted, 'Tag write was interrupted'),
      (NfcWriteFailureKind.unexpected, 'Tag registration failed'),
    ];
    for (final (kind, message) in failures) {
      nfcService.nextWriteResult = NfcWriteFailed(kind);
      await tester.tap(find.text('Register NFC tag'));
      await _pumpInteraction(tester);
      await tester.tap(find.text('Replace and register'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.text('No inventory changes were made.'), findsWidgets);
      expect(find.text('Shelf A · 01'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    }

    await tester.tap(find.text('Home'));
    await _pumpInteraction(tester);
    nfcService.scanEvent = const NfcScanUnavailable(
      NfcAvailability.unavailable,
    );
    await tester.tap(find.text('Scan a storage-slot tag'));
    await _pumpInteraction(tester);
    expect(find.text('NFC is unavailable'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsOneWidget);
  });

  testWidgets('cancels an in-progress tag registration', (tester) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await _pumpInteraction(tester);
    await _createStorageSlotThroughUi(tester, name: 'Shelf A · 01');

    nfcService.pendingWrite = Completer<NfcWriteResult>();
    await tester.tap(find.text('Register NFC tag'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Replace and register'));
    await _pumpInteraction(tester);

    expect(find.text('Ready to write'), findsOneWidget);
    expect(find.text('Cancel tag registration'), findsOneWidget);
    await tester.tap(find.text('Cancel tag registration'));
    await tester.pumpAndSettle();

    expect(find.text('Tag registration cancelled'), findsOneWidget);
    expect(find.text('No inventory changes were made.'), findsWidgets);
    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('uses back from an inventory area to return to Scan home', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Spools'));
    await _pumpInteraction(tester);

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);

    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
  });

  testWidgets('keeps every destination reachable at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );

    for (final label in ['Home', 'Spools', 'Places', 'Archive']) {
      expect(find.text(label), findsOneWidget);
    }

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Scan a storage-slot tag'), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> _createStorageSlotThroughUi(
  WidgetTester tester, {
  required String name,
}) async {
  await tester.tap(find.text('Add storage slot'));
  await _pumpInteraction(tester);
  await tester.enterText(find.bySemanticsLabel('Storage-slot name'), name);
  await tester.pump();

  final reviewButton = find.widgetWithText(
    OutlinedButton,
    'Review storage slot',
  );
  expect(tester.widget<OutlinedButton>(reviewButton).onPressed, isNotNull);
  await tester.tap(reviewButton);
  await _pumpInteraction(tester);
  expect(find.text('REVIEW STORAGE SLOT'), findsOneWidget);
  expect(find.text(name), findsOneWidget);
  expect(find.text('No inventory changes have been made.'), findsOneWidget);

  final createButton = find.widgetWithText(FilledButton, 'Create storage slot');
  await tester.runAsync(() => tester.tap(createButton));
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await _pumpInteraction(tester);
}

Future<void> _launchApp(
  WidgetTester tester,
  InventoryStore Function() inventoryStoreFactory,
  NfcService nfcService,
  IncomingLinkService incomingLinkService,
) async {
  final dependencies = await tester.runAsync(
    () => AppDependencies.initialize(
      inventoryStore: inventoryStoreFactory(),
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
      storageSlotIdGenerator: () => StorageSlotId.parse(_storageSlotId),
    ),
  );

  await tester.pumpWidget(FilaManagerApp(dependencies: dependencies!));
  await _pumpInteraction(tester);
}

final class FakeInventoryStore implements InventoryStore {
  InventoryDocument _inventory = const InventoryDocument(schemaVersion: 1);

  @override
  Future<InventoryDocument> open() async => _inventory;

  @override
  Future<void> save(InventoryDocument inventory) async {
    _inventory = inventory;
  }
}

Future<void> _pumpInteraction(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

final class FakeNfcService implements NfcService {
  final _events = StreamController<NfcEvent>.broadcast();
  final writeRequests = <Uri>[];
  NfcAvailability availabilityState = NfcAvailability.available;
  NfcWriteResult nextWriteResult = const NfcWriteSucceeded();
  NfcEvent? scanEvent;
  Completer<NfcWriteResult>? pendingWrite;

  @override
  Stream<NfcEvent> get events => _events.stream;

  @override
  Future<NfcAvailability> availability() async => availabilityState;

  @override
  Future<void> scan() async {
    final event = scanEvent;
    if (event != null) {
      emit(event);
    }
  }

  @override
  Future<NfcWriteResult> writeStorageSlotReference(Uri reference) async {
    writeRequests.add(reference);
    return pendingWrite?.future ?? nextWriteResult;
  }

  @override
  Future<void> cancelSession() async {
    final write = pendingWrite;
    if (write != null && !write.isCompleted) {
      write.complete(const NfcWriteCancelled());
    }
    pendingWrite = null;
  }

  void emit(NfcEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

final class FakeIncomingLinkService implements IncomingLinkService {
  final _links = StreamController<Uri>.broadcast();
  Uri? initialLink;

  @override
  Stream<Uri> get links => _links.stream;

  @override
  Future<Uri?> takeInitialLink() async {
    final link = initialLink;
    initialLink = null;
    return link;
  }

  void emit(Uri link) => _links.add(link);

  Future<void> close() => _links.close();
}
