import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import '../widgets/publication_card.dart';
import '../services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/logs_helper.dart';

class PdfReader extends StatefulWidget {
  final String pdfUrl;
  final PublicationCard publicationCard;

  PdfReader({Key? key, required this.pdfUrl, required this.publicationCard})
      : super(key: key);

  @override
  _PdfReaderState createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  final logger = LogsService().logger;
  final controller = PdfViewerController();
  late DatabaseHelper databaseHelper;
  late String resolvedPdfPath = "";
  bool isPathResolved = false;
  bool isDownloaded = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    resolvePdfPath();
  }

  void resolvePdfPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfFileName = p.basename(widget.pdfUrl);
    final newPdfPath = p.join(directory.path, pdfFileName);

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
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: AppLocalizations.of(context)!.openExternalPdfApp,
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
                PdfViewer.file(resolvedPdfPath,
                    controller: controller,
                    params: PdfViewerParams(
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
                    ))
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
