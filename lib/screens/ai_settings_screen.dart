import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/translations/deepseek_translation_provider.dart';
import 'package:wispar/services/translations/gemini_translation_provider.dart';
import 'package:wispar/services/translations/chatgpt_translation_provider.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({Key? key}) : super(key: key);

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _providers = ['Gemini', 'DeepSeek', 'ChatGPT'];
  String? _selectedProvider;

  final TextEditingController _geminiApiKeyController = TextEditingController();
  final TextEditingController _deepseekApiKeyController =
      TextEditingController();
  final TextEditingController _chatgptApiKeyController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    _deepseekApiKeyController.dispose();
    _chatgptApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProvider = prefs.getString('ai_provider') ?? _providers.first;
      _geminiApiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _deepseekApiKeyController.text =
          prefs.getString('deepseek_api_key') ?? '';
      _chatgptApiKeyController.text = prefs.getString('chatgpt_api_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedProvider != null) {
      await prefs.setString('ai_provider', _selectedProvider!);
    }

    final String geminiKey = _geminiApiKeyController.text;
    final String deepseekKey = _deepseekApiKeyController.text;
    final String chatgptKey = _chatgptApiKeyController.text;

    await prefs.setString('gemini_api_key', geminiKey);
    await prefs.setString('deepseek_api_key', deepseekKey);
    await prefs.setString('chatgpt_api_key', chatgptKey);

    final geminiProvider = await GeminiTranslationProvider.instance;
    geminiProvider.setApiKey(geminiKey);

    final deepseekProvider = await DeepSeekTranslationProvider.instance;
    deepseekProvider.setApiKey(deepseekKey);

    final chatgptProvider = await ChatgptTranslationProvider.instance;
    chatgptProvider.setApiKey(chatgptKey);
  }

  TextEditingController _getCurrentApiKeyController() {
    switch (_selectedProvider) {
      case 'Gemini':
        return _geminiApiKeyController;
      case 'DeepSeek':
        return _deepseekApiKeyController;
      case 'ChatGPT':
        return _chatgptApiKeyController;
      default:
        return TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiSettings),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.aiProvider,
                  border: OutlineInputBorder(),
                ),
                value: _selectedProvider,
                items: _providers
                    .map((provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedProvider = val);
                },
                validator: (val) => val == null || val.isEmpty
                    ? AppLocalizations.of(context)!.pleaseSelectProvider
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _getCurrentApiKeyController(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .apiKeyLabel(_selectedProvider ?? ''),
                  border: const OutlineInputBorder(),
                ),
                onSaved: (val) {},
                validator: (val) => (val == null || val.isEmpty)
                    ? AppLocalizations.of(context)!
                        .pleaseEnterAiAPIKey(_selectedProvider ?? '')
                    : null,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.save),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    await _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.settingsSaved)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
