import 'dart:io';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/links/app_links_incoming_link_service.dart';
import 'package:filamanager/infrastructure/nfc/nfc_manager_service.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:path_provider/path_provider.dart';

abstract final class ProductionCompositionRoot {
  static Future<AppDependencies> create() async {
    final incomingLinkService = AppLinksIncomingLinkService();
    final applicationDirectory = await getApplicationSupportDirectory();

    return AppDependencies.initialize(
      inventoryStore: JsonInventoryStore(
        File('${applicationDirectory.path}/inventory.json'),
      ),
      nfcService: NfcManagerService(),
      incomingLinkService: incomingLinkService,
    );
  }
}
