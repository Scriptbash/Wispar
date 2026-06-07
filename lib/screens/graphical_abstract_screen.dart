import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/logs_helper.dart';

class ImageScreen extends StatelessWidget {
  final File imageFile;
  final String imagePath;
  final String title;

  const ImageScreen(
      {super.key,
      required this.imageFile,
      required this.imagePath,
      required this.title});

  @override
  Widget build(BuildContext context) {
    final logger = LogsService().logger;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: AppLocalizations.of(context)!.openExternalApp,
            onPressed: () async {
              try {
                OpenFile.open(imagePath);
              } catch (e, stackTrace) {
                logger.severe(
                    'Unable to open the graphical abstract image in an external app.',
                    e,
                    stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .errorOpenExternalPdfApp)));
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.1,
        maxScale: 4.0,
        child: Align(
          alignment: Alignment.center,
          child: Image.file(
            imageFile,
          ),
        ),
      ),
    );
  }
}
