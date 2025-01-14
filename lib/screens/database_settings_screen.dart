import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({Key? key}) : super(key: key);

  @override
  _DatabaseSettingsScreenState createState() => _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  int _cleanupInterval = 7; // Default for cleanup interval
  int _fetchInterval = 6; // Default API fetch to 6 hours
  TextEditingController _cleanupIntervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved preferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load the values from SharedPreferences if available
      _cleanupInterval = prefs.getInt('cleanupInterval') ?? 7;
      _fetchInterval = prefs.getInt('fetchInterval') ?? 6;
    });
    _cleanupIntervalController.text = _cleanupInterval.toString();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setInt('cleanupInterval', _cleanupInterval);
      await prefs.setInt('fetchInterval', _fetchInterval); // Save as integer

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.databaseSettings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cleanupIntervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.cleanupInterval,
                  hintText: AppLocalizations.of(context)!.cleanupIntervalHint,
                ),
                onChanged: (value) {
                  setState(() {
                    _cleanupInterval = int.tryParse(value) ?? _cleanupInterval;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!
                        .cleanupIntervalInvalidNumber;
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1 || intValue > 365) {
                    return AppLocalizations.of(context)!
                        .cleanupIntervalNumberNotBetween;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _fetchInterval,
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text(AppLocalizations.of(context)!.saveSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
