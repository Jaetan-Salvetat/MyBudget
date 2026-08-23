# app_updater

Plug-and-play update lifecycle for Android apps: detection, download, and installation of APKs from **GitHub Releases**.

- **Android only** (for now)
- **No UI** — the lib is display-agnostic, the consuming app handles its own UI
- **No state management** — exposes `Future`/`Stream` for consumers to wrap in their own

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  app_updater:
    path: ../app_updater  # or git URL
```

### Android Setup

**AndroidManifest.xml** — add these permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" /> <!-- Android 13+ -->
```

**FileProvider** — required for APK installation on Android 7+. Add to your `AndroidManifest.xml` inside `<application>`:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external" path="." />
</paths>
```

**Minimum SDK**: 21

## Quick Start

### Initialize

```dart
import 'package:app_updater/app_updater.dart';

final updater = await AppUpdater.initialize(UpdateConfig(
  githubOwner: 'your-username',
  githubRepo: 'your-repo',
));
```

### Check for Updates

```dart
try {
  final release = await updater.checkForUpdates();
  if (release != null) {
    print('New version: ${release.version}');
    print('Notes: ${release.notes}');
  }
} on NetworkException {
  // No internet
} on GitHubApiException catch (e) {
  print('GitHub error: ${e.statusCode}');
}
```

### Download

```dart
final release = await updater.checkForUpdates();
if (release != null) {
  updater.downloadUpdate(release).listen(
    (progress) {
      print('${(progress * 100).toStringAsFixed(0)}%');
    },
    onError: (error) {
      // DownloadException after all retries exhausted
    },
    onDone: () {
      print('Download complete');
    },
  );
}
```

### Install

```dart
try {
  await updater.installUpdate('/path/to/downloaded.apk');
} on InstallException catch (e) {
  print('Install failed: ${e.message}');
}
```

## Configuration

```dart
final updater = await AppUpdater.initialize(UpdateConfig(
  githubOwner: 'your-username',        // required
  githubRepo: 'your-repo',             // required
  currentVersion: '1.0.0',             // auto-detected if omitted
  githubToken: 'ghp_...',              // for private repos or higher rate limits
  channel: UpdateChannel.stable,       // stable or beta
  maxRetries: 3,                       // download retry count
  retryDelay: Duration(seconds: 2),    // base delay between retries
));
```

### Custom Version Comparator

```dart
UpdateConfig(
  githubOwner: 'owner',
  githubRepo: 'repo',
  versionComparator: (current, candidate) {
    return int.parse(candidate) > int.parse(current);
  },
);
```

### Custom Asset Selector

```dart
UpdateConfig(
  githubOwner: 'owner',
  githubRepo: 'repo',
  assetSelector: (assets) {
    return assets.where((a) => a.name.contains('arm64')).firstOrNull;
  },
);
```

## Error Handling

All exceptions extend `UpdateException` (sealed class):

| Exception | When | Key Fields |
|---|---|---|
| `NetworkException` | No internet / timeout | `message` |
| `GitHubApiException` | GitHub API error | `statusCode`, `message` |
| `DownloadException` | Download failed after retries | `url`, `attempts` |
| `InstallException` | APK install failed | `filePath` |
| `VersionParseException` | Invalid version string | `version` |

```dart
try {
  final release = await updater.checkForUpdates();
} on UpdateException catch (e) {
  // Catch all update-related errors
  print(e);
}
```

## License

MIT
