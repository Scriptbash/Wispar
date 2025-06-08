import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:wispar/screens/article_website.dart';
import '../models/crossref_journals_works_models.dart';
import '../services/database_helper.dart';
import '../widgets/publication_card.dart';
import './journals_details_screen.dart';
import '../services/zotero_api.dart';
import '../services/string_format_helper.dart';
import '../services/abstract_scraper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latext/latext.dart';
import '../services/logs_helper.dart';
import '../widgets/translate_sheet.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;
  final String title;
  final List<String> issn;
  final String abstract;
  final String journalTitle;
  final DateTime? publishedDate;
  final List<PublicationAuthor> authors;
  final String url;
  final String license;
  final String licenseName;
  final String? publisher;
  final VoidCallback? onAbstractChanged;

  const ArticleScreen({
    Key? key,
    required this.doi,
    required this.title,
    required this.issn,
    required this.abstract,
    required this.journalTitle,
    this.publishedDate,
    required this.authors,
    required this.url,
    required this.license,
    required this.licenseName,
    this.publisher,
    this.onAbstractChanged,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;
  final logger = LogsService().logger;
  String? title;
  String? abstract;
  bool isLoadingAbstract = false;
  bool _scrapeAbstracts = true;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadScrapingSettings();
    checkIfLiked();
    title = widget.title;
    abstract = widget.abstract;
  }

  void _onShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text:
            '${widget.title}\n\n${widget.url}\n\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (e, stackTrace) {
      logger.severe('Sharing failed.', e, stackTrace);
    }
  }

  Future<void> _loadScrapingSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _scrapeAbstracts = prefs.getBool('scrapeAbstracts') ?? true;
    });
    if (_scrapeAbstracts) {
      final missingAbstractText =
          AppLocalizations.of(context)!.abstractunavailable;

      if (abstract == null ||
          abstract!.isEmpty ||
          abstract == missingAbstractText) {
        fetchAbstract();
      }
    }
  }

  Future<void> fetchAbstract() async {
    if (!mounted) return;
    setState(() {
      isLoadingAbstract = true;
    });

    //debugPrint("Calling scraper for: ${widget.url}");

    AbstractScraper scraper = AbstractScraper();
    String? scraped;
    try {
      scraped = await scraper.scrapeAbstract(widget.url);
    } catch (e) {
      scraped = '';
    }
    String finalAbstract = '';
    if (scraped != null && scraped.isNotEmpty) {
      finalAbstract = scraped;
      try {
        bool isArticleInDb = await databaseHelper.checkIfDoiExists(widget.doi);
        if (isArticleInDb) {
          databaseHelper.updateArticleAbstract(widget.doi, finalAbstract);
          widget.onAbstractChanged!();
        } else {
          logger.warning(
              'Unable to update the abstract for DOI ${widget.doi}. The article is not in the database.');
        }
      } catch (e, stackTrace) {
        logger.severe(
            'An error occured while updating the abstract for DOI ${widget.doi}.',
            e,
            stackTrace);
      }
    } else {
      finalAbstract = AppLocalizations.of(context)!.abstractunavailable;
    }
    if (!mounted) return;
    setState(() {
      abstract = finalAbstract;
      isLoadingAbstract = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LaTexT(
            breakDelimiter: r'\nl', laTeXCode: (Text(title ?? widget.title))),
        actions: [
          IconButton(
              icon: Icon(Icons.copy_outlined),
              tooltip: AppLocalizations.of(context)!.copydoi,
              onPressed: () async {
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (BuildContext context) {
                    return Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.short_text),
                          title: Text(AppLocalizations.of(context)!.copyTitle),
                          onTap: () => Navigator.pop(context, 'title'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.article),
                          title:
                              Text(AppLocalizations.of(context)!.copyAbstract),
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
                    );
                  },
                );

                if (choice != null) {
                  String contentToCopy = '';
                  switch (choice) {
                    case 'title':
                      contentToCopy = title ?? widget.title;
                      break;
                    case 'abstract':
                      contentToCopy = abstract ?? '';
                      break;
                    case 'doi':
                      contentToCopy = widget.doi;
                      break;
                    case 'url':
                      contentToCopy = widget.url;
                      break;
                  }

                  await Clipboard.setData(ClipboardData(text: contentToCopy));

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.copiedToClipboard),
                    duration: const Duration(seconds: 1),
                  ));
                }
              }),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () => _onShare(context),
                icon: Icon(Icons.share_outlined),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .publishedon(widget.publishedDate!),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 5),
              LaTexT(
                  breakDelimiter: r'\nl',
                  laTeXCode: Text(
                    title ?? widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )),
              SizedBox(height: 5),
              SelectableText(getAuthorsNames(widget.authors),
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              SizedBox(height: 15),
              isLoadingAbstract
                  ? Center(child: CircularProgressIndicator())
                  : abstract != null && abstract!.isNotEmpty
                      ? LaTexT(
                          breakDelimiter: r'\nl',
                          laTeXCode: Text(
                            abstract!,
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.abstractunavailable,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 16),
                        ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DOI: ${widget.doi}',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              String journalPublisher = "";
                              Map<String, dynamic>? journalInfo;

                              journalInfo =
                                  await getJournalDetails(widget.issn);

                              if (widget.publisher == null) {
                                debugPrint("publisher is null");
                                if (journalInfo != null &&
                                    journalInfo['publisher'] != null) {
                                  journalPublisher = journalInfo['publisher'];
                                } else {
                                  journalPublisher = widget.publisher ?? "";
                                }

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
                            child: widget.journalTitle.isNotEmpty
                                ? Text(
                                    '${AppLocalizations.of(context)!.publishedin} ${widget.journalTitle}',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : SizedBox(),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                    onPressed: () async {
                      setState(() {
                        isLiked = !isLiked;
                      });

                      if (isLiked) {
                        await databaseHelper.insertArticle(
                          PublicationCard(
                            title: widget.title,
                            abstract: widget.abstract,
                            journalTitle: widget.journalTitle,
                            issn: widget.issn,
                            publishedDate: widget.publishedDate,
                            doi: widget.doi,
                            authors: widget.authors,
                            url: widget.url,
                            license: widget.license,
                            licenseName: widget.licenseName,
                            publisher: widget.publisher,
                          ),
                          isLiked: true,
                        );
                      } else {
                        await databaseHelper.removeFavorite(widget.doi);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isLiked
                            ? '${widget.title} ${AppLocalizations.of(context)!.favoriteadded}'
                            : '${widget.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<Map<String, String?>>(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => TranslateOptionsSheet(
                          title: widget.title,
                          abstractText: abstract ?? '',
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          if (result['title'] != null) {
                            title = result['title'];
                          }
                          if (result['abstract'] != null) {
                            abstract = result['abstract'];
                          }
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.translate,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleWebsite(
                            publicationCard: PublicationCard(
                              doi: widget.doi,
                              title: widget.title,
                              authors: widget.authors,
                              publishedDate: widget.publishedDate,
                              journalTitle: widget.journalTitle,
                              issn: widget.issn,
                              url: widget.url,
                              license: widget.license,
                              licenseName: widget.licenseName,
                              abstract: widget.abstract,
                              publisher: widget.publisher,
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.viewarticle,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      List<Map<String, dynamic>> authorsData = [];
                      for (PublicationAuthor author in widget.authors) {
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
                        widget.issn,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.sendToZotero,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    setState(() {
      isLiked = liked;
    });
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
