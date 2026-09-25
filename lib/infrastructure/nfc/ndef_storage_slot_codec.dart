import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

abstract final class NdefStorageSlotCodec {
  static const _uriType = 0x55;
  static const _httpsPrefixCode = 0x04;
  static const _httpsPrefix = 'https://';

  static const _uriPrefixes = <String>[
    '',
    'http://www.',
    'https://www.',
    'http://',
    'https://',
    'tel:',
    'mailto:',
    'ftp://anonymous:anonymous@',
    'ftp://ftp.',
    'ftps://',
    'sftp://',
    'smb://',
    'nfs://',
    'ftp://',
    'dav://',
    'news:',
    'telnet://',
    'imap:',
    'rtsp://',
    'urn:',
    'pop:',
    'sip:',
    'sips:',
    'tftp:',
    'btspp://',
    'btl2cap://',
    'btgoep://',
    'tcpobex://',
    'irdaobex://',
    'file://',
    'urn:epc:id:',
    'urn:epc:tag:',
    'urn:epc:pat:',
    'urn:epc:raw:',
    'urn:epc:',
    'urn:nfc:',
  ];

  static NdefMessage encode(Uri reference) {
    final text = reference.toString();
    if (!text.startsWith(_httpsPrefix)) {
      throw ArgumentError.value(reference, 'reference', 'must use HTTPS');
    }

    return NdefMessage(
      records: [
        NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown,
          type: Uint8List.fromList([_uriType]),
          identifier: Uint8List(0),
          payload: Uint8List.fromList([
            _httpsPrefixCode,
            ...utf8.encode(text.substring(_httpsPrefix.length)),
          ]),
        ),
      ],
    );
  }

  static String? decode(NdefMessage? message) {
    if (message == null || message.records.length != 1) {
      return null;
    }

    final record = message.records.single;
    if (record.typeNameFormat != TypeNameFormat.wellKnown ||
        record.type.length != 1 ||
        record.type.single != _uriType ||
        record.identifier.isNotEmpty ||
        record.payload.isEmpty) {
      return null;
    }

    final prefixCode = record.payload.first;
    if (prefixCode >= _uriPrefixes.length) {
      return null;
    }

    try {
      return '${_uriPrefixes[prefixCode]}'
          '${utf8.decode(record.payload.sublist(1))}';
    } on FormatException {
      return null;
    }
  }
}
