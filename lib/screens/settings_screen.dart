import 'dart:io';
import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import './institutions_screen.dart';
import './zotero_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import './database_settings_screen.dart';
import './display_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<String>> appInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DisplaySettingsScreen(),
                    ),
                  );
                },
                title: Row(
                  children: [
                    Icon(Icons.palette_outlined),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.display),
                  ],
                ),
              ),
              ListTile(
                  onTap: () {
                    _showUnpaywallDialog(context);
                  },
                  title: Row(
                    children: [
                      Icon(Icons.lock_open_outlined),
                      SizedBox(width: 8),
                      Text('Unpaywall'),
                    ],
                  ),
                  subtitle: Row(children: [
                    SizedBox(width: 32),
                    FutureBuilder<String?>(
                      future: getUnpaywallStatus(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          String status =
                              snapshot.data ?? '1'; // Default to '1' (Enabled)
                          String statusText = status == '1'
                              ? AppLocalizations.of(context)!.enabled
                              : AppLocalizations.of(context)!.disabled;

                          return Center(
                            child: Text(statusText),
                          );
                        } else {
                          return Center(
                            child: Text(AppLocalizations.of(context)!
                                .enabled), // Default text
                          );
                        }
                      },
                    ),
                  ])),
              ListTile(
                onTap: () async {
                  Map<String, dynamic>? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstitutionScreen(),
                    ),
                  );
                  if (result != null &&
                      result.containsKey('name') &&
                      result.containsKey('url')) {
                    String institutionName = result['name'] as String;
                    String institutionUrl = result['url'] as String;

                    if (institutionName == 'None') {
                      // Remove the institution if no institution is selected
                      await unsetInstitution();
                    } else {
                      // Otherwise, save the selected institution
                      await saveInstitutionPreference(
                          institutionName, institutionUrl);
                    }
                  }
                },
                title: Row(children: [
                  Icon(Icons.school_outlined),
                  SizedBox(width: 8),
                  Text('EZproxy'),
                ]),
                subtitle: Row(
                  children: [
                    SizedBox(width: 32),
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: getInstitutionName(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data ??
                                  AppLocalizations.of(context)!.noinstitution,
                            );
                          } else {
                            return Text(
                              AppLocalizations.of(context)!.noinstitution,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ZoteroSettings(),
                    ),
                  );
                },
                title: Row(
                  children: [
                    Icon(Icons.book_outlined),
                    SizedBox(width: 8),
                    Text('Zotero'),
                  ],
                ),
                /*subtitle: Row(children: [
                SizedBox(width: 32),
                Text('Manage Zotero'),
              ]),*/
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DatabaseSettingsScreen(),
                    ),
                  );
                },
                title: Row(
                  children: [
                    Icon(Icons.dns_outlined),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.database),
                  ],
                ),
              ),
              ListTile(
                onTap: () {
                  launchUrl(
                      Uri.parse(
                          'https://github.com/Scriptbash/Wispar/blob/main/PRIVACY.md'),
                      mode: LaunchMode.platformDefault);
                },
                title: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.privacyPolicy),
                  ],
                ),
              ),
              ListTile(
                onTap: () async {
                  List<String> appInfo = await getAppVersion();
                  final version = appInfo[0];
                  final build = appInfo[1];
                  showAboutDialog(
                      context: context,
                      applicationName: "Wispar",
                      applicationIcon: Image.asset(
                        'assets/icon/icon.png',
                        width: 50,
                      ),
                      applicationVersion: "Version $version (Build $build)",
                      children: [
                        TextButton.icon(
                            onPressed: () {
                              launchUrl(
                                  Uri.parse(
                                      'https://github.com/Scriptbash/Wispar'),
                                  mode: LaunchMode.platformDefault);
                            },
                            icon: Icon(Icons.code),
                            label:
                                Text(AppLocalizations.of(context)!.sourceCode)),
                        TextButton.icon(
                            onPressed: () {
                              launchUrl(
                                  Uri.parse(
                                      'https://github.com/Scriptbash/Wispar/issues'),
                                  mode: LaunchMode.platformDefault);
                            },
                            icon: Icon(Icons.bug_report_outlined),
                            label: Text(
                                AppLocalizations.of(context)!.reportIssue)),
                      ],
                      applicationLegalese: AppLocalizations.of(context)!
                          .madeBy("Francis Lapointe"));
                  //applicationLegalese: "");
                },
                title: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.about),
                  ],
                ),
              ),
              if (!Platform.isIOS)
                ListTile(
                  onTap: () {
                    launchUrl(Uri.parse('https://ko-fi.com/scriptbash'),
                        mode: LaunchMode.platformDefault);
                  },
                  title: Row(
                    children: [
                      Icon(Icons.favorite_border),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.donate),
                    ],
                  ),
                  subtitle: Row(children: [
                    SizedBox(width: 32),
                    Text(AppLocalizations.of(context)!.donateMessage)
                  ]),
                ),
            ],
          ),
        ),
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

  void _showUnpaywallDialog(BuildContext context) async {
    // Fetch the current status of Unpaywall before opening the dialog
    String? currentStatus = await getUnpaywallStatus();
    currentStatus ??= '1';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unpaywall'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.enabled),
                value: "1",
                groupValue: currentStatus,
                onChanged: (value) {
                  if (value != null) {
                    saveUnpaywallPreference(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.disabled),
                value: "0",
                groupValue: currentStatus,
                onChanged: (value) {
                  if (value != null) {
                    saveUnpaywallPreference(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<List<String>> getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return [packageInfo.version, packageInfo.buildNumber];
}
