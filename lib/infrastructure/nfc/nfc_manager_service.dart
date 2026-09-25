import 'dart:async';

import 'package:filamanager/infrastructure/nfc/ndef_storage_slot_codec.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart' as platform_ndef_record;
import 'package:nfc_manager/nfc_manager.dart' as platform;
import 'package:nfc_manager/nfc_manager_android.dart' as android;
import 'package:nfc_manager/nfc_manager_ios.dart' as ios;
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart' as platform_ndef;

final class NfcManagerService implements NfcService {
  NfcManagerService() : _manager = platform.NfcManager.instance;

  final platform.NfcManager _manager;
  final _events = StreamController<NfcEvent>.broadcast();
  var _sessionActive = false;
  Completer<NfcWriteResult>? _pendingWrite;

  @override
  Stream<NfcEvent> get events => _events.stream;

  @override
  Future<NfcAvailability> availability() async {
    try {
      return switch (await _manager.checkAvailability()) {
        platform.NfcAvailability.enabled => NfcAvailability.available,
        platform.NfcAvailability.disabled => NfcAvailability.disabled,
        platform.NfcAvailability.unsupported => NfcAvailability.unavailable,
      };
    } catch (_) {
      return NfcAvailability.unavailable;
    }
  }

  @override
  Future<void> cancelSession() async {
    if (!_sessionActive) {
      return;
    }

    final pendingWrite = _pendingWrite;
    await _stopSession(errorMessageIos: 'Tag registration cancelled.');
    if (pendingWrite != null && !pendingWrite.isCompleted) {
      pendingWrite.complete(const NfcWriteCancelled());
    } else {
      _events.add(const NfcScanCancelled());
    }
  }

  @override
  Future<void> scan() async {
    final currentAvailability = await availability();
    if (currentAvailability != NfcAvailability.available) {
      _events.add(NfcScanUnavailable(currentAvailability));
      return;
    }
    if (_sessionActive) {
      _events.add(const NfcScanFailed());
      return;
    }

    _sessionActive = true;
    try {
      await _manager.startSession(
        pollingOptions: const {platform.NfcPollingOption.iso14443},
        alertMessageIos: 'Hold your phone near a FilaManager tag.',
        invalidateAfterFirstReadIos: false,
        onDiscovered: (tag) => unawaited(_readTag(tag)),
        onSessionErrorIos: _handleScanSessionError,
      );
    } catch (_) {
      _sessionActive = false;
      _events.add(const NfcScanFailed());
    }
  }

  Future<void> _readTag(platform.NfcTag tag) async {
    try {
      final ndef = platform_ndef.Ndef.from(tag);
      final message = ndef == null
          ? null
          : ndef.cachedMessage ?? await ndef.read();
      _events.add(NfcContentRead(NdefStorageSlotCodec.decode(message) ?? ''));
      await _stopSession(alertMessageIos: 'Storage-slot tag read.');
    } catch (_) {
      _events.add(const NfcScanFailed());
      await _stopSession(errorMessageIos: 'The tag could not be read.');
    }
  }

  void _handleScanSessionError(ios.NfcReaderSessionErrorIos error) {
    _sessionActive = false;
    if (error.code ==
        ios.NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled) {
      _events.add(const NfcScanCancelled());
    } else {
      _events.add(const NfcScanFailed());
    }
  }

  @override
  Future<NfcWriteResult> writeStorageSlotReference(Uri reference) async {
    final currentAvailability = await availability();
    if (currentAvailability == NfcAvailability.disabled) {
      return const NfcWriteFailed(NfcWriteFailureKind.disabled);
    }
    if (currentAvailability == NfcAvailability.unavailable) {
      return const NfcWriteFailed(NfcWriteFailureKind.unavailable);
    }
    if (_sessionActive) {
      return const NfcWriteFailed(NfcWriteFailureKind.unexpected);
    }

    final message = NdefStorageSlotCodec.encode(reference);
    final result = Completer<NfcWriteResult>();
    _pendingWrite = result;
    _sessionActive = true;

    try {
      await _manager.startSession(
        pollingOptions: const {platform.NfcPollingOption.iso14443},
        alertMessageIos: 'Hold your phone near the tag to register it.',
        invalidateAfterFirstReadIos: false,
        onDiscovered: (tag) =>
            unawaited(_writeTag(tag, message: message, result: result)),
        onSessionErrorIos: (error) {
          _sessionActive = false;
          if (!result.isCompleted) {
            result.complete(_writeSessionError(error));
          }
        },
      );
    } catch (error) {
      _sessionActive = false;
      _pendingWrite = null;
      return _writeFailure(error);
    }

    try {
      return await result.future;
    } finally {
      if (identical(_pendingWrite, result)) {
        _pendingWrite = null;
      }
    }
  }

  Future<void> _writeTag(
    platform.NfcTag tag, {
    required platform_ndef_record.NdefMessage message,
    required Completer<NfcWriteResult> result,
  }) async {
    NfcWriteResult outcome;
    String? successMessage;
    String? errorMessage;
    try {
      final ndef = platform_ndef.Ndef.from(tag);
      if (ndef == null) {
        outcome =
            defaultTargetPlatform == TargetPlatform.android &&
                android.NdefFormatableAndroid.from(tag) != null
            ? const NfcWriteFailed(NfcWriteFailureKind.unformatted)
            : const NfcWriteFailed(NfcWriteFailureKind.incompatible);
        errorMessage = 'Use a preformatted NDEF tag.';
      } else if (!ndef.isWritable) {
        outcome = const NfcWriteFailed(NfcWriteFailureKind.readOnly);
        errorMessage = 'This tag is read-only.';
      } else if (ndef.maxSize < message.byteLength) {
        outcome = const NfcWriteFailed(
          NfcWriteFailureKind.insufficientCapacity,
        );
        errorMessage = 'This tag is too small.';
      } else {
        await ndef.write(message: message);
        outcome = const NfcWriteSucceeded();
        successMessage = 'FilaManager tag registered.';
      }
    } catch (error) {
      outcome = _writeFailure(error);
      errorMessage = 'The tag was not changed.';
    }

    await _stopSession(
      alertMessageIos: successMessage,
      errorMessageIos: errorMessage,
    );
    if (!result.isCompleted) {
      result.complete(outcome);
    }
  }

  NfcWriteResult _writeSessionError(ios.NfcReaderSessionErrorIos error) {
    return switch (error.code) {
      ios.NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled =>
        const NfcWriteCancelled(),
      ios.NfcReaderErrorCodeIos.ndefReaderSessionErrorTagNotWritable =>
        const NfcWriteFailed(NfcWriteFailureKind.readOnly),
      ios.NfcReaderErrorCodeIos.ndefReaderSessionErrorTagSizeTooSmall =>
        const NfcWriteFailed(NfcWriteFailureKind.insufficientCapacity),
      ios.NfcReaderErrorCodeIos.readerTransceiveErrorTagConnectionLost ||
      ios.NfcReaderErrorCodeIos.readerTransceiveErrorTagNotConnected ||
      ios.NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout =>
        const NfcWriteFailed(NfcWriteFailureKind.interrupted),
      _ => const NfcWriteFailed(NfcWriteFailureKind.unexpected),
    };
  }

  NfcWriteResult _writeFailure(Object error) {
    final description = error.toString().toLowerCase();
    if (description.contains('cancel')) {
      return const NfcWriteCancelled();
    }
    if (description.contains('writable') || description.contains('read-only')) {
      return const NfcWriteFailed(NfcWriteFailureKind.readOnly);
    }
    if (description.contains('size') || description.contains('capacity')) {
      return const NfcWriteFailed(NfcWriteFailureKind.insufficientCapacity);
    }
    if (description.contains('lost') ||
        description.contains('disconnect') ||
        description.contains('timeout') ||
        description.contains('transceive') ||
        description.contains('ioexception') ||
        description.contains('io_exception') ||
        description.contains('i/o')) {
      return const NfcWriteFailed(NfcWriteFailureKind.interrupted);
    }
    return const NfcWriteFailed(NfcWriteFailureKind.unexpected);
  }

  Future<void> _stopSession({
    String? alertMessageIos,
    String? errorMessageIos,
  }) async {
    try {
      await _manager.stopSession(
        alertMessageIos: alertMessageIos,
        errorMessageIos: errorMessageIos,
      );
    } catch (_) {
      // A platform session can already be invalidated when cleanup runs.
    } finally {
      _sessionActive = false;
    }
  }
}
