import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme_provider.dart';
import './institutions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  //final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListTile(
                onTap: () {
                  _showThemeDialog(context);
                },
                title: Row(
                  children: [
                    Icon(Icons.palette_outlined),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.appearance),
                  ],
                ),
                subtitle: Row(children: [
                  SizedBox(width: 32),
                  Text(_getThemeSubtitle(
                      context, Provider.of<ThemeProvider>(context).themeMode)),
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
                  saveInstitutionPreference(
                    result['name'] as String,
                    result['url'] as String,
                  );
                }
              },
              title: Row(children: [
                Icon(Icons.school_outlined),
                SizedBox(width: 8),
                Text('EZproxy'),
                TextButton(
                    onPressed: () {
                      unsetInstitution();
                    },
                    child: Text('Unset'))
              ]),
              subtitle: Row(children: [
                SizedBox(width: 32),
                FutureBuilder<String?>(
                  future: getInstitutionName(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Center(
                        child: Text(snapshot.data ?? 'No institution'),
                      );
                    } else {
                      return Center(
                        child: Text('No institution'),
                      );
                    }
                  },
                ),
              ]),
            ),
          ],
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
}

void _showThemeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.appearance),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.light),
              value: ThemeMode.light,
              groupValue: Provider.of<ThemeProvider>(context).themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .setThemeMode(value);
                }
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.dark),
              value: ThemeMode.dark,
              groupValue: Provider.of<ThemeProvider>(context).themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .setThemeMode(value);
                }
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.systemtheme),
              value: ThemeMode.system,
              groupValue: Provider.of<ThemeProvider>(context).themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .setThemeMode(value);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

String _getThemeSubtitle(BuildContext context, ThemeMode? themeMode) {
  switch (themeMode) {
    case ThemeMode.light:
      return AppLocalizations.of(context)!.light;
    case ThemeMode.dark:
      return AppLocalizations.of(context)!.dark;
    case ThemeMode.system:
      return AppLocalizations.of(context)!.systemtheme;
    default:
      return 'Unknown';
  }
}
