import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'promo_support.dart';
import 'promotion_navigation.dart';
import 'remote_config_service.dart';

class VpnFullscreenBanner extends StatefulWidget {
  const VpnFullscreenBanner({
    required this.details,
    required this.language,
    super.key,
  });

  final PromotionDetails details;
  final String language;
  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context, {
    required PromotionDetails details,
    required String language,
  }) async {
    if (_isShowing ||
        !context.mounted ||
        !details.canShow ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.userGestureInProgress ||
        !PromotionNavigation.isSettled(navigator)) {
      return;
    }
    _isShowing = true;
    try {
      await navigator.push<void>(
        CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) =>
              VpnFullscreenBanner(details: details, language: language),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<VpnFullscreenBanner> createState() => _VpnFullscreenBannerState();
}

class _VpnFullscreenBannerState extends State<VpnFullscreenBanner>
    with WidgetsBindingObserver {
  Timer? _countdownTimer;
  late int _remainingSeconds;
  late String _language;
  bool _opening = false;

  bool get _canClose => _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Snapshot the accepted config so a refresh cannot reset this countdown.
    _remainingSeconds = widget.details.closeDelaySeconds;
    _language = widget.language;
    if (!_canClose) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        setState(() => _remainingSeconds--);
        if (_canClose) timer.cancel();
      });
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final language =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    setState(() => _language = language == 'ru' ? 'ru' : 'en');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _openPromotion() async {
    if (_opening) return;
    _opening = true;
    try {
      await openPromotionUrl(widget.details.url);
    } finally {
      _opening = false;
    }
  }

  void _close() {
    if (_canClose) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final language = _language;
    final title = widget.details.text('title', language);
    final subtitle = widget.details.text('subtitle', language);
    final cta = widget.details.text('cta_button', language);

    final page = PopScope(
      canPop: _canClose,
      child: CupertinoPageScaffold(
        backgroundColor: PromoColors.background,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPromotion,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PromoColors.background,
                  PromoColors.surface,
                  PromoColors.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Ad',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PromoColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          button: true,
                          enabled: _canClose,
                          label: language == 'ru'
                              ? 'Закрыть рекламу'
                              : 'Close ad',
                          value: _canClose ? null : '$_remainingSeconds',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _close,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: PromoColors.surface,
                                    border: Border.all(
                                      color: PromoColors.border,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: _canClose
                                      ? const Icon(
                                          CupertinoIcons.xmark,
                                          color: PromoColors.text,
                                          size: 14,
                                        )
                                      : Text(
                                          '$_remainingSeconds',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: PromoColors.textSecondary,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    children: [
                                      const Spacer(),
                                      const SizedBox(height: 24),
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: PromoColors.mint.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.shield_fill,
                                          color: PromoColors.mint,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: PromoColors.text,
                                          height: 1.2,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: PromoColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Spacer(),
                                      Semantics(
                                        button: true,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _openPromotion,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 18,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  PromoColors.mint,
                                                  PromoColors.lime,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: PromoColors.mint
                                                      .withValues(alpha: 0.16),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              cta,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: PromoColors.onAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return DefaultTextStyle(
      style: CupertinoTheme.of(context).textTheme.textStyle,
      child: page,
    );
  }
}
