sealed class NfcEvent {
  const NfcEvent();
}

enum NfcAvailability { available, disabled, unavailable }

sealed class NfcWriteResult {
  const NfcWriteResult();
}

final class NfcWriteSucceeded extends NfcWriteResult {
  const NfcWriteSucceeded();
}

final class NfcWriteCancelled extends NfcWriteResult {
  const NfcWriteCancelled();
}

enum NfcWriteFailureKind {
  disabled,
  unavailable,
  incompatible,
  unformatted,
  readOnly,
  insufficientCapacity,
  interrupted,
  unexpected,
}

final class NfcWriteFailed extends NfcWriteResult {
  const NfcWriteFailed(this.kind);

  final NfcWriteFailureKind kind;
}

final class NfcUriPayloadRead extends NfcEvent {
  const NfcUriPayloadRead(this.payload);

  final Uri payload;
}

final class NfcContentRead extends NfcEvent {
  const NfcContentRead(this.content);

  final String content;
}

enum NfcTagFailureKind { incompatible, unformatted }

final class NfcTagRejected extends NfcEvent {
  const NfcTagRejected(this.kind);

  final NfcTagFailureKind kind;
}

final class NfcScanUnavailable extends NfcEvent {
  const NfcScanUnavailable(this.availability);

  final NfcAvailability availability;
}

final class NfcScanCancelled extends NfcEvent {
  const NfcScanCancelled();
}

final class NfcScanFailed extends NfcEvent {
  const NfcScanFailed();
}

abstract interface class NfcService {
  Stream<NfcEvent> get events;

  Future<NfcAvailability> availability();

  Future<void> cancelSession();

  Future<void> scan();

  Future<NfcWriteResult> writeStorageSlotReference(Uri reference);
}

final class UnavailableNfcService implements NfcService {
  const UnavailableNfcService();

  @override
  Stream<NfcEvent> get events => const Stream.empty();

  @override
  Future<NfcAvailability> availability() async => NfcAvailability.unavailable;

  @override
  Future<void> cancelSession() async {}

  @override
  Future<void> scan() async {}

  @override
  Future<NfcWriteResult> writeStorageSlotReference(Uri reference) async {
    return const NfcWriteFailed(NfcWriteFailureKind.unavailable);
  }
}
