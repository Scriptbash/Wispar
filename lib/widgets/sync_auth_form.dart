import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/pocketbase_service.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class SyncAuthForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const SyncAuthForm({super.key, required this.onLoginSuccess});

  @override
  State<SyncAuthForm> createState() => _SyncAuthFormState();
}

class _SyncAuthFormState extends State<SyncAuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();

  final pbService = PocketBaseService();
  final logger = LogsService().logger;

  bool _isSyncing = false;
  bool _isRegisterMode = false;
  bool _isSelfHosted = false;
  String? _errorMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _isSelfHosted = pbService.baseURL != 'https://sync.wispar.app';
    _urlController.text = _isSelfHosted ? pbService.baseURL : '';
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final url = _urlController.text.trim();

    if (_isSelfHosted && url.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.invalidUrl);
      return;
    }

    if (email.isEmpty) {
      setState(
          () => _errorMessage = AppLocalizations.of(context)!.pleaseEnterEmail);
      return;
    }

    if (password.isEmpty) {
      setState(() =>
          _errorMessage = AppLocalizations.of(context)!.pleaseEnterPassword);
      return;
    }
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      if (_isSelfHosted) {
        await pbService.updateCustomUrl(url);
      }

      if (_isRegisterMode) {
        await pbService.register(
          email,
          password,
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
              email,
              password,
            );

        if (!pbService.isVerified) {
          pbService.client.authStore.clear();
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.emailNotVerifiedError;
          });
          return;
        }
        logger.info('Logged in a cloud account.');
        widget.onLoginSuccess();
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _errorMessage = _getCleanErrorMessage(e));
      }
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
      if (mounted) setState(() => _errorMessage = _getCleanErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
      if (mounted) setState(() => _errorMessage = _getCleanErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
    return Column(
      children: [
        SegmentedButton<bool>(
          segments: [
            const ButtonSegment(
                value: false,
                label: Text('Wispar Sync'),
                icon: Icon(Icons.cloud)),
            ButtonSegment(
                value: true,
                label: Text(AppLocalizations.of(context)!.selfHosted),
                icon: const Icon(Icons.dns)),
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
        if (_isSelfHosted)
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.serverUrl,
                hintText: 'http://192.168.1.50:8090'),
          ),
        TextField(
          controller: _emailController,
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context)!.email),
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
            child: Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w500)),
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
              label: Text(_resendCooldown > 0
                  ? AppLocalizations.of(context)!
                      .waitResendEmail(_resendCooldown)
                  : AppLocalizations.of(context)!.resendEmail),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSyncing ? null : _handleLogin,
            child: _isSyncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isRegisterMode
                    ? AppLocalizations.of(context)!.signUp
                    : AppLocalizations.of(context)!.login),
          ),
        ),
        if (!_isSelfHosted)
          TextButton(
            onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
            child: Text(_isRegisterMode
                ? AppLocalizations.of(context)!.haveAnAccount
                : AppLocalizations.of(context)!.needAnAccount),
          ),
        SizedBox(height: 8),
        const Divider(),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.tonalIcon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://github.com/Scriptbash/Wispar/blob/main/PRIVACY.md'),
                  );
                },
                label: Text(AppLocalizations.of(context)!.privacyPolicy)),
            FilledButton.tonalIcon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://wispar.app/docs/initial-setup/cloud-sync'),
                  );
                },
                label: Text(AppLocalizations.of(context)!.documentation))
          ],
        ),
      ],
    );
  }
}
