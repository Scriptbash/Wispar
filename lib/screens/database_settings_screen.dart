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
import '../services/database_helper.dart';

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

  bool _useCustomPath = false;
  String? _customDatabasePath;

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
      _useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      _customDatabasePath = prefs.getString('customDatabasePath');
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

  Future<void> _saveCustomDatabaseSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCustomDatabasePath', _useCustomPath);
    if (_customDatabasePath != null) {
      await prefs.setString('customDatabasePath', _customDatabasePath!);
    }
  }

  Future<void> _moveDatabaseTo(String newDirectory) async {
    try {
      await _showLoadingDialog(AppLocalizations.of(context)!.movingDatabase);
      final dbHelper = DatabaseHelper();
      await dbHelper.closeDatabase();

      final oldDBPath = p.join(await getDatabasesPath(), 'wispar.db');
      final newDBPath = p.join(newDirectory, 'wispar.db');
      final appDir = await getApplicationDocumentsDirectory();
      final newGraphicalDir =
          Directory(p.join(newDirectory, 'graphical_abstracts'));

      // Move database
      final oldDBFile = File(oldDBPath);
      if (await oldDBFile.exists()) {
        await oldDBFile.copy(newDBPath);
        await oldDBFile.delete();
      }

      // Move PDFs
      for (final file in appDir.listSync()) {
        if (file is File && file.path.endsWith('.pdf')) {
          final newFile = File(p.join(newDirectory, p.basename(file.path)));
          await file.copy(newFile.path);
          await file.delete();
        }
      }

      // Move graphical abstracts
      final oldGraphicalDir =
          Directory(p.join(appDir.path, 'graphical_abstracts'));
      if (await oldGraphicalDir.exists()) {
        await for (final entity in oldGraphicalDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath =
                p.relative(entity.path, from: oldGraphicalDir.path);
            final newPath = p.join(newGraphicalDir.path, relativePath);

            await Directory(p.dirname(newPath)).create(recursive: true);

            await File(entity.path).copy(newPath);
            await File(entity.path).delete();
          }
        }
        await oldGraphicalDir.delete(recursive: true);
      }

      await dbHelper.database;

      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseMoved),
        ));
      }

      logger.info('Database successfully moved to $newDirectory');
    } catch (e, stackTrace) {
      _hideLoadingDialog();
      logger.severe('Failed to move database.', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.databaseMoveFailed(e))),
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

      final prefs = await SharedPreferences.getInstance();
      final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      final customPath = prefs.getString('customDatabasePath');

      String sourceBasePath;
      if (useCustomPath && customPath != null) {
        sourceBasePath = customPath;
      } else {
        final defaultAppDir = await getApplicationDocumentsDirectory();
        sourceBasePath = defaultAppDir.path;
      }

      String dbDirectoryPath;
      if (useCustomPath && customPath != null) {
        dbDirectoryPath = customPath;
      } else {
        dbDirectoryPath = await getDatabasesPath();
      }

      String dbPath = p.join(dbDirectoryPath, "wispar.db");
      File dbFile = File(dbPath);

      final sourceDir = Directory(sourceBasePath);

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

      for (var entity in sourceDir.listSync()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          await encoder.addFile(entity, p.basename(entity.path));
        }
      }

      final graphicalAbstractsDir =
          Directory(p.join(sourceBasePath, 'graphical_abstracts'));

      if (await graphicalAbstractsDir.exists()) {
        final relativeToDir = Directory(sourceBasePath);

        for (var entity in graphicalAbstractsDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath =
                p.relative(entity.path, from: relativeToDir.path);
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
      final dbHelper = DatabaseHelper();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || !mounted) return;
      await _showLoadingDialog(AppLocalizations.of(context)!.importingDatabase);
      await dbHelper.closeDatabase();
      File selectedFile = File(result.files.single.path!);

      final prefs = await SharedPreferences.getInstance();
      final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      final customPath = prefs.getString('customDatabasePath');

      String dbDestinationPath;
      if (useCustomPath && customPath != null) {
        dbDestinationPath = customPath;
      } else {
        dbDestinationPath = await getDatabasesPath();
      }

      String docsDestinationPath;
      if (useCustomPath && customPath != null) {
        docsDestinationPath = customPath;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        docsDestinationPath = appDir.path;
      }

      final inputStream = InputFileStream(selectedFile.path);
      final archive = ZipDecoder().decodeStream(inputStream);
      String? importedDBPath;

      for (final file in archive) {
        final destinationBasePath =
            file.name == 'wispar.db' ? dbDestinationPath : docsDestinationPath;

        final filePath = p.join(destinationBasePath, file.name);
        final outFile = File(filePath);
        await outFile.create(recursive: true);

        if (file.isFile) {
          final outputStream = OutputFileStream(outFile.path);
          file.writeContent(outputStream);
          await outputStream.close();

          if (file.name == 'wispar.db') {
            importedDBPath = filePath;
          }
        }
      }

      if (importedDBPath != null) {
        await dbHelper.database;
      } else {
        logger.severe('Imported ZIP archive did not contain wispar.db');
      }

      logger.info(
          'The database was successfully imported to $dbDestinationPath from ${selectedFile.path}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.databaseImported)),
      );

      _hideLoadingDialog();
    } catch (e, stackTrace) {
      logger.severe('Database import error.', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseImportFailed)));
      _hideLoadingDialog();
    }
  }

  Future<void> _moveDatabaseBackToDefault() async {
    if (_customDatabasePath == null) {
      logger.warning(
          'Attempted to move database back, but no custom path was set.');
      return;
    }

    try {
      await _showLoadingDialog(AppLocalizations.of(context)!.movingDatabase);
      final dbHelper = DatabaseHelper();

      await dbHelper.closeDatabase();

      final oldCustomPath = _customDatabasePath!;
      final defaultDBPath = p.join(await getDatabasesPath(), 'wispar.db');
      final appDir = await getApplicationDocumentsDirectory();

      final oldDBPath = p.join(oldCustomPath, 'wispar.db');
      final oldGraphicalDir =
          Directory(p.join(oldCustomPath, 'graphical_abstracts'));
      final newGraphicalDir =
          Directory(p.join(appDir.path, 'graphical_abstracts'));

      // Move database
      final oldDBFile = File(oldDBPath);
      if (await oldDBFile.exists()) {
        await oldDBFile.copy(defaultDBPath);
        await oldDBFile.delete();
      }

      // Move PDFs
      final customDir = Directory(oldCustomPath);
      await for (final file in customDir.list()) {
        if (file is File && file.path.endsWith('.pdf')) {
          final newFile = File(p.join(appDir.path, p.basename(file.path)));
          await file.copy(newFile.path);
          await file.delete();
        }
      }

      // Move graphical abstracts
      if (await oldGraphicalDir.exists()) {
        await for (final entity in oldGraphicalDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath =
                p.relative(entity.path, from: oldGraphicalDir.path);
            final newPath = p.join(newGraphicalDir.path, relativePath);

            await Directory(p.dirname(newPath)).create(recursive: true);

            await File(entity.path).copy(newPath);
            await File(entity.path).delete();
          }
        }
        await oldGraphicalDir.delete(recursive: true);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('customDatabasePath');
      await prefs.setBool('useCustomDatabasePath', false);

      await dbHelper.database;

      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.databaseMoved),
        ));
      }

      logger.info('Database successfully moved back to default app directory.');
    } catch (e, stackTrace) {
      _hideLoadingDialog();
      logger.severe('Failed to move database back to default app directory.', e,
          stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.databaseMoveFailed(e))),
        );
      }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!
                            .customDatabaseLocation),
                        Switch(
                          value: _useCustomPath,
                          onChanged: (bool value) async {
                            if (value) {
                              String? directory =
                                  await FilePicker.platform.getDirectoryPath(
                                dialogTitle: AppLocalizations.of(context)!
                                    .selectCustomDBLocation,
                              );
                              if (directory != null) {
                                await _moveDatabaseTo(directory);
                                setState(() {
                                  _useCustomPath = true;
                                  _customDatabasePath = directory;
                                });
                                await _saveCustomDatabaseSettings();
                              }
                            } else {
                              if (_customDatabasePath != null) {
                                await _moveDatabaseBackToDefault();
                              }

                              setState(() {
                                _useCustomPath = false;
                                _customDatabasePath = null;
                              });

                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('customDatabasePath');
                              await prefs.setBool(
                                  'useCustomDatabasePath', false);
                            }
                          },
                        ),
                      ],
                    ),
                    if (_customDatabasePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!
                              .currentDBLocation(_customDatabasePath!),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
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
