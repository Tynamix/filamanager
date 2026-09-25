import 'dart:convert';
import 'dart:math';

import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/persistence/inventory_store.dart';
import 'package:filamanager/services/incoming_link_service.dart';
import 'package:filamanager/services/nfc_service.dart';

final class AppDependencies {
  AppDependencies._({
    required this.inventoryStore,
    required this.inventory,
    required this.nfcService,
    required this.incomingLinkService,
    required this.initialIncomingLink,
    required this._storageSlotIdGenerator,
  });

  final InventoryStore inventoryStore;
  InventoryDocument inventory;
  final NfcService nfcService;
  final IncomingLinkService incomingLinkService;
  final Uri? initialIncomingLink;
  final StorageSlotId Function() _storageSlotIdGenerator;

  Future<StorageSlot> createStorageSlot(String name) async {
    final storageSlot = StorageSlot(
      id: _storageSlotIdGenerator(),
      name: name.trim(),
    );
    final updatedInventory = inventory.copyWith(
      storageSlots: [...inventory.storageSlots, storageSlot],
    );
    await inventoryStore.save(updatedInventory);
    inventory = updatedInventory;
    return storageSlot;
  }

  static StorageSlotId _newOpaqueId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return StorageSlotId.parse(base64UrlEncode(bytes).replaceAll('=', ''));
  }

  static Future<AppDependencies> initialize({
    required InventoryStore inventoryStore,
    required NfcService nfcService,
    required IncomingLinkService incomingLinkService,
    StorageSlotId Function() storageSlotIdGenerator = _newOpaqueId,
  }) async {
    final inventory = await inventoryStore.open();
    final initialIncomingLink = await incomingLinkService.takeInitialLink();

    return AppDependencies._(
      inventoryStore: inventoryStore,
      inventory: inventory,
      nfcService: nfcService,
      incomingLinkService: incomingLinkService,
      initialIncomingLink: initialIncomingLink,
      storageSlotIdGenerator: storageSlotIdGenerator,
    );
  }
}
