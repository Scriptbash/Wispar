import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/crossref_journals_works_models.dart';
import '../screens/article_screen.dart';
import '../screens/journals_details_screen.dart';
import '../services/database_helper.dart';
import '../services/zotero_api.dart';
import '../services/string_format_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum SampleItem {
  itemOne,
  itemTwo,
  itemThree,
}

class PublicationCard extends StatefulWidget {
  final String title;
  final String abstract;
  final String journalTitle;
  final String issn;
  final DateTime? publishedDate;
  final String doi;
  final List<PublicationAuthor> authors;
  final String url;
  final String license;
  final String licenseName;
  final String? dateLiked;
  final VoidCallback? onFavoriteChanged;
  final String? publisher;

  const PublicationCard({
    Key? key,
    required this.title,
    required this.abstract,
    required this.journalTitle,
    required this.issn,
    this.publishedDate,
    required this.doi,
    required List<PublicationAuthor> authors,
    required this.url,
    required this.license,
    required this.licenseName,
    this.dateLiked,
    this.onFavoriteChanged,
    this.publisher,
  })  : authors = authors,
        super(key: key);

  @override
  _PublicationCardState createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;
  SampleItem? selectedMenu;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfLiked();
  }

  @override
  Widget build(BuildContext context) {
    // Skip the card creation if the publication title or authors is empty
    if (widget.title.isEmpty || widget.authors.isEmpty) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to the ArticleScreen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              doi: widget.doi,
              title: widget.title,
              issn: widget.issn,
              abstract: widget.abstract,
              journalTitle: widget.journalTitle,
              publishedDate: widget.publishedDate,
              authors: widget.authors,
              url: widget.url,
              license: widget.license,
              licenseName: widget.licenseName,
              publisher: widget.publisher,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          Map<String, dynamic>? journalInfo =
                              await getJournalDetails(widget.issn);
                          if (journalInfo != null && journalInfo.isNotEmpty) {
                            String journalPublisher = journalInfo['publisher'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalDetailsScreen(
                                  title: widget.journalTitle,
                                  publisher: journalPublisher,
                                  issn: widget.issn,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.journalTitle,
                          style: TextStyle(fontSize: 16),
                          softWrap: true,
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<SampleItem>(
                          onSelected: (SampleItem result) {
                            setState(() {
                              if (result == SampleItem.itemOne) {
                                // Send article to Zotero
                                // Prepare the author names
                                List<Map<String, dynamic>> authorsData = [];
                                for (PublicationAuthor author
                                    in widget.authors) {
                                  authorsData.add({
                                    'creatorType': 'author',
                                    'firstName': author.given,
                                    'lastName': author.family,
                                  });
                                }
                                ZoteroService.sendToZotero(
                                    context,
                                    authorsData,
                                    widget.title,
                                    widget.abstract,
                                    widget.journalTitle,
                                    widget.publishedDate,
                                    widget.doi,
                                    widget.issn);
                              } else if (result == SampleItem.itemTwo) {
                                // Copy DOI
                                Clipboard.setData(
                                    ClipboardData(text: widget.doi));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      AppLocalizations.of(context)!.doicopied),
                                  duration: const Duration(seconds: 1),
                                ));
                              } else if (result == SampleItem.itemThree) {
                                final box =
                                    context.findRenderObject() as RenderBox?;
                                try {
                                  Share.share(
                                    '${widget.title}\n\n${widget.url}\n\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
                                    sharePositionOrigin:
                                        box!.localToGlobal(Offset.zero) &
                                            box.size,
                                  );
                                } catch (e) {
                                  debugPrint('Shared too fast: {$e}');
                                }
                              }
                            });
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<SampleItem>>[
                            PopupMenuItem<SampleItem>(
                                value: SampleItem.itemOne,
                                child: ListTile(
                                    leading: Icon(Icons.book_outlined),
                                    title: Text(AppLocalizations.of(context)!
                                        .sendToZotero))),
                            PopupMenuItem<SampleItem>(
                                value: SampleItem.itemTwo,
                                child: ListTile(
                                  leading: Icon(Icons.copy),
                                  title: Text(
                                      AppLocalizations.of(context)!.copydoi),
                                )),
                            PopupMenuItem<SampleItem>(
                                value: SampleItem.itemThree,
                                child: ListTile(
                                  leading: Icon(Icons.share_outlined),
                                  title: Text(AppLocalizations.of(context)!
                                      .shareArticle),
                                )),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold),
                softWrap: true,
              ),
              Text(
                AppLocalizations.of(context)!
                    .publishedon(widget.publishedDate!),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 5.0),
              Text(
                '${getAuthorsNames(widget.authors)}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8),
              if (widget.abstract.isNotEmpty)
                Text(
                  widget.abstract,
                  maxLines: 10,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16),
                ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            debugPrint(widget.license);
                            if (widget.license.isNotEmpty) {
                              debugPrint(widget.license);
                              launchUrl(Uri.parse(widget.license));
                            }
                          },
                          child: Text(
                            widget.license.isNotEmpty
                                ? (widget.licenseName.isNotEmpty
                                    ? widget.licenseName
                                    : AppLocalizations.of(context)!
                                        .otherLicense)
                                : AppLocalizations.of(context)!.unknownLicense,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () {
                      setState(() {
                        isLiked = !isLiked;
                      });
                      if (isLiked) {
                        databaseHelper.insertArticle(widget, isLiked: true);
                      } else {
                        databaseHelper.removeFavorite(widget.doi);
                      }

                      if (widget.onFavoriteChanged != null) {
                        widget.onFavoriteChanged!();
                      }
                    },
                  ),
                ],
              ),
              if (widget.dateLiked != null)
                Text(
                  AppLocalizations.of(context)!
                      .addedtoyourfav(DateTime.parse(widget.dateLiked!)),
                  style: TextStyle(color: Colors.grey),
                )
            ],
          ),
        ),
      ),
    );
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        isLiked = liked;
      });
    }
  }

  Future<Map<String, dynamic>?> getJournalDetails(String issn) async {
    if (widget.publisher != null) {
      return {'publisher': widget.publisher};
    }
    // If publisher is not passed, fetch from the database
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'journals',
      columns: ['publisher'],
      where: 'issn = ?',
      whereArgs: [issn],
    );

    return rows.isNotEmpty ? rows.first : null;
  }
}
