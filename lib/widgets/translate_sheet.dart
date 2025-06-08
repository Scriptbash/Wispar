import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import '../generated_l10n/app_localizations.dart';
import '../services/logs_helper.dart';

class TranslateOptionsSheet extends StatefulWidget {
  final String title;
  final String abstractText;

  const TranslateOptionsSheet({
    Key? key,
    required this.title,
    required this.abstractText,
  }) : super(key: key);

  @override
  _TranslateOptionsSheetState createState() => _TranslateOptionsSheetState();
}

class _TranslateOptionsSheetState extends State<TranslateOptionsSheet> {
  final logger = LogsService().logger;

  TranslateLanguage? _sourceLang = TranslateLanguage.english;
  TranslateLanguage? _targetLang = TranslateLanguage.french;
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedAbstract;

  @override
  void initState() {
    super.initState();
    _loadLastUsedLanguages();
  }

  Future<void> _loadLastUsedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceCode = prefs.getString('translate_source_lang');
    final targetCode = prefs.getString('translate_target_lang');

    setState(() {
      _sourceLang = TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == sourceCode,
        orElse: () => TranslateLanguage.english,
      );
      _targetLang = TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == targetCode,
        orElse: () => TranslateLanguage.french,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizedNames = LocaleNames.of(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickLanguage(isSource: true),
                  child: Text(localizedNames?.nameOf(_sourceLang!.bcpCode) ??
                      _sourceLang!.name),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: AppLocalizations.of(context)!.swapLanguages,
                onPressed: () {
                  setState(() {
                    final temp = _sourceLang;
                    _sourceLang = _targetLang;
                    _targetLang = temp;
                  });
                },
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickLanguage(isSource: false),
                  child: Text(localizedNames?.nameOf(_targetLang!.bcpCode) ??
                      _targetLang!.name),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isTranslating ? null : _translate,
            child: _isTranslating
                ? const CircularProgressIndicator()
                : Text(AppLocalizations.of(context)!.translate),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage({required bool isSource}) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LanguagePickerScreen(
          current: isSource ? _sourceLang : _targetLang,
        ),
      ),
    );

    if (selected != null && selected is TranslateLanguage) {
      setState(() {
        if (isSource) {
          _sourceLang = selected;
        } else {
          _targetLang = selected;
        }
      });
      final prefs = await SharedPreferences.getInstance();
      if (isSource) {
        await prefs.setString('translate_source_lang', selected.bcpCode);
      } else {
        await prefs.setString('translate_target_lang', selected.bcpCode);
      }
    }
  }

  Future<void> _translate() async {
    if (_sourceLang == null || _targetLang == null) return;

    setState(() {
      _isTranslating = true;
      _translatedTitle = null;
      _translatedAbstract = null;
    });

    final translator = OnDeviceTranslator(
      sourceLanguage: _sourceLang!,
      targetLanguage: _targetLang!,
    );

    try {
      final titleResult = await translator.translateText(widget.title);
      final abstractResult =
          await translator.translateText(widget.abstractText);

      if (!mounted) return;
      setState(() {
        _translatedTitle = titleResult;
        _translatedAbstract = abstractResult;
      });
      Navigator.pop(context, {
        'title': _translatedTitle,
        'abstract': _translatedAbstract,
      });
    } catch (e, stackTrace) {
      logger.severe('Translation failed using ML kit', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _translatedTitle = '(Translation failed)';
        _translatedAbstract = '(Translation failed)';
      });
    } finally {
      translator.close();
      if (!mounted) return;
      setState(() => _isTranslating = false);
    }
  }
}

class LanguagePickerScreen extends StatefulWidget {
  final TranslateLanguage? current;
  const LanguagePickerScreen({Key? key, this.current}) : super(key: key);

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  final modelManager = OnDeviceTranslatorModelManager();
  final Map<String, bool> _downloadStatus = {};
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedModels();
  }

  Future<void> _loadDownloadedModels() async {
    for (var lang in TranslateLanguage.values) {
      final isDownloaded = await modelManager.isModelDownloaded(lang.bcpCode);
      _downloadStatus[lang.bcpCode] = isDownloaded;
    }
    setState(() => _loading = false);
  }

  Future<void> _downloadModel(TranslateLanguage lang) async {
    setState(() => _downloadStatus[lang.bcpCode] = false);
    await modelManager.downloadModel(lang.bcpCode);
    setState(() => _downloadStatus[lang.bcpCode] = true);
  }

  @override
  Widget build(BuildContext context) {
    final localizedNames = LocaleNames.of(context);

    final filtered = TranslateLanguage.values.where((lang) {
      final localized = localizedNames?.nameOf(lang.bcpCode) ?? lang.name;
      return localized.toLowerCase().contains(_search.toLowerCase());
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: TextField(
          autofocus: false,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchPlaceholder,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (val) => setState(() => _search = val),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: filtered.map((lang) {
                final downloaded = _downloadStatus[lang.bcpCode] ?? false;
                return ListTile(
                  title:
                      Text(localizedNames?.nameOf(lang.bcpCode) ?? lang.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      downloaded
                          ? IconButton(
                              icon: Icon(Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary),
                              tooltip: AppLocalizations.of(context)!
                                  .deleteLanguageModel,
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .deleteLanguageModel),
                                    content: Text(AppLocalizations.of(context)!
                                        .deleteLanguageModelLong(localizedNames
                                                ?.nameOf(lang.bcpCode) ??
                                            lang.name)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .delete),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await modelManager.deleteModel(lang.bcpCode);
                                  setState(() =>
                                      _downloadStatus[lang.bcpCode] = false);
                                }
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.download,
                                  color: Theme.of(context).colorScheme.primary),
                              tooltip: AppLocalizations.of(context)!
                                  .downloadLanguageModel,
                              onPressed: () => _downloadModel(lang),
                            ),
                    ],
                  ),
                  onTap: () => Navigator.pop(context, lang),
                );
              }).toList(),
            ),
    );
  }
}
