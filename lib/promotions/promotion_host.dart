import 'dart:async';

import 'package:flutter/widgets.dart';

import 'promotion_navigation.dart';
import 'remote_config_service.dart';
import 'vpn_fullscreen_banner.dart';

class PromotionScope extends InheritedNotifier<RemoteConfigService> {
  const PromotionScope({
    required RemoteConfigService service,
    required this.language,
    required this.active,
    required super.child,
    super.key,
  }) : super(notifier: service);

  final String language;
  final bool active;

  static PromotionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PromotionScope>();

  @override
  bool updateShouldNotify(PromotionScope oldWidget) =>
      language != oldWidget.language ||
      active != oldWidget.active ||
      super.updateShouldNotify(oldWidget);
}

/// Owns advertising only while the initialized workspace is mounted.
class PromotionHost extends StatefulWidget {
  const PromotionHost({required this.child, super.key});

  final Widget child;

  @override
  State<PromotionHost> createState() => _PromotionHostState();
}

class _PromotionHostState extends State<PromotionHost>
    with WidgetsBindingObserver {
  final _service = RemoteConfigService();
  Timer? _initialTimer;
  Timer? _periodicTimer;
  late bool _resumed;
  late String _language;
  bool _initialDelayElapsed = false;
  bool _firstShowPending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _updateLanguage();
    _service.addListener(_onConfigChanged);
    _service.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialTimer = Timer(const Duration(seconds: 2), () {
        _initialDelayElapsed = true;
        _tryShow();
      });
      _periodicTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _tryShow(),
      );
    });
  }

  void _updateLanguage() {
    // MaterialApp supports English only. Ads use the actual device locale
    // without changing the rest of the app's localization behavior.
    final language =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _language = language == 'ru' ? 'ru' : 'en';
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(_updateLanguage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _resumed = state == AppLifecycleState.resumed);
  }

  void _onConfigChanged() {
    // A slow first fetch may finish after the initial two-second delay.
    if (_firstShowPending) _tryShow();
  }

  void _tryShow() {
    if (!mounted || !_resumed || !_initialDelayElapsed) return;
    final navigator = Navigator.of(context);
    if (navigator.userGestureInProgress ||
        !PromotionNavigation.isSettled(navigator)) {
      return;
    }
    final route = ModalRoute.of(context);
    // A sheet, dialog, pushed detail/paywall, or route transition wins over ads.
    if (route == null ||
        !route.isCurrent ||
        route.animation?.status != AnimationStatus.completed ||
        (route.secondaryAnimation != null &&
            route.secondaryAnimation!.status != AnimationStatus.dismissed)) {
      return;
    }
    final config = _service.config;
    if (config == null || !config.canShowBanner) return;
    _firstShowPending = false;
    unawaited(
      VpnFullscreenBanner.show(
        context,
        details: config.banner,
        language: _language,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialTimer?.cancel();
    _periodicTimer?.cancel();
    _service.removeListener(_onConfigChanged);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PromotionScope(
    service: _service,
    language: _language,
    active: _resumed && (ModalRoute.of(context)?.isCurrent ?? false),
    child: widget.child,
  );
}
