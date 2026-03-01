import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wispar/services/openAlex_api.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => ApiSettingsScreenState();
}

class ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _openAlexKeyController = TextEditingController();
  bool passwordVisible = false;

  bool _scrapeAbstracts = true; // Default to scraping missing abstracts
  int _fetchInterval = 6; // Default API fetch to 6 hours
  int _concurrentFetches = 3; // Default to 3 concurrent fetches

  bool _overrideUserAgent = false;
  final TextEditingController _userAgentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void dispose() {
    _userAgentController.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();

    final openAlexKey = prefs.getString('openalex_api_key') ?? '';
    final fetchInterval = prefs.getInt('fetchInterval') ?? 6;
    final scrapeAbstracts = prefs.getBool('scrapeAbstracts') ?? true;
    final concurrentFetches = prefs.getInt('concurrentFetches') ?? 3;
    final overrideUserAgent = prefs.getBool('overrideUserAgent') ?? false;
    final customUserAgent = prefs.getString('customUserAgent') ?? '';

    setState(() {
      _openAlexKeyController.text = openAlexKey;
      _fetchInterval = fetchInterval;
      _scrapeAbstracts = scrapeAbstracts;
      _concurrentFetches = concurrentFetches;
      _overrideUserAgent = overrideUserAgent;
      _userAgentController.text = customUserAgent;
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        'openalex_api_key', _openAlexKeyController.text.trim());

    await prefs.setInt('fetchInterval', _fetchInterval);
    await prefs.setBool('scrapeAbstracts', _scrapeAbstracts);
    await prefs.setInt('concurrentFetches', _concurrentFetches);
    await prefs.setBool('overrideUserAgent', _overrideUserAgent);
    if (_overrideUserAgent) {
      await prefs.setString('customUserAgent', _userAgentController.text);
    }

    OpenAlexApi.apiKey = _openAlexKeyController.text.trim();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.apiSettings),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.openAlexApiKeyDesc,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: () {
                    launchUrl(
                      Uri.parse('https://openalex.org/settings/api'),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.zoteroCreateKey)),
              const SizedBox(height: 16),
              TextField(
                controller: _openAlexKeyController,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.openAlexApiKey,
                  border: OutlineInputBorder(),
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
                  ),
                ),
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.cachedArticleRetentionDaysDesc,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _fetchInterval,
                onChanged: (int? newValue) {
                  setState(() {
                    _fetchInterval = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.apiFetchInterval,
                  hintText: AppLocalizations.of(context)!.apiFetchIntervalHint,
                ),
                items: [
                  DropdownMenuItem(
                    value: 3,
                    child: Text('3 ${AppLocalizations.of(context)!.hours}'),
                  ),
                  DropdownMenuItem(
                    value: 6,
                    child: Text('6 ${AppLocalizations.of(context)!.hours}'),
                  ),
                  DropdownMenuItem(
                    value: 12,
                    child: Text('12 ${AppLocalizations.of(context)!.hours}'),
                  ),
                  DropdownMenuItem(
                    value: 24,
                    child: Text('24 ${AppLocalizations.of(context)!.hours}'),
                  ),
                  DropdownMenuItem(
                    value: 48,
                    child: Text('48 ${AppLocalizations.of(context)!.hours}'),
                  ),
                  DropdownMenuItem(
                    value: 72,
                    child: Text('72 ${AppLocalizations.of(context)!.hours}'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!
                    .concurrentFetches(_concurrentFetches),
              ),
              Slider(
                value: _concurrentFetches.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _concurrentFetches.toString(),
                onChanged: (double value) {
                  setState(() {
                    _concurrentFetches = value.toInt();
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.scrapeAbstracts,
                  ),
                  Switch(
                    value: _scrapeAbstracts,
                    onChanged: (bool value) async {
                      setState(() {
                        _scrapeAbstracts = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.overrideUserAgent),
                  Switch(
                    value: _overrideUserAgent,
                    onChanged: (bool value) {
                      setState(() {
                        _overrideUserAgent = value;
                      });
                    },
                  ),
                ],
              ),
              if (_overrideUserAgent)
                TextFormField(
                  controller: _userAgentController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.customUserAgent,
                    hintText:
                        "Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:140.0) Gecko/140.0 Firefox/140.0",
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saveKeys,
                child: Text(AppLocalizations.of(context)!.saveSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
