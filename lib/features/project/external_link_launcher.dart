import 'package:url_launcher/url_launcher.dart';

class ExternalLinkLauncher {
  const ExternalLinkLauncher();

  Future<bool> open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
