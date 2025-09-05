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
  bool passwordVisible = false;
  bool _hideAI = false;

  final List<String> _providers = ['Gemini', 'DeepSeek', 'ChatGPT'];
  String? _selectedProvider;

  double _geminiTemperature = 0.7;
  double _deepseekTemperature = 0.7;
  double _chatgptTemperature = 1.0;

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

  final TextEditingController _customPrompt1Controller =
      TextEditingController();
  final TextEditingController _customPrompt2Controller =
      TextEditingController();
  final TextEditingController _customPrompt3Controller =
      TextEditingController();
  int _selectedPrompt = 1;

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
    _customPrompt1Controller.dispose();
    _customPrompt2Controller.dispose();
    _customPrompt3Controller.dispose();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideAI = prefs.getBool('hide_ai_features') ?? false;
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
          prefs.getString('chatgpt_model_name') ?? 'gpt-4.1-mini';

      _useCustomGeminiBaseUrl =
          prefs.getBool('use_custom_gemini_base_url') ?? false;
      _useCustomDeepseekBaseUrl =
          prefs.getBool('use_custom_deepseek_base_url') ?? false;
      _useCustomChatgptBaseUrl =
          prefs.getBool('use_custom_chatgpt_base_url') ?? false;

      _geminiTemperature = prefs.getDouble('gemini_temperature') ?? 0.7;
      _deepseekTemperature = prefs.getDouble('deepseek_temperature') ?? 0.7;
      _chatgptTemperature = prefs.getDouble('chatgpt_temperature') ?? 1.0;

      final prompts =
          prefs.getStringList('custom_translation_prompts') ?? ['', '', ''];
      _customPrompt1Controller.text = prompts.length > 0 ? prompts[0] : '';
      _customPrompt2Controller.text = prompts.length > 1 ? prompts[1] : '';
      _customPrompt3Controller.text = prompts.length > 2 ? prompts[2] : '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_ai_features', _hideAI);
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
    await prefs.setDouble('gemini_temperature', _geminiTemperature);
    await prefs.setDouble('deepseek_temperature', _deepseekTemperature);
    await prefs.setDouble('chatgpt_temperature', _chatgptTemperature);
    await prefs.setStringList('custom_translation_prompts', [
      _customPrompt1Controller.text,
      _customPrompt2Controller.text,
      _customPrompt3Controller.text,
    ]);

    await prefs.setInt('selected_translation_prompt', _selectedPrompt);

    final geminiProvider = await GeminiTranslationProvider.instance;
    geminiProvider.setApiKey(geminiKey);
    geminiProvider.setBaseUrl(geminiBaseUrl, _useCustomGeminiBaseUrl);
    geminiProvider.setModelName(geminiModelName);
    geminiProvider.setTemperature(_geminiTemperature);

    final deepseekProvider = await DeepSeekTranslationProvider.instance;
    deepseekProvider.setApiKey(deepseekKey);
    deepseekProvider.setBaseUrl(deepseekBaseUrl, _useCustomDeepseekBaseUrl);
    deepseekProvider.setModelName(deepseekModelName);
    deepseekProvider.setTemperature(_deepseekTemperature);

    final chatgptProvider = await ChatgptTranslationProvider.instance;
    chatgptProvider.setApiKey(chatgptKey);
    chatgptProvider.setBaseUrl(chatgptBaseUrl, _useCustomChatgptBaseUrl);
    chatgptProvider.setModelName(chatgptModelName);
    chatgptProvider.setTemperature(_chatgptTemperature);
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

  double _getCurrentTemperature() {
    switch (_selectedProvider) {
      case 'Gemini':
        return _geminiTemperature;
      case 'DeepSeek':
        return _deepseekTemperature;
      case 'ChatGPT':
        return _chatgptTemperature;
      default:
        return 1.0;
    }
  }

  void _setCurrentTemperature(double value) {
    setState(() {
      switch (_selectedProvider) {
        case 'Gemini':
          _geminiTemperature = value;
          break;
        case 'DeepSeek':
          _deepseekTemperature = value;
          break;
        case 'ChatGPT':
          _chatgptTemperature = value;
          break;
      }
    });
  }

  String? _validateCustomPrompt(String? prompt) {
    if (prompt == null || prompt.isEmpty) return null;
    final missing = <String>[];
    if (!prompt.contains('\$src')) missing.add('\$src');
    if (!prompt.contains('\$dst')) missing.add('\$dst');
    if (!prompt.contains('\$text')) missing.add('\$text');

    if (missing.isNotEmpty) {
      return AppLocalizations.of(context)!.missingPlaceholders(
        missing.join(', '),
      );
    }
    return null;
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
                    passwordVisible = false;
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      )),
                  onSaved: (val) {},
                  validator: (val) => (val == null || val.isEmpty)
                      ? AppLocalizations.of(context)!
                          .pleaseEnterAiAPIKey(_selectedProvider ?? '')
                      : null,
                  obscureText: !passwordVisible,
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
                                ? 'e.g., gpt-4.1-mini'
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
                Text(AppLocalizations.of(context)!.aiTemperature),
                Slider(
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  label: _getCurrentTemperature().toStringAsFixed(2),
                  value: _getCurrentTemperature(),
                  onChanged: _setCurrentTemperature,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.aiCustomPrompts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(AppLocalizations.of(context)!.aiCustomPromptsDescription,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customPrompt1Controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '1',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCustomPrompt,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customPrompt2Controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '2',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCustomPrompt,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customPrompt3Controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '3',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCustomPrompt,
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
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.hideAiFeatures),
                  value: _hideAI,
                  onChanged: (val) {
                    setState(() => _hideAI = val);
                    _saveSettings();
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
