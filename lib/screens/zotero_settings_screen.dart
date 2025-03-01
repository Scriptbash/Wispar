import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/zotero_api.dart';

class ZoteroSettings extends StatefulWidget {
  const ZoteroSettings({Key? key});

  @override
  _ZoteroSettingsState createState() => _ZoteroSettingsState();
}

class _ZoteroSettingsState extends State<ZoteroSettings> {
  TextEditingController _apiKeyController = TextEditingController();
  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  _loadApiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('zoteroApiKey');
    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.zoteroSettings),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.zoteroPermissions1),
                    Text(
                      '\n${AppLocalizations.of(context)!.zoteroPermissions2}\n',
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          launchUrl(
                            Uri.parse(
                                'https://www.zotero.org/settings/keys/new'),
                          );
                        },
                        child:
                            Text(AppLocalizations.of(context)!.zoteroCreateKey),
                      ),
                    ),
                    Text(
                      '\n${AppLocalizations.of(context)!.zoteroPermissions3}\n',
                    ),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.zoteroEnterKey,
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
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String apiKey = _apiKeyController.text;
                          if (apiKey.isNotEmpty) {
                            int userId = await ZoteroService.getUserId(apiKey);
                            if (userId != 0) {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('zoteroApiKey', apiKey);
                              await prefs.setString(
                                  'zoteroUserId', userId.toString());
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .zoteroValidKey),
                                      duration: const Duration(seconds: 2)));
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .zoteroInvalidKey),
                                duration: const Duration(seconds: 3),
                              ));
                            }
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
