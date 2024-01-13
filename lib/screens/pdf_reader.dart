import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:internet_file/internet_file.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewer extends StatelessWidget {
  final String pdfUrl;
  final bool isDownloadable;
  late final PdfControllerPinch pdfPinchController;

  PdfViewer({Key? key, required this.pdfUrl, required this.isDownloadable})
      : super(key: key) {
    pdfPinchController = PdfControllerPinch(
      document: PdfDocument.openData(InternetFile.get(pdfUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text("Article viewer"),
          actions: <Widget>[
            isDownloadable == true
                ? IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Download',
                    onPressed: () {},
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outlined),
                    tooltip: 'Delete',
                    onPressed: () {},
                  ),
          ]),
      body: PdfViewPinch(
        controller: pdfPinchController,
        onDocumentError: (error) {
          // temporary "fix" for Elsevier. Would need to catch the redirect
          // and use that redirect link to load the PDF
          launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.inAppBrowserView);
        },
      ),
    );
  }
}
