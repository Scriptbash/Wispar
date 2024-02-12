import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZoteroSettings extends StatefulWidget {
  const ZoteroSettings({Key? key});

  @override
  _ZoteroSettingsState createState() => _ZoteroSettingsState();
}

class _ZoteroSettingsState extends State<ZoteroSettings> {
  TextEditingController _apiKeyController = TextEditingController();

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
        title: Text('Zotero settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'Wispar needs both read and write access to your Zotero account to fully enjoy its integration.',
              ),
              Text(
                '\nWhen creating a new Zotero API key, you must select both "Allow library access" and "Allow write access ".\n',
              ),
              ElevatedButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://www.zotero.org/settings/keys/new'),
                  );
                },
                child: Text('Create a new API key'),
              ),
              Text(
                '\nOnce the API key is created, copy the value and paste it inside the text field below.\n',
              ),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  //border: OutlineInputBorder(),
                  hintText: 'Enter an API key',
                ),
                onChanged: (value) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('zoteroApiKey', value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
