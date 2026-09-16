# FlowSend

FlowSend is a premium local-network file transfer app for moving files directly between nearby devices.

**Move anything. Anywhere.**

## What It Does

FlowSend supports:

- Multi-file selection from the device file picker.
- Real LAN device discovery using UDP announcements.
- Direct TCP file streaming without loading whole files into memory.
- Live transfer progress, speed, ETA, pause, resume, cancel, and reconnect handling.
- SHA-256 verification before a transfer is reported complete.
- Sending to one device or multiple devices with independent progress and retry.
- Persistent transfer history.
- QR and temporary transfer-link session screens.
- Smart Transfer Check before sending.
- Smart Handoff options: send everything, send new files only, send best photos, or review manually.
- A receiver mode that persists received files and displays live incoming progress.

## How To Use

### Receive On Device B

1. Install and open FlowSend on Device B.
2. Tap **Receive**.
3. Leave the **Ready to receive** screen open.
4. FlowSend starts a local receiver and advertises the device on the Wi-Fi network.

### Send From Device A

1. Connect both devices to the same local Wi-Fi network.
2. Open FlowSend on Device A.
3. Tap **Send Files**.
4. Select one or more photos, videos, documents, or files.
5. Tap **Continue**.
6. Wait for Device B to appear by its real device name.
7. Select one device, or tick multiple devices and tap **Start Transfer**.
8. Review **Smart Transfer Check**:
	- **Send Everything** transfers every selected file.
	- **Send New Only** excludes confirmed exact duplicates.
	- **Send Best Photos** applies conservative filename and file-size heuristics.
	- **Review** lets you choose individual files.
9. Start the transfer and monitor each receiver independently.
10. On Device B, received files appear after verification. Use the open-file action to launch a compatible Android app.

## Smart Duplicate Protection

Before transfer, FlowSend asks the receiver for its existing file inventory. It compares file size and filename first, then calculates SHA-256 only for same-size candidates that need confirmation.

The review separates:

- **New files**: no matching receiver evidence.
- **Exact duplicates**: confirmed matching content.
- **Possible duplicates**: similar metadata, but content is not confirmed equal.
- **Large files**: informational files at or above 1 GB.

FlowSend never deletes files and never silently skips files. Only the user-approved list is passed to the transfer engine.

## Multi-Device Transfers

Select multiple discovered receivers from the Choose Device screen. FlowSend uses one existing `TransferService` per receiver and manages them with `MultiDeviceTransferManager`.

- Transfers are independently tracked.
- One failed receiver does not stop other receivers.
- Failed receivers can be retried individually.
- The manager caps concurrency at two active transfers to limit storage and CPU pressure.
- Each receiver can receive a different final file list after Smart Transfer Check.

## Development Setup

Requirements:

- Flutter stable with Dart 3.4 or later.
- Android SDK with compile SDK 36 for the current `file_picker` dependency.
- Android device or emulator for Android testing.
- macOS and Xcode for iOS builds.

From the `flowsend` directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Install the Android debug build:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.flowsend.flowsend/.MainActivity
```

## Architecture

The app keeps UI, orchestration, and transport separate:

- `DeviceService`: device discovery abstraction. Production discovery uses `LanDeviceService`.
- `TransferTransport`: transport abstraction. Production transfers use `TcpTransferTransport`; mocks remain available for tests.
- `TransferService`: existing single-device transfer state machine.
- `MultiDeviceTransferManager`: independent transfer orchestration for multiple receivers.
- `TcpTransferReceiver`: receiver listener, inventory preflight, streaming writes, and verification acknowledgment.
- `DuplicateProtectionService`: receiver inventory comparison and selective hashing.
- `HistoryService`: local persistent transfer history.

## Current Limitations

- Transfers currently require both devices to be on the same local network.
- TCP transport is LAN-only; cloud, relay, and internet transfer are not included.
- QR and transfer-link screens create temporary session metadata, but do not provide an internet relay.
- Smart Handoff uses conservative file metadata heuristics. It does not claim visual similarity, blur detection, or true photo favorites without additional media-analysis data.
- Incoming transfer approval is not yet a separate accept/decline prompt; the receiver screen accepts the active local session.

## Tests

The test suite includes:
A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
