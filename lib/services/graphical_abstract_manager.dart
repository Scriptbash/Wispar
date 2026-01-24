import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import './logs_helper.dart';

class GraphicalAbstractManager {
  static Future<String> _getDirectoryPath() async {
    final logger = LogsService().logger;
    final prefs = await SharedPreferences.getInstance();

    final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
    final customPath = prefs.getString('customDatabasePath');

    String basePath;

    if (useCustomPath && customPath != null) {
      basePath = customPath;
    } else if (Platform.isWindows) {
      final dir = await getApplicationSupportDirectory();
      basePath = dir.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      basePath = dir.path;
    }

    final abstractsDir = Directory(p.join(basePath, 'graphical_abstracts'));

    if (!await abstractsDir.exists()) {
      await abstractsDir.create(recursive: true);
      logger.info(
          "A folder for the graphical abstracts was created at: ${abstractsDir.path}");
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
      final file = File(p.join(path, fileName));

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
    final file = File(p.join(path, fileName));
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }
}
