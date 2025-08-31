import 'dart:io';
import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import './institutions_screen.dart';
import './zotero_settings_screen.dart';
import './ai_settings_screen.dart';
import './database_settings_screen.dart';
import './display_settings_screen.dart';
import './logs_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _loadNotificationPermissionStatus();
    }
  }

  Future<void> _loadNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      isNotificationEnabled = status.isGranted;
    });
  }

  Future<void> _checkNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await Permission.notification.status;

    if (status.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
      return;
    }

    final bool deniedBefore = prefs.getBool('notification_perms') ?? false;

    if (deniedBefore) await prefs.remove('notification_perms');

    final permissionGranted = await _requestNotificationPermission();

    if (!permissionGranted) {
      await prefs.setBool('notification_perms', true);
    } else {
      await prefs.setBool('notification_perms', false);
    }

    setState(() {
      isNotificationEnabled = permissionGranted;
    });
  }

  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isDenied || status.isLimited) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> settingsItems = [
      _buildTile(
        icon: Icons.palette_outlined,
        label: AppLocalizations.of(context)!.display,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const DisplaySettingsScreen())),
      ),
      _buildTile(
        icon: Icons.lock_open_outlined,
        label: 'Unpaywall',
        isToggle: true,
        toggleFuture: getUnpaywallStatus(),
        onToggle: _toggleUnpaywall,
      ),
      _buildTile(
        icon: Icons.school_outlined,
        label: AppLocalizations.of(context)!.institutionalAccess,
        subtitleFuture: getInstitutionName(),
        subtitleBuilder: (name) =>
            name ?? AppLocalizations.of(context)!.noinstitution,
        onTap: () async {
          Map<String, dynamic>? result = await Navigator.push(context,
              MaterialPageRoute(builder: (context) => InstitutionScreen()));
          if (result != null &&
              result.containsKey('name') &&
              result.containsKey('url')) {
            String institutionName = result['name'] as String;
            String institutionUrl = result['url'] as String;

            if (institutionName == 'None') {
              await unsetInstitution();
            } else {
              await saveInstitutionPreference(institutionName, institutionUrl);
            }
          }
        },
      ),
      _buildTile(
        icon: Icons.book_outlined,
        label: 'Zotero',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ZoteroSettings())),
      ),
      _buildTile(
        icon: Icons.smart_toy_outlined,
        label: AppLocalizations.of(context)!.aiSettings,
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AISettingsScreen()));
          setState(() {});
        },
      ),
      _buildTile(
        icon: Icons.dns_outlined,
        label: AppLocalizations.of(context)!.database,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const DatabaseSettingsScreen())),
      ),
      if (Platform.isAndroid || Platform.isIOS)
        _buildTile(
          icon: Icons.notifications_outlined,
          label: AppLocalizations.of(context)!.notifications,
          subtitle: isNotificationEnabled
              ? AppLocalizations.of(context)!.notifPermsGranted
              : AppLocalizations.of(context)!.notifPermsNotGranted,
          onTap: _checkNotificationPermission,
        ),
      _buildTile(
        icon: Icons.privacy_tip_outlined,
        label: AppLocalizations.of(context)!.privacyPolicy,
        onTap: () => launchUrl(
            Uri.parse(
                'https://github.com/Scriptbash/Wispar/blob/main/PRIVACY.md'),
            mode: LaunchMode.platformDefault),
      ),
      _buildTile(
        icon: Icons.warning_amber,
        label: AppLocalizations.of(context)!.viewLogs,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const LogsScreen())),
      ),
      _buildTile(
        icon: Icons.info_outline,
        label: AppLocalizations.of(context)!.about,
        onTap: () async {
          List<String> appInfo = await getAppVersion();
          final version = appInfo[0];
          final build = appInfo[1];
          showAboutDialog(
            context: context,
            applicationName: "Wispar",
            applicationIcon: Image.asset('assets/icon/icon.png', width: 50),
            applicationVersion: "Version $version (Build $build)",
            children: [
              TextButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse('https://github.com/Scriptbash/Wispar'),
                    mode: LaunchMode.platformDefault),
                icon: const Icon(Icons.code),
                label: Text(AppLocalizations.of(context)!.sourceCode),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse('https://github.com/Scriptbash/Wispar/issues'),
                    mode: LaunchMode.platformDefault),
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(AppLocalizations.of(context)!.reportIssue),
              ),
            ],
            applicationLegalese:
                AppLocalizations.of(context)!.madeBy("Francis Lapointe"),
          );
        },
      ),
      if (!Platform.isIOS)
        _buildTile(
          icon: Icons.favorite_border,
          label: AppLocalizations.of(context)!.donate,
          subtitle: AppLocalizations.of(context)!.donateMessage,
          onTap: () => launchUrl(Uri.parse('https://ko-fi.com/scriptbash'),
              mode: LaunchMode.platformDefault),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3.5,
          ),
          itemCount: settingsItems.length,
          itemBuilder: (context, index) => settingsItems[index],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Future<String?>? subtitleFuture,
    String Function(String?)? subtitleBuilder,
    VoidCallback? onTap,
    bool isToggle = false,
    Future<String?>? toggleFuture,
    Function(String)? onToggle,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isToggle
            ? () async {
                final prefs = await SharedPreferences.getInstance();
                String current = await toggleFuture! ?? '1';
                String newStatus = current == '1' ? '0' : '1';
                await prefs.setString('unpaywall', newStatus);
                if (onToggle != null) onToggle(newStatus);
                setState(() {});
              }
            : onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                    if (isToggle && toggleFuture != null)
                      FutureBuilder<String?>(
                        future: toggleFuture,
                        builder: (context, snapshot) {
                          final enabled = snapshot.data ?? '1';
                          return Switch(
                            value: enabled == '1',
                            onChanged: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                  'unpaywall', value ? '1' : '0');
                              if (onToggle != null) onToggle(value ? '1' : '0');
                              setState(() {});
                            },
                          );
                        },
                      ),
                  ],
                ),
                if (!isToggle && subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 8),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                if (!isToggle &&
                    subtitleFuture != null &&
                    subtitleBuilder != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 8),
                    child: FutureBuilder<String?>(
                      future: subtitleFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            subtitleBuilder(snapshot.data),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
              ],
            )),
      ),
    );
  }

  Future<void> saveInstitutionPreference(String name, String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('institution_name', name);
    prefs.setString('institution_url', url);
  }

  Future<String?> getInstitutionName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {});
    return prefs.getString('institution_name');
  }

  Future<void> unsetInstitution() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('institution_name');
    prefs.remove('institution_url');
    setState(() {});
  }

  Future<void> saveUnpaywallPreference(String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('unpaywall', status);
  }

  Future<String?> getUnpaywallStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {});
    return prefs.getString('unpaywall') ?? '1';
  }

  Future<void> _toggleUnpaywall(String newStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('unpaywall', newStatus);
    setState(() {});
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notifications),
        content:
            Text(AppLocalizations.of(context)!.notificationSettingsMessage),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.openAppSettings),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}

Future<List<String>> getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return [packageInfo.version, packageInfo.buildNumber];
}
