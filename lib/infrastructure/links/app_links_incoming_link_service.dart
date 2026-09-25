import 'package:app_links/app_links.dart';
import 'package:filamanager/services/incoming_link_service.dart';

final class AppLinksIncomingLinkService implements IncomingLinkService {
  AppLinksIncomingLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;

  @override
  Future<Uri?> takeInitialLink() => _appLinks.getInitialLink();
}
