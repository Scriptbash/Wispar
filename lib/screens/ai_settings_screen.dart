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

  final TextEditingController _geminiBaseUrlController =
      TextEditingController();
  final TextEditingController _deepseekBaseUrlController =
      TextEditingController();
  final TextEditingController _chatgptBaseUrlController =
      TextEditingController();

  final TextEditingController _geminiModelNameController =
      TextEditingController();
  final TextEditingController _deepseekModelNameController =
      TextEditingController();
  final TextEditingController _chatgptModelNameController =
      TextEditingController();

  bool _useCustomGeminiBaseUrl = false;
  bool _useCustomDeepseekBaseUrl = false;
  bool _useCustomChatgptBaseUrl = false;

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
    _geminiBaseUrlController.dispose();
    _deepseekBaseUrlController.dispose();
    _chatgptBaseUrlController.dispose();
    _geminiModelNameController.dispose();
    _deepseekModelNameController.dispose();
    _chatgptModelNameController.dispose();
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

      _geminiBaseUrlController.text = prefs.getString('gemini_base_url') ?? '';
      _deepseekBaseUrlController.text =
          prefs.getString('deepseek_base_url') ?? '';
      _chatgptBaseUrlController.text =
          prefs.getString('chatgpt_base_url') ?? '';

      _geminiModelNameController.text =
          prefs.getString('gemini_model_name') ?? 'gemini-2.5-flash';
      _deepseekModelNameController.text =
          prefs.getString('deepseek_model_name') ?? 'deepseek-chat';
      _chatgptModelNameController.text =
          prefs.getString('chatgpt_model_name') ?? 'gpt-4o';

      _useCustomGeminiBaseUrl =
          prefs.getBool('use_custom_gemini_base_url') ?? false;
      _useCustomDeepseekBaseUrl =
          prefs.getBool('use_custom_deepseek_base_url') ?? false;
      _useCustomChatgptBaseUrl =
          prefs.getBool('use_custom_chatgpt_base_url') ?? false;
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

    final String geminiBaseUrl = _geminiBaseUrlController.text;
    final String deepseekBaseUrl = _deepseekBaseUrlController.text;
    final String chatgptBaseUrl = _chatgptBaseUrlController.text;
    await prefs.setString('gemini_base_url', geminiBaseUrl);
    await prefs.setString('deepseek_base_url', deepseekBaseUrl);
    await prefs.setString('chatgpt_base_url', chatgptBaseUrl);

    final String geminiModelName = _geminiModelNameController.text;
    final String deepseekModelName = _deepseekModelNameController.text;
    final String chatgptModelName = _chatgptModelNameController.text;
    await prefs.setString('gemini_model_name', geminiModelName);
    await prefs.setString('deepseek_model_name', deepseekModelName);
    await prefs.setString('chatgpt_model_name', chatgptModelName);

    await prefs.setBool('use_custom_gemini_base_url', _useCustomGeminiBaseUrl);
    await prefs.setBool(
        'use_custom_deepseek_base_url', _useCustomDeepseekBaseUrl);
    await prefs.setBool(
        'use_custom_chatgpt_base_url', _useCustomChatgptBaseUrl);

    final geminiProvider = await GeminiTranslationProvider.instance;
    geminiProvider.setApiKey(geminiKey);
    geminiProvider.setBaseUrl(geminiBaseUrl, _useCustomGeminiBaseUrl);
    geminiProvider.setModelName(geminiModelName);

    final deepseekProvider = await DeepSeekTranslationProvider.instance;
    deepseekProvider.setApiKey(deepseekKey);
    deepseekProvider.setBaseUrl(deepseekBaseUrl, _useCustomDeepseekBaseUrl);
    deepseekProvider.setModelName(deepseekModelName);

    final chatgptProvider = await ChatgptTranslationProvider.instance;
    chatgptProvider.setApiKey(chatgptKey);
    chatgptProvider.setBaseUrl(chatgptBaseUrl, _useCustomChatgptBaseUrl);
    chatgptProvider.setModelName(chatgptModelName);
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

  TextEditingController _getCurrentBaseUrlController() {
    switch (_selectedProvider) {
      case 'Gemini':
        return _geminiBaseUrlController;
      case 'DeepSeek':
        return _deepseekBaseUrlController;
      case 'ChatGPT':
        return _chatgptBaseUrlController;
      default:
        return TextEditingController();
    }
  }

  TextEditingController _getCurrentModelNameController() {
    switch (_selectedProvider) {
      case 'Gemini':
        return _geminiModelNameController;
      case 'DeepSeek':
        return _deepseekModelNameController;
      case 'ChatGPT':
        return _chatgptModelNameController;
      default:
        return TextEditingController();
    }
  }

  bool _getCurrentUseCustomBaseUrl() {
    switch (_selectedProvider) {
      case 'Gemini':
        return _useCustomGeminiBaseUrl;
      case 'DeepSeek':
        return _useCustomDeepseekBaseUrl;
      case 'ChatGPT':
        return _useCustomChatgptBaseUrl;
      default:
        return false;
    }
  }

  void _setCurrentUseCustomBaseUrl(bool value) {
    setState(() {
      switch (_selectedProvider) {
        case 'Gemini':
          _useCustomGeminiBaseUrl = value;
          break;
        case 'DeepSeek':
          _useCustomDeepseekBaseUrl = value;
          break;
        case 'ChatGPT':
          _useCustomChatgptBaseUrl = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiSettings),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: 8),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _getCurrentModelNameController(),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .modelNameLabel(_selectedProvider ?? ''),
                    hintText: _selectedProvider == 'Gemini'
                        ? 'e.g., gemini-2.5-flash'
                        : _selectedProvider == 'DeepSeek'
                            ? 'e.g., deepseek-chat'
                            : _selectedProvider == 'ChatGPT'
                                ? 'e.g., gpt-4o'
                                : '',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterModelName(_selectedProvider ?? '');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.overrideBaseUrl),
                  value: _getCurrentUseCustomBaseUrl(),
                  onChanged: _setCurrentUseCustomBaseUrl,
                ),
                if (_getCurrentUseCustomBaseUrl())
                  TextFormField(
                    controller: _getCurrentBaseUrlController(),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.customBaseUrl,
                      hintText: "https://api.example.com/v1",
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (val) {
                      if (_getCurrentUseCustomBaseUrl() &&
                          (val == null || val.isEmpty)) {
                        return AppLocalizations.of(context)!.pleaseEnterBaseUrl;
                      }
                      if (_getCurrentUseCustomBaseUrl() &&
                          !Uri.tryParse(val!)!.isAbsolute) {
                        return AppLocalizations.of(context)!.invalidUrl;
                      }
                      return null;
                    },
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
