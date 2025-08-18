
//library persistence_vault;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PersistenceVault {
  PersistenceVault._({
    this.keyPrefix = 'pv:',
    this.iosAccessGroup,
    this.iosSynchronizable = false,
    this.iosAccessibility = KeychainAccessibility.unlocked,
  });

  static PersistenceVault? _instance;
  static PersistenceVault init({
    String keyPrefix = 'pv:',
    String? iosAccessGroup,
    bool iosSynchronizable = false,
    KeychainAccessibility iosAccessibility = KeychainAccessibility.unlocked,
  }) {
    return _instance ??= PersistenceVault._(
      keyPrefix: keyPrefix,
      iosAccessGroup: iosAccessGroup,
      iosSynchronizable: iosSynchronizable,
      iosAccessibility: iosAccessibility,
    );
  }

  static PersistenceVault get I {
    final i = _instance;
    if (i == null) throw StateError('Call PersistenceVault.init() first.');
    return i;
  }

  final String keyPrefix;
  final String? iosAccessGroup;
  final bool iosSynchronizable;
  final KeychainAccessibility iosAccessibility;

  static const _channel = MethodChannel('persistence_vault/methods');
  FlutterSecureStorage? _secure;

  Future<void> _ensureReady() async {
    if (Platform.isIOS) _secure ??= const FlutterSecureStorage();
  }

  String _k(String key) => '$keyPrefix$key';

  IOSOptions get _iosOpts => IOSOptions(
    accessibility: iosAccessibility,
    groupId: iosAccessGroup,
    synchronizable: iosSynchronizable,
  );

  Future<void> writeString(String key, String value) async {
    await _ensureReady();
    final k = _k(key);
    if (Platform.isIOS) {
      await _secure!.write(key: k, value: value, iOptions: _iosOpts);
    } else {
      await _channel.invokeMethod('writeString', {'key': k, 'value': value});
    }
  }

  Future<String?> readString(String key) async {
    await _ensureReady();
    final k = _k(key);
    if (Platform.isIOS) {
      return _secure!.read(key: k, iOptions: _iosOpts);
    } else {
      return await _channel.invokeMethod<String>('readString', {'key': k});
    }
  }

  Future<String?> readAndroidId() async {
    await _ensureReady();
    return await _channel.invokeMethod<String>('getUDID');
  }

  Future<void> delete(String key) async {
    await _ensureReady();
    final k = _k(key);
    if (Platform.isIOS) {
      await _secure!.delete(key: k, iOptions: _iosOpts);
    } else {
      await _channel.invokeMethod('delete', {'key': k});
    }
  }

  Future<bool> containsKey(String key) async {
    await _ensureReady();
    final k = _k(key);
    if (Platform.isIOS) {
      return (await _secure!.read(key: k, iOptions: _iosOpts)) != null;
    } else {
      return await _channel.invokeMethod<bool>('containsKey', {'key': k}) ?? false;
    }
  }

  Future<void> clear() async {
    await _ensureReady();
    if (Platform.isIOS) {
      final all = await _secure!.readAll(iOptions: _iosOpts);
      for (final e in all.keys.where((k) => k.startsWith(keyPrefix))) {
        await _secure!.delete(key: e, iOptions: _iosOpts);
      }
    } else {
      await _channel.invokeMethod('clearWithPrefix', {'prefix': keyPrefix});
    }
  }

  Future<void> writeJson(String key, Object value) async =>
      writeString(key, jsonEncode(value));

  Future<T?> readJson<T>(String key) async {
    final s = await readString(key);
    if (s == null) return null;
    try { return jsonDecode(s) as T; } catch (_) { return null; }
  }
}

