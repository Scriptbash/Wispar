import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  final FocusNode _AffiliationFocusNode = FocusNode(debugLabel: 'Menu Button');
  String? test_value = "";

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
                        Icon(Icons.brush_outlined), // Add your desired icon
                        SizedBox(width: 8), // Add spacing
                        Text('Appearance'),
                      ],
                    ),
                  );
                },
              ),
              MenuAnchor(
                childFocusNode: _AffiliationFocusNode,
                menuChildren: <Widget>[
                  RadioMenuButton<String>(
                    value: "UdeS",
                    groupValue: test_value,
                    onChanged: (val) {
                      setState(() {
                        test_value = val;
                        print(test_value);
                      });
                    },
                    child: const Text('Université de Sherbrooke'),
                  ),
                  RadioMenuButton<String>(
                    value: "mcgill",
                    groupValue: test_value,
                    onChanged: (val) {
                      setState(() {
                        test_value = val;
                        print(test_value);
                      });
                    },
                    child: const Text('McGill'),
                  ),
                  RadioMenuButton<String>(
                    value: "bishops",
                    groupValue: test_value,
                    onChanged: (val) {
                      setState(() {
                        test_value = val;
                        print(test_value);
                      });
                    },
                    child: const Text('Bishops'),
                  ),
                ],
                builder: (BuildContext context, MenuController controller,
                    Widget? child) {
                  return TextButton(
                    focusNode: _AffiliationFocusNode,
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.school_outlined), // Add your desired icon
                        SizedBox(width: 8), // Add spacing
                        Text('University'),
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
