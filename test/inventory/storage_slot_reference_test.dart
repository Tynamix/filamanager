import 'package:filamanager/inventory/storage_slot_id.dart';
import 'package:filamanager/inventory/storage_slot_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const value = 'AbCdEfGhIjKlMnOpQrStUv';

  test('storage-slot identities enforce the canonical opaque syntax', () {
    final identity = StorageSlotId.parse(value);

    expect(identity.value, value);
    expect(StorageSlotId.tryParse('too-short'), isNull);
    expect(StorageSlotId.tryParse('AbCdEfGhIjKlMnOpQrStU!'), isNull);
  });

  test('storage-slot references round-trip a validated identity', () {
    final identity = StorageSlotId.parse(value);
    final reference = StorageSlotReference.forStorageSlot(identity);

    expect(
      reference.toString(),
      'https://filamanager.vibesolutions.de/s#v1.$value',
    );
    expect(StorageSlotReference.parse(reference), identity);
  });
}
