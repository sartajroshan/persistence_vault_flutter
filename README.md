# persistence_vault

**Secure, persistent key–value storage for Flutter.**
- **iOS:** Uses **Keychain** (via `flutter_secure_storage`) — values typically survive uninstall/reinstall.
- **Android:** Uses **SharedPreferences** with **Key/Value Backup** (via `BackupAgentHelper`) — values are backed up to the user’s Google account and restored on reinstall.

> Ideal for small secrets (tokens, user IDs, flags) that must be secure and/or persist across reinstalls.

---

## ✨ Features

- 🔐 Secure on iOS (Keychain)
- ♻️ Restore on Android using Key/Value Backup (no Auto Backup)
- 🧰 Simple Dart API: `writeString`, `readString`, `delete`, `containsKey`, `clear`, plus JSON helpers
- 🏷️ Namespacing via `keyPrefix`
- 🫶 Optional iOS Keychain access group, accessibility, and iCloud Keychain sync

---

## Platform Support

| Platform | Backend                                  | Uninstall Persistence |
|---------|-------------------------------------------|-----------------------|
| iOS     | Keychain (`flutter_secure_storage`)        | ✅ Usually persists   |
| Android | SharedPreferences + Key/Value Backup       | ✅ If Google Backup enabled |

> Android restore requires: user logged into Google, **Backup by Google One** enabled, same package/signing key, and successful backup completed before uninstall.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  persistence_vault: ^0.2.0
```

Then:

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:persistence_vault/persistence_vault.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize once at startup
  PersistenceVault.init(
    keyPrefix: 'nearwala:', // optional namespace
    // iOS-only (optional):
    iosAccessGroup: '$(AppIdentifierPrefix)com.yourcompany.yourapp',
    iosAccessibility: KeychainAccessibility.afterFirstUnlock,
    iosSynchronizable: false, // true to sync via iCloud Keychain
  );

  runApp(const MyApp());
}

// Use anywhere after init()
await PersistenceVault.I.writeString('user_id', 'U123');
final id = await PersistenceVault.I.readString('user_id'); // => 'U123'
final hasId = await PersistenceVault.I.containsKey('user_id'); // true
await PersistenceVault.I.delete('user_id');
```

---

## Android Setup (Key/Value Backup)

This plugin uses a **`BackupAgentHelper`** to include the plugin’s SharedPreferences file in key/value backups.

✅ **Checklist to get restore working**
- Device/emulator is Play-enabled and logged into a Google account.
- **Backup by Google One** is enabled in system settings.
- Your app’s **package name & signing key** remain the same across uninstall/reinstall.
- You successfully triggered a backup **before** uninstall (see testing below).
- You are **not** using Auto Backup (`android:fullBackupContent="false"` is set).

---

## iOS Setup (Keychain)

If you want to use a **custom access group** or share keychain across targets, add to your app’s **`ios/Runner/Info.plist`**:

```xml
<key>KeychainAccessGroups</key>
<array>
  <string>$(AppIdentifierPrefix)com.yourcompany.yourapp</string>
</array>
```

Then pass the same value to `PersistenceVault.init(iosAccessGroup: ...)`.  
If you don’t need a custom group, you can omit `iosAccessGroup`.

> Default accessibility used here is `afterFirstUnlock`. Adjust as needed.

---

## API

```dart
// Initialize (call once)
PersistenceVault.init({
  String keyPrefix = 'pv:',
  String? iosAccessGroup,
  bool iosSynchronizable = false,
  KeychainAccessibility iosAccessibility = KeychainAccessibility.afterFirstUnlock,
});

// String values
Future<void> writeString(String key, String value);
Future<String?> readString(String key);
Future<void> delete(String key);
Future<bool> containsKey(String key);
Future<void> clear(); // clears only keys with your prefix

// JSON helpers
Future<void> writeJson(String key, Object value);
Future<T?> readJson<T>(String key);
```

**Notes**
- Data size should be **small** (a few KB). For larger payloads, store a **pointer/key** here and fetch the real data from your backend.
- `clear()` only affects keys with your `keyPrefix`.

---

## Example

A minimal demo is included in `example/`. Core usage:

```dart
await PersistenceVault.I.writeString('auth_token', 'abc.xyz.123');
final token = await PersistenceVault.I.readString('auth_token');

await PersistenceVault.I.writeJson('profile', {'id': 'U1', 'name': 'Hisham'});
final profile = await PersistenceVault.I.readJson<Map<String, dynamic>>('profile');
```

---

## Testing Android Backup/Restore

> Use **Key/Value Backup transport** (not D2D transport).

1. Ensure the device has Google account + backup enabled.
2. Run your app and write some data.
3. Trigger backup:

```bash
adb shell bmgr enable true
adb shell bmgr transport com.google.android.gms/.backup.BackupTransportService
adb shell bmgr backupnow your.package.name
```

Expect `Package your.package.name with result: Success`.

4. Uninstall and reinstall the **same build/signing key**. On first run, the system should restore your SharedPreferences file and `readString()` should return the previous value.

**Troubleshooting**

- Inspect backup state:
  ```bash
  adb shell dumpsys backup | sed -n '1,200p'
  ```
- Watch logs during backup:
  ```bash
  adb logcat -s BackupManagerService GmsBackupTransport
  ```

---

## Security & Limitations

- **iOS Keychain**: great for secrets; typically survives uninstall/reinstall, but not a device wipe.
- **Android**: SharedPreferences are **not encrypted by default**.
- Backups are **subject to OS policies**: throttling, user settings, account state, etc.
- Not suitable for large data or files.

---

## FAQ

**Q: Will Android always restore my data?**  
A: Restore occurs when the device meets all requirements (Google account, backup enabled, same package/signing). It’s ultimately controlled by the OS and transport.

**Q: Does iOS *guarantee* persistence across uninstall?**  
A: Apple does not hard-guarantee, but in practice Keychain items persist across uninstall/reinstall for the same team prefix and access group. A full device erase removes them.

---
