import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import './logs_helper.dart';

class GraphicalAbstractManager {
  static Future<String> _getDirectoryPath() async {
    final logger = LogsService().logger;
    final dir = await getApplicationDocumentsDirectory();
    final abstractsDir = Directory('${dir.path}/graphical_abstracts');

    if (!await abstractsDir.exists()) {
      await abstractsDir.create(recursive: true);
      logger.info("A folder for the graphical abstracts was created.");
    }

    return abstractsDir.path;
  }

  static String _sanitizeFileName(String doi) {
    return doi.replaceAll(RegExp(r'[^\w\s-]'), '');
  }

  static Future<File?> downloadAndSave(String doi, String imageUrl) async {
    final logger = LogsService().logger;
    try {
      final path = await _getDirectoryPath();
      final fileName = '${_sanitizeFileName(doi)}.jpg';
      final file = File('$path/$fileName');

      if (await file.exists()) {
        return file;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        logger.severe(
            'Failed to download graphical abstract: ${response.statusCode}',
            response.reasonPhrase);
      }
    } catch (e, stackTrace) {
      logger.severe("Error saving graphical abstract", e, stackTrace);
    }
    return null;
  }

  static Future<File?> getLocalFile(String doi) async {
    final path = await _getDirectoryPath();
    final fileName = '${_sanitizeFileName(doi)}.jpg';
    final file = File('$path/$fileName');
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }
}
