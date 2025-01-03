import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import '../widgets/publication_card.dart';
import '../services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfReader extends StatefulWidget {
  final String pdfUrl;
  final PublicationCard publicationCard;

  PdfReader({Key? key, required this.pdfUrl, required this.publicationCard})
      : super(key: key);

  @override
  _PdfReaderState createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  final controller = PdfViewerController();
  late DatabaseHelper databaseHelper;
  bool isDownloaded = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfDownloaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text(AppLocalizations.of(context)!.articleViewer),
          actions: <Widget>[
            isDownloaded == false
                ? IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: AppLocalizations.of(context)!.download,
                    onPressed: () async {
                      // Otherwise, insert a new article
                      await databaseHelper.insertArticle(
                        widget.publicationCard,
                        isDownloaded: true,
                        pdfPath: widget.pdfUrl,
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
      body: Stack(children: [
        PdfViewer.file(widget.pdfUrl,
            controller: controller,
            params: PdfViewerParams(
              enableTextSelection: false, // This is not ready yet.
              maxScale: 8,
              loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                return Center(
                  child: CircularProgressIndicator(
                    // totalBytes may not be available on certain case
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
                  // handle URL or Dest
                  if (link.url != null) {
                    launchUrl(link.url!);
                  } else if (link.dest != null) {
                    controller.goToDest(link.dest);
                  }
                },
              ),
            ))
      ]),
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
