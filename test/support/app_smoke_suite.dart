import 'dart:async';
import 'dart:io';

import 'package:filamanager/app/app.dart';
import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void appSmokeSuite() {
  late Directory temporaryDirectory;
  late FakeNfcService nfcService;
  late FakeIncomingLinkService incomingLinkService;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'filamanager-app-test-',
    );
    nfcService = FakeNfcService();
    incomingLinkService = FakeIncomingLinkService();
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
      temporaryDirectory,
      nfcService,
      incomingLinkService,
    );

    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Spools'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Spools'));
    await tester.pumpAndSettle();
    expect(find.text('No active filament spools yet'), findsOneWidget);

    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('No storage slots or material units yet'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('No consumed or retired filament spools'), findsOneWidget);
  });

  testWidgets('renders injected NFC and incoming-link events', (tester) async {
    await _launchApp(
      tester,
      temporaryDirectory,
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
    expect(find.text('No inventory changes were made.'), findsOneWidget);
  });

  testWidgets('reopens the same production-format store after restart', (
    tester,
  ) async {
    await _launchApp(
      tester,
      temporaryDirectory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('No storage slots or material units yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _launchApp(
      tester,
      temporaryDirectory,
      nfcService,
      incomingLinkService,
    );

    expect(find.text('Scan a storage-slot tag'), findsOneWidget);
  });

  testWidgets('uses back from an inventory area to return to Scan home', (
    tester,
  ) async {
    await _launchApp(
      tester,
      temporaryDirectory,
      nfcService,
      incomingLinkService,
    );
    await tester.tap(find.text('Spools'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

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
      temporaryDirectory,
      nfcService,
      incomingLinkService,
    );

    for (final label in ['Home', 'Spools', 'Places', 'Archive']) {
      expect(find.text(label), findsOneWidget);
    }

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Scan storage-slot tag'), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> _launchApp(
  WidgetTester tester,
  Directory temporaryDirectory,
  NfcService nfcService,
  IncomingLinkService incomingLinkService,
) async {
  final inventoryStore = JsonInventoryStore(
    File('${temporaryDirectory.path}/inventory.json'),
  );
  final dependencies = await tester.runAsync(
    () => AppDependencies.initialize(
      inventoryStore: inventoryStore,
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
    ),
  );

  await tester.pumpWidget(FilaManagerApp(dependencies: dependencies!));
  await tester.pumpAndSettle();
}

final class FakeNfcService implements NfcService {
  final _events = StreamController<NfcEvent>.broadcast();

  @override
  Stream<NfcEvent> get events => _events.stream;

  @override
  Future<void> scan() async {}

  void emit(NfcEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

final class FakeIncomingLinkService implements IncomingLinkService {
  final _links = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => _links.stream;

  void emit(Uri link) => _links.add(link);

  Future<void> close() => _links.close();
}
