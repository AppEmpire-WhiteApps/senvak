import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'app_data.dart';
import 'audit_controllers.dart';
import 'core/settings/audit_desk_info_panel.dart';

void _trackAppLaunch() {
  var launchTracked = false;
  Clarity.setOnSessionStartedCallback((_) {
    if (!launchTracked) {
      launchTracked = Clarity.sendCustomEvent('app_launch');
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _trackAppLaunch();
  DartPluginRegistrant.ensureInitialized();
  runApp(
    ClarityWidget(
      clarityConfig: ClarityConfig(projectId: 'ycmdzp3gnf'),
      app: const SenvakApp(),
    ),
  );
}

const ink = Color(0xFF080B0C);
const panel = Color(0xFF111718);
const line = Color(0xFF263031);
const mint = Color(0xFF66F5D2);
const lime = Color(0xFFCCFF62);
const muted = Color(0xFF8A9997);
const orange = Color(0xFFFF9B54);

class SenvakApp extends StatelessWidget {
  const SenvakApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Senvak',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        surface: panel,
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xF20C1112),
        indicatorColor: Color(0xFF213F39),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    home: const SenvakLaunchGate(),
  );
}

class SenvakLaunchGate extends StatelessWidget {
  const SenvakLaunchGate({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: SharedPreferences.getInstance().then(
      (prefs) => prefs.getBool('senvak.onboarding.completed') ?? false,
    ),
    builder: (_, snapshot) =>
        snapshot.data == true ? const AppLoader() : const Onboarding(),
  );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final controller = PageController();
  late final AuditIntroController intro = AuditIntroController(
    slideCount: slides.length,
  );
  static const slides = [
    (
      'See the invisible.',
      'Document Wi-Fi performance room by room with real network measurements.',
      'assets/onboarding/office_scan.png',
      '01 / MAP',
    ),
    (
      'Walk. Measure. Know.',
      'Capture latency, network details, notes and photos as you move.',
      'assets/onboarding/live_audit.png',
      '02 / AUDIT',
    ),
    (
      'Keep the evidence.',
      'Store every audit on-device and share a CSV report with your IT team.',
      'assets/onboarding/insights.png',
      '03 / REPORT',
    ),
  ];

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('senvak.onboarding.completed', true);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppLoader()));
  }

  void next() {
    if (!intro.isFinalSlide) {
      controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      complete();
    }
  }

  @override
  Widget build(BuildContext context) => Watch(
    (context) => Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: intro.showSlide,
            itemBuilder: (_, index) {
              final slide = slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(slide.$3, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x11080B0C),
                          Color(0x66080B0C),
                          Color(0xFF080B0C),
                        ],
                        stops: [0, .55, .85],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Brand(),
                          const Spacer(),
                          Text(
                            slide.$4,
                            style: const TextStyle(
                              color: mint,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.$1,
                            style: const TextStyle(
                              fontSize: 44,
                              height: .98,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.$2,
                            style: const TextStyle(
                              color: Color(0xFFB4C0BE),
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  ...List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: index == intro.value ? 24 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: index == intro.value ? mint : line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: next,
                    icon: Icon(
                      intro.isFinalSlide
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: ink,
                      minimumSize: const Size(62, 62),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.radar_rounded, color: mint, size: 25),
      SizedBox(width: 9),
      Text(
        'SENVAK',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.4,
        ),
      ),
    ],
  );
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});
  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  final store = AppStore();
  @override
  void initState() {
    super.initState();
    store.initialize();
  }

  @override
  Widget build(BuildContext context) => Watch(
    (context) => store.initialized
        ? Shell(store: store)
        : const Scaffold(
            body: Center(child: CircularProgressIndicator(color: mint)),
          ),
  );
}

class Shell extends StatefulWidget {
  const Shell({required this.store, super.key});
  final AppStore store;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final WorkspaceTabsController tabs = WorkspaceTabsController();

  @override
  Widget build(BuildContext context) => Watch(
    (context) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tabs.value,
          children: [
            Overview(store: widget.store),
            SitesScreen(store: widget.store),
            HistoryScreen(store: widget.store),
            const SenvakSettings(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.value,
        onDestinationSelected: tabs.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers_rounded),
            label: 'Sites',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    ),
  );
}

class SenvakSettings extends StatelessWidget {
  const SenvakSettings({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
    children: const [
      Text(
        'SETTINGS',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
      ),
      SizedBox(height: 10),
      Text('Manage Senvak and get help.', style: TextStyle(color: muted)),
      SizedBox(height: 24),
      AuditDeskInfoPanel(appName: 'Senvak', accent: mint, textColor: muted),
    ],
  );
}

class PageTop extends StatelessWidget {
  const PageTop(this.eyebrow, this.title, {this.onRefresh, super.key});
  final String eyebrow;
  final String title;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: mint,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                height: 1,
                letterSpacing: -1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      if (onRefresh != null)
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: panel,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: line),
          ),
        ),
    ],
  );
}

class Overview extends StatelessWidget {
  const Overview({required this.store, super.key});
  final AppStore store;

  @override
  Widget build(BuildContext context) => Watch((context) {
    final network = store.network;
    final site = store.activeSite;
    return RefreshIndicator(
      onRefresh: store.refreshNetwork,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          PageTop(
            'CURRENT CONNECTION',
            network.displayName,
            onRefresh: store.loadingNetwork ? null : store.refreshNetwork,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    pulse(network.connected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            network.connected ? 'Wi-Fi connected' : 'No Wi-Fi',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            network.checkedAt == null
                                ? 'Checking network…'
                                : 'Measured on this device',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (store.loadingNetwork)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    metric(
                      'LATENCY',
                      network.latencyMs == null
                          ? '—'
                          : '${network.latencyMs} ms',
                    ),
                    metric('LOCAL IP', network.ip ?? '—'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    metric('GATEWAY', network.gateway ?? '—'),
                    metric('BSSID', network.bssid ?? 'Unavailable'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (site == null)
            EmptyCard(
              icon: Icons.domain_add_outlined,
              title: 'Create your first site',
              subtitle: 'A site groups real measurements from one location.',
              button: 'CREATE SITE',
              onTap: () => showAddSite(context, store),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: lime,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: ink, size: 32),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.name.toUpperCase(),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${site.points.length} saved measurement${site.points.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xAA080B0C),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (site.averageLatency case final latency?)
                    Text(
                      '$latency ms',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: store.loadingNetwork
                  ? null
                  : () async {
                      if (!store.network.connected) {
                        await store.connectStubWifi();
                      }
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuditScreen(store: store),
                        ),
                      );
                    },
              icon: Icon(
                network.connected ? Icons.radar_rounded : Icons.wifi_rounded,
              ),
              label: Text(
                store.loadingNetwork && !network.connected
                    ? 'CONNECTING…'
                    : network.connected
                    ? 'START LIVE AUDIT'
                    : 'CONNECT TO WI-FI TO AUDIT',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: mint,
                foregroundColor: ink,
                disabledBackgroundColor: line,
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            if (site.points.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: store.shareReport,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('SHARE CSV REPORT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: lime,
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 28),
          const SectionLabel('RECENT MEASUREMENTS'),
          const SizedBox(height: 12),
          if (site == null || site.points.isEmpty)
            const Text(
              'No measurements yet.',
              style: TextStyle(color: muted, fontSize: 12),
            )
          else
            ...site.points.reversed
                .take(3)
                .map((point) => PointTile(point: point)),
        ],
      ),
    );
  });
}

Widget pulse(bool connected) => Container(
  width: 46,
  height: 46,
  decoration: BoxDecoration(
    color: (connected ? mint : orange).withValues(alpha: .12),
    shape: BoxShape.circle,
  ),
  child: Icon(
    connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
    color: connected ? mint : orange,
  ),
);

Widget metric(String title, String value) => Expanded(
  child: Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: muted,
            fontSize: 8,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  ),
);

class SitesScreen extends StatelessWidget {
  const SitesScreen({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Watch(
    (context) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const PageTop('SAVED ON THIS DEVICE', 'Audit sites'),
        const SizedBox(height: 24),
        if (store.sites.isEmpty)
          EmptyCard(
            icon: Icons.layers_outlined,
            title: 'No sites yet',
            subtitle: 'Create a real location before collecting data.',
            button: 'CREATE SITE',
            onTap: () => showAddSite(context, store),
          )
        else
          ...store.sites.map(
            (site) => SiteTile(
              site: site,
              selected: site.id == store.activeSiteId,
              onTap: () => store.selectSite(site.id),
              onDelete: () => confirmDelete(context, store, site),
            ),
          ),
        if (store.sites.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showAddSite(context, store),
            icon: const Icon(Icons.add_rounded),
            label: const Text('ADD SITE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: mint,
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: line),
            ),
          ),
        ],
      ],
    ),
  );
}

class SiteTile extends StatelessWidget {
  const SiteTile({
    required this.site,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    super.key,
  });
  final Site site;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    color: selected ? const Color(0xFF18302C) : panel,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: selected ? mint : line),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      leading: Icon(Icons.apartment_rounded, color: selected ? mint : muted),
      title: Text(
        site.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${site.points.length} points · ${site.averageLatency == null ? 'not measured' : '${site.averageLatency} ms avg'}',
        style: const TextStyle(color: muted, fontSize: 11),
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded, color: muted, size: 20),
      ),
    ),
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Watch((context) {
    final points =
        store.sites
            .expand((site) => site.points.map((point) => (site, point)))
            .toList()
          ..sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        PageTop('${points.length} MEASUREMENTS', 'History'),
        const SizedBox(height: 24),
        if (points.isEmpty)
          const EmptyCard(
            icon: Icons.history_rounded,
            title: 'History is empty',
            subtitle: 'Captured audit points will appear here.',
          )
        else
          ...points.map(
            (entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.$1.name.toUpperCase(),
                  style: const TextStyle(
                    color: mint,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                PointTile(point: entry.$2),
              ],
            ),
          ),
      ],
    );
  });
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({required this.store, super.key});
  final AppStore store;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final label = TextEditingController();
  late final AuditDraftController draft = AuditDraftController();

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    draft.beginSaving();
    final point = await widget.store.capturePoint(
      label: label.text,
      takePhoto: draft.takePhoto,
    );
    if (!mounted) return;
    draft.finishSaving();
    if (point != null) {
      label.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${point.label} saved on this device')),
      );
    }
  }

  String speed(double value) => value.toStringAsFixed(value >= 100 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final network = widget.store.network;
      final site = widget.store.activeSite!;
      final speedTest = widget.store.speedTest;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Add measurement',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  site.name.toUpperCase(),
                  style: const TextStyle(
                    color: mint,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            const Text(
              'Record this spot',
              style: TextStyle(
                fontSize: 29,
                height: 1.05,
                letterSpacing: -.8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Name the location, check the connection, then save one reliable snapshot.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: network.connected ? mint : line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (network.connected ? mint : orange).withValues(
                            alpha: .12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          network.connected
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: network.connected ? mint : orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              network.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              network.connected
                                  ? 'Ready to measure'
                                  : 'Connect to Wi-Fi to measure',
                              style: TextStyle(
                                color: network.connected ? mint : orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh connection',
                        onPressed: widget.store.loadingNetwork
                            ? null
                            : widget.store.refreshNetwork,
                        icon: widget.store.loadingNetwork
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      metric(
                        'LATENCY',
                        network.latencyMs == null
                            ? '—'
                            : '${network.latencyMs} ms',
                      ),
                      metric('LOCAL IP', network.ip ?? '—'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: lime),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Internet speed',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Uses about 7 MB of data',
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed:
                            !network.connected || widget.store.runningSpeedTest
                            ? null
                            : widget.store.runSpeedTest,
                        child: Text(speedTest == null ? 'RUN TEST' : 'RETEST'),
                      ),
                    ],
                  ),
                  if (widget.store.runningSpeedTest) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: lime),
                    const SizedBox(height: 8),
                    const Text(
                      'Testing download and upload…',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                  ] else if (speedTest != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SpeedValue(
                          icon: Icons.south_rounded,
                          label: 'DOWNLOAD',
                          value: speed(speedTest.downloadMbps),
                        ),
                        const SizedBox(width: 10),
                        _SpeedValue(
                          icon: Icons.north_rounded,
                          label: 'UPLOAD',
                          value: speed(speedTest.uploadMbps),
                        ),
                      ],
                    ),
                  ] else if (widget.store.speedTestError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.store.speedTestError!,
                      style: const TextStyle(color: orange, fontSize: 10),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Optional. Results will be included with this measurement.',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('MEASUREMENT DETAILS'),
            const SizedBox(height: 10),
            TextField(
              controller: label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Room or checkpoint',
                hintText: 'Meeting room Atlas',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: panel,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                value: draft.takePhoto,
                onChanged: draft.saving ? null : draft.selectPhotoCapture,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                secondary: const Icon(Icons.camera_alt_outlined, color: mint),
                title: const Text(
                  'Attach room photo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Opens the camera after tapping save',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: draft.saving || !network.connected ? null : capture,
              icon: draft.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink,
                      ),
                    )
                  : const Icon(Icons.add_location_alt_outlined),
              label: Text(
                network.connected ? 'SAVE MEASUREMENT' : 'WI-FI REQUIRED',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: ink,
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SectionLabel('SAVED IN THIS AUDIT · ${site.points.length}'),
            const SizedBox(height: 10),
            if (site.points.isEmpty)
              const Text('No saved points yet.', style: TextStyle(color: muted))
            else
              ...site.points.reversed.map(
                (point) => Dismissible(
                  key: ValueKey(point.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade900,
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                  onDismissed: (_) => widget.store.deletePoint(point.id),
                  child: PointTile(point: point),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SpeedValue extends StatelessWidget {
  const _SpeedValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: mint, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value Mbps',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class PointTile extends StatelessWidget {
  const PointTile({required this.point, super.key});
  final AuditPoint point;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: line),
    ),
    child: Row(
      children: [
        if (point.photoPath case final path?)
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              File(path),
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: muted),
            ),
          )
        else
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (point.reachable ? mint : orange).withValues(alpha: .11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              point.reachable
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              color: point.reachable ? mint : orange,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${point.createdAt.hour.toString().padLeft(2, '0')}:${point.createdAt.minute.toString().padLeft(2, '0')} · ${point.ip ?? 'No IP'}',
                style: const TextStyle(color: muted, fontSize: 10),
              ),
              if (point.downloadMbps != null && point.uploadMbps != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${point.downloadMbps!.toStringAsFixed(1)} Mbps down · ${point.uploadMbps!.toStringAsFixed(1)} Mbps up',
                  style: const TextStyle(
                    color: mint,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          point.latencyMs == null ? 'FAIL' : '${point.latencyMs} ms',
          style: TextStyle(
            color: point.reachable ? mint : orange,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.button,
    this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? button;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
    ),
    child: Column(
      children: [
        Icon(icon, color: mint, size: 34),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        if (button != null) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: onTap, child: Text(button!)),
        ],
      ],
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: muted,
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w800,
    ),
  );
}

Future<void> showAddSite(BuildContext context, AppStore store) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: panel,
      builder: (context) => _AddSiteSheet(store: store),
    );

class _AddSiteSheet extends StatefulWidget {
  const _AddSiteSheet({required this.store});

  final AppStore store;

  @override
  State<_AddSiteSheet> createState() => _AddSiteSheetState();
}

class _AddSiteSheetState extends State<_AddSiteSheet> {
  final controller = TextEditingController();
  late final SiteCreationController submission = SiteCreationController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> createSite() async {
    if (controller.text.trim().isEmpty) return;
    if (!submission.beginSubmitting()) return;
    await widget.store.addSite(controller.text);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Watch(
    (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'New audit site',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Site name',
              hintText: 'Berlin office',
            ),
            onSubmitted: (_) => createSite(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: submission.submitting ? null : createSite,
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: ink,
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(submission.submitting ? 'CREATING…' : 'CREATE SITE'),
          ),
        ],
      ),
    ),
  );
}

Future<void> confirmDelete(
  BuildContext context,
  AppStore store,
  Site site,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete site?'),
      content: Text(
        '${site.name} and ${site.points.length} saved measurements will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
  if (confirmed == true) await store.deleteSite(site.id);
}
