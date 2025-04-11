import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import '../locale_provider.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  _DisplaySettingsScreenState createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  int _publicationCardOption = 1;

  final Map<String, String> _languageLabels = {
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'nb': 'Norsk bokmål',
    'ta': 'தமிழ்',
    'nl': 'Nederlands',
    'fa': 'فارسی',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'ja': '日本語',
    'id': 'Bahasa Indonesia',
  };

  final List<Locale> _supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('nb'),
    Locale('ta'),
    Locale('nl'),
    Locale('fa'),
    Locale('tr'),
    Locale('ru'),
    Locale('ja'),
    Locale('id'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPublicationCardOption();
  }

  void _loadPublicationCardOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _publicationCardOption = prefs.getInt('publicationCardAbstractSetting') ??
          1; // Default to "hide missing abstracts"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.displaySettings),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            onTap: () {
              _showThemeDialog(context);
            },
            title: Row(
              children: [
                Icon(Icons.brightness_4_outlined),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.appearance),
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
                Icon(Icons.article_outlined),
                SizedBox(width: 8),
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
          ListTile(
            onTap: () => _showLanguageDialog(context),
            title: Row(
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.language),
              ],
            ),
            subtitle: Row(
              children: [
                const SizedBox(width: 32),
                Text(_getLocaleLabel(context)),
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

  void _showLanguageDialog(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLang = provider.locale?.languageCode ?? 'system';

    // Sort languagea alphabetically
    final sortedLocales = [..._supportedLocales]..sort((a, b) {
        final labelA = _languageLabels[a.languageCode] ?? a.languageCode;
        final labelB = _languageLabels[b.languageCode] ?? b.languageCode;
        return labelA.compareTo(labelB);
      });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...sortedLocales.map((locale) {
                final code = locale.languageCode;
                return RadioListTile<String>(
                  title: Text(_languageLabels[code] ?? code),
                  value: code,
                  groupValue: currentLang,
                  onChanged: (value) {
                    provider.setLocale(value!);
                    Navigator.of(context).pop();
                  },
                );
              }),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.system),
                value: 'system',
                groupValue: currentLang,
                onChanged: (_) {
                  provider.clearLocale();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocaleLabel(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;
    if (locale == null) {
      return AppLocalizations.of(context)!.system;
    }
    return _languageLabels[locale.languageCode] ??
        AppLocalizations.of(context)!.system;
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
