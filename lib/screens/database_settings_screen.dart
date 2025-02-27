import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';

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
      await prefs.setInt('fetchInterval', _fetchInterval);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    }
  }

  /*Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // On Android 11+, request Manage External Storage permission
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    if (await Permission.storage.isPermanentlyDenied) {
      openAppSettings();
    }

    return false;
  }*/

  Future<void> _exportDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      String dbPath = '$databasePath/wispar.db';
      File dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.databaseNotFound),
          ),
        );
        return;
      }

      Uint8List fileBytes = await dbFile.readAsBytes();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.selectDBExportLocation,
        fileName: 'wispar.db',
        //type: FileType.custom,
        //allowedExtensions: ['db'],
        bytes: fileBytes,
      );

      if (outputFile == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseExported),
        ),
      );
    } catch (e) {
      debugPrint("Database export error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("${AppLocalizations.of(context)!.databaseExportFailed}: $e"),
        ),
      );
    }
  }

  Future<void> _importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          //type: FileType.custom,
          //allowedExtensions: ['db'], //It's currently broken https://github.com/miguelpruivo/flutter_file_picker/issues/1689
          );

      if (result == null) return;

      File selectedFile = File(result.files.single.path!);
      final databasePath = await getDatabasesPath();
      String dbPath = '$databasePath/wispar.db';

      // Replace the existing database
      await selectedFile.copy(dbPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseImported),
        ),
      );

      // Reload the database
      await openDatabase(dbPath);
    } catch (e) {
      debugPrint("Database import error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseImportFailed),
        ),
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
        child: SingleChildScrollView(
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
                      _cleanupInterval =
                          int.tryParse(value) ?? _cleanupInterval;
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
                    hintText:
                        AppLocalizations.of(context)!.apiFetchIntervalHint,
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
                const SizedBox(height: 64),
                ElevatedButton.icon(
                  onPressed: _exportDatabase,
                  icon: Icon(Icons.save_alt),
                  label: Text(AppLocalizations.of(context)!.exportDatabase),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _importDatabase,
                  icon: Icon(Icons.upload_file_outlined),
                  label: Text(AppLocalizations.of(context)!.importDatabase),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
