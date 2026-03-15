import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:wispar/widgets/pdf_control_overlay.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/screens/chat_screen.dart';
import 'dart:math';

class PdfReader extends StatefulWidget {
  final String pdfUrl;
  final PublicationCard publicationCard;

  const PdfReader(
      {super.key, required this.pdfUrl, required this.publicationCard});

  @override
  PdfReaderState createState() => PdfReaderState();
}

class PdfReaderState extends State<PdfReader> {
  final logger = LogsService().logger;
  final controller = PdfViewerController();
  late DatabaseHelper databaseHelper;
  late String resolvedPdfPath = "";
  bool isPathResolved = false;
  bool isDownloaded = false;

  bool _useCustomPath = false;
  String? _customPath;
  bool _hideAI = false;
  bool _darkPdfTheme = false;
  int _pdfOrientation = 0;
  bool _isZoomed = false;
  bool _overlayVisible = true;

  PdfTextSearcher? textSearcher;

  @override
  void dispose() {
    textSearcher?.removeListener(_update);
    textSearcher?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadPreferences().then((_) {
      resolvePdfPath();
    });
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final pdfThemeOption = prefs.getInt('pdfThemeOption') ?? 0;
    final pdfOrientation = prefs.getInt('pdfOrientationOption') ?? 0;

    bool darkTheme;
    if (pdfThemeOption == 0) {
      darkTheme = false;
    } else if (pdfThemeOption == 1) {
      darkTheme = true;
    } else {
      if (!mounted) return;
      final brightness = MediaQuery.of(context).platformBrightness;
      darkTheme = brightness == Brightness.dark;
    }
    setState(() {
      _useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      _customPath = prefs.getString('customDatabasePath');
      _hideAI = prefs.getBool('hide_ai_features') ?? false;
      _darkPdfTheme = darkTheme;
      _pdfOrientation = pdfOrientation;
    });
  }

  void resolvePdfPath() async {
    String basePath;
    if (_useCustomPath && _customPath != null) {
      basePath = _customPath!;
    } else if (Platform.isWindows) {
      final defaultDirectory = await getApplicationSupportDirectory();
      basePath = defaultDirectory.path;
    } else {
      final defaultDirectory = await getApplicationDocumentsDirectory();
      basePath = defaultDirectory.path;
    }
    final pdfFileName = p.basename(widget.pdfUrl);
    final newPdfPath = p.join(basePath, pdfFileName);

    setState(() {
      resolvedPdfPath = newPdfPath;
      isPathResolved = true;
    });

    checkIfDownloaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text(AppLocalizations.of(context)!.articleViewer),
          actions: <Widget>[
            if (!_hideAI)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: AppLocalizations.of(context)!.chatWithPdf,
                onPressed: () async {
                  if (isPathResolved && resolvedPdfPath.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          pdfPath: resolvedPdfPath,
                          publicationCard: widget.publicationCard,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('The PDF is not ready yet'),
                      ),
                    );
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: AppLocalizations.of(context)!.openInExternalPdfViewer,
              onPressed: () async {
                try {
                  OpenFilex.open(resolvedPdfPath);
                } catch (e, stackTrace) {
                  logger.severe(
                      'Unable to open the PDF file in an external app.',
                      e,
                      stackTrace);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .errorOpenExternalPdfApp)));
                }
              },
            ),
            isDownloaded == false
                ? IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: AppLocalizations.of(context)!.download,
                    onPressed: () async {
                      // Otherwise, insert a new article
                      await databaseHelper.insertArticle(
                        widget.publicationCard,
                        isDownloaded: true,
                        pdfPath: p.basename(widget.pdfUrl),
                      );
                      setState(() {
                        isDownloaded = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .downloadSuccessful)));
                    })
                : IconButton(
                    icon: const Icon(Icons.delete_outlined),
                    tooltip: AppLocalizations.of(context)!.delete,
                    onPressed: () async {
                      await databaseHelper.removeDownloaded(
                        widget.publicationCard.doi,
                      );
                      setState(() {
                        isDownloaded = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.downloadDeleted)));
                    },
                  ),
          ]),
      body: SafeArea(
        child: isPathResolved
            ? Stack(children: [
                ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.white,
                        _darkPdfTheme ? BlendMode.difference : BlendMode.dst),
                    child: PdfViewer.file(resolvedPdfPath,
                        controller: controller,
                        params: PdfViewerParams(
                          onViewerReady: (document, controller) {
                            setState(() {
                              textSearcher = PdfTextSearcher(controller)
                                ..addListener(_update);
                            });
                          },
                          pagePaintCallbacks: [
                            if (textSearcher != null)
                              textSearcher!.pageTextMatchPaintCallback,
                          ],
                          layoutPages: _pdfOrientation == 1
                              ? (pages, params) {
                                  final height = pages.fold(
                                          0.0,
                                          (prev, page) =>
                                              max(prev, page.height)) +
                                      params.margin * 2;
                                  final pageLayouts = <Rect>[];
                                  double x = params.margin;
                                  for (var page in pages) {
                                    pageLayouts.add(
                                      Rect.fromLTWH(
                                        x,
                                        (height - page.height) /
                                            2, // center vertically
                                        page.width,
                                        page.height,
                                      ),
                                    );
                                    x += page.width + params.margin;
                                  }
                                  return PdfPageLayout(
                                    pageLayouts: pageLayouts,
                                    documentSize: Size(x, height),
                                  );
                                }
                              : null,
                          maxScale: 8,
                          loadingBannerBuilder:
                              (context, bytesDownloaded, totalBytes) {
                            return Center(
                              child: CircularProgressIndicator(
                                value: totalBytes != null
                                    ? bytesDownloaded / totalBytes
                                    : null,
                                backgroundColor: Colors.grey,
                              ),
                            );
                          },
                          linkHandlerParams: PdfLinkHandlerParams(
                            linkColor: const Color.fromARGB(20, 255, 235, 59),
                            onLinkTap: (link) {
                              if (link.url != null) {
                                launchUrl(link.url!);
                              } else if (link.dest != null) {
                                controller.goToDest(link.dest);
                              }
                            },
                          ),
                          viewerOverlayBuilder:
                              (context, size, handleLinkTap) => [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onDoubleTap: () {
                                setState(() {
                                  if (_isZoomed) {
                                    controller.zoomDown(loop: false);
                                  } else {
                                    controller.zoomUp(loop: false);
                                  }
                                  _isZoomed = !_isZoomed;
                                });
                              },
                              onTapUp: (details) {
                                handleLinkTap(details.localPosition);

                                setState(() {
                                  _overlayVisible = !_overlayVisible;
                                });
                              },
                              child: IgnorePointer(
                                child: SizedBox(
                                    width: size.width, height: size.height),
                              ),
                            ),
                            PdfViewerScrollThumb(
                              controller: controller,
                              orientation: _pdfOrientation == 1
                                  ? ScrollbarOrientation.bottom
                                  : ScrollbarOrientation.right,
                              thumbSize: _pdfOrientation == 1
                                  ? const Size(60, 26)
                                  : const Size(40, 26),
                              thumbBuilder:
                                  (context, thumbSize, pageNumber, controller) {
                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  opacity: _overlayVisible ? 1 : 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      pageNumber.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            PdfControlOverlay(
                              controller: controller,
                              textSearcher: textSearcher,
                              overlayVisible: _overlayVisible,
                            ),
                          ],
                        )))
              ])
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void checkIfDownloaded() async {
    bool downloaded =
        await databaseHelper.isArticleDownloaded(widget.publicationCard.doi);
    setState(() {
      isDownloaded = downloaded;
    });
  }
}
