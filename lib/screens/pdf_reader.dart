import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:math';

class PdfReader extends StatefulWidget {
  final String pdfUrl;
  final bool isDownloadable;

  PdfReader({Key? key, required this.pdfUrl, required this.isDownloadable})
      : super(key: key);

  @override
  _PdfReaderState createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  final controller = PdfViewerController();
  bool bookLayout = false;

  @override
  void dispose() {
    super.dispose();
  }

// MUST RECENTER THE VIEW WHEN SWITCHING BETWEEN LAYOUTS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text("Article viewer"),
          actions: <Widget>[
            IconButton(
              icon: bookLayout
                  ? const Icon(Icons.article_outlined)
                  : const Icon(Icons.menu_book_outlined),
              tooltip:
                  bookLayout ? 'Toggle vertical layout' : 'Toggle book layout',
              onPressed: () {
                setState(() {
                  bookLayout = !bookLayout;
                  controller.relayout();
                });
              },
            ),
            widget.isDownloadable == true
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
        PdfViewer.uri(
          Uri.parse(widget.pdfUrl),
          controller: controller,
          displayParams: PdfViewerParams(
            annotationRenderingMode: PdfAnnotationRenderingMode.annotation,
            enableTextSelection: true,
            maxScale: 2.5,
            viewerOverlayBuilder: (context, size) => [
              // Show vertical scroll with page number
              PdfViewerScrollThumb(
                controller: controller,
                orientation: ScrollbarOrientation.right,
                thumbSize: const Size(13, 40),
                thumbBuilder: (context, thumbSize, pageNumber, controller) =>
                    ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Colors.grey,
                    child: Center(
                      child: Text(
                        pageNumber.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
                Center(
              child: CircularProgressIndicator(
                value: totalBytes != null ? bytesDownloaded / totalBytes : null,
                backgroundColor: Colors.grey,
              ),
            ),
            layoutPages: (pages, params) {
              if (bookLayout) {
                // Book layout
                final double doublePageWidth = params.margin * 2 +
                    pages.fold(
                        0.0, (prev, page) => prev + page.width + params.margin);
                final double singlePageWidth =
                    (doublePageWidth - params.margin) / 2;
                final double doublePageHeight =
                    pages.fold(0.0, (prev, page) => max(prev, page.height)) +
                        params.margin * 2;
                final double singlePageHeight = doublePageHeight;

                final pageLayouts = <Rect>[];
                double x = params.margin;
                for (var page in pages) {
                  pageLayouts.add(
                    Rect.fromLTWH(
                      x,
                      (doublePageHeight - page.height) / 2, // center vertically
                      page.width,
                      page.height,
                    ),
                  );
                  x += page.width + params.margin;
                }

                return PdfPageLayout(
                  pageLayouts: pageLayouts,
                  documentSize: Size(doublePageWidth, doublePageHeight),
                );
              } else {
                final double doublePageHeight = params.margin * 2 +
                    pages.fold(0.0,
                        (prev, page) => prev + page.height + params.margin);
                final double singlePageHeight =
                    (doublePageHeight - params.margin) / 2;
                final double doublePageWidth =
                    pages.fold(0.0, (prev, page) => max(prev, page.width)) +
                        params.margin * 2;
                final double singlePageWidth = doublePageWidth;

                final pageLayouts = <Rect>[];
                double y = params.margin;
                for (var page in pages) {
                  pageLayouts.add(
                    Rect.fromLTWH(
                      (doublePageWidth - page.width) / 2, // center horizontally
                      y,
                      page.width,
                      page.height,
                    ),
                  );
                  y += page.height + params.margin;
                }

                return PdfPageLayout(
                  pageLayouts: pageLayouts,
                  documentSize: Size(doublePageWidth, y),
                );
              }
            },
          ),
        )
      ]),
    );
  }
}
