import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:wispar/services/pocketbase_service.dart';
import 'package:wispar/services/sync_service.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/logs_helper.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _isSyncing = false;
  bool _isRegisterMode = false;

  final _urlController = TextEditingController();
  bool _isSelfHosted = false;

  final pbService = PocketBaseService();
  final syncManager = SyncManager();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final logger = LogsService().logger;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController.text = pbService.baseURL;
    _isSelfHosted = pbService.baseURL !=
        'http://10.0.2.2:8090'; // Todo replace with sync.wispar.app
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });
    try {
      if (_isRegisterMode) {
        await pbService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await pbService.client.collection('users').authWithPassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      }

      setState(() {});
      logger.info('Logged in a cloud account.');

      await _runSync();
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getCleanErrorMessage(e);
      });
      logger.severe(
        'Failed to authenticate.',
        e,
        stackTrace,
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccountQmark),
        content: Text(AppLocalizations.of(context)!.deleteAccountExplanation),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.deleteCloudAccount,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSyncing = true);
      try {
        await pbService.deleteAccount();
        _clearAuthForm();
        setState(() {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.accountAndDataDeleted)),
        );
        logger.info('A cloud account was deleted.');
      } catch (e, stackTrace) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteAccountFailed(e)),
        ));
        logger.severe(
          'Failed to delete account.',
          e,
          stackTrace,
        );
      } finally {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
          () => _errorMessage = AppLocalizations.of(context)!.pleaseEnterEmail);
      return;
    }

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await pbService.requestPasswordReset(email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordResetSent)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _getCleanErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _clearAuthForm() {
    _emailController.clear();
    _passwordController.clear();
    _isRegisterMode = false;
    _isSyncing = false;
  }

  Future<void> _runSync() async {
    setState(() => _isSyncing = true);
    try {
      await syncManager.sync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.syncSuccess)),
      );
      logger.info('Cloud syncing was successful.');
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.syncFailed(e))),
      );
      logger.severe(
        'Sync encountered an error.',
        e,
        stackTrace,
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String _getCleanErrorMessage(dynamic e) {
    if (e is! ClientException) return e.toString();

    final data = e.response['data'] as Map<String, dynamic>? ?? {};

    if (e.statusCode == 400) {
      if (data.containsKey('identity') || data.containsKey('email')) {
        final emailErr = data['identity'] ?? data['email'];
        final code = emailErr['code'];

        if (code == 'validation_required') {
          return AppLocalizations.of(context)!.pleaseEnterEmail;
        }
        if (code == 'validation_not_unique') {
          return AppLocalizations.of(context)!.accountAlreadyExists;
        }
        if (code == 'validation_is_email') {
          return AppLocalizations.of(context)!.pleaseEnterValidEmail;
        }
      }

      if (data.containsKey('password')) {
        final passErr = data['password'];
        final code = passErr['code'];

        if (code == 'validation_required') {
          return AppLocalizations.of(context)!.pleaseEnterPassword;
        }
        if (code == 'validation_min_text_constraint') {
          return AppLocalizations.of(context)!.passwordTooShort;
        }
      }

      return AppLocalizations.of(context)!.checkdetailAndTryAgain;
    }

    if (e.statusCode == 401 || e.statusCode == 404) {
      return AppLocalizations.of(context)!.invalidEmailOrPassword;
    }

    return AppLocalizations.of(context)!.cantConnectServer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.cloudSync)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!pbService.isAuthenticated) ...[
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text('Wispar Sync'),
                    icon: Icon(Icons.cloud)),
                ButtonSegment(
                    value: true,
                    label: Text(AppLocalizations.of(context)!.selfHosted),
                    icon: Icon(Icons.dns)),
              ],
              selected: {_isSelfHosted},
              onSelectionChanged: (value) async {
                setState(() => _isSelfHosted = value.first);
                if (!_isSelfHosted) {
                  await pbService.updateCustomUrl(
                      'http://10.0.2.2:8090'); // Todo replace with sync.wispar.app
                  _urlController.text =
                      'http://10.0.2.2:8090'; // Todo replace with sync.wispar.app
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loginToSyncDevices,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_isSelfHosted) ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL (e.g. http://192.168.1.50:8090)',
                  hintText: 'http://your-ip:port',
                  prefixIcon: Icon(Icons.link),
                ),
                onSubmitted: (val) async =>
                    await pbService.updateCustomUrl(val.trim()),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password),
              obscureText: true,
            ),
            if (!_isRegisterMode && !_isSelfHosted)
              TextButton(
                onPressed: _isSyncing ? null : _handleForgotPassword,
                child: Text(AppLocalizations.of(context)!.forgotPassword),
              ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            FilledButton(
              onPressed: _isSyncing
                  ? null
                  : () async {
                      if (_isSelfHosted) {
                        await pbService
                            .updateCustomUrl(_urlController.text.trim());
                      }
                      _handleLogin();
                    },
              child: Text(_isRegisterMode
                  ? AppLocalizations.of(context)!.signUp
                  : AppLocalizations.of(context)!.login),
            ),
            if (!_isSelfHosted)
              TextButton(
                onPressed: () =>
                    setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(_isRegisterMode
                    ? AppLocalizations.of(context)!.haveAnAccount
                    : AppLocalizations.of(context)!.needAnAccount),
              ),
            SizedBox(height: 16),
            if (!_isSelfHosted)
              Text(AppLocalizations.of(context)!.syncDisclaimer)
          ] else ...[
            Card(
              child: ListTile(
                leading: Icon(Icons.cloud_done,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(AppLocalizations.of(context)!
                    .syncServer(_urlController.text)),
                subtitle: Text(AppLocalizations.of(context)!.user(
                    pbService.client.authStore.record?.get<String>("email") ??
                        "Unknown")),
                trailing: TextButton(
                  onPressed: () {
                    pbService.client.authStore.clear();
                    _clearAuthForm();
                    setState(() {});
                  },
                  child: Text(AppLocalizations.of(context)!.logout),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSyncing ? null : _runSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: Text(_isSyncing
                  ? AppLocalizations.of(context)!.syncing
                  : AppLocalizations.of(context)!.syncNow),
            ),
            const SizedBox(height: 48),
            const Divider(),
            TextButton.icon(
              onPressed: _isSyncing ? null : _handleDeleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(AppLocalizations.of(context)!.deleteCloudAccount,
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }
}
