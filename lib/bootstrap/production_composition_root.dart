import 'dart:io';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/infrastructure/persistence/json_inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:path_provider/path_provider.dart';

abstract final class ProductionCompositionRoot {
  static Future<AppDependencies> create() async {
    final applicationDirectory = await getApplicationSupportDirectory();

    return AppDependencies.initialize(
      inventoryStore: JsonInventoryStore(
        File('${applicationDirectory.path}/inventory.json'),
      ),
      nfcService: const UnavailableNfcService(),
      incomingLinkService: const NoIncomingLinkService(),
    );
  }
}
