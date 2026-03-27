import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wispar/services/pocketbase_service.dart';
import 'package:wispar/services/sync_service.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/widgets/sync_auth_form.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final pbService = PocketBaseService();
  final syncManager = SyncManager();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final logger = LogsService().logger;
  bool _isSyncing = false;
  DateTime? _lastSyncDate;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
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
        setState(() {
          _isSyncing = false;
          _lastSyncDate = null;
        });
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

  Future<bool> _isBackgroundSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('background_sync_enabled') ?? true;
  }

  Future<void> _toggleBackgroundSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', value);
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.cloudSync)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.of(context)!.loginToSyncDevices,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(
            height: 16,
          ),
          if (!pbService.isAuthenticated) ...[
            SyncAuthForm(
              onLoginSuccess: () {
                setState(() {});
                _runSync();
              },
            ),
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
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .syncServer(pbService.baseURL),
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
            FutureBuilder<bool>(
              future: _isBackgroundSyncEnabled(),
              builder: (context, snapshot) {
                final bool isEnabled = snapshot.data ?? true;
                return SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.backgroundSync),
                  subtitle: Text(
                      AppLocalizations.of(context)!.backgroundSyncDescription),
                  value: isEnabled,
                  onChanged: _isSyncing ? null : _toggleBackgroundSync,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () {
                pbService.client.authStore.clear();
                setState(() {
                  _lastSyncDate = null;
                  _isSyncing = false;
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(AppLocalizations.of(context)!.logout),
            ),
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
