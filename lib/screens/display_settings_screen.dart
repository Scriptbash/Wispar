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
  int _pdfThemeOption = 0;
  int _pdfOrientationOption = 0;

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
    'pt': 'Português',
    'de': 'Deutsch',
    'zh': '中文',
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
    Locale('pt'),
    Locale('de'),
    Locale('zh'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPublicationCardOption();
    _loadPdfThemeOption();
    _loadPdfOrientationOption();
  }

  void _loadPublicationCardOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _publicationCardOption = prefs.getInt('publicationCardAbstractSetting') ??
          1; // Default to "hide missing abstracts"
    });
  }

  void _loadPdfThemeOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pdfThemeOption = prefs.getInt('pdfThemeOption') ?? 0;
    });
  }

  void _savePdfThemeOption(int value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('pdfThemeOption', value);
  }

  void _loadPdfOrientationOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pdfOrientationOption = prefs.getInt('pdfOrientationOption') ?? 0;
    });
  }

  void _savePdfOrientationOption(int value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('pdfOrientationOption', value);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "icon": Icons.brightness_4_outlined,
        "label": AppLocalizations.of(context)!.appearance,
        "subtitle": _getThemeSubtitle(
          context,
          Provider.of<ThemeProvider>(context).themeMode,
        ),
        "onTap": () => _showThemeDialog(context),
      },
      {
        "icon": Icons.picture_as_pdf_outlined,
        "label": AppLocalizations.of(context)!.pdfTheme,
        "subtitle": _getPdfThemeSubtitle(_pdfThemeOption),
        "onTap": () => _showPdfThemeDialog(context),
      },
      {
        "icon": Icons.screen_rotation_alt_rounded,
        "label": AppLocalizations.of(context)!.pdfReadingOrientation,
        "subtitle": _getPdfOrientationSubtitle(_pdfOrientationOption),
        "onTap": () => _showPdfOrientationDialog(context),
      },
      {
        "icon": Icons.article_outlined,
        "label": AppLocalizations.of(context)!.publicationCard,
        "subtitle":
            _getPublicationCardSubtitle(context, _publicationCardOption),
        "onTap": () => _showPublicationCardsDialog(context),
      },
      {
        "icon": Icons.language,
        "label": AppLocalizations.of(context)!.language,
        "subtitle": _getLocaleLabel(context),
        "onTap": () => _showLanguageDialog(context),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.displaySettings),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxTileWidth = 400;
            final int crossAxisCount =
                (constraints.maxWidth / maxTileWidth).floor().clamp(1, 4);

            final double tileWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                    crossAxisCount;

            final double minTileHeight = 100;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: tileWidth / minTileHeight,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: item["onTap"] as VoidCallback,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(item["icon"] as IconData),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item["label"] as String)),
                            ],
                          ),
                          if (item["subtitle"] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 32),
                              child: Text(
                                item["subtitle"] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.appearance),
          content: RadioGroup<ThemeMode>(
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.light),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.dark),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.systemtheme),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPdfThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.pdfTheme),
          content: RadioGroup<int>(
            groupValue: _pdfThemeOption,
            onChanged: (int? value) {
              if (value != null) {
                setState(() => _pdfThemeOption = value);
                _savePdfThemeOption(value);
                Navigator.of(context).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.light),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.dark),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.systemtheme),
                  value: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPdfThemeSubtitle(int option) {
    switch (option) {
      case 0:
        return AppLocalizations.of(context)!.light;
      case 1:
        return AppLocalizations.of(context)!.dark;
      case 2:
        return AppLocalizations.of(context)!.systemtheme;
      default:
        return 'Unknown';
    }
  }

  void _showPdfOrientationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.pdfReadingOrientation),
          content: RadioGroup<int>(
            groupValue: _pdfOrientationOption,
            onChanged: (int? value) {
              if (value != null) {
                setState(() => _pdfOrientationOption = value);
                _savePdfOrientationOption(value);
                Navigator.of(context).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.vertical),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.horizontal),
                  value: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPdfOrientationSubtitle(int option) {
    switch (option) {
      case 0:
        return AppLocalizations.of(context)!.vertical;
      case 1:
        return AppLocalizations.of(context)!.horizontal;
      default:
        return 'Unknown';
    }
  }

  void _showPublicationCardsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.publicationCard),
          content: RadioGroup<int>(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.showAllAbstracts),
                  value: 0,
                ),
                RadioListTile<int>(
                  title:
                      Text(AppLocalizations.of(context)!.hideMissingAbstracts),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text(AppLocalizations.of(context)!.hideAllAbstracts),
                  value: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLang = provider.locale?.languageCode ?? 'system';

    // Sort languages alphabetically
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
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: currentLang,
              onChanged: (value) {
                if (value == 'system') {
                  provider.clearLocale();
                } else {
                  provider.setLocale(value!);
                }
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...sortedLocales.map((locale) {
                    final code = locale.languageCode;
                    return RadioListTile<String>(
                      title: Text(_languageLabels[code] ?? code),
                      value: code,
                    );
                  }),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.system),
                    value: 'system',
                  ),
                ],
              ),
            ),
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
