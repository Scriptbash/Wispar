import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class PdfReader extends StatefulWidget {
  final String pdfUrl;

  PdfReader({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PdfReaderState createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  final controller = PdfViewerController();
  final isDownloadable = true;

  @override
  void dispose() {
    super.dispose();
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
      body: Stack(children: [
        PdfViewer.file(widget.pdfUrl,
            controller: controller,
            params: PdfViewerParams(
              enableTextSelection: false, // This is not ready yet.
              maxScale: 2.5,
              layoutPages: (pages, params) {
                final width =
                    pages.fold(0.0, (prev, page) => max(prev, page.width));
                final pageLayouts = <Rect>[];
                double y = params.margin;
                for (final page in pages) {
                  final height = page.height * (width / page.width);
                  pageLayouts.add(
                    Rect.fromLTWH(
                      params.margin,
                      y,
                      width,
                      height,
                    ),
                  );
                  y += height + params.margin;
                }
                return PdfPageLayout(
                  pageLayouts: pageLayouts,
                  documentSize: Size(width + params.margin * 2, y),
                );
              },
              /*linkWidgetBuilder: (context, link, size) => Material(
                color: Colors.blue.withOpacity(0.0),
                child: InkWell(
                  onTap: () async {
                    if (link.url != null) {
                      launchUrl(link.url!);
                    } else if (link.dest != null) {
                      controller.goToDest(link.dest);
                    }
                  },
                  hoverColor: Colors.blue.withOpacity(0.0),
                ),
              ),*/
            ))
      ]),
    );
  }
}
