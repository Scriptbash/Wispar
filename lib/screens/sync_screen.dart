import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
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

  DateTime? _lastSyncDate;
  String? _errorMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (pbService.isAuthenticated) {
      _urlController.text = pbService.baseURL;
      _isSelfHosted = pbService.baseURL != 'https://sync.wispar.app';
    } else {
      _isSelfHosted = false;
      _urlController.text = '';
    }
    _loadLastSync();
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
        // Don't log the user until the user verify their email
        pbService.client.authStore.clear();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.checkEmail),
            content: Text(AppLocalizations.of(context)!.checkEmailDescription),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isRegisterMode = false);
                  _passwordController.clear();
                },
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      } else {
        await pbService.client.collection('users').authWithPassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

        if (!pbService.isVerified) {
          pbService.client.authStore.clear();
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.emailNotVerifiedError;
          });
          return;
        }

        setState(() {});
        logger.info('Logged in a cloud account.');
        await _runSync();
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getCleanErrorMessage(e);
      });
      logger.severe('Failed to authenticate.', e, stackTrace);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleResendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSyncing = true);
    try {
      await pbService.resendVerification(email);
      _startResendCooldown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.checkEmailDescription)),
      );
    } catch (e) {
      setState(() => _errorMessage = _getCleanErrorMessage(e));
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
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

  Future<void> _loadLastSync() async {
    final rawDate = await dbHelper.getLastSync();
    if (rawDate != null) {
      if (mounted) {
        setState(() {
          _lastSyncDate = DateTime.parse(rawDate).toLocal();
        });
      }
    }
  }

  Future<void> _runSync() async {
    setState(() => _isSyncing = true);
    try {
      await syncManager.sync(isFullSync: true);
      await _loadLastSync();
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
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
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
                setState(() {
                  _errorMessage = null;
                  _isSelfHosted = value.first;
                });

                if (!_isSelfHosted) {
                  const prodUrl = 'https://sync.wispar.app';
                  await pbService.updateCustomUrl(prodUrl);
                  _urlController.text = prodUrl;
                } else {
                  _urlController.text = '';
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.serverUrl,
                  hintText: 'http://192.168.1.50:8090',
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
            if (_errorMessage != null &&
                _errorMessage!.contains("verify") &&
                !_isRegisterMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextButton.icon(
                  onPressed: (_resendCooldown > 0 || _isSyncing)
                      ? null
                      : _handleResendVerification,
                  icon: const Icon(Icons.email),
                  label: Text(
                    _resendCooldown > 0
                        ? AppLocalizations.of(context)!
                            .waitResendEmail(_resendCooldown)
                        : AppLocalizations.of(context)!.resendEmail,
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
              elevation: 3,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    pbService.client.authStore.record
                                            ?.get<String>("email") ??
                                        "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  pbService.client.authStore.clear();
                                  _clearAuthForm();
                                  setState(() => _lastSyncDate = null);
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child:
                                    Text(AppLocalizations.of(context)!.logout),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .syncServer(_urlController.text),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                          if (_lastSyncDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                AppLocalizations.of(context)!.lastSync(
                                  DateFormat.yMMMd(
                                          Localizations.localeOf(context)
                                              .languageCode)
                                      .add_jm()
                                      .format(_lastSyncDate!),
                                ),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
