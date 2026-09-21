sealed class NfcEvent {
  const NfcEvent();
}

final class NfcUriPayloadRead extends NfcEvent {
  const NfcUriPayloadRead(this.payload);

  final Uri payload;
}

abstract interface class NfcService {
  Stream<NfcEvent> get events;

  Future<void> scan();
}

final class UnavailableNfcService implements NfcService {
  const UnavailableNfcService();

  @override
  Stream<NfcEvent> get events => const Stream.empty();

  @override
  Future<void> scan() async {}
}
