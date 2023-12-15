import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatefulWidget {
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
                    child: Row(
                      children: [
                        Icon(Icons.brush_outlined), // Add your desired icon
                        const SizedBox(width: 8), // Add spacing
                        const Text('Appearance'),
                      ],
                    ),
                  );
                },
              ),
            ]),
      ),
    );
  }
}
