import 'dart:io';
import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../services/logs_helper.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  DatabaseSettingsScreenState createState() => DatabaseSettingsScreenState();
}

class DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  final logger = LogsService().logger;
  final _formKey = GlobalKey<FormState>();

  bool _scrapeAbstracts = true; // Default to scraping missing abstracts
  int _cleanupInterval = 7; // Default for cleanup interval
  int _fetchInterval = 6; // Default API fetch to 6 hours
  int _concurrentFetches = 3; // Default to 3 concurrent fetches
  final TextEditingController _cleanupIntervalController =
      TextEditingController();

  bool _overrideUserAgent = false;
  final TextEditingController _userAgentController = TextEditingController();

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
      _scrapeAbstracts = prefs.getBool('scrapeAbstracts') ?? true;
      _concurrentFetches = prefs.getInt('concurrentFetches') ?? 3;
      _overrideUserAgent = prefs.getBool('overrideUserAgent') ?? false;
      _userAgentController.text = prefs.getString('customUserAgent') ?? '';
    });
    _cleanupIntervalController.text = _cleanupInterval.toString();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cleanupInterval', _cleanupInterval);
      await prefs.setInt('fetchInterval', _fetchInterval);
      await prefs.setBool('scrapeAbstracts', _scrapeAbstracts);
      await prefs.setInt('concurrentFetches', _concurrentFetches);
      await prefs.setBool('overrideUserAgent', _overrideUserAgent);
      if (_overrideUserAgent) {
        await prefs.setString('customUserAgent', _userAgentController.text);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
        );
      }
    }
  }

  Future<void> _exportDatabase() async {
    try {
      String? outputDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.selectDBExportLocation,
      );

      if (outputDirectory == null || !mounted) return;
      await _showLoadingDialog(AppLocalizations.of(context)!.exportingDatabase);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String outputFile =
          p.join(outputDirectory, 'wispar_backup_$timestamp.zip');

      final appDir = await getApplicationDocumentsDirectory();
      final databasePath = await getDatabasesPath();
      String dbPath = '$databasePath/wispar.db';
      File dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.databaseNotFound)),
        );
        _hideLoadingDialog();
        return;
      }

      final encoder = ZipFileEncoder();
      encoder.create(outputFile);

      await encoder.addFile(dbFile, 'wispar.db');

      for (var entity in appDir.listSync()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          await encoder.addFile(entity, p.basename(entity.path));
        }
      }

      final graphicalAbstractsDir =
          Directory(p.join(appDir.path, 'graphical_abstracts'));
      if (await graphicalAbstractsDir.exists()) {
        for (var entity in graphicalAbstractsDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: appDir.path);
            await encoder.addFile(entity, relativePath);
          }
        }
      }

      encoder.close();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.databaseExported)),
      );
      _hideLoadingDialog();
      logger.info('The database was successfully exported to $outputFile');
    } catch (e, stackTrace) {
      logger.severe('Database export error.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "${AppLocalizations.of(context)!.databaseExportFailed}: $e")));
      _hideLoadingDialog();
    }
  }

  Future<void> _importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || !mounted) return;
      await _showLoadingDialog(AppLocalizations.of(context)!.importingDatabase);

      File selectedFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final databasePath = await getDatabasesPath();

      final inputStream = InputFileStream(selectedFile.path);
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final file in archive) {
        final filePath = file.name == 'wispar.db'
            ? '$databasePath/${file.name}'
            : '${appDir.path}/${file.name}';
        final outFile = File(filePath);
        await outFile.create(recursive: true);

        if (file.isFile) {
          final outputStream = OutputFileStream(outFile.path);
          file.writeContent(outputStream);
          await outputStream.close();
        }
      }

      logger.info(
          'The database was successfully imported from ${selectedFile.path}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.databaseImported)),
      );
      await openDatabase('$databasePath/wispar.db');
      _hideLoadingDialog();
    } catch (e, stackTrace) {
      logger.severe('Database import error.', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseImportFailed)));
      _hideLoadingDialog();
    }
  }

  Future<void> _showLoadingDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.databaseSettings),
        ),
        body: SafeArea(
          child: Padding(
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
                        labelText:
                            AppLocalizations.of(context)!.cleanupInterval,
                        hintText:
                            AppLocalizations.of(context)!.cleanupIntervalHint,
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
                        if (intValue == null ||
                            intValue < 1 ||
                            intValue > 365) {
                          return AppLocalizations.of(context)!
                              .cleanupIntervalNumberNotBetween;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _fetchInterval,
                      onChanged: (int? newValue) {
                        setState(() {
                          _fetchInterval = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.apiFetchInterval,
                        hintText:
                            AppLocalizations.of(context)!.apiFetchIntervalHint,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 3,
                          child:
                              Text('3 ${AppLocalizations.of(context)!.hours}'),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child:
                              Text('6 ${AppLocalizations.of(context)!.hours}'),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child:
                              Text('12 ${AppLocalizations.of(context)!.hours}'),
                        ),
                        DropdownMenuItem(
                          value: 24,
                          child:
                              Text('24 ${AppLocalizations.of(context)!.hours}'),
                        ),
                        DropdownMenuItem(
                          value: 48,
                          child:
                              Text('48 ${AppLocalizations.of(context)!.hours}'),
                        ),
                        DropdownMenuItem(
                          value: 72,
                          child:
                              Text('72 ${AppLocalizations.of(context)!.hours}'),
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
                          labelText:
                              AppLocalizations.of(context)!.customUserAgent,
                          hintText:
                              "Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:140.0) Gecko/140.0 Firefox/140.0",
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saveSettings,
                      child: Text(AppLocalizations.of(context)!.saveSettings),
                    ),
                    const SizedBox(height: 64),
                    const Divider(),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _exportDatabase,
                      icon: Icon(Icons.save_alt),
                      label: Text(AppLocalizations.of(context)!.exportDatabase),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _importDatabase,
                      icon: Icon(Icons.upload_file_outlined),
                      label: Text(AppLocalizations.of(context)!.importDatabase),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
