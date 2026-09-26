import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:filamanager/app/app.dart';
import 'package:filamanager/app/app_bootstrap.dart';
import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/inventory/filament_spool.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _storageSlotId = 'AbCdEfGhIjKlMnOpQrStUv';
const _storageSlotUri =
    'https://filamanager.vibesolutions.de/s#v1.$_storageSlotId';

void appSmokeSuite() {
  late Directory temporaryDirectory;
  late InventoryStore Function() inventoryStoreFactory;
  late _SaveSignal saveSignal;
  late FakeNfcService nfcService;
  late FakeIncomingLinkService incomingLinkService;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'filamanager-app-test-',
    );
    nfcService = FakeNfcService();
    incomingLinkService = FakeIncomingLinkService();
    saveSignal = _SaveSignal();
    inventoryStoreFactory = () => _SignalingInventoryStore(
      JsonInventoryStore(File('${temporaryDirectory.path}/inventory.json')),
      saveSignal,
    );
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

  testWidgets('refuses a schema-3 store missing its filament spools', (
    tester,
  ) async {
    final file = File('${temporaryDirectory.path}/inventory.json');
    const unreadable =
        '{"schemaVersion":3,"storageSlots":[],"materialUnits":[]}';
    await tester.runAsync(() => file.writeAsString(unreadable));

    final startupFailure = await tester.runAsync<Object?>(() async {
      try {
        await AppDependencies.initialize(
          inventoryStore: inventoryStoreFactory(),
          nfcService: nfcService,
          incomingLinkService: incomingLinkService,
        );
        return null;
      } catch (error) {
        return error;
      }
    });
    expect(startupFailure, isA<FormatException>());
    expect(await tester.runAsync(file.readAsString), unreadable);
  });

  testWidgets('shows recovery and retries after an unreadable local store', (
    tester,
  ) async {
    final file = File('${temporaryDirectory.path}/inventory.json');
    const unreadable =
        '{"schemaVersion":3,"storageSlots":[],"materialUnits":[]}';
    await tester.runAsync(() => file.writeAsString(unreadable));
    await tester.pumpWidget(
      FilaManagerBootstrap(
        createDependencies: () => AppDependencies.initialize(
          inventoryStore: inventoryStoreFactory(),
          nfcService: nfcService,
          incomingLinkService: incomingLinkService,
        ),
      ),
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Inventory could not be opened').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(find.text('Inventory could not be opened'), findsOneWidget);
    expect(
      find.text('Local inventory data was left unchanged.'),
      findsOneWidget,
    );
    expect(find.text('Retry opening inventory'), findsOneWidget);
    expect(find.text('Add filament spool'), findsNothing);
    expect(await tester.runAsync(file.readAsString), unreadable);

    await tester.runAsync(
      () => file.writeAsString(
        '{"schemaVersion":3,"storageSlots":[],"materialUnits":[],"filamentSpools":[]}',
      ),
    );
    await tester.tap(find.text('Retry opening inventory'));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Scan a storage-slot tag').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
  });

  testWidgets('refuses persisted Unlocated spools with broken invariants', (
    tester,
  ) async {
    final file = File('${temporaryDirectory.path}/inventory.json');
    for (final (remaining, assignment, invalidHistory)
        in <(int, String?, bool)>[
          (0, null, false),
          (500, 'unverified-place', false),
          (500, null, true),
        ]) {
      final unreadable = jsonEncode({
        'schemaVersion': 3,
        'storageSlots': <Object>[],
        'materialUnits': <Object>[],
        'filamentSpools': [
          {
            'id': _storageSlotId,
            'description': {'materialType': 'PLA', 'filamentColor': '#123456'},
            'remainingGrams': remaining,
            'state': 'unlocated',
            'assignmentId': assignment,
            'history': [
              {
                'occurredAt': '2026-09-26T12:00:00Z',
                'action': 'Registered',
                'affectedSpoolIds': [_storageSlotId],
                'beforeState': null,
                'afterState': 'unlocated',
                'beforeRemainingGrams': null,
                'afterRemainingGrams': remaining,
              },
              if (invalidHistory)
                {
                  'occurredAt': '2026-09-26T13:00:00Z',
                  'action': 'Quantity corrected',
                  'affectedSpoolIds': <String>[],
                  'beforeState': 'unlocated',
                  'afterState': 'unlocated',
                  'beforeRemainingGrams': remaining,
                  'afterRemainingGrams': remaining,
                },
            ],
          },
        ],
      });
      await tester.runAsync(() => file.writeAsString(unreadable));
      final startupFailure = await tester.runAsync<Object?>(() async {
        try {
          await AppDependencies.initialize(
            inventoryStore: inventoryStoreFactory(),
            nfcService: nfcService,
            incomingLinkService: incomingLinkService,
          );
          return null;
        } catch (error) {
          return error;
        }
      });
      expect(startupFailure, isA<FormatException>());
      expect(await tester.runAsync(file.readAsString), unreadable);
    }
  });

  testWidgets('refuses two persisted filament spools with one identity', (
    tester,
  ) async {
    final file = File('${temporaryDirectory.path}/inventory.json');
    final spool = {
      'id': _storageSlotId,
      'description': {'materialType': 'PLA', 'filamentColor': '#123456'},
      'remainingGrams': 500,
      'state': 'unlocated',
      'assignmentId': null,
      'history': [
        {
          'occurredAt': '2026-09-26T12:00:00Z',
          'action': 'Registered',
          'affectedSpoolIds': [_storageSlotId],
          'beforeState': null,
          'afterState': 'unlocated',
          'beforeRemainingGrams': null,
          'afterRemainingGrams': 500,
        },
      ],
    };
    final unreadable = jsonEncode({
      'schemaVersion': 3,
      'storageSlots': <Object>[],
      'materialUnits': <Object>[],
      'filamentSpools': [spool, spool],
    });
    await tester.runAsync(() => file.writeAsString(unreadable));
    final startupFailure = await tester.runAsync<Object?>(() async {
      try {
        await AppDependencies.initialize(
          inventoryStore: inventoryStoreFactory(),
          nfcService: nfcService,
          incomingLinkService: incomingLinkService,
        );
        return null;
      } catch (error) {
        return error;
      }
    });
    expect(startupFailure, isA<FormatException>());
    expect(await tester.runAsync(file.readAsString), unreadable);
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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('STORAGE SLOT'), findsOneWidget);
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
    expect(find.text('STORAGE SLOT'), findsOneWidget);
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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);
    nfcService.emit(NfcUriPayloadRead(Uri.parse(_storageSlotUri)));
    await _pumpInteraction(tester);

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('STORAGE SLOT'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpInteraction(tester);
    incomingLinkService.emit(Uri.parse(_storageSlotUri));
    await _pumpInteraction(tester);

    expect(find.text('Shelf A · 01'), findsOneWidget);
    expect(find.text('STORAGE SLOT'), findsOneWidget);
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
    expect(find.text('Incompatible NFC tag'), findsWidgets);
    expect(find.text('No inventory changes were made.'), findsWidgets);

    nfcService.emit(const NfcTagRejected(NfcTagFailureKind.unformatted));
    await _pumpInteraction(tester);
    expect(find.text('Tag is not NDEF-formatted'), findsWidgets);
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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

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
    expect(find.text('STORAGE SLOT'), findsOneWidget);

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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

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
    await _createStorageSlotThroughUi(
      tester,
      name: 'Shelf A · 01',
      saveSignal: saveSignal,
    );

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

  testWidgets(
    'registers an Unlocated filament spool and finds it after restart',
    (tester) async {
      await _launchApp(
        tester,
        inventoryStoreFactory,
        nfcService,
        incomingLinkService,
      );
      await tester.tap(find.text('Spools'));
      await _pumpInteraction(tester);
      await tester.tap(find.text('Add filament spool'));
      await _pumpInteraction(tester);

      await tester.tap(find.text('PLA'));
      await tester.enterText(
        find.bySemanticsLabel('Filament color (#RRGGBB)'),
        '#22aa88',
      );
      await tester.enterText(
        find.bySemanticsLabel('Remaining quantity (g)'),
        '750',
      );
      await tester.tap(find.text('Review filament spool'));
      await _pumpInteraction(tester);
      expect(find.text('Unlocated'), findsWidgets);
      expect(find.text('No assignment'), findsWidgets);

      await _confirmSpoolRegistration(tester);
      expect(find.text('Filament spool registered'), findsOneWidget);
      expect(find.text('750 g'), findsWidgets);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('STATE'), findsOneWidget);
      expect(find.text('ASSIGNMENT'), findsOneWidget);
      expect(find.text('REMAINING QUANTITY'), findsOneWidget);
      expect(find.text('FILAMENT COLOR'), findsOneWidget);
      expect(find.bySemanticsLabel('State: Unlocated'), findsOneWidget);
      expect(find.text('AFFECTED'), findsOneWidget);
      expect(find.text('this filament spool'), findsOneWidget);
      expect(find.text('BEFORE'), findsOneWidget);
      expect(find.text('not registered'), findsOneWidget);
      expect(find.text('AFTER'), findsOneWidget);
      expect(find.text('Unlocated · 750 g · no assignment'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await _pumpInteraction(tester);
      expect(find.text('No active filament spools yet'), findsNothing);
      expect(find.text('PLA'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpInteraction(tester);
      await _launchApp(
        tester,
        inventoryStoreFactory,
        nfcService,
        incomingLinkService,
      );
      await tester.tap(find.text('Spools'));
      await _pumpInteraction(tester);
      expect(find.text('PLA'), findsWidgets);
      await tester.tap(find.text('PLA').last);
      await _pumpInteraction(tester);
      expect(find.text('Unlocated'), findsWidgets);
      expect(find.text('No assignment'), findsWidgets);
      expect(find.text('#22AA88'), findsOneWidget);
      expect(find.text('750 g'), findsWidgets);
      expect(find.text('Registered'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid and cancelled registration leave no filament spool or history',
    (tester) async {
      await _launchApp(
        tester,
        inventoryStoreFactory,
        nfcService,
        incomingLinkService,
      );
      await tester.tap(find.text('Spools'));
      await _pumpInteraction(tester);
      await tester.tap(find.text('Add filament spool'));
      await _pumpInteraction(tester);

      await tester.enterText(find.bySemanticsLabel('Material type'), 'PLA');
      await tester.enterText(
        find.bySemanticsLabel('Filament color (#RRGGBB)'),
        'clear',
      );
      await tester.enterText(
        find.bySemanticsLabel('Remaining quantity (g)'),
        '0',
      );
      await tester.tap(find.text('Review filament spool'));
      await _pumpInteraction(tester);
      expect(
        find.text('Enter a positive whole-gram remaining quantity.'),
        findsOneWidget,
      );
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(
              find.text('Enter a positive whole-gram remaining quantity.'),
            )
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      semantics.dispose();
      expect(find.text('Register filament spool'), findsNothing);

      await tester.enterText(
        find.bySemanticsLabel('Remaining quantity (g)'),
        '900',
      );
      await tester.tap(find.text('Review filament spool'));
      await _pumpInteraction(tester);
      expect(find.text('Choose a color in #RRGGBB format.'), findsOneWidget);
      await tester.enterText(
        find.bySemanticsLabel('Filament color (#RRGGBB)'),
        '#AABBCC',
      );
      await tester.tap(find.text('Review filament spool'));
      await _pumpInteraction(tester);
      expect(find.text('Register this filament spool?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _pumpInteraction(tester);
      expect(find.text('No active filament spools yet'), findsOneWidget);
      expect(find.text('No inventory changes were made.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpInteraction(tester);
      await _launchApp(
        tester,
        inventoryStoreFactory,
        nfcService,
        incomingLinkService,
      );
      await tester.tap(find.text('Spools'));
      await _pumpInteraction(tester);
      expect(find.text('No active filament spools yet'), findsOneWidget);
      expect(find.text('Registered'), findsNothing);
    },
  );

  testWidgets('searches active filament spools by their descriptive details', (
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
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('PLA'));
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#CC3333',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '500',
    );
    await tester.enterText(find.bySemanticsLabel('Spool label'), 'Red sample');
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    await _confirmSpoolRegistration(tester);
    expect(find.text('Filament spool registered'), findsOneWidget);
    await tester.tap(find.text('Back to spools'));
    await _pumpInteraction(tester);

    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.enterText(find.bySemanticsLabel('Material type'), 'PCTG');
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#44AA77',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '850',
    );
    await tester.enterText(
      find.bySemanticsLabel('Spool label'),
      'Green sample',
    );
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    await _confirmSpoolRegistration(tester);
    await tester.tap(find.text('Back to spools'));
    await _pumpInteraction(tester);

    expect(find.text('Red sample'), findsOneWidget);
    expect(find.text('Green sample'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('Search filament spools'),
      'green',
    );
    await _pumpInteraction(tester);
    expect(find.text('Green sample'), findsOneWidget);
    expect(find.text('Red sample'), findsNothing);
    await tester.enterText(
      find.bySemanticsLabel('Search filament spools'),
      'pctg',
    );
    await _pumpInteraction(tester);
    expect(find.text('Green sample'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('Search filament spools'),
      'missing',
    );
    await _pumpInteraction(tester);
    expect(find.text('No matching filament spools'), findsOneWidget);
  });

  testWidgets(
    'retries a generated identity collision before registering another spool',
    (tester) async {
      final generatedIds = [
        _storageSlotId,
        _storageSlotId,
        'ZyXwVuTsRqPoNmLkJiHgFe',
      ];
      var nextId = 0;
      await _launchApp(
        tester,
        inventoryStoreFactory,
        nfcService,
        incomingLinkService,
        spoolIdGenerator: () => FilamentSpoolId.parse(generatedIds[nextId++]),
      );
      await tester.tap(find.text('Spools'));
      await _pumpInteraction(tester);
      for (final label in ['First roll', 'Second roll']) {
        await tester.tap(find.text('Add filament spool'));
        await _pumpInteraction(tester);
        await tester.tap(find.text('PLA'));
        await tester.enterText(
          find.bySemanticsLabel('Filament color (#RRGGBB)'),
          '#123456',
        );
        await tester.enterText(
          find.bySemanticsLabel('Remaining quantity (g)'),
          '500',
        );
        await tester.enterText(find.bySemanticsLabel('Spool label'), label);
        await tester.tap(find.text('Review filament spool'));
        await _pumpInteraction(tester);
        await _confirmSpoolRegistration(tester);
        if (label == 'First roll') {
          await tester.tap(find.text('Back to spools'));
          await _pumpInteraction(tester);
        }
      }

      await tester.tap(find.text('Edit details'));
      await _pumpInteraction(tester);
      await tester.enterText(
        find.bySemanticsLabel('Spool label'),
        'Second corrected',
      );
      await tester.tap(find.text('Review changes'));
      await _pumpInteraction(tester);
      await tester.tap(find.text('Save details'));
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Filament spool details saved').evaluate().isNotEmpty) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.tap(find.text('Back to spools'));
      await _pumpInteraction(tester);
      expect(find.text('First roll'), findsOneWidget);
      expect(find.text('Second corrected'), findsOneWidget);
      expect(find.text('Second roll'), findsNothing);
    },
  );

  testWidgets('edits descriptive details without adding operational history', (
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
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('PLA'));
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#123456',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '500',
    );
    await tester.enterText(find.bySemanticsLabel('Spool label'), 'First roll');
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    await _confirmSpoolRegistration(tester);

    await tester.tap(find.text('Edit details'));
    await _pumpInteraction(tester);
    await tester.enterText(find.bySemanticsLabel('Material type'), 'PETG');
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#abcdef',
    );
    await tester.enterText(
      find.bySemanticsLabel('Spool label'),
      'Corrected roll',
    );
    await tester.enterText(find.bySemanticsLabel('Manufacturer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Product name'), 'Silk');
    await tester.enterText(
      find.bySemanticsLabel('Original nominal quantity (g)'),
      '1000',
    );
    await tester.enterText(
      find.bySemanticsLabel('Notes'),
      'Transparent in person',
    );
    await tester.tap(find.text('Review changes'));
    await _pumpInteraction(tester);
    expect(
      find.text('No change to quantity, state, assignment, or history.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save details'));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Filament spool details saved').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(find.text('Corrected roll'), findsOneWidget);
    expect(find.text('#ABCDEF'), findsOneWidget);
    expect(find.text('500 g'), findsWidgets);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Silk'), findsOneWidget);
    expect(find.text('1000 g'), findsOneWidget);
    expect(find.text('Transparent in person'), findsOneWidget);
    expect(find.text('Registered'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpInteraction(tester);
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Spools'));
    await _pumpInteraction(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search filament spools'),
      'Corrected roll',
    );
    await _pumpInteraction(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Corrected roll'));
    await _pumpInteraction(tester);
    expect(find.text('PETG'), findsOneWidget);
    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('500 g'), findsWidgets);
  });

  testWidgets('chooses one representative color for a multicolored spool', (
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
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.enterText(
      find.bySemanticsLabel('Material type'),
      'Rainbow PLA',
    );
    await tester.tap(find.text('Pick filament color'));
    await _pumpInteraction(tester);
    expect(find.text('Choose one representative color'), findsOneWidget);
    await tester.ensureVisible(find.text('Blue'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Blue'));
    await _pumpInteraction(tester);
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '300',
    );
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    expect(find.text('FILAMENT COLOR'), findsOneWidget);
    expect(find.text('#3468C0'), findsOneWidget);
    await _confirmSpoolRegistration(tester);
    expect(find.text('#3468C0'), findsOneWidget);
    expect(find.text('Unlocated'), findsOneWidget);
  });

  testWidgets('moves assistive focus through registration and back to Spools', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Spools'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Material type'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );

    await tester.tap(find.text('PLA'));
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#224466',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '650',
    );
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    expect(
      tester
          .getSemantics(find.text('Register this filament spool?'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.tap(find.text('Cancel'));
    await _pumpInteraction(tester);
    expect(
      tester
          .getSemantics(find.text('Add filament spool'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('returns focus to Add after a failed registration write', (
    tester,
  ) async {
    await _launchApp(
      tester,
      inventoryStoreFactory,
      nfcService,
      incomingLinkService,
    );
    await tester.runAsync(
      () => Directory('${temporaryDirectory.path}/inventory.json.tmp').create(),
    );
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Spools'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('PLA'));
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#123456',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '500',
    );
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    await _confirmSpoolRegistration(tester);

    expect(
      find.text('Could not register filament spool. Try again.'),
      findsOneWidget,
    );
    expect(find.text('No active filament spools yet'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('Add filament spool'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('returns focus to Edit after a failed detail save', (
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
    await tester.tap(find.text('Add filament spool'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('PLA'));
    await tester.enterText(
      find.bySemanticsLabel('Filament color (#RRGGBB)'),
      '#123456',
    );
    await tester.enterText(
      find.bySemanticsLabel('Remaining quantity (g)'),
      '500',
    );
    await tester.enterText(
      find.bySemanticsLabel('Spool label'),
      'Original label',
    );
    await tester.tap(find.text('Review filament spool'));
    await _pumpInteraction(tester);
    await _confirmSpoolRegistration(tester);
    await tester.runAsync(
      () => Directory('${temporaryDirectory.path}/inventory.json.tmp').create(),
    );

    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Edit details'));
    await _pumpInteraction(tester);
    await tester.enterText(
      find.bySemanticsLabel('Spool label'),
      'Unsaved label',
    );
    await tester.tap(find.text('Review changes'));
    await _pumpInteraction(tester);
    await tester.tap(find.text('Save details'));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .text('Could not save details. Try again.')
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(find.text('Could not save details. Try again.'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Original label'), findsOneWidget);
    expect(find.text('Unsaved label'), findsNothing);
    expect(
      tester.getSemantics(find.text('Edit details')).flagsCollection.isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
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
  required _SaveSignal saveSignal,
}) async {
  await tester.tap(find.text('Add place'));
  await _pumpInteraction(tester);
  await tester.tap(find.text('Storage slot'));
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
  final saved = saveSignal.nextSave;
  await tester.runAsync(() => tester.tap(createButton));
  await tester.runAsync(() => saved);
  await tester.pumpAndSettle();
  await _pumpInteraction(tester);
}

Future<void> _confirmSpoolRegistration(WidgetTester tester) async {
  await tester.tap(find.text('Register filament spool'));
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Back to spools').evaluate().isNotEmpty ||
        find
            .text('Could not register filament spool. Try again.')
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

Future<void> _launchApp(
  WidgetTester tester,
  InventoryStore Function() inventoryStoreFactory,
  NfcService nfcService,
  IncomingLinkService incomingLinkService, {
  FilamentSpoolId Function()? spoolIdGenerator,
}) async {
  final dependencies = await tester.runAsync(
    () => AppDependencies.initialize(
      inventoryStore: inventoryStoreFactory(),
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
      storageSlotIdGenerator: () => StorageSlotId.parse(_storageSlotId),
      spoolIdGenerator: spoolIdGenerator,
    ),
  );

  await tester.pumpWidget(FilaManagerApp(dependencies: dependencies!));
  await _pumpInteraction(tester);
}

final class FakeInventoryStore implements InventoryStore {
  InventoryDocument _inventory = const InventoryDocument(
    schemaVersion: JsonInventoryStore.currentSchemaVersion,
  );

  @override
  Future<InventoryDocument> open() async => _inventory;

  @override
  Future<void> save(InventoryDocument inventory) async {
    _inventory = inventory;
  }
}

final class _SaveSignal {
  Completer<void> _next = Completer<void>();

  Future<void> get nextSave => _next.future;

  void saved() {
    _next.complete();
    _next = Completer<void>();
  }
}

final class _SignalingInventoryStore implements InventoryStore {
  _SignalingInventoryStore(this.delegate, this.signal);

  final InventoryStore delegate;
  final _SaveSignal signal;

  @override
  Future<InventoryDocument> open() => delegate.open();

  @override
  Future<void> save(InventoryDocument inventory) async {
    await delegate.save(inventory);
    signal.saved();
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
