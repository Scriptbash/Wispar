import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  _DisplaySettingsScreenState createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  int _publicationCardOption = 0;

  @override
  void initState() {
    super.initState();
    _loadPublicationCardOption();
  }

  void _loadPublicationCardOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _publicationCardOption = prefs.getInt('publicationCardAbstractSetting') ??
          0; // Default to "show all abstracts"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.display),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            onTap: () {
              _showThemeDialog(context);
            },
            title: Row(
              children: [
                //Icon(Icons.palette_outlined),
                SizedBox(width: 32),
                Text(AppLocalizations.of(context)!.theme),
              ],
            ),
            subtitle: Row(
              children: [
                SizedBox(width: 32),
                Text(
                  _getThemeSubtitle(
                    context,
                    Provider.of<ThemeProvider>(context).themeMode,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              _showPublicationCardsDialog(context);
            },
            title: Row(
              children: [
                //Icon(Icons.description_outlined),
                SizedBox(width: 32),
                Text(AppLocalizations.of(context)!.publicationCard),
              ],
            ),
            subtitle: Row(
              children: [
                SizedBox(width: 32),
                Text(_getPublicationCardSubtitle(
                    context, _publicationCardOption)),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _showPublicationCardsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.publicationCard),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<int>(
                title: Text(AppLocalizations.of(context)!.showAllAbstracts),
                value: 0,
                groupValue: _publicationCardOption,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _publicationCardOption = value;
                    });
                    _savePublicationCardOption(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<int>(
                title: Text(AppLocalizations.of(context)!.hideMissingAbstracts),
                value: 1,
                groupValue: _publicationCardOption,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _publicationCardOption = value;
                    });
                    _savePublicationCardOption(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<int>(
                title: Text(AppLocalizations.of(context)!.hideAllAbstracts),
                value: 2,
                groupValue: _publicationCardOption,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _publicationCardOption = value;
                    });
                    _savePublicationCardOption(value);
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

  void _savePublicationCardOption(int value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('publicationCardAbstractSetting', value);
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

  String _getPublicationCardSubtitle(BuildContext context, int option) {
    switch (option) {
      case 0:
        return AppLocalizations.of(context)!.showAllAbstracts;
      case 1:
        return AppLocalizations.of(context)!.hideMissingAbstracts;
      case 2:
        return AppLocalizations.of(context)!.hideAllAbstracts;
      default:
        return 'Unknown';
    }
  }
}
