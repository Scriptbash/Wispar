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
import 'package:flutter/services.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  DatabaseSettingsScreenState createState() => DatabaseSettingsScreenState();
}

class DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  static const platform = MethodChannel('app.wispar.wispar/database_access');
  final logger = LogsService().logger;
  final _formKey = GlobalKey<FormState>();

  bool _scrapeAbstracts = true; // Default to scraping missing abstracts
  int _cleanupThreshold = 90; // Default for cleanup interval
  int _fetchInterval = 6; // Default API fetch to 6 hours
  int _concurrentFetches = 3; // Default to 3 concurrent fetches
  final TextEditingController _cleanupThresholdController =
      TextEditingController();

  bool _overrideUserAgent = false;
  final TextEditingController _userAgentController = TextEditingController();

  bool _useCustomPath = false;
  String? _customDatabasePath;
  String?
      _customDatabaseBookmark; // Bookmark needed for iOS to keep read/write permissions

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
      _cleanupThreshold = prefs.getInt('cleanupThreshold') ?? 90;
      _fetchInterval = prefs.getInt('fetchInterval') ?? 6;
      _scrapeAbstracts = prefs.getBool('scrapeAbstracts') ?? true;
      _concurrentFetches = prefs.getInt('concurrentFetches') ?? 3;
      _overrideUserAgent = prefs.getBool('overrideUserAgent') ?? false;
      _userAgentController.text = prefs.getString('customUserAgent') ?? '';
      _useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      _customDatabasePath = prefs.getString('customDatabasePath');
      _customDatabaseBookmark = prefs.getString('customDatabaseBookmark');
    });
    _cleanupThresholdController.text = _cleanupThreshold.toString();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cleanupThreshold', _cleanupThreshold);
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

  Future<String?> _showConflictDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.databaseConflictTitle),
          content: Text(AppLocalizations.of(context)!.databaseConflictMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('use_existing'),
              child: Text(AppLocalizations.of(context)!.useExistingFiles),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('overwrite'),
              child: Text(AppLocalizations.of(context)!.overwriteFiles),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveDatabaseTo(String? pickedFolder) async {
    if (pickedFolder == null) {
      logger.info('No folder picked.');
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.closeDatabase();

      String? targetPath;

      if (Platform.isIOS) {
        targetPath = await DatabaseHelper.resolveBookmarkPath(pickedFolder);
        if (targetPath == null) {
          throw Exception('Failed to resolve custom database bookmark on iOS.');
        }
      } else {
        targetPath = pickedFolder;
      }

      final existingDBFile = File(p.join(targetPath, 'wispar.db'));
      final existingGraphicalDir =
          Directory(p.join(targetPath, 'graphical_abstracts'));

      bool conflict =
          await existingDBFile.exists() || await existingGraphicalDir.exists();
      String? action = 'overwrite';

      if (conflict && mounted) {
        logger.warning("Existing database files were found. Prompting user.");
        action = await _showConflictDialog();
      }

      if (action == null) {
        return;
      }

      if (action == 'use_existing') {
        logger.info('Using existing database files.');
      } else {
        try {
          await _showLoadingDialog(
              AppLocalizations.of(context)!.movingDatabase);
          await dbHelper.closeDatabase();
          final oldDbPath = await dbHelper.getDbPath();
          final oldBaseDir = Directory(p.dirname(oldDbPath));

          final newDbPath = p.join(targetPath, 'wispar.db');

          // Move database
          final oldDBFile = File(oldDbPath);
          if (await oldDBFile.exists()) {
            await oldDBFile.copy(newDbPath);
            await oldDBFile.delete();
          }

          // Move PDFs
          await for (final file in oldBaseDir.list()) {
            if (file is File && file.path.endsWith('.pdf')) {
              final newFile = File(p.join(targetPath, p.basename(file.path)));
              await file.copy(newFile.path);
              await file.delete();
            }
          }

          // Move graphical abstracts
          final oldGraphicalDir =
              Directory(p.join(oldBaseDir.path, 'graphical_abstracts'));
          final newGraphicalDir =
              Directory(p.join(targetPath, 'graphical_abstracts'));

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
        } catch (e, stackTrace) {
          _hideLoadingDialog();
          logger.severe('Failed to move database.', e, stackTrace);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.databaseMoveFailed(e))),
            );
          }
          return;
        }
      }

      // Save the new custom path
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (Platform.isIOS) {
        await prefs.setString('customDatabaseBookmark', pickedFolder);
      }
      await prefs.setString('customDatabasePath', targetPath);
      await prefs.setBool('useCustomDatabasePath', true);
      setState(() {
        _customDatabasePath = targetPath;
        _customDatabaseBookmark = Platform.isIOS ? pickedFolder : null;
        _useCustomPath = true;
      });
      await dbHelper.database;

      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.databaseMoved)),
        );
      }

      logger.info('Database successfully moved to $targetPath');
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

  Future<void> _moveDatabaseBackToDefault() async {
    try {
      await _showLoadingDialog(AppLocalizations.of(context)!.movingDatabase);
      final dbHelper = DatabaseHelper();
      await dbHelper.closeDatabase();

      final customPath = await _getUsableCustomPath();
      if (customPath == null) {
        throw Exception("Custom DB folder not accessible");
      }
      String defaultDBPath;
      Directory defaultBaseDir;

      if (Platform.isWindows) {
        final appDir = await getApplicationDocumentsDirectory();
        defaultDBPath = p.join(appDir.path, 'wispar.db');
        defaultBaseDir = appDir;
      } else {
        final defaultPath = await getDatabasesPath();
        defaultDBPath = p.join(defaultPath, 'wispar.db');
        defaultBaseDir = Directory(defaultPath);
      }

      final oldDBPath = p.join(customPath, 'wispar.db');
      final oldGraphicalDir =
          Directory(p.join(customPath, 'graphical_abstracts'));
      final newGraphicalDir =
          Directory(p.join(defaultBaseDir.path, 'graphical_abstracts'));

      // Move DB
      final oldDBFile = File(oldDBPath);
      if (await oldDBFile.exists()) {
        await oldDBFile.copy(defaultDBPath);
        await oldDBFile.delete();
      }

      // Move PDFs
      final customDir = Directory(customPath);
      await for (final file in customDir.list()) {
        if (file is File && file.path.endsWith('.pdf')) {
          final newFile =
              File(p.join(defaultBaseDir.path, p.basename(file.path)));
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customDatabasePath');
      await prefs.remove('customDatabaseBookmark');
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

  Future<String?> _getUsableCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
    String? customPath = prefs.getString('customDatabasePath');

    if (!useCustomPath || customPath == null) {
      return null;
    }

    if (Platform.isIOS) {
      final bookmark = prefs.getString('customDatabaseBookmark');
      if (bookmark != null) {
        final resolvedPath =
            await platform.invokeMethod('resolveCustomPath', bookmark);

        if (resolvedPath == null) {
          logger.severe('Failed to resolve custom database bookmark on iOS.');
        }
        return resolvedPath;
      }
      return null; // Shouldnt'happen
    }
    // Return the path directly for Android
    return customPath;
  }

  Future<void> _exportDatabase() async {
    String? outputDirectory;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    try {
      if (Platform.isIOS) {
        final bookmark = await platform.invokeMethod('getExportDirectory');
        if (bookmark != null) {
          outputDirectory =
              await platform.invokeMethod('resolveCustomPath', bookmark);
        }
      } else {
        outputDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: AppLocalizations.of(context)!.selectDBExportLocation,
        );
      }

      if (outputDirectory == null || !mounted) {
        return;
      }

      await _showLoadingDialog(AppLocalizations.of(context)!.exportingDatabase);

      final String outputFile =
          p.join(outputDirectory, 'wispar_backup_$timestamp.zip');

      final dbPath = await DatabaseHelper().getDbPath();
      final dbFile = File(dbPath);
      final sourceBasePath = p.dirname(dbPath);

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
          content: Text(AppLocalizations.of(context)!.databaseExportFailed)));
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

      final dbPath = await dbHelper.getDbPath();
      final dbDirectoryPath = p.dirname(dbPath);

      final prefs = await SharedPreferences.getInstance();
      final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      final customPath = prefs.getString('customDatabasePath');
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
            file.name == 'wispar.db' ? dbDirectoryPath : docsDestinationPath;

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
          'The database was successfully imported to $dbDirectoryPath from ${selectedFile.path}');

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
  void dispose() {
    _cleanupThresholdController.dispose();
    _userAgentController.dispose();
    super.dispose();
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
                      controller: _cleanupThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .cachedArticleRetentionDays,
                        hintText:
                            AppLocalizations.of(context)!.cleanupIntervalHint,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _cleanupThreshold =
                              int.tryParse(value) ?? _cleanupThreshold;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .cleanupIntervalInvalidNumber;
                        }
                        final intValue = int.tryParse(value);
                        if (intValue == null ||
                            intValue < 0 ||
                            intValue > 365) {
                          return AppLocalizations.of(context)!
                              .cleanupIntervalNumberNotBetween;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!
                          .cachedArticleRetentionDaysDesc,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!
                                  .customDatabaseLocation),
                              Text(
                                "(Experimental - Use at your own risk!)",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.red),
                              )
                            ],
                          ),
                        ),
                        Switch(
                            value: _useCustomPath,
                            onChanged: (bool value) async {
                              if (value) {
                                String? pickedBookmark;
                                String? directoryPath;

                                if (Platform.isIOS) {
                                  pickedBookmark = await platform
                                      .invokeMethod('selectCustomDatabasePath');
                                  if (pickedBookmark != null) {
                                    directoryPath = await platform.invokeMethod(
                                        'resolveCustomPath', pickedBookmark);
                                  }
                                } else {
                                  directoryPath = await FilePicker.platform
                                      .getDirectoryPath(
                                    dialogTitle: AppLocalizations.of(context)!
                                        .selectCustomDBLocation,
                                  );
                                }

                                if (directoryPath != null) {
                                  await _moveDatabaseTo(
                                      pickedBookmark ?? directoryPath);
                                } else if (Platform.isIOS) {
                                  logger.info(
                                      "Failed to get persistent access to folder.");
                                }
                              } else {
                                if (_customDatabasePath != null) {
                                  await _moveDatabaseBackToDefault();
                                }

                                setState(() {
                                  _useCustomPath = false;
                                  _customDatabasePath = null;
                                  _customDatabaseBookmark = null;
                                });

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.remove('customDatabasePath');
                                await prefs.remove('customDatabaseBookmark');
                                await prefs.setBool(
                                    'useCustomDatabasePath', false);
                              }
                            }),
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
