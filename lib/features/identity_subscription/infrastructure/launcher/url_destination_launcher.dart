import 'package:url_launcher/url_launcher.dart';

/// Opens a configured external destination; false when no app can open it.
Future<bool> openExternalDestination(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
