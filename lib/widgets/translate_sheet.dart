import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import '../generated_l10n/app_localizations.dart';
import '../services/logs_helper.dart';
import 'dart:async';
import 'package:wispar/services/translations/gemini_translation_provider.dart';
import 'package:wispar/services/translations/deepseek_translation_provider.dart';
import 'package:wispar/services/translations/chatgpt_translation_provider.dart';

enum TranslateLanguage {
  english('en', 'English'),
  spanish('es', 'Spanish'),
  french('fr', 'French'),
  german('de', 'German'),
  chineseSimplified('zh', 'Chinese (Simplified)'),
  chineseTraditional('zh-Hant', 'Chinese (Traditional)'),
  japanese('ja', 'Japanese'),
  korean('ko', 'Korean'),
  russian('ru', 'Russian'),
  portuguese('pt', 'Portuguese'),
  italian('it', 'Italian'),
  arabic('ar', 'Arabic'),
  hindi('hi', 'Hindi'),
  bengali('bn', 'Bengali'),
  dutch('nl', 'Dutch'),
  turkish('tr', 'Turkish'),
  vietnamese('vi', 'Vietnamese'),
  polish('pl', 'Polish'),
  pirate('pirate', 'Pirate'),
  ukrainian('uk', 'Ukrainian'),
  greek('el', 'Greek'),
  hebrew('he', 'Hebrew'),
  thai('th', 'Thai'),
  swedish('sv', 'Swedish'),
  norwegian('no', 'Norwegian'),
  danish('da', 'Danish'),
  finnish('fi', 'Finnish'),
  indonesian('id', 'Indonesian'),
  malay('ms', 'Malay'),
  czech('cs', 'Czech'),
  hungarian('hu', 'Hungarian'),
  romanian('ro', 'Romanian'),
  slovak('sk', 'Slovak'),
  afrikaans('af', 'Afrikaans'),
  albanian('sq', 'Albanian'),
  amharic('am', 'Amharic'),
  azerbaijani('az', 'Azerbaijani'),
  basque('eu', 'Basque'),
  belarusian('be', 'Belarusian'),
  bulgarian('bg', 'Bulgarian'),
  catalan('ca', 'Catalan'),
  croatian('hr', 'Croatian'),
  estonian('et', 'Estonian'),
  filipino('fil', 'Filipino'),
  georgian('ka', 'Georgian'),
  gujarati('gu', 'Gujarati'),
  haitianCreole('ht', 'Haitian Creole'),
  icelandic('is', 'Icelandic'),
  irish('ga', 'Irish'),
  kannada('kn', 'Kannada'),
  kazakh('kk', 'Kazakh'),
  khmer('km', 'Khmer'),
  lao('lo', 'Lao'),
  latvian('lv', 'Latvian'),
  lithuanian('lt', 'Lithuanian'),
  macedonian('mk', 'Macedonian'),
  malagasy('mg', 'Malagasy'),
  malayalam('ml', 'Malayalam'),
  maltese('mt', 'Maltese'),
  maori('mi', 'Maori'),
  marathi('mr', 'Marathi'),
  mongolian('mn', 'Mongolian'),
  nepali('ne', 'Nepali'),
  persian('fa', 'Persian'),
  serbian('sr', 'Serbian'),
  sinhala('si', 'Sinhala'),
  slovenian('sl', 'Slovenian'),
  somali('so', 'Somali'),
  swahili('sw', 'Swahili'),
  tamil('ta', 'Tamil'),
  telugu('te', 'Telugu'),
  urdu('ur', 'Urdu'),
  welsh('cy', 'Welsh'),
  xhosa('xh', 'Xhosa'),
  yiddish('yi', 'Yiddish'),
  zulu('zu', 'Zulu');

  final String bcpCode;
  final String name;

  const TranslateLanguage(this.bcpCode, this.name);
}

class TranslateOptionsSheet extends StatefulWidget {
  final String title;
  final String abstractText;
  final Function(Stream<String> titleStream, Stream<String> abstractStream)
      onTranslateStart;

  const TranslateOptionsSheet({
    Key? key,
    required this.title,
    required this.abstractText,
    required this.onTranslateStart,
  }) : super(key: key);

  @override
  _TranslateOptionsSheetState createState() => _TranslateOptionsSheetState();
}

class _TranslateOptionsSheetState extends State<TranslateOptionsSheet> {
  final logger = LogsService().logger;

  TranslateLanguage? _sourceLang = TranslateLanguage.english;
  TranslateLanguage? _targetLang = TranslateLanguage.french;
  String? _selectedAiProvider;
  List<String> _availableAiProviders = [];
  bool _isTranslating = false;

  List<String> _availableCustomPrompts = [];
  String? _selectedCustomPrompt;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndAvailableProviders();
  }

  Future<void> _loadSettingsAndAvailableProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceCode = prefs.getString('translate_source_lang');
    final targetCode = prefs.getString('translate_target_lang');

    final List<String> available = [];
    if (prefs.getString('gemini_api_key')?.isNotEmpty == true) {
      available.add('Gemini');
    }
    if (prefs.getString('deepseek_api_key')?.isNotEmpty == true) {
      available.add('DeepSeek');
    }
    if (prefs.getString('chatgpt_api_key')?.isNotEmpty == true) {
      available.add('ChatGPT');
    }

    final customPrompts =
        prefs.getStringList('custom_translation_prompts') ?? [];
    _availableCustomPrompts = ['Default', ...customPrompts];

    final savedPrompt = prefs.getString('selected_custom_prompt');
    _selectedCustomPrompt =
        _availableCustomPrompts.contains(savedPrompt) ? savedPrompt : 'Default';

    setState(() {
      _sourceLang = TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == sourceCode,
        orElse: () => TranslateLanguage.english,
      );
      _targetLang = TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == targetCode,
        orElse: () => TranslateLanguage.french,
      );
      _availableAiProviders = available;
      _selectedAiProvider = prefs.getString('selected_ai_provider') ??
          (available.isNotEmpty ? available.first : null);
    });
  }

  Future<void> _saveSelectedAiProvider(String? provider) async {
    final prefs = await SharedPreferences.getInstance();
    if (provider != null) {
      await prefs.setString('selected_ai_provider', provider);
    } else {
      await prefs.remove('selected_ai_provider');
    }
  }

  Future<void> _saveSelectedCustomPrompt(String? prompt) async {
    final prefs = await SharedPreferences.getInstance();
    if (prompt != null) {
      await prefs.setString('selected_custom_prompt', prompt);
    } else {
      await prefs.remove('selected_custom_prompt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizedNames = LocaleNames.of(context);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding:
            MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_availableAiProviders.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.aiProvider,
                  border: OutlineInputBorder(),
                ),
                value: _selectedAiProvider,
                items: _availableAiProviders
                    .map((provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAiProvider = val;
                  });
                  _saveSelectedAiProvider(val);
                },
                validator: (val) => val == null || val.isEmpty
                    ? AppLocalizations.of(context)!.pleaseSelectProvider
                    : null,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.noAiApiKeySetError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.prompt,
                border: OutlineInputBorder(),
              ),
              value: _selectedCustomPrompt,
              items: _availableCustomPrompts.map((prompt) {
                return DropdownMenuItem<String>(
                  value: prompt,
                  child: Tooltip(
                    message: prompt,
                    child: Text(
                      prompt,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCustomPrompt = val;
                });
                _saveSelectedCustomPrompt(val);
              },
            ),
            const SizedBox(height: 8),
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
              onPressed: (_isTranslating ||
                      _selectedAiProvider == null ||
                      _availableAiProviders.isEmpty)
                  ? null
                  : _translate,
              child: _isTranslating
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context)!.translate),
            ),
          ],
        ),
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
    if (_sourceLang == null ||
        _targetLang == null ||
        _selectedAiProvider == null) {
      logger.warning('Source, target language, or AI provider not selected.');
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      Stream<String> titleStream;
      Stream<String> abstractStream;

      final GeminiTranslationProvider geminiProvider =
          await GeminiTranslationProvider.instance;
      final DeepSeekTranslationProvider deepseekProvider =
          await DeepSeekTranslationProvider.instance;
      final ChatgptTranslationProvider chatgptProvider =
          await ChatgptTranslationProvider.instance;

      switch (_selectedAiProvider) {
        case 'Gemini':
          titleStream = await geminiProvider.translateStream(
              text: widget.title,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          abstractStream = await geminiProvider.translateStream(
              text: widget.abstractText,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          break;
        case 'DeepSeek':
          titleStream = await deepseekProvider.translateStream(
              text: widget.title,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          abstractStream = await deepseekProvider.translateStream(
              text: widget.abstractText,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          break;
        case 'ChatGPT':
          titleStream = await chatgptProvider.translateStream(
              text: widget.title,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          abstractStream = await chatgptProvider.translateStream(
              text: widget.abstractText,
              sourceLangName: _sourceLang!.name,
              targetLangName: _targetLang!.name,
              customPrompt: _selectedCustomPrompt);
          break;
        default:
          throw Exception('No valid AI provider selected or configured.');
      }

      if (!mounted) return;

      widget.onTranslateStart(titleStream, abstractStream);

      Navigator.pop(context);
    } catch (e, stackTrace) {
      logger.severe('Translation initiation failed', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translationFailed}: ${e.toString()}')),
      );
    } finally {
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
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final localizedNames = LocaleNames.of(context);

    // Get all languages, filter, and then sort
    final List<TranslateLanguage> sortedFilteredLanguages =
        TranslateLanguage.values.where((lang) {
      final localized = localizedNames?.nameOf(lang.bcpCode) ?? lang.name;
      return localized.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    sortedFilteredLanguages.sort((a, b) {
      final aName = localizedNames?.nameOf(a.bcpCode) ?? a.name;
      final bName = localizedNames?.nameOf(b.bcpCode) ?? b.name;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: false,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchPlaceholder,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (val) => setState(() => _search = val),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: sortedFilteredLanguages.map((lang) {
            return ListTile(
              title: Text(localizedNames?.nameOf(lang.bcpCode) ?? lang.name),
              trailing: widget.current == lang ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, lang),
            );
          }).toList(),
        ),
      ),
    );
  }
}
