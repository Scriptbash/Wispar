import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

class LogsService {
  static final LogsService _instance = LogsService._internal();
  factory LogsService() => _instance;

  final Logger _logger = Logger('Wispar');
  final List<LogRecord> _logRecords = [];

  LogsService._internal() {
    _init();
  }

  void _init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logRecords.add(record);

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

  List<LogRecord> getLogs() => List.unmodifiable(_logRecords);

  void clearLogs() => _logRecords.clear();
}
