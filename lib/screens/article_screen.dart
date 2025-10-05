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
import '../services/graphical_abstract_manager.dart';
import '../screens/graphical_abstract_screen.dart';
import 'dart:io';

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
  final String? graphicalAbstractUrl;

  const ArticleScreen({
    super.key,
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
    this.graphicalAbstractUrl,
  });

  @override
  ArticleScreenState createState() => ArticleScreenState();
}

class ArticleScreenState extends State<ArticleScreen> {
  bool isLiked = false;
  bool _hideAI = false;
  late DatabaseHelper databaseHelper;
  final logger = LogsService().logger;
  String? abstract;
  bool isLoadingAbstract = false;
  bool _scrapeAbstracts = true;
  File? graphicalAbstract;
  bool isFetchingGraphicalAbstract = false;

  StreamController<String>? _translatedTitleController;
  StreamController<String>? _translatedAbstractController;

  // If a translation was ever done, this will be true
  bool _isTitleTranslated = false;
  bool _isAbstractTranslated = false;

  bool _showTranslatedTitle = false;
  bool _showTranslatedAbstract = false;

  String _accumulatedTranslatedTitle = '';
  String _accumulatedTranslatedAbstract = '';

  late ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    // scrollController used for switching font color in app bar to avoid
    // having white text on white background
    _scrollController = ScrollController()
      ..addListener(() {
        bool isCollapsed = _scrollController.hasClients &&
            _scrollController.offset > (320 - kToolbarHeight);
        if (isCollapsed != _isCollapsed) {
          setState(() {
            _isCollapsed = isCollapsed;
          });
        }
      });
    databaseHelper = DatabaseHelper();
    _loadScrapingSettings();
    _loadHideAIPreference();
    _loadGraphicalAbstract();
    checkIfLiked();
    if (widget.abstract.isEmpty) {
      abstract = null;
    } else {
      abstract = widget.abstract;
    }

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

  Future<void> _loadHideAIPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideAI = prefs.getBool('hide_ai_features') ?? false;
    });
  }

  void _onShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text:
            '${_showTranslatedTitle ? _accumulatedTranslatedTitle : widget.title}\n\n${widget.url}\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
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
    if (!mounted) return;

    if (_scrapeAbstracts) {
      final missingAbstractText =
          AppLocalizations.of(context)!.abstractunavailable;

      // Check if the text abstract is missing
      final bool isTextAbstractMissing = abstract == null ||
          abstract!.isEmpty ||
          abstract == missingAbstractText;
      // Check if the gtraphical abstract is missing
      final bool isGraphicalAbstractMissingInDB =
          widget.graphicalAbstractUrl == null;

      // If either is missing launch the scraper
      if (isTextAbstractMissing || isGraphicalAbstractMissingInDB) {
        fetchAbstract(scrapeTextAbstract: isTextAbstractMissing);
      }
    }
  }

  Future<void> fetchAbstract({bool scrapeTextAbstract = true}) async {
    if (!mounted) return;

    final bool shouldScrapeGraphicalAbstract =
        _scrapeAbstracts && graphicalAbstract == null;

    if (scrapeTextAbstract) {
      setState(() => isLoadingAbstract = true);
    }
    if (shouldScrapeGraphicalAbstract) {
      setState(() => isFetchingGraphicalAbstract = true);
    }

    AbstractScraper scraper = AbstractScraper();
    Map<String, String?>? scraped;
    try {
      scraped = await scraper.scrapeAbstractAndGraphical(
        widget.url,
        textAbstract: scrapeTextAbstract,
        graphicalAbstract: shouldScrapeGraphicalAbstract,
      );
    } catch (e) {
      logger.warning(
          'Failed to scrape abstract/graphical from ${widget.url}: $e');
      scraped = {};
    }

    // Text abstract handling
    if (!mounted) return;
    String finalAbstract =
        abstract ?? AppLocalizations.of(context)!.abstractunavailable;
    bool abstractUpdated = false;
    if (scrapeTextAbstract && scraped['abstract']?.isNotEmpty == true) {
      finalAbstract = scraped['abstract']!;
      abstractUpdated = true;
      try {
        if (await databaseHelper.checkIfDoiExists(widget.doi)) {
          databaseHelper.updateArticleAbstract(widget.doi, finalAbstract);
          widget.onAbstractChanged?.call();
        }
      } catch (e, st) {
        logger.severe('Error updating abstract for ${widget.doi}', e, st);
      }
    }

    // Graphical abstract handling
    if (shouldScrapeGraphicalAbstract && scraped['graphicalUrl'] != null) {
      File? file = await GraphicalAbstractManager.downloadAndSave(
        widget.doi,
        scraped['graphicalUrl']!,
      );
      if (file != null && mounted) {
        setState(() => graphicalAbstract = file);
        try {
          databaseHelper.updateGraphicalAbstractPath(widget.doi, file);
          widget.onAbstractChanged?.call();
        } catch (e) {
          logger.severe('Failed to update GA path in DB for ${widget.doi}', e);
        }
      }
    }

    if (!mounted) return;

    setState(() {
      abstract = abstractUpdated
          ? finalAbstract
          : (abstract ?? AppLocalizations.of(context)!.abstractunavailable);
      isLoadingAbstract = false;
      isFetchingGraphicalAbstract = false;
      _translatedAbstractController!.add(abstract!);
    });
  }

  Future<void> _loadGraphicalAbstract() async {
    if (widget.graphicalAbstractUrl != null) {
      if (mounted) {
        setState(() {
          isFetchingGraphicalAbstract = true;
        });
      }

      File? file = await GraphicalAbstractManager.getLocalFile(widget.doi);
      file ??= await GraphicalAbstractManager.downloadAndSave(
        widget.doi,
        widget.graphicalAbstractUrl!,
      );
      if (file != null && mounted) {
        setState(() => graphicalAbstract = file);
      }

      if (mounted) {
        setState(() {
          isFetchingGraphicalAbstract = false;
        });
      }
    }
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
      _accumulatedTranslatedTitle = hasTranslatedTitle
          ? translatedContent['translatedTitle']!
          : widget.title;

      _isAbstractTranslated = hasTranslatedAbstract;
      _accumulatedTranslatedAbstract = hasTranslatedAbstract
          ? translatedContent['translatedAbstract']!
          : (abstract ?? widget.abstract);
      _showTranslatedTitle = false;
      _showTranslatedAbstract = false;
    });

    if (!_translatedTitleController!.isClosed) {
      _translatedTitleController!.add(widget.title);
    }
    if (!_translatedAbstractController!.isClosed) {
      _translatedAbstractController!.add(abstract ?? widget.abstract);
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
          _translatedTitleController?.close();
          _translatedAbstractController?.close();
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
                _translatedTitleController!.add(_accumulatedTranslatedTitle);
              });
            },
            onError: (error) {
              logger.severe('Title Translation Error', error);
              if (mounted) {
                setState(() {
                  _showTranslatedTitle = false;
                  _translatedTitleController!.add(widget.title);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.translationFailed)),
                );
              }
            },
            onDone: () {
              databaseHelper.updateTranslatedContent(
                doi: widget.doi,
                translatedTitle: _accumulatedTranslatedTitle,
              );
              if (!mounted) return;
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
                _translatedAbstractController!
                    .add(_accumulatedTranslatedAbstract);
              });
            },
            onError: (error) {
              logger.severe('Abstract Translation Error', error);
              if (mounted) {
                setState(() {
                  _showTranslatedAbstract = false;
                  _translatedAbstractController!
                      .add(abstract ?? widget.abstract);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.translationFailed)),
                );
              }
            },
            onDone: () {
              databaseHelper.updateTranslatedContent(
                doi: widget.doi,
                translatedAbstract: _accumulatedTranslatedAbstract,
              );
              if (!mounted) return;
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
          contentToCopy =
              _showTranslatedTitle ? _accumulatedTranslatedTitle : widget.title;
          break;
        case 'abstract':
          contentToCopy = _showTranslatedAbstract
              ? _accumulatedTranslatedAbstract
              : (abstract ?? widget.abstract);
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
    final bool hasBannerContent =
        graphicalAbstract != null || widget.graphicalAbstractUrl != null;
    // Style for the text that goes over the banner image
    final TextStyle onImageTitleStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white);

    void onBannerTap() {
      if (graphicalAbstract != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageScreen(
                imageFile: graphicalAbstract!,
                imagePath: graphicalAbstract!.path,
                title: AppLocalizations.of(context)!.graphicalAbstract),
          ),
        );
      }
    }

    return Scaffold(
      // -- APPBAR --
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            foregroundColor: _isCollapsed
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white,
            iconTheme: IconThemeData(
              color: _isCollapsed
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
            ),
            actionsIconTheme: IconThemeData(
              color: _isCollapsed
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
            ),
            title: _isCollapsed
                ? (_showTranslatedTitle
                    ? StreamBuilder<String>(
                        stream: _translatedTitleController?.stream,
                        initialData: _accumulatedTranslatedTitle,
                        builder: (context, snapshot) {
                          return LaTexT(
                            breakDelimiter: r'\nl',
                            laTeXCode: Text(
                              snapshot.data!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      )
                    : LaTexT(
                        breakDelimiter: r'\nl',
                        laTeXCode: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                : null,
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

            // -- BANNER, TITLE AND PUB. DATE --
            flexibleSpace: FlexibleSpaceBar(
              title: null,
              background: GestureDetector(
                onTap: onBannerTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (graphicalAbstract != null)
                      Image.file(
                        graphicalAbstract!,
                        fit: BoxFit.cover,
                        color: Colors.black.withAlpha(138),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) {
                          logger.severe(
                              "Error displaying the graphical abstract",
                              error,
                              stackTrace);
                          return Container(
                            color: Colors.deepPurple,
                            alignment: Alignment.center,
                          );
                        },
                      )
                    else if (widget.graphicalAbstractUrl != null)
                      const Center(child: LinearProgressIndicator())
                    else
                      Container(
                        color: Colors.deepPurple,
                        alignment: Alignment.center,
                      ),
                    if (isFetchingGraphicalAbstract)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.black,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: hasBannerContent
                              ? LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withAlpha(204),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 1.0],
                                )
                              : null,
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
                        child: IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Published Date
                              if (widget.publishedDate != null)
                                Text(
                                  AppLocalizations.of(context)!
                                      .publishedon(widget.publishedDate!),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              // Title
                              _showTranslatedTitle
                                  ? StreamBuilder<String>(
                                      stream:
                                          _translatedTitleController?.stream,
                                      initialData: _accumulatedTranslatedTitle,
                                      builder: (context, snapshot) {
                                        return LaTexT(
                                          breakDelimiter: r'\nl',
                                          laTeXCode: Text(
                                            snapshot.data!,
                                            maxLines: 9,
                                            overflow: TextOverflow.ellipsis,
                                            style: onImageTitleStyle,
                                          ),
                                        );
                                      },
                                    )
                                  : LaTexT(
                                      breakDelimiter: r'\nl',
                                      laTeXCode: Text(
                                        widget.title,
                                        maxLines: 9,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: onImageTitleStyle,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -- Article Content --
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
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
                                  _showTranslatedAbstract =
                                      !_showTranslatedAbstract;
                                  if (_showTranslatedTitle) {
                                    _translatedTitleController!
                                        .add(_accumulatedTranslatedTitle);
                                  } else {
                                    _translatedTitleController!
                                        .add(widget.title);
                                  }

                                  if (_showTranslatedAbstract) {
                                    _translatedAbstractController!
                                        .add(_accumulatedTranslatedAbstract);
                                  } else {
                                    _translatedAbstractController!
                                        .add(abstract ?? widget.abstract);
                                  }
                                });
                              },
                              child: Text(
                                _showTranslatedTitle || _showTranslatedAbstract
                                    ? AppLocalizations.of(context)!.showOriginal
                                    : AppLocalizations.of(context)!
                                        .showTranslation,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Authors
                      SelectableText(getAuthorsNames(widget.authors),
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),

                      // Abstract
                      isLoadingAbstract
                          ? const Center(child: CircularProgressIndicator())
                          : _showTranslatedAbstract
                              ? StreamBuilder<String>(
                                  stream: _translatedAbstractController?.stream,
                                  initialData: _accumulatedTranslatedAbstract,
                                  builder: (context, snapshot) {
                                    return LaTexT(
                                      breakDelimiter: r'\nl',
                                      laTeXCode: Text(
                                        snapshot.data!,
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
                      const SizedBox(height: 20),
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

                                      if (widget.publisher == null ||
                                          widget.publisher!.isEmpty) {
                                        if (journalInfo != null &&
                                            journalInfo['publisher'] != null) {
                                          journalPublisher =
                                              journalInfo['publisher'];
                                        } else {
                                          journalPublisher =
                                              widget.publisher ?? "";
                                        }
                                      } else {
                                        journalPublisher = widget.publisher!;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              JournalDetailsScreen(
                                            title: widget.journalTitle,
                                            publisher: journalPublisher,
                                            issn: widget.issn,
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: widget.journalTitle.isNotEmpty
                                        ? Text(
                                            '${AppLocalizations.of(context)!.publishedin} ${widget.journalTitle}',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          )
                                        : SizedBox(),
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

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(isLiked
                                    ? '${widget.title} ${AppLocalizations.of(context)!.favoriteadded}'
                                    : '${widget.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
                              ));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_hideAI)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showTranslateSheet,
                      borderRadius: BorderRadius.circular(8),
                      splashColor:
                          Theme.of(context).colorScheme.primary.withAlpha(77),
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
                    splashColor:
                        Theme.of(context).colorScheme.primary.withAlpha(77),
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
                        _showTranslatedAbstract
                            ? _accumulatedTranslatedAbstract
                            : (abstract ?? widget.abstract),
                        widget.journalTitle,
                        widget.publishedDate,
                        widget.doi,
                        widget.issn,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    splashColor:
                        Theme.of(context).colorScheme.primary.withAlpha(77),
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
    if (mounted) {
      setState(() {
        isLiked = liked;
      });
    }
  }

  Future<Map<String, dynamic>?> getJournalDetails(List<String> issn) async {
    if (widget.publisher != null && widget.publisher!.isNotEmpty) {
      return {'publisher': widget.publisher};
    }

    // If publisher is not passed, fetch from the database
    final db = await databaseHelper.database;
    final id = await databaseHelper.getJournalIdByIssns(issn);
    if (id == null) {
      return null;
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'journals',
      columns: ['publisher'],
      where: 'journal_id = ?',
      whereArgs: [id],
    );

    return rows.isNotEmpty ? rows.first : null;
  }
}
