import 'package:flutter/material.dart';
import 'dart:io';

class ImageScreen extends StatelessWidget {
  final File imageFile;
  final String title;

  const ImageScreen({super.key, required this.imageFile, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
