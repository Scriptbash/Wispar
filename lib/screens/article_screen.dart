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
import 'dart:async';
import 'package:wispar/widgets/translate_sheet.dart';

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
  String? abstract;
  bool isLoadingAbstract = false;
  bool _scrapeAbstracts = true;

  StreamController<String>? _translatedTitleController;
  StreamController<String>? _translatedAbstractController;

  // If a translation was ever done, this will be true
  bool _isTitleTranslated = false;
  bool _isAbstractTranslated = false;

  bool _showTranslatedTitle = false;
  bool _showTranslatedAbstract = false;

  String _accumulatedTranslatedTitle = '';
  String _accumulatedTranslatedAbstract = '';

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadScrapingSettings();
    checkIfLiked();
    abstract = widget.abstract;

    _accumulatedTranslatedTitle = widget.title;
    _accumulatedTranslatedAbstract = abstract ?? widget.abstract;

    _translatedTitleController = StreamController<String>.broadcast();
    _translatedAbstractController = StreamController<String>.broadcast();

    _loadTranslatedContent();
  }

  @override
  void dispose() {
    _translatedTitleController?.close();
    _translatedAbstractController?.close();
    super.dispose();
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
      if (!_isAbstractTranslated && !_showTranslatedAbstract) {
        _accumulatedTranslatedAbstract = finalAbstract;
      }
    });
  }

  Future<void> _loadTranslatedContent() async {
    final translatedContent =
        await databaseHelper.getTranslatedContent(widget.doi);

    bool hasTranslatedTitle = translatedContent['translatedTitle'] != null &&
        translatedContent['translatedTitle']!.isNotEmpty;
    bool hasTranslatedAbstract =
        translatedContent['translatedAbstract'] != null &&
            translatedContent['translatedAbstract']!.isNotEmpty;

    setState(() {
      _isTitleTranslated = hasTranslatedTitle;
      _showTranslatedTitle = hasTranslatedTitle;
      _accumulatedTranslatedTitle = hasTranslatedTitle
          ? translatedContent['translatedTitle']!
          : widget.title;

      _isAbstractTranslated = hasTranslatedAbstract;
      _showTranslatedAbstract = hasTranslatedAbstract;
      _accumulatedTranslatedAbstract = hasTranslatedAbstract
          ? translatedContent['translatedAbstract']!
          : (abstract ?? widget.abstract);
    });

    if (!_translatedTitleController!.isClosed) {
      _translatedTitleController!.add(_accumulatedTranslatedTitle);
    }
    if (!_translatedAbstractController!.isClosed) {
      _translatedAbstractController!.add(_accumulatedTranslatedAbstract);
    }
  }

  void _showTranslateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TranslateOptionsSheet(
        title: widget.title,
        abstractText:
            abstract ?? AppLocalizations.of(context)!.abstractunavailable,
        onTranslateStart: (Stream<String> titleStreamFromProvider,
            Stream<String> abstractStreamFromProvider) {
          if (_translatedTitleController != null &&
              !_translatedTitleController!.isClosed) {
            _translatedTitleController!.close();
          }
          if (_translatedAbstractController != null &&
              !_translatedAbstractController!.isClosed) {
            _translatedAbstractController!.close();
          }

          _translatedTitleController = StreamController<String>.broadcast();
          _translatedAbstractController = StreamController<String>.broadcast();

          setState(() {
            _accumulatedTranslatedTitle = '';
            _accumulatedTranslatedAbstract = '';
            _showTranslatedTitle = true;
            _showTranslatedAbstract = true;
          });

          titleStreamFromProvider.listen(
            (data) {
              if (!mounted) return;
              setState(() {
                _accumulatedTranslatedTitle += data;
              });
            },
            onError: (error) {
              logger.severe('Title Translation Error', error);
            },
            onDone: () {
              databaseHelper.updateTranslatedContent(
                doi: widget.doi,
                translatedTitle: _accumulatedTranslatedTitle,
              );
              setState(() {
                _isTitleTranslated = true;
              });
            },
          );

          abstractStreamFromProvider.listen(
            (data) {
              if (!mounted) return;
              setState(() {
                _accumulatedTranslatedAbstract += data;
              });
            },
            onError: (error) {
              logger.severe('Abstract Translation Error', error);
            },
            onDone: () {
              databaseHelper.updateTranslatedContent(
                doi: widget.doi,
                translatedAbstract: _accumulatedTranslatedAbstract,
              );
              setState(() {
                _isAbstractTranslated = true;
              });
            },
          );
        },
      ),
    );
  }

  void _onCopy(BuildContext context) async {
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
          contentToCopy = _accumulatedTranslatedTitle;
          break;
        case 'abstract':
          contentToCopy = _accumulatedTranslatedAbstract;
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
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showTranslatedTitle
            ? StreamBuilder<String>(
                stream: _translatedTitleController?.stream,
                initialData: _accumulatedTranslatedTitle,
                builder: (context, snapshot) {
                  return LaTexT(
                    breakDelimiter: r'\nl',
                    laTeXCode: Text(
                      _accumulatedTranslatedTitle,
                    ),
                  );
                },
              )
            : LaTexT(breakDelimiter: r'\nl', laTeXCode: Text(widget.title)),
        actions: [
          IconButton(
            onPressed: () => _onCopy(context),
            icon: const Icon(Icons.copy_outlined),
            tooltip: AppLocalizations.of(context)!.copy,
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.share_outlined),
                tooltip: AppLocalizations.of(context)!.shareArticle,
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
              if (_isTitleTranslated || _isAbstractTranslated)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          _showTranslatedTitle = !_showTranslatedTitle;
                          _showTranslatedAbstract = !_showTranslatedAbstract;
                          if (_showTranslatedTitle) {
                            _translatedTitleController!
                                .add(_accumulatedTranslatedTitle);
                          } else {
                            _translatedTitleController!.add(widget.title);
                          }

                          if (_showTranslatedAbstract) {
                            _translatedAbstractController!
                                .add(_accumulatedTranslatedAbstract);
                          } else {
                            _translatedAbstractController!.add(abstract ?? '');
                          }
                        });
                      },
                      child: Text(
                        _showTranslatedTitle || _showTranslatedAbstract
                            ? AppLocalizations.of(context)!.showOriginal
                            : AppLocalizations.of(context)!.showTranslation,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!
                    .publishedon(widget.publishedDate!),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 5),
              _showTranslatedTitle
                  ? StreamBuilder<String>(
                      stream: _translatedTitleController?.stream,
                      initialData: _accumulatedTranslatedTitle,
                      builder: (context, snapshot) {
                        return LaTexT(
                          breakDelimiter: r'\nl',
                          laTeXCode: Text(
                            _accumulatedTranslatedTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        );
                      },
                    )
                  : LaTexT(
                      breakDelimiter: r'\nl',
                      laTeXCode: Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
              SizedBox(height: 5),
              SelectableText(getAuthorsNames(widget.authors),
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              SizedBox(height: 15),
              isLoadingAbstract
                  ? Center(child: CircularProgressIndicator())
                  : _showTranslatedAbstract
                      ? StreamBuilder<String>(
                          stream: _translatedAbstractController?.stream,
                          initialData: _accumulatedTranslatedAbstract,
                          builder: (context, snapshot) {
                            return LaTexT(
                              breakDelimiter: r'\nl',
                              laTeXCode: Text(
                                _accumulatedTranslatedAbstract,
                                textAlign: TextAlign.justify,
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          },
                        )
                      : LaTexT(
                          breakDelimiter: r'\nl',
                          laTeXCode: Text(
                            abstract ??
                                AppLocalizations.of(context)!
                                    .abstractunavailable,
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontSize: 16),
                          ),
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
                    onTap: _showTranslateSheet,
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
                          Icon(Icons.translate_outlined, size: 30),
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
