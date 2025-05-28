import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/logs_helper.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<LogRecord> logs = LogsService().getLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.primary),
            tooltip: 'Delete logs',
            onPressed: () {
              LogsService().clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs deleted')),
              );
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No logs available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
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
