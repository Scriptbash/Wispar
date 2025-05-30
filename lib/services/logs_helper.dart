import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class LogsService {
  static final LogsService _instance = LogsService._internal();
  factory LogsService() => _instance;

  final Logger _logger = Logger('Wispar');
  final ValueNotifier<List<LogRecord>> logsNotifier = ValueNotifier([]);

  LogsService._internal() {
    _init();
  }

  void _init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      logsNotifier.value = [...logsNotifier.value, record];

      if (kDebugMode) {
        print(
            '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
        if (record.error != null) print('Error: ${record.error}');
        if (record.stackTrace != null)
          print('Stacktrace: ${record.stackTrace}');
      }
    });
  }

  Logger get logger => _logger;

  void clearLogs() {
    logsNotifier.value = [];
  }

  Future<void> saveLogsToFile(BuildContext context) async {
    final logs = LogsService().logsNotifier.value;
    final buffer = StringBuffer();

    try {
      for (var record in logs) {
        buffer.writeln(
            '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
        if (record.error != null) buffer.writeln('Error: ${record.error}');
        if (record.stackTrace != null)
          buffer.writeln('Stacktrace: ${record.stackTrace}');
        buffer.writeln();
      }

      final Uint8List logBytes =
          Uint8List.fromList(buffer.toString().codeUnits);

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.selectLogsLocation,
        fileName: 'wispar_logs.txt',
        bytes: logBytes,
      );

      if (outputPath == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.logsExportedSuccessfully)),
      );
    } catch (e, stackTrace) {
      logger.severe('Error saving logs.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.logsExportedError)),
      );
    }
  }

  Future<void> shareLogs(BuildContext context) async {
    final logs = LogsService().logsNotifier.value;
    final buffer = StringBuffer();

    try {
      for (var record in logs) {
        buffer.writeln(
            '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
        if (record.error != null) buffer.writeln('Error: ${record.error}');
        if (record.stackTrace != null)
          buffer.writeln('Stacktrace: ${record.stackTrace}');
        buffer.writeln();
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/wispar_logs.txt');
      await tempFile.writeAsString(buffer.toString());

      await SharePlus.instance.share(ShareParams(
          files: [XFile(tempFile.path)],
          text: AppLocalizations.of(context)!.logs));

      await tempFile.delete();
    } catch (e, stackTrace) {
      logger.severe('Error sharing logs.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.logsExportedError)),
      );
    }
  }
}
