import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PocketBaseService {
  PocketBaseService._internal();
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;

  bool get isAuthenticated => _client?.authStore.isValid ?? false;
  bool get isVerified =>
      _client?.authStore.record?.getBoolValue('verified') ?? false;
  String get baseURL => _client?.baseURL ?? 'https://sync.wispar.app';

  PocketBase? _client;

  PocketBase get client {
    if (_client == null) {
      throw StateError("PocketBaseService not initialized. Call init() first.");
    }
    return _client!;
  }

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    final secureStorage = const FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final store = AsyncAuthStore(
      save: (String data) async =>
          await secureStorage.write(key: 'pb_auth', value: data),
      initial: await secureStorage.read(key: 'pb_auth'),
      clear: () async => await secureStorage.delete(key: 'pb_auth'),
    );

    final savedUrl =
        prefs.getString('pb_custom_url') ?? 'https://sync.wispar.app';

    _client = PocketBase(savedUrl, authStore: store);
    _isInitialized = true;

    await refreshAuth();
  }

  Future<void> refreshAuth() async {
    if (client.authStore.isValid) {
      try {
        await client.collection('users').authRefresh();
      } catch (e) {
        if (e is ClientException && e.statusCode != 0) {
          client.authStore.clear();
        }
      }
    }
  }

  Future<RecordAuth> register(String email, String password) async {
    try {
      await client.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'emailVisibility': false,
      });
      await client.collection('users').requestVerification(email);
      return await client.collection('users').authWithPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await client.collection('users').requestVerification(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = client.authStore.record?.id;
      if (userId == null) return;

      await client.collection('users').delete(userId);

      client.authStore.clear();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await client.collection('users').requestPasswordReset(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pb_custom_url', newUrl);

    _isInitialized = false;
    await init();
  }
}
