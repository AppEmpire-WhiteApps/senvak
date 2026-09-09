import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

bool isIOSSimulator({
  required bool isIOS,
  required Map<String, String> environment,
}) =>
    isIOS &&
    (environment.containsKey('SIMULATOR_UDID') ||
        environment.containsKey('SIMULATOR_DEVICE_NAME'));

bool isAuditNetworkAvailable(
  List<ConnectivityResult> connectivity, {
  required bool isIOSSimulator,
}) => isIOSSimulator || connectivity.contains(ConnectivityResult.wifi);

class NetworkSnapshot {
  const NetworkSnapshot({
    required this.connected,
    this.ssid,
    this.bssid,
    this.ip,
    this.gateway,
    this.latencyMs,
    this.checkedAt,
  });

  final bool connected;
  final String? ssid;
  final String? bssid;
  final String? ip;
  final String? gateway;
  final int? latencyMs;
  final DateTime? checkedAt;

  String get displayName =>
      ssid?.replaceAll('"', '') ?? (connected ? 'Wi-Fi network' : 'Offline');
}

class SpeedTestResult {
  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.completedAt,
  });

  final double downloadMbps;
  final double uploadMbps;
  final DateTime completedAt;
}

class SpeedTestRunner {
  const SpeedTestRunner();

  static const _baseUrl = 'https://speed.cloudflare.com';
  static const _downloadBytes = 5 * 1024 * 1024;
  static const _uploadBytes = 2 * 1024 * 1024;

  Future<SpeedTestResult> run() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..idleTimeout = const Duration(seconds: 8);
    try {
      final download = await _measureDownload(client);
      final upload = await _measureUpload(client);
      return SpeedTestResult(
        downloadMbps: download,
        uploadMbps: upload,
        completedAt: DateTime.now(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<double> _measureDownload(HttpClient client) async {
    final uri = Uri.parse(
      '$_baseUrl/__down?bytes=$_downloadBytes&ts=${DateTime.now().millisecondsSinceEpoch}',
    );
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    final watch = Stopwatch()..start();
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Download test returned ${response.statusCode}',
        uri: uri,
      );
    }
    var bytes = 0;
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      bytes += chunk.length;
    }
    watch.stop();
    return _megabitsPerSecond(bytes, watch.elapsed);
  }

  Future<double> _measureUpload(HttpClient client) async {
    final uri = Uri.parse('$_baseUrl/__up');
    final request = await client.postUrl(uri);
    request.contentLength = _uploadBytes;
    request.headers.contentType = ContentType.binary;
    final chunk = Uint8List(64 * 1024);
    final watch = Stopwatch()..start();
    var remaining = _uploadBytes;
    while (remaining > 0) {
      final count = math.min(remaining, chunk.length);
      request.add(count == chunk.length ? chunk : chunk.sublist(0, count));
      remaining -= count;
    }
    final response = await request.close().timeout(const Duration(seconds: 20));
    await response.drain<void>().timeout(const Duration(seconds: 20));
    watch.stop();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Upload test returned ${response.statusCode}',
        uri: uri,
      );
    }
    return _megabitsPerSecond(_uploadBytes, watch.elapsed);
  }

  double _megabitsPerSecond(int bytes, Duration elapsed) {
    final seconds = math.max(elapsed.inMicroseconds / 1000000, .001);
    return bytes * 8 / seconds / 1000000;
  }
}

class AuditPoint {
  const AuditPoint({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.reachable,
    this.latencyMs,
    this.ip,
    this.gateway,
    this.photoPath,
    this.downloadMbps,
    this.uploadMbps,
  });

  final String id;
  final DateTime createdAt;
  final String label;
  final bool reachable;
  final int? latencyMs;
  final String? ip;
  final String? gateway;
  final String? photoPath;
  final double? downloadMbps;
  final double? uploadMbps;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'label': label,
    'reachable': reachable,
    'latencyMs': latencyMs,
    'ip': ip,
    'gateway': gateway,
    'photoPath': photoPath,
    'downloadMbps': downloadMbps,
    'uploadMbps': uploadMbps,
  };

  factory AuditPoint.fromJson(Map<String, Object?> json) => AuditPoint(
    id: json['id']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    label: json['label']! as String,
    reachable: json['reachable']! as bool,
    latencyMs: json['latencyMs'] as int?,
    ip: json['ip'] as String?,
    gateway: json['gateway'] as String?,
    photoPath: json['photoPath'] as String?,
    downloadMbps: (json['downloadMbps'] as num?)?.toDouble(),
    uploadMbps: (json['uploadMbps'] as num?)?.toDouble(),
  );
}

class Site {
  const Site({
    required this.id,
    required this.name,
    required this.createdAt,
    this.points = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<AuditPoint> points;

  int get successfulPoints => points.where((point) => point.reachable).length;
  int? get averageLatency {
    final values = points
        .map((point) => point.latencyMs)
        .whereType<int>()
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  int? get reliability =>
      points.isEmpty ? null : (successfulPoints * 100 / points.length).round();

  Site copyWith({String? name, List<AuditPoint>? points}) => Site(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    points: points ?? this.points,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'points': points.map((point) => point.toJson()).toList(),
  };

  factory Site.fromJson(Map<String, Object?> json) => Site(
    id: json['id']! as String,
    name: json['name']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    points: (json['points']! as List<Object?>)
        .map(
          (item) =>
              AuditPoint.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList(),
  );
}

class AppStore {
  AppStore({SpeedTestRunner? speedTestRunner})
    : _speedTestRunner = speedTestRunner ?? const SpeedTestRunner();

  static const _sitesKey = 'senvak.sites.v1';
  final _networkInfo = NetworkInfo();
  final _picker = ImagePicker();
  final SpeedTestRunner _speedTestRunner;
  late final SharedPreferencesAsync _prefs;

  final _sites = signal<List<Site>>([]);
  final _network = signal(const NetworkSnapshot(connected: false));
  final _loadingNetwork = signal(false);
  final _initialized = signal(false);
  final _runningSpeedTest = signal(false);
  final _stubWifi = signal(false);
  final _speedTest = signal<SpeedTestResult?>(null);
  final _speedTestError = signal<String?>(null);
  final _activeSiteId = signal<String?>(null);

  late final _activeSite = computed<Site?>(() {
    if (sites.isEmpty) return null;
    return sites.firstWhere(
      (site) => site.id == activeSiteId,
      orElse: () => sites.first,
    );
  });
  late final _totalPoints = computed(
    () => sites.fold<int>(0, (total, site) => total + site.points.length),
  );

  List<Site> get sites => _sites.value;
  set sites(List<Site> value) => _sites.value = value;

  NetworkSnapshot get network => _network.value;
  set network(NetworkSnapshot value) => _network.value = value;

  bool get loadingNetwork => _loadingNetwork.value;
  set loadingNetwork(bool value) => _loadingNetwork.value = value;

  bool get initialized => _initialized.value;
  set initialized(bool value) => _initialized.value = value;

  bool get runningSpeedTest => _runningSpeedTest.value;
  set runningSpeedTest(bool value) => _runningSpeedTest.value = value;

  bool get stubWifi => _stubWifi.value;
  set stubWifi(bool value) => _stubWifi.value = value;

  SpeedTestResult? get speedTest => _speedTest.value;
  set speedTest(SpeedTestResult? value) => _speedTest.value = value;

  String? get speedTestError => _speedTestError.value;
  set speedTestError(String? value) => _speedTestError.value = value;

  String? get activeSiteId => _activeSiteId.value;
  set activeSiteId(String? value) => _activeSiteId.value = value;

  Site? get activeSite => _activeSite.value;
  int get totalPoints => _totalPoints.value;

  Future<void> initialize() async {
    _prefs = SharedPreferencesAsync();
    final raw = await _prefs.getString(_sitesKey);
    batch(() {
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as List<Object?>;
          sites = decoded
              .map(
                (item) =>
                    Site.fromJson(Map<String, Object?>.from(item! as Map)),
              )
              .toList();
        } on FormatException {
          sites = [];
        }
      }
      if (sites.isNotEmpty) activeSiteId = sites.first.id;
      initialized = true;
    });
    await refreshNetwork(requestAccess: false);
  }

  static const stubNetwork = NetworkSnapshot(
    connected: true,
    ssid: 'Senvak Demo',
    bssid: 'aa:bb:cc:dd:ee:ff',
    ip: '192.168.1.42',
    gateway: '192.168.1.1',
    latencyMs: 18,
  );

  Future<void> connectStubWifi() async {
    if (stubWifi && network.connected) return;
    loadingNetwork = true;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    batch(() {
      stubWifi = true;
      network = NetworkSnapshot(
        connected: stubNetwork.connected,
        ssid: stubNetwork.ssid,
        bssid: stubNetwork.bssid,
        ip: stubNetwork.ip,
        gateway: stubNetwork.gateway,
        latencyMs: stubNetwork.latencyMs,
        checkedAt: DateTime.now(),
      );
      loadingNetwork = false;
    });
  }

  Future<void> refreshNetwork({bool requestAccess = true}) async {
    loadingNetwork = true;
    try {
      if (stubWifi) {
        network = NetworkSnapshot(
          connected: stubNetwork.connected,
          ssid: stubNetwork.ssid,
          bssid: stubNetwork.bssid,
          ip: stubNetwork.ip,
          gateway: stubNetwork.gateway,
          latencyMs: stubNetwork.latencyMs,
          checkedAt: DateTime.now(),
        );
        return;
      }
      final connectivity = await Connectivity().checkConnectivity();
      final simulator = isIOSSimulator(
        isIOS: Platform.isIOS,
        environment: Platform.environment,
      );
      final connected = isAuditNetworkAvailable(
        connectivity,
        isIOSSimulator: simulator,
      );
      if (!connected) {
        network = NetworkSnapshot(connected: false, checkedAt: DateTime.now());
      } else if (simulator) {
        network = NetworkSnapshot(
          connected: true,
          ssid: 'iOS Simulator',
          latencyMs: await _measureLatency(null),
          checkedAt: DateTime.now(),
        );
      } else {
        final gateway = await _networkInfo.getWifiGatewayIP();
        network = NetworkSnapshot(
          connected: true,
          ssid: Platform.isIOS ? null : await _networkInfo.getWifiName(),
          bssid: Platform.isIOS ? null : await _networkInfo.getWifiBSSID(),
          ip: await _networkInfo.getWifiIP(),
          gateway: gateway,
          latencyMs: await _measureLatency(gateway),
          checkedAt: DateTime.now(),
        );
      }
    } catch (_) {
      network = NetworkSnapshot(connected: false, checkedAt: DateTime.now());
    } finally {
      loadingNetwork = false;
    }
  }

  Future<int?> _measureLatency(String? gateway) async {
    final host = gateway ?? '1.1.1.1';
    final watch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      watch.stop();
      return watch.elapsedMilliseconds;
    } on SocketException {
      return null;
    }
  }

  Future<void> runSpeedTest() async {
    if (runningSpeedTest) return;
    batch(() {
      runningSpeedTest = true;
      speedTest = null;
      speedTestError = null;
    });
    try {
      speedTest = await _speedTestRunner.run();
    } catch (_) {
      speedTestError = 'Speed test could not reach the test server. Try again.';
    } finally {
      runningSpeedTest = false;
    }
  }

  Future<Site> addSite(String name) async {
    final site = Site(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    batch(() {
      sites = [site, ...sites];
      activeSiteId = site.id;
    });
    await _save();
    return site;
  }

  void selectSite(String id) {
    activeSiteId = id;
  }

  Future<void> deleteSite(String id) async {
    batch(() {
      sites = sites.where((site) => site.id != id).toList();
      activeSiteId = sites.isEmpty ? null : sites.first.id;
    });
    await _save();
  }

  Future<AuditPoint?> capturePoint({
    required String label,
    bool takePhoto = false,
  }) async {
    final site = activeSite;
    if (site == null) return null;
    await refreshNetwork();
    String? photoPath;
    if (takePhoto) {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (image == null) return null;
      photoPath = await _persistPhoto(image);
    }
    final point = AuditPoint(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      label: label.trim().isEmpty ? 'Point ${site.points.length + 1}' : label,
      reachable: network.connected && network.latencyMs != null,
      latencyMs: network.latencyMs,
      ip: network.ip,
      gateway: network.gateway,
      photoPath: photoPath,
      downloadMbps: speedTest?.downloadMbps,
      uploadMbps: speedTest?.uploadMbps,
    );
    final updated = site.copyWith(points: [...site.points, point]);
    batch(() {
      sites = sites.map((item) => item.id == site.id ? updated : item).toList();
      speedTest = null;
    });
    await _save();
    return point;
  }

  Future<String> _persistPhoto(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final photos = Directory('${directory.path}/audit_photos');
    await photos.create(recursive: true);
    final extension = image.path.split('.').last;
    final target = File(
      '${photos.path}/${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await File(image.path).copy(target.path);
    return target.path;
  }

  Future<void> deletePoint(String pointId) async {
    final site = activeSite;
    if (site == null) return;
    final removed = site.points.where((point) => point.id == pointId);
    for (final point in removed) {
      if (point.photoPath case final path?) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    final updated = site.copyWith(
      points: site.points.where((point) => point.id != pointId).toList(),
    );
    sites = sites.map((item) => item.id == site.id ? updated : item).toList();
    await _save();
  }

  Future<void> shareReport() async {
    final site = activeSite;
    if (site == null) return;
    final directory = await getTemporaryDirectory();
    final safeName = site.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/senvak_$safeName.csv');
    final buffer = StringBuffer()
      ..writeln(
        'Site,Point,Date,Reachable,Latency ms,Download Mbps,Upload Mbps,IP,Gateway,Photo',
      );
    for (final point in site.points) {
      buffer.writeln(
        [
          _csv(site.name),
          _csv(point.label),
          point.createdAt.toIso8601String(),
          point.reachable,
          point.latencyMs ?? '',
          point.downloadMbps ?? '',
          point.uploadMbps ?? '',
          point.ip ?? '',
          point.gateway ?? '',
          _csv(point.photoPath ?? ''),
        ].join(','),
      );
    }
    await file.writeAsString(buffer.toString(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Senvak audit · ${site.name}',
        text:
            'Measured ${site.points.length} points on ${network.displayName}.',
      ),
    );
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> _save() => _prefs.setString(
    _sitesKey,
    jsonEncode(sites.map((site) => site.toJson()).toList()),
  );
}
