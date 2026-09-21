import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

void main() => runApp(const NfcTagSpikeApp());

class NfcTagSpikeApp extends StatelessWidget {
  const NfcTagSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FilaManager NFC tag spike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const NfcTagSpikePage(),
    );
  }
}

class NfcTagSpikePage extends StatefulWidget {
  const NfcTagSpikePage({super.key});

  @override
  State<NfcTagSpikePage> createState() => _NfcTagSpikePageState();
}

class _NfcTagSpikePageState extends State<NfcTagSpikePage> {
  static const _externalType = 'filamanager.app:storage-slot';

  final _slotIdController = TextEditingController(text: 'slot-probe-a');
  final List<String> _events = [];
  String _availability = 'Not checked';
  String _lastTag = 'No tag scanned';
  bool _sessionActive = false;
  int _successfulReads = 0;

  @override
  void dispose() {
    _slotIdController.dispose();
    if (_sessionActive) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    if (!mounted) return;
    setState(() => _events.insert(0, '$timestamp  $message'));
  }

  Future<bool> _checkAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (!mounted) return false;
      setState(() => _availability = availability.name);
      _log('NFC availability: ${availability.name}');
      return availability == NfcAvailability.enabled;
    } catch (error) {
      _log('Availability check failed: $error');
      return false;
    }
  }

  Future<void> _startSession({
    required String purpose,
    required Future<String> Function(NfcTag tag) action,
  }) async {
    if (_sessionActive) {
      _log('A session is already active.');
      return;
    }
    if (!await _checkAvailability()) {
      _log('Session not started because NFC is not enabled.');
      return;
    }

    setState(() => _sessionActive = true);
    _log('$purpose session started.');

    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        alertMessageIos:
            'Hold the top of the iPhone near the storage-slot tag.',
        onSessionErrorIos: (error) {
          _log('iOS session ended: ${error.code.name}: ${error.message}');
          if (mounted) setState(() => _sessionActive = false);
        },
        onDiscovered: (tag) async {
          try {
            final result = await action(tag);
            _log('$purpose succeeded: $result');
            await NfcManager.instance.stopSession(
              alertMessageIos: '$purpose succeeded',
            );
          } catch (error) {
            _log('$purpose failed: $error');
            await NfcManager.instance.stopSession(
              errorMessageIos: '$purpose failed',
            );
          } finally {
            if (mounted) setState(() => _sessionActive = false);
          }
        },
      );
    } catch (error) {
      _log('Could not start $purpose session: $error');
      if (mounted) setState(() => _sessionActive = false);
    }
  }

  Future<void> _stopSession() async {
    try {
      await NfcManager.instance.stopSession(errorMessageIos: 'Cancelled');
      _log('Session cancelled by the tester.');
    } catch (error) {
      _log('Stopping the session returned: $error');
    } finally {
      if (mounted) setState(() => _sessionActive = false);
    }
  }

  Future<void> _inspect() async {
    await _startSession(
      purpose: 'Inspect',
      action: (tag) async {
        final facts = await _describeTag(tag);
        if (mounted) setState(() => _lastTag = facts);
        return 'tag details captured';
      },
    );
  }

  Future<void> _read() async {
    await _startSession(
      purpose: 'Read',
      action: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          throw StateError('Tag is not NDEF-formatted or NDEF is unsupported.');
        }

        final message = await ndef.read();
        final slotIds =
            message?.records
                .map(_storageSlotIdFrom)
                .whereType<String>()
                .toList() ??
            const <String>[];
        final facts = await _describeTag(tag);
        if (mounted) {
          setState(() {
            _successfulReads += 1;
            _lastTag =
                '$facts\n\nStorage-slot IDs: '
                '${slotIds.isEmpty ? '(none)' : slotIds.join(', ')}';
          });
        }
        return slotIds.isEmpty
            ? 'NDEF read, but no FilaManager storage-slot record was found'
            : 'read ${slotIds.join(', ')}';
      },
    );
  }

  Future<void> _confirmWrite() async {
    final slotId = _slotIdController.text.trim();
    if (slotId.isEmpty) {
      _log('Enter a storage-slot identifier before writing.');
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overwrite this tag?'),
            content: Text(
              'The next scanned tag will have its complete NDEF message '
              'replaced with storage-slot identifier “$slotId”.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start confirmed write'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _startSession(
      purpose: 'Write',
      action: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          throw StateError('Tag is not NDEF-formatted or NDEF is unsupported.');
        }
        if (!ndef.isWritable) {
          throw StateError('Tag reports that it is read-only.');
        }

        final record = NdefRecord(
          typeNameFormat: TypeNameFormat.external,
          type: Uint8List.fromList(utf8.encode(_externalType)),
          identifier: Uint8List(0),
          payload: Uint8List.fromList(utf8.encode(slotId)),
        );
        final message = NdefMessage(records: [record]);
        if (message.byteLength > ndef.maxSize) {
          throw StateError(
            'Message needs ${message.byteLength} bytes; tag allows ${ndef.maxSize}.',
          );
        }

        await ndef.write(message: message);
        return 'wrote $slotId (${message.byteLength}/${ndef.maxSize} bytes)';
      },
    );
  }

  String? _storageSlotIdFrom(NdefRecord record) {
    final type = utf8.decode(record.type, allowMalformed: true);
    if (record.typeNameFormat != TypeNameFormat.external ||
        type != _externalType) {
      return null;
    }
    return utf8.decode(record.payload, allowMalformed: true);
  }

  Future<String> _describeTag(NfcTag tag) async {
    final lines = <String>['Platform: ${Platform.operatingSystem}'];
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      lines.add('NDEF: unsupported/unformatted');
    } else {
      lines.add('NDEF: formatted');
      lines.add('NDEF writable: ${ndef.isWritable}');
      lines.add('NDEF capacity: ${ndef.maxSize} bytes');
      lines.add('Cached records: ${ndef.cachedMessage?.records.length ?? 0}');
      lines.add('NDEF additional data: ${ndef.additionalData}');
    }

    if (Platform.isAndroid) {
      final androidTag = NfcTagAndroid.from(tag);
      final nfcA = NfcAAndroid.from(tag);
      final ultralight = MifareUltralightAndroid.from(tag);
      if (androidTag != null) {
        lines.add('Hardware ID (diagnostic only): ${_hex(androidTag.id)}');
        lines.add('Android technologies: ${androidTag.techList.join(', ')}');
      }
      if (nfcA != null) {
        lines.add('NFC-A ATQA: ${_hex(nfcA.atqa)}');
        lines.add('NFC-A SAK: 0x${nfcA.sak.toRadixString(16)}');
      }
      if (ultralight != null) {
        lines.add('Android MIFARE type: ${ultralight.type.name}');
        lines.add(await _probeNxpVersionAndroid(ultralight));
      }
    } else if (Platform.isIOS) {
      final mifare = MiFareIos.from(tag);
      if (mifare != null) {
        lines.add('Hardware ID (diagnostic only): ${_hex(mifare.identifier)}');
        lines.add('iOS MIFARE family: ${mifare.mifareFamily.name}');
        lines.add(await _probeNxpVersionIos(mifare));
      }
    }

    if (ndef?.cachedMessage != null) {
      for (
        var index = 0;
        index < ndef!.cachedMessage!.records.length;
        index += 1
      ) {
        lines.add(_describeRecord(index, ndef.cachedMessage!.records[index]));
      }
    }
    return lines.join('\n');
  }

  Future<String> _probeNxpVersionAndroid(MifareUltralightAndroid tag) async {
    try {
      final response = await tag.transceive(Uint8List.fromList([0x60]));
      return _describeNxpVersion(response);
    } catch (error) {
      return 'GET_VERSION: unsupported or failed ($error)';
    }
  }

  Future<String> _probeNxpVersionIos(MiFareIos tag) async {
    try {
      final response = await tag.sendMiFareCommand(
        commandPacket: Uint8List.fromList([0x60]),
      );
      return _describeNxpVersion(response);
    } catch (error) {
      return 'GET_VERSION: unsupported or failed ($error)';
    }
  }

  String _describeNxpVersion(Uint8List bytes) {
    String? likelyModel;
    if (bytes.length >= 8 && bytes[1] == 0x04 && bytes[2] == 0x04) {
      likelyModel = switch (bytes[6]) {
        0x0f => 'NXP NTAG213-compatible',
        0x11 => 'NXP NTAG215-compatible',
        0x13 => 'NXP NTAG216-compatible',
        _ => 'NXP Type 2 tag with unknown storage-size code',
      };
    }
    return 'GET_VERSION: ${_hex(bytes)}'
        '${likelyModel == null ? '' : ' ($likelyModel)'}';
  }

  String _describeRecord(int index, NdefRecord record) {
    final type = utf8.decode(record.type, allowMalformed: true);
    if (record.typeNameFormat == TypeNameFormat.external &&
        type == _externalType) {
      final slotId = utf8.decode(record.payload, allowMalformed: true);
      return 'Record $index: ${record.typeNameFormat.name}, type=$type, '
          'storage-slot ID=$slotId';
    }
    return 'Record $index: ${record.typeNameFormat.name}, type=$type, '
        'payload=<redacted, ${record.payload.length} bytes>';
  }

  String _hex(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> _copyLog() async {
    final report = [
      'Availability: $_availability',
      'Successful reads this run: $_successfulReads',
      '',
      'Last tag:',
      _lastTag,
      '',
      'Event log (newest first):',
      ..._events,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: report));
    _log('Report copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC tag spike — throwaway')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Purpose: validate the exact tags, both phones, and representative '
            'storage placement before choosing the MVP NFC package and hardware.',
          ),
          const SizedBox(height: 12),
          Text('NFC: $_availability'),
          Text('Successful reads this run: $_successfulReads'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _sessionActive ? null : _checkAvailability,
                child: const Text('Check NFC'),
              ),
              FilledButton.tonal(
                onPressed: _sessionActive ? null : _inspect,
                child: const Text('Inspect tag'),
              ),
              FilledButton.tonal(
                onPressed: _sessionActive ? null : _read,
                child: const Text('Read slot ID'),
              ),
              OutlinedButton(
                onPressed: _sessionActive ? _stopSession : null,
                child: const Text('Cancel session'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _slotIdController,
            enabled: !_sessionActive,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Storage-slot identifier',
              helperText:
                  'Use slot-android-a, then slot-ios-b for cross-writing.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _sessionActive ? null : _confirmWrite,
            child: const Text('Write after confirmation'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Last tag', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: _copyLog, child: const Text('Copy report')),
            ],
          ),
          SelectableText(_lastTag),
          const SizedBox(height: 24),
          Text('Event log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_events.isEmpty) const Text('No events yet.'),
          for (final event in _events) ...[
            SelectableText(event),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
