# Senvak

**Spatial Wi-Fi audits for modern IT teams.**

Senvak is a Flutter app for walking a site and documenting real Wi-Fi performance — room by room, with evidence. Measure live network details, record checkpoint points with photos and notes, and share a CSV report with your team.

## Features

- **Sites** — group measurements per location (office, floor, campus).
- **Live network snapshot** — connection state, SSID, BSSID, IP, gateway.
- **Latency check** — ping measured on-device against the Wi-Fi gateway.
- **Internet speed test** — download & upload Mbps (~7 MB of data per run).
- **Audit points** — label each room/checkpoint, attach a photo and optional note.
- **History** — every captured point stays on the device with its evidence.
- **CSV report** — export and share the full audit with your IT team.
- **On-device storage** — audit data never leaves the phone except when you share it.

## Getting started

```bash
flutter pub get
flutter run
```

Wi-Fi details (SSID/BSSID) require location permission on Android and iOS; see `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`.

CI for iOS builds is configured in `codemagic.yaml`.
