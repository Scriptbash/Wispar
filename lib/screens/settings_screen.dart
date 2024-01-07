import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import './institutions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            MenuAnchor(
              childFocusNode: _buttonFocusNode,
              menuChildren: <Widget>[
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: Provider.of<ThemeProvider>(context).themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .setThemeMode(value);
                    }
                  },
                  child: const Text('Light'),
                ),
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: Provider.of<ThemeProvider>(context).themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .setThemeMode(value);
                    }
                  },
                  child: const Text('Dark'),
                ),
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: Provider.of<ThemeProvider>(context).themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .setThemeMode(value);
                    }
                  },
                  child: const Text('System theme'),
                ),
              ],
              builder: (BuildContext context, MenuController controller,
                  Widget? child) {
                return TextButton(
                  focusNode: _buttonFocusNode,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.brush_outlined),
                      SizedBox(width: 8),
                      Text('Appearance'),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.school_outlined),
                            SizedBox(width: 8),
                            Text('EZproxy'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          unsetInstitution();
                        },
                        child: Text('Unset'),
                      ),
                    ],
                  ),
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
                ],
              ),
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
