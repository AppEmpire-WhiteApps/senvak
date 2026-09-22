import 'package:flutter/cupertino.dart';

import 'promo_support.dart';
import 'promotion_host.dart';
import 'remote_config_service.dart';

class VpnPromoButton extends StatelessWidget {
  const VpnPromoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PromotionScope.maybeOf(context);
    final config = scope?.notifier?.config;
    if (scope == null || config == null || !config.canShowButton) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TickerMode(
        enabled: scope.active && TickerMode.valuesOf(context).enabled,
        child: Semantics(
          button: true,
          child: _AnimatedPromoCard(
            details: config.button,
            language: scope.language,
          ),
        ),
      ),
    );
  }
}

class _AnimatedPromoCard extends StatefulWidget {
  const _AnimatedPromoCard({required this.details, required this.language});

  final PromotionDetails details;
  final String language;

  @override
  State<_AnimatedPromoCard> createState() => _AnimatedPromoCardState();
}

class _AnimatedPromoCardState extends State<_AnimatedPromoCard>
    with TickerProviderStateMixin {
  bool _opening = false;
  static const _gradientColors = [
    PromoColors.background,
    PromoColors.surface,
    PromoColors.surface,
    PromoColors.background,
  ];

  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _gradientController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _gradientController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final title = widget.details.text('title', widget.language);
    final subtitle = widget.details.text('subtitle', widget.language);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _shimmerAnimation,
        _gradientController,
      ]),
      builder: (context, _) {
        final colors = _interpolateGradient(_gradientController.value);
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openPromotion,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PromoColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: PromoColors.background.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ShimmerPainter(
                                progress: _shimmerAnimation.value,
                              ),
                            ),
                          ),
                        ),
                        _PromoContent(title: title, subtitle: subtitle),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 20,
                  child: Text(
                    'Ad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PromoColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _interpolateGradient(double phase) {
    final position = phase * (_gradientColors.length - 1);
    final index = position.floor().clamp(0, _gradientColors.length - 2);
    final amount = position - index;
    final nextIndex = (index + 1).clamp(0, _gradientColors.length - 1);
    final followingIndex = (index + 2).clamp(0, _gradientColors.length - 1);
    return [
      Color.lerp(_gradientColors[index], _gradientColors[nextIndex], amount)!,
      Color.lerp(
        _gradientColors[nextIndex],
        _gradientColors[followingIndex],
        amount,
      )!,
    ];
  }
}

class _PromoContent extends StatelessWidget {
  const _PromoContent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PromoColors.mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            CupertinoIcons.lock_shield_fill,
            color: PromoColors.mint,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: PromoColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PromoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PromoColors.lime,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.chevron_right,
            color: PromoColors.onAccent,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width * progress;
    final paint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              PromoColors.mint.withValues(alpha: 0),
              PromoColors.mint.withValues(alpha: 0.08),
              PromoColors.mint.withValues(alpha: 0),
            ],
            stops: [0, 0.5, 1],
          ).createShader(
            Rect.fromCenter(
              center: Offset(center, size.height / 2),
              width: size.width * 0.6,
              height: size.height,
            ),
          );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
