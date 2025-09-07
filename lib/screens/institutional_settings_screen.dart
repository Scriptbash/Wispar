import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated_l10n/app_localizations.dart';
import './institutions_screen.dart';
import '../services/database_helper.dart';

class InstitutionalSettingsScreen extends StatefulWidget {
  const InstitutionalSettingsScreen({super.key});

  @override
  State<InstitutionalSettingsScreen> createState() =>
      _InstitutionalSettingsScreenState();
}

class _InstitutionalSettingsScreenState
    extends State<InstitutionalSettingsScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> knownUrls = [];

  @override
  void initState() {
    super.initState();
    _loadKnownUrls();
  }

  Future<void> _loadKnownUrls() async {
    final db = await dbHelper.database;
    final urls = await db.query('knownUrls');
    setState(() {
      knownUrls = urls;
    });
  }

  Future<void> saveInstitutionPreference(String name, String url) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('institution_name', name);
    prefs.setString('institution_url', url);
  }

  Future<String?> getInstitutionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('institution_name');
  }

  Future<void> unsetInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('institution_name');
    prefs.remove('institution_url');
    setState(() {});
  }

  Future<void> _editKnownUrl(Map<String, dynamic> entry) async {
    final urlController = TextEditingController(text: entry['url']);
    int proxySuccess = entry['proxySuccess'] ?? 0;

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editKnownUrl),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: "URL"),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) => RadioGroup<int>(
                    groupValue: proxySuccess,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => proxySuccess = val);
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!
                              .redirectsSuccessfully),
                          leading: Radio<int>(value: 1),
                          onTap: () => setDialogState(() => proxySuccess = 1),
                        ),
                        ListTile(
                          title: Text(
                              AppLocalizations.of(context)!.failsToRedirect),
                          leading: Radio<int>(value: 0),
                          onTap: () => setDialogState(() => proxySuccess = 0),
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.loginPage),
                          leading: Radio<int>(value: 2),
                          onTap: () => setDialogState(() => proxySuccess = 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'url': urlController.text,
              'proxySuccess': proxySuccess,
            }),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (updated != null) {
      await dbHelper.updateKnownUrl(
        entry['id'],
        url: updated['url'],
        proxySuccess: updated['proxySuccess'],
      );
      _loadKnownUrls();
    }
  }

  Future<void> _deleteKnownUrl(int id) async {
    await dbHelper.deleteKnownUrl(id);
    _loadKnownUrls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.institutionalAccess),
      ),
      body: SafeArea(
          child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text("EZproxy"),
            subtitle: FutureBuilder<String?>(
              future: getInstitutionName(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(snapshot.data!);
                }
                return Text(AppLocalizations.of(context)!.noinstitution);
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>?>(
                context,
                MaterialPageRoute(builder: (context) => InstitutionScreen()),
              );

              if (result != null &&
                  result.containsKey('name') &&
                  result.containsKey('url')) {
                if (result['name'] == 'None') {
                  await unsetInstitution();
                } else {
                  await saveInstitutionPreference(
                      result['name'], result['url']);
                }
                setState(() {});
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              AppLocalizations.of(context)!.manageUrlsAndRedirect,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(),
            ),
          ),
          ...knownUrls.map((entry) {
            String statusText;
            switch (entry['proxySuccess']) {
              case 1:
                statusText =
                    AppLocalizations.of(context)!.redirectsSuccessfully;
                break;
              case 0:
                statusText = AppLocalizations.of(context)!.failsToRedirect;
                break;
              case 2:
                statusText = AppLocalizations.of(context)!.loginPage;
                break;
              default:
                statusText = "Unknown";
            }

            return ListTile(
              title: Text(entry['url'] ?? ''),
              subtitle: Text(statusText),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: Icon(Icons.edit,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _editKnownUrl(entry)),
                  IconButton(
                      icon: Icon(Icons.delete,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _deleteKnownUrl(entry['id'])),
                ],
              ),
            );
          }).toList(),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addKnownUrl,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addKnownUrl() async {
    final urlController = TextEditingController();
    int proxySuccess = 0;

    final newEntry = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addKnownUrl),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: "URL"),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) => RadioGroup<int>(
                    groupValue: proxySuccess,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => proxySuccess = val);
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!
                              .redirectsSuccessfully),
                          leading: Radio<int>(value: 1),
                          onTap: () => setDialogState(() => proxySuccess = 1),
                        ),
                        ListTile(
                          title: Text(
                              AppLocalizations.of(context)!.failsToRedirect),
                          leading: Radio<int>(value: 0),
                          onTap: () => setDialogState(() => proxySuccess = 0),
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.loginPage),
                          leading: Radio<int>(value: 2),
                          onTap: () => setDialogState(() => proxySuccess = 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'url': urlController.text,
              'proxySuccess': proxySuccess,
            }),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (newEntry != null &&
        newEntry['url'] != null &&
        newEntry['url'].isNotEmpty) {
      await dbHelper.insertKnownUrl(newEntry['url'], newEntry['proxySuccess']);
      _loadKnownUrls();
    }
  }
}
