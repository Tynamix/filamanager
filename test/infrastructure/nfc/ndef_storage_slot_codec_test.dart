import 'dart:convert';
import 'dart:typed_data';

import 'package:filamanager/infrastructure/nfc/ndef_storage_slot_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';

void main() {
  const reference =
      'https://filamanager.vibesolutions.de/s#v1.AbCdEfGhIjKlMnOpQrStUv';

  test('builds exactly one canonical NFC Forum URI record', () {
    final message = NdefStorageSlotCodec.encode(Uri.parse(reference));

    expect(message.records, hasLength(1));
    final record = message.records.single;
    expect(record.typeNameFormat, TypeNameFormat.wellKnown);
    expect(record.type, [0x55]);
    expect(record.identifier, isEmpty);
    expect(record.payload.first, 0x04);
    expect(utf8.decode(record.payload.sublist(1)), reference.substring(8));
  });

  test('reads one URI record and rejects blank or foreign messages', () {
    final canonical = NdefStorageSlotCodec.encode(Uri.parse(reference));
    final foreign = NdefMessage(
      records: [
        NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown,
          type: Uint8List.fromList([0x54]),
          identifier: Uint8List(0),
          payload: Uint8List.fromList(utf8.encode('foreign text')),
        ),
      ],
    );

    expect(NdefStorageSlotCodec.decode(canonical), reference);
    expect(NdefStorageSlotCodec.decode(null), isNull);
    expect(NdefStorageSlotCodec.decode(const NdefMessage(records: [])), isNull);
    expect(NdefStorageSlotCodec.decode(foreign), isNull);
    expect(
      NdefStorageSlotCodec.decode(
        NdefMessage(records: [...canonical.records, ...canonical.records]),
      ),
      isNull,
    );
  });
}
