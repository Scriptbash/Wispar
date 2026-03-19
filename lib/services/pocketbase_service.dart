import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  PocketBaseService._internal();
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;

  bool get isAuthenticated => _client?.authStore.isValid ?? false;
  String get baseURL =>
      _client?.baseURL ??
      'http://10.0.2.2:8090'; // Todo replace with sync.wispar.app

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

    final prefs = await SharedPreferences.getInstance();
    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: () async => prefs.remove('pb_auth'),
    );

    final savedUrl = prefs.getString('pb_custom_url') ??
        'http://10.0.2.2:8090'; // Todo replace with sync.wispar.app

    _client = PocketBase(savedUrl, authStore: store);
    _isInitialized = true;
  }

  Future<RecordAuth> register(String email, String password) async {
    try {
      await client.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'emailVisibility': false,
      });
      return await client.collection('users').authWithPassword(email, password);
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
