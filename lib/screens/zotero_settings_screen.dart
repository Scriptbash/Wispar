import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/widgets/zotero_bottomsheet.dart';
import 'package:wispar/services/zotero_api.dart';
import 'package:wispar/models/zotero_models.dart';
import 'dart:convert';

class ZoteroSettings extends StatefulWidget {
  const ZoteroSettings({super.key});

  @override
  ZoteroSettingsState createState() => ZoteroSettingsState();
}

class ZoteroSettingsState extends State<ZoteroSettings> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool passwordVisible = false;
  bool _alwaysSendToCollection = false;
  String? _defaultCollectionKey;
  String? _defaultCollectionName;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadCollectionSettings();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('zoteroApiKey');
    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  Future<void> _loadCollectionSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString('zoteroDefaultCollection');

    ZoteroCollection? collection;

    if (raw != null) {
      try {
        collection = ZoteroCollection.fromJson(
          jsonDecode(raw),
        );
      } catch (_) {
        collection = null;
      }
    }

    setState(() {
      _alwaysSendToCollection = prefs.getBool('zoteroAlwaysSend') ?? false;

      _defaultCollectionKey = collection?.key;
      _defaultCollectionName = collection?.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.zoteroSettings),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(AppLocalizations.of(context)!
                                  .zoteroPermissions1),
                              Text(
                                '\n${AppLocalizations.of(context)!.zoteroPermissions2}\n',
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    launchUrl(
                                      Uri.parse(
                                          'https://www.zotero.org/settings/keys/new'),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .zoteroCreateKey,
                                  ),
                                ),
                              ),
                              Text(
                                '\n${AppLocalizations.of(context)!.zoteroPermissions3}\n',
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextField(
                                  controller: _apiKeyController,
                                  obscureText: !passwordVisible,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .zoteroEnterKey,
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
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () async {
                                    final apiKey = _apiKeyController.text;
                                    if (apiKey.isNotEmpty) {
                                      final userId =
                                          await ZoteroService.getUserId(apiKey);
                                      if (userId != 0) {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setString(
                                            'zoteroApiKey', apiKey);
                                        await prefs.setString(
                                            'zoteroUserId', userId.toString());
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .zoteroValidKey,
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .zoteroInvalidKey,
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.save),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SwitchListTile(
                                title: Text(AppLocalizations.of(context)!
                                    .zoteroSpecificCollection),
                                value: _alwaysSendToCollection,
                                onChanged: (value) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'zoteroAlwaysSend', value);

                                  setState(() {
                                    _alwaysSendToCollection = value;
                                  });
                                },
                              ),
                              if (_alwaysSendToCollection)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.folder,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  title: Text(
                                    _defaultCollectionName ??
                                        AppLocalizations.of(context)!
                                            .noZoteroCollectionSelected,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final selectedCollection =
                                        await selectZoteroCollection(context,
                                            isSelectionMode: true);

                                    if (selectedCollection != null) {
                                      final prefs =
                                          await SharedPreferences.getInstance();

                                      await prefs.setString(
                                        'zoteroDefaultCollection',
                                        jsonEncode(selectedCollection.toJson()),
                                      );

                                      setState(() {
                                        _defaultCollectionKey =
                                            selectedCollection.key;
                                        _defaultCollectionName =
                                            selectedCollection.name;
                                      });
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
