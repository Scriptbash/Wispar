import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wispar/screens/article_website.dart';
import '../models/crossref_journals_works_models.dart';
import '../services/database_helper.dart';
import '../widgets/publication_card.dart';
import './journals_details_screen.dart';
import '../services/zotero_api.dart';
import '../services/string_format_helper.dart';
import '../services/abstract_scraper.dart';
import 'package:share_plus/share_plus.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;
  final String title;
  final String issn;
  final String abstract;
  final String journalTitle;
  final DateTime? publishedDate;
  final List<PublicationAuthor> authors;
  final String url;
  final String license;
  final String licenseName;
  final String? publisher;

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
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;
  String? abstract;
  bool isLoadingAbstract = false;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfLiked();
    abstract = widget.abstract;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final missingAbstractText =
        AppLocalizations.of(context)!.abstractunavailable;

    if (abstract == null ||
        abstract!.isEmpty ||
        abstract == missingAbstractText) {
      fetchAbstract();
    }
  }

  void _onShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share(
        '${widget.title}\n\n${widget.url}\n\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint('Shared too fast: {$e}');
    }
  }

  Future<void> fetchAbstract() async {
    setState(() {
      isLoadingAbstract = true;
    });

    debugPrint("Calling scraper for: ${widget.url}");

    AbstractScraper scraper = AbstractScraper();
    String? scraped = await scraper.scrapeAbstract(widget.url);
    String finalAbstract = '';
    if (scraped != null && scraped.isNotEmpty) {
      finalAbstract = scraped;
      try {
        databaseHelper.updateArticleAbstract(widget.doi, finalAbstract);
      } catch (e) {
        debugPrint("Unable to update the abstract: ${e}");
      }
    } else {
      finalAbstract = AppLocalizations.of(context)!.abstractunavailable;
    }

    setState(() {
      abstract = finalAbstract;
      isLoadingAbstract = false;
    });
    debugPrint("Final Abstract: $abstract");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                  onPressed: () => _onShare(context),
                  icon: Icon(Icons.share_outlined));
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
              SelectableText(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 5),
              SelectableText(getAuthorsNames(widget.authors),
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              SizedBox(height: 15),
              isLoadingAbstract
                  ? Center(child: CircularProgressIndicator())
                  : abstract != null && abstract!.isNotEmpty
                      ? SelectableText(
                          abstract!,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 16),
                        )
                      : Text(AppLocalizations.of(context)!.abstractunavailable),

              /*SelectableText(
                widget.abstract.isNotEmpty
                    ? widget.abstract
                    : AppLocalizations.of(context)!.abstractunavailable,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16),
              ),*/
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
                              Map<String, dynamic>? journalInfo =
                                  await getJournalDetails(widget.issn);
                              if (journalInfo != null) {
                                String journalPublisher =
                                    journalInfo['publisher'];

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
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.doi));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!.doicopied),
                        duration: const Duration(seconds: 1),
                      ));
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
                          Icon(Icons.copy_outlined, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.copydoi,
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
