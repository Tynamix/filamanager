abstract interface class IncomingLinkService {
  Stream<Uri> get links;
}

final class NoIncomingLinkService implements IncomingLinkService {
  const NoIncomingLinkService();

  @override
  Stream<Uri> get links => const Stream.empty();
}
