import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'promo_support.dart';

class PromotionDetails {
  const PromotionDetails({
    required this.enabled,
    required this.url,
    required this.closeDelaySeconds,
    required this.locales,
  });

  final bool enabled;
  final Uri? url;
  final int closeDelaySeconds;
  final Map<String, Map<String, String>> locales;

  String text(String key, String language) {
    final localized = locales[language]?[key];
    if (localized != null && localized.trim().isNotEmpty) return localized;
    return locales['en']?[key] ?? '';
  }

  bool get canShow => enabled && url != null;

  factory PromotionDetails.fromJson(Object? value, {required bool fullscreen}) {
    final section = _object(value);
    final enabled = section['enabled'];
    final url = section['url'];
    final delay = fullscreen ? section['close_delay_seconds'] : 0;
    if (enabled is! bool || url is! String || delay is! int || delay < 0) {
      throw const FormatException('Invalid promotion settings');
    }
    final rawLocales = _object(section['locales']);
    final fields = ['title', 'subtitle', if (fullscreen) 'cta_button'];
    final locales = <String, Map<String, String>>{};
    for (final entry in rawLocales.entries) {
      final values = _object(entry.value);
      final translations = <String, String>{};
      for (final field in fields) {
        final text = values[field];
        if (!values.containsKey(field)) continue;
        if (text is! String) {
          throw const FormatException('Invalid promotion translation');
        }
        translations[field] = text;
      }
      locales[entry.key] = Map.unmodifiable(translations);
    }
    if (enabled &&
        fields.any((field) => (locales['en']?[field] ?? '').trim().isEmpty)) {
      throw const FormatException('Missing English promotion fallback');
    }
    return PromotionDetails(
      enabled: enabled,
      url: promotionUri(url),
      closeDelaySeconds: delay,
      locales: Map.unmodifiable(locales),
    );
  }
}

class PromotionConfig {
  const PromotionConfig({
    required this.showAd,
    required this.refreshHours,
    required this.button,
    required this.banner,
  });

  final bool showAd;
  final int refreshHours;
  final PromotionDetails button;
  final PromotionDetails banner;

  bool get canShowButton => showAd && button.canShow;
  bool get canShowBanner => showAd && banner.canShow;

  factory PromotionConfig.fromJson(Object? value) {
    final json = _object(value);
    final showAd = json['show_ad'];
    final refreshHours = json['refresh_hours'];
    if (showAd is! bool || refreshHours is! int || refreshHours <= 0) {
      throw const FormatException('Invalid advertising configuration');
    }
    return PromotionConfig(
      showAd: showAd,
      refreshHours: refreshHours,
      button: PromotionDetails.fromJson(json['vpn_button'], fullscreen: false),
      banner: PromotionDetails.fromJson(json['vpn_banner'], fullscreen: true),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected an advertising configuration object');
  }
  return value;
}

class RemoteConfigService extends ChangeNotifier {
  static final _configUri = Uri.parse(
    'https://gist.githubusercontent.com/Avvanesyannn/'
    '101acc07bfe6f06601c371aeb0bfc085/raw/gistfile1.txt',
  );
  static const _timeout = Duration(seconds: 5);
  static const _defaultRefreshHours = 12;
  static const _maxResponseBytes = 256 * 1024;

  PromotionConfig? _config;
  Timer? _refreshTimer;
  HttpClient? _client;
  bool _disposed = false;
  bool _started = false;

  PromotionConfig? get config => _config;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final client = HttpClient()..connectionTimeout = _timeout;
    _client = client;
    try {
      final config = await _download(client).timeout(_timeout);
      if (_disposed) return;
      _config = config;
      notifyListeners();
    } catch (_) {
      // Fail closed initially; a later failure preserves the last valid config.
    } finally {
      client.close(force: true);
      _client = null;
      if (!_disposed) {
        _refreshTimer = Timer(
          Duration(hours: _config?.refreshHours ?? _defaultRefreshHours),
          () => unawaited(_refresh()),
        );
      }
    }
  }

  Future<PromotionConfig> _download(HttpClient client) async {
    final request = await client.getUrl(_configUri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Advertising config HTTP ${response.statusCode}');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maxResponseBytes) {
        throw const FormatException('Advertising configuration is too large');
      }
      bytes.addAll(chunk);
    }
    return PromotionConfig.fromJson(jsonDecode(utf8.decode(bytes)));
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _client?.close(force: true);
    super.dispose();
  }
}
