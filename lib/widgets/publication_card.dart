import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../generated_l10n/app_localizations.dart';
import '../models/crossref_journals_works_models.dart';
import '../screens/article_screen.dart';
import '../screens/journals_details_screen.dart';
import '../services/database_helper.dart';
import '../services/zotero_api.dart';
import '../services/string_format_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latext/latext.dart';

enum SampleItem { itemOne, itemTwo, itemThree, itemFour }

class PublicationCard extends StatefulWidget {
  final String title;
  final String abstract;
  final String journalTitle;
  final List<String> issn;
  final DateTime? publishedDate;
  final String doi;
  final List<PublicationAuthor> authors;
  final String url;
  final String license;
  final String licenseName;
  final String? dateLiked;
  final VoidCallback? onFavoriteChanged;
  final VoidCallback? onAbstractChanged;
  final String? publisher;
  final bool? showHideBtn;
  final bool? isHidden;
  final VoidCallback? onHide;

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
    this.onAbstractChanged,
    this.publisher,
    this.showHideBtn,
    this.isHidden,
    this.onHide,
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

    return Slidable(
      key: Key(widget.doi),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.7,
        children: [
          CustomSlidableAction(
            onPressed: (_) async {
              List<Map<String, dynamic>> authorsData = widget.authors
                  .map((author) => {
                        'creatorType': 'author',
                        'firstName': author.given,
                        'lastName': author.family,
                      })
                  .toList();

              ZoteroService.sendToZotero(
                context,
                authorsData,
                widget.title,
                widget.abstract,
                widget.journalTitle,
                widget.publishedDate,
                widget.doi,
                widget.issn,
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 26),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.sendToZotero,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ),
          ),
          if (widget.showHideBtn == true)
            CustomSlidableAction(
              onPressed: (_) async {
                if (widget.isHidden == true) {
                  await databaseHelper.unhideArticle(widget.doi);
                } else {
                  await databaseHelper.hideArticle(widget.doi);
                }
                widget.onHide?.call();
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isHidden == true
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isHidden == true
                        ? AppLocalizations.of(context)!.unhideArticle
                        : AppLocalizations.of(context)!.hideArticle,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ],
              ),
            ),
        ],
      ),
      child: GestureDetector(
        onTap: () async {
          String finalAbstract = widget.abstract;

          if (widget.abstract.isEmpty) {
            final dbAbstract = await databaseHelper.getAbstract(widget.doi);
            if (dbAbstract != null && dbAbstract.isNotEmpty) {
              finalAbstract = dbAbstract;
            }
          }
          // Navigate to the ArticleScreen when the card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleScreen(
                doi: widget.doi,
                title: widget.title,
                issn: widget.issn,
                abstract: finalAbstract,
                journalTitle: widget.journalTitle,
                publishedDate: widget.publishedDate,
                authors: widget.authors,
                url: widget.url,
                license: widget.license,
                licenseName: widget.licenseName,
                publisher: widget.publisher,
                onAbstractChanged: () {
                  widget.onAbstractChanged!();
                },
              ),
            ),
          );
        },
        child: Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
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
                              String journalPublisher =
                                  journalInfo['publisher'] ??
                                      'Unknown Publisher';
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
                            style: const TextStyle(fontSize: 16),
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
                            onSelected: (SampleItem result) async {
                              if (result == SampleItem.itemOne) {
                                List<Map<String, dynamic>> authorsData =
                                    widget.authors
                                        .map((author) => {
                                              'creatorType': 'author',
                                              'firstName': author.given,
                                              'lastName': author.family,
                                            })
                                        .toList();

                                ZoteroService.sendToZotero(
                                  context,
                                  authorsData,
                                  widget.title,
                                  widget.abstract,
                                  widget.journalTitle,
                                  widget.publishedDate,
                                  widget.doi,
                                  widget.issn,
                                );
                              } else if (result == SampleItem.itemTwo) {
                                _showCopyOptions();
                              } else if (result == SampleItem.itemThree) {
                                final box =
                                    context.findRenderObject() as RenderBox?;
                                SharePlus.instance.share(ShareParams(
                                  text:
                                      '${widget.title}\n\n${widget.url}\n\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
                                  sharePositionOrigin:
                                      box!.localToGlobal(Offset.zero) &
                                          box.size,
                                ));
                              } else if (result == SampleItem.itemFour) {
                                await databaseHelper.hideArticle(widget.doi);
                                widget.onHide?.call();
                              }
                            },
                            itemBuilder: (context) =>
                                <PopupMenuEntry<SampleItem>>[
                              PopupMenuItem<SampleItem>(
                                value: SampleItem.itemOne,
                                child: ListTile(
                                  leading: const Icon(Icons.book_outlined),
                                  title: Text(AppLocalizations.of(context)!
                                      .sendToZotero),
                                ),
                              ),
                              PopupMenuItem<SampleItem>(
                                value: SampleItem.itemTwo,
                                child: ListTile(
                                  leading: const Icon(Icons.copy),
                                  title:
                                      Text(AppLocalizations.of(context)!.copy),
                                ),
                              ),
                              PopupMenuItem<SampleItem>(
                                value: SampleItem.itemThree,
                                child: ListTile(
                                  leading: const Icon(Icons.share_outlined),
                                  title: Text(AppLocalizations.of(context)!
                                      .shareArticle),
                                ),
                              ),
                              if (widget.showHideBtn == true)
                                PopupMenuItem<SampleItem>(
                                  value: SampleItem.itemFour,
                                  child: ListTile(
                                    leading: widget.isHidden == true
                                        ? const Icon(Icons.visibility_outlined)
                                        : const Icon(
                                            Icons.visibility_off_outlined),
                                    title: Text(
                                      widget.isHidden == true
                                          ? AppLocalizations.of(context)!
                                              .unhideArticle
                                          : AppLocalizations.of(context)!
                                              .hideArticle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context)!
                      .publishedon(widget.publishedDate!),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                LaTexT(
                    breakDelimiter: r'\nl',
                    laTeXCode: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      softWrap: true,
                    )),
                Text(
                  '${getAuthorsNames(widget.authors)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                if (widget.abstract.isNotEmpty)
                  LaTexT(
                    breakDelimiter: r'\nl',
                    laTeXCode: Text(
                      widget.abstract,
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (widget.license.isNotEmpty) {
                            launchUrl(Uri.parse(widget.license));
                          }
                        },
                        child: Text(
                          widget.licenseName.isNotEmpty
                              ? widget.licenseName
                              : (widget.license.isNotEmpty
                                  ? AppLocalizations.of(context)!.otherLicense
                                  : AppLocalizations.of(context)!
                                      .unknownLicense),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
                        widget.onFavoriteChanged?.call();
                      },
                    ),
                  ],
                ),
                if (widget.dateLiked != null)
                  Text(
                    AppLocalizations.of(context)!
                        .addedtoyourfav(DateTime.parse(widget.dateLiked!)),
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCopyOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.short_text),
                title: Text(AppLocalizations.of(context)!.copyTitle),
                onTap: () => Navigator.pop(context, 'title'),
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: Text(AppLocalizations.of(context)!.copyAbstract),
                onTap: () => Navigator.pop(context, 'abstract'),
              ),
              ListTile(
                leading: const Icon(Icons.numbers),
                title: Text(AppLocalizations.of(context)!.copydoi),
                onTap: () => Navigator.pop(context, 'doi'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(AppLocalizations.of(context)!.copyUrl),
                onTap: () => Navigator.pop(context, 'url'),
              ),
            ],
          ),
        );
      },
    );

    if (choice != null) {
      String contentToCopy = '';
      switch (choice) {
        case 'title':
          contentToCopy = widget.title;
          break;
        case 'abstract':
          contentToCopy = widget.abstract;
          break;
        case 'doi':
          contentToCopy = widget.doi;
          break;
        case 'url':
          contentToCopy = widget.url;
          break;
      }

      await Clipboard.setData(ClipboardData(text: contentToCopy));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    if (mounted) {
      setState(() {
        isLiked = liked;
      });
    }
  }

  Future<Map<String, dynamic>?> getJournalDetails(List<String> issn) async {
    if (widget.publisher != null) {
      return {'publisher': widget.publisher};
    }
    // If publisher is not passed, fetch from the database
    final db = await databaseHelper.database;
    final id = await databaseHelper.getJournalIdByIssns(issn);
    final List<Map<String, dynamic>> rows = await db.query(
      'journals',
      columns: ['publisher'],
      where: 'journal_id = ?',
      whereArgs: [id],
    );

    return rows.isNotEmpty ? rows.first : null;
  }
}
