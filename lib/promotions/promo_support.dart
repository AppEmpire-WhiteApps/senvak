import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

// Advertising-only adapter for the existing palette in main.dart.
abstract final class PromoColors {
  static const background = Color(0xFF080B0C); // ink
  static const surface = Color(0xFF111718); // panel
  static const border = Color(0xFF263031); // line
  static const mint = Color(0xFF66F5D2);
  static const lime = Color(0xFFCCFF62);
  static const text = CupertinoColors.white;
  static const textSecondary = Color(0xFF8A9997); // muted
  static const onAccent = background;
}

Uri? promotionUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      !uri.hasAuthority ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}

Future<void> openPromotionUrl(Uri? uri) async {
  if (uri == null || promotionUri(uri.toString()) == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // An unavailable browser or platform handler must not interrupt the app.
  }
}
