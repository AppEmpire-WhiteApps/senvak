import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senvak/promotions/promotion_navigation.dart';
import 'package:senvak/promotions/remote_config_service.dart';
import 'package:senvak/promotions/vpn_fullscreen_banner.dart';

void main() {
  final details = PromotionDetails(
    enabled: true,
    url: Uri.parse('https://example.com/vpn'),
    closeDelaySeconds: 3,
    locales: const {
      'en': {
        'title': 'Secure your connection',
        'subtitle': 'Protect your privacy on any Wi-Fi network.',
        'cta_button': 'Get VPN',
      },
      'ru': {
        'title': 'Защитите своё соединение',
        'subtitle': 'Сохраняйте конфиденциальность в любой сети Wi-Fi.',
        'cta_button': 'Подключить VPN',
      },
    },
  );

  for (final language in ['en', 'ru']) {
    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      testWidgets('$language banner has no inherited underline at $size', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final navigation = PromotionNavigation();
        addTearDown(navigation.dispose);
        final navigatorKey = GlobalKey<NavigatorState>();
        addTearDown(() async {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
          await tester.pumpAndSettle();
        });

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(brightness: Brightness.dark),
            navigatorObservers: [navigation],
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => VpnFullscreenBanner.show(
                    context,
                    details: details,
                    language: language,
                  ),
                  child: const Text('Open banner'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open banner'));
        await tester.pumpAndSettle();

        final banner = find.byType(VpnFullscreenBanner);
        expect(banner, findsOneWidget);
        for (final key in ['title', 'subtitle', 'cta_button']) {
          expect(find.text(details.text(key, language)), findsOneWidget);
        }
        expect(find.text('Ad'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.descendant(of: banner, matching: find.byType(RichText)),
        );
        expect(paragraphs, isNotEmpty);
        for (final paragraph in paragraphs) {
          expect(
            paragraph.text.style?.decoration,
            anyOf(isNull, TextDecoration.none),
            reason: '${paragraph.text.toPlainText()} must not be underlined',
          );
        }
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('3'));
        await tester.pump();
        expect(banner, findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('3'), findsNothing);
        final close = find.byIcon(CupertinoIcons.xmark);
        expect(close.hitTestable(), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(banner, findsNothing);
        expect(find.text('Open banner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
