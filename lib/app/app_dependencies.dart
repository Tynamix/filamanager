import 'package:filamanager/persistence/inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';

final class AppDependencies {
  const AppDependencies._({
    required this.inventoryStore,
    required this.inventory,
    required this.nfcService,
    required this.incomingLinkService,
  });

  final InventoryStore inventoryStore;
  final InventoryDocument inventory;
  final NfcService nfcService;
  final IncomingLinkService incomingLinkService;

  static Future<AppDependencies> initialize({
    required InventoryStore inventoryStore,
    required NfcService nfcService,
    required IncomingLinkService incomingLinkService,
  }) async {
    final inventory = await inventoryStore.open();

    return AppDependencies._(
      inventoryStore: inventoryStore,
      inventory: inventory,
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
    );
  }
}
