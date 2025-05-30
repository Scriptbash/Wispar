import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import '../services/logs_helper.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logs),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.download,
                color: Theme.of(context).colorScheme.primary),
            tooltip: AppLocalizations.of(context)!.saveLogs,
            onPressed: () async {
              await LogsService().saveLogsToFile(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete,
                color: Theme.of(context).colorScheme.primary),
            tooltip: AppLocalizations.of(context)!.deleteLogs,
            onPressed: () {
              LogsService().clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.logsDeleted),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogRecord>>(
        valueListenable: LogsService().logsNotifier,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!.logsUnavailable));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return GestureDetector(
                onLongPress: () {
                  final content =
                      '[${log.level.name}] ${log.time.toLocal()} — ${log.message}'
                      '${log.error != null ? '\nError: ${log.error}' : ''}'
                      '${log.stackTrace != null ? '\nStack trace:\n${log.stackTrace}' : ''}';
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!.logCopied)),
                  );
                },
                child: Card(
                  color: _logColor(log.level),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${log.level.name}] ${log.time.toLocal()} — ${log.message}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (log.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Error: ${log.error}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (log.stackTrace != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Stack trace:\n${log.stackTrace}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _logColor(Level level) {
    if (level >= Level.SEVERE) return Colors.red.shade100;
    if (level >= Level.WARNING) return Colors.orange.shade100;
    if (level >= Level.INFO) return Colors.blue.shade50;
    return Colors.grey.shade100;
  }
}
