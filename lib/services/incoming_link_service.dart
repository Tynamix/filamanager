abstract interface class IncomingLinkService {
  Future<Uri?> takeInitialLink();

  Stream<Uri> get links;
}

final class NoIncomingLinkService implements IncomingLinkService {
  const NoIncomingLinkService();

  @override
  Stream<Uri> get links => const Stream.empty();

  @override
  Future<Uri?> takeInitialLink() async => null;
}
