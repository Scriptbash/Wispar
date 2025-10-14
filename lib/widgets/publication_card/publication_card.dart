import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/models/crossref_journals_works_models.dart';
import 'package:wispar/screens/article_screen.dart';
import 'package:wispar/screens/journals_details_screen.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/zotero_api.dart';
import 'package:wispar/widgets/publication_card/publication_card_content.dart';
import 'package:wispar/widgets/publication_card/card_swipe_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SwipeAction { none, hide, favorite, sendToZotero, share }

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
  final bool showHideBtn;
  final bool? isHidden;
  final VoidCallback? onHide;

  final SwipeAction swipeLeftAction;
  final SwipeAction swipeRightAction;

  final bool showJournalTitle;
  final bool showPublicationDate;
  final bool showAuthorNames;
  final bool showLicense;
  final bool showOptionsMenu;
  final bool showFavoriteButton;

  const PublicationCard({
    super.key,
    required this.title,
    required this.abstract,
    required this.journalTitle,
    required this.issn,
    this.publishedDate,
    required this.doi,
    required this.authors,
    required this.url,
    required this.license,
    required this.licenseName,
    this.dateLiked,
    this.onFavoriteChanged,
    this.onAbstractChanged,
    this.publisher,
    this.showHideBtn = false,
    this.isHidden,
    this.onHide,
    this.swipeLeftAction = SwipeAction.hide,
    this.swipeRightAction = SwipeAction.favorite,
    this.showJournalTitle = true,
    this.showPublicationDate = true,
    this.showAuthorNames = true,
    this.showLicense = true,
    this.showOptionsMenu = true,
    this.showFavoriteButton = true,
  });

  @override
  PublicationCardState createState() => PublicationCardState();
}

class PublicationCardState extends State<PublicationCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;
  late AnimationController _swipeController;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0.0;
  static const double _dismissThreshold = 0.3; // 30% to trigger the swipe

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfLiked();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {});
      });

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _handleJournalTap() async {
    Map<String, dynamic>? journalInfo = await getJournalDetails(widget.issn);
    if (journalInfo != null && journalInfo.isNotEmpty) {
      String journalPublisher = journalInfo['publisher'] ?? 'Unknown Publisher';
      if (!mounted) return;
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
  }

  void _handleFavoriteToggle() async {
    setState(() => isLiked = !isLiked);
    if (isLiked) {
      await databaseHelper.insertArticle(widget, isLiked: true);
    } else {
      await databaseHelper.removeFavorite(widget.doi);
    }
    widget.onFavoriteChanged?.call();
  }

  void _handleLicenseTap() {
    if (widget.license.isNotEmpty) {
      launchUrl(Uri.parse(widget.license));
    }
  }

  void _handleHideToggle() async {
    await _handleSwipe(SwipeAction.hide);
  }

  Future<void> _handleSwipe(SwipeAction action) async {
    switch (action) {
      case SwipeAction.hide:
        if (widget.isHidden == true) {
          await databaseHelper.unhideArticle(widget.doi);
        } else {
          await databaseHelper.hideArticle(widget.doi);
        }
        widget.onHide?.call();
        break;
      case SwipeAction.favorite:
        setState(() => isLiked = !isLiked);
        if (isLiked) {
          await databaseHelper.insertArticle(widget, isLiked: true);
        } else {
          await databaseHelper.removeFavorite(widget.doi);
        }
        widget.onFavoriteChanged?.call();
        break;
      case SwipeAction.sendToZotero:
        _sendToZotero();
        break;
      case SwipeAction.share:
        _shareArticle();
        break;
      case SwipeAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title.isEmpty || widget.authors.isEmpty) return Container();

    return KeyedSubtree(
      key: ValueKey(widget.doi),
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _swipeController.stop();
          _dragExtent = 0.0;
          _slideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0),
          ).animate(
              CurvedAnimation(parent: _swipeController, curve: Curves.linear));
        },
        onHorizontalDragUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          if (renderBox.size.width == 0) return;
          final cardWidth = renderBox.size.width;

          _dragExtent += details.primaryDelta! / cardWidth;
          final clampedExtent = _dragExtent.clamp(-1.0, 1.0);

          setState(() {
            _slideAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: Offset(clampedExtent.sign, 0),
            ).animate(CurvedAnimation(
                parent: _swipeController, curve: Curves.linear));

            _swipeController.value = clampedExtent.abs();
          });
        },
        onHorizontalDragEnd: (details) async {
          if (_swipeController.isAnimating) return;

          final double dx = details.primaryVelocity ?? 0;
          final double currentExtent = _dragExtent;
          SwipeAction actionToPerform = SwipeAction.none;

          bool isDismissed =
              (currentExtent.abs() >= _dismissThreshold || dx.abs() > 800);

          if (isDismissed) {
            actionToPerform = currentExtent < 0
                ? widget.swipeLeftAction
                : widget.swipeRightAction;
          }

          if (actionToPerform == SwipeAction.hide &&
              widget.showHideBtn == false) {
            actionToPerform = SwipeAction.none;
          }

          final double currentControllerValue = _swipeController.value;

          if (actionToPerform == SwipeAction.none) {
            _swipeController.reverse();
            _dragExtent = 0.0;
            return;
          }

          final bool isDismissal = actionToPerform == SwipeAction.hide;

          final double targetOffset = isDismissal
              ? currentExtent.sign * 2.0 // Fully dismiss the card (slides it)
              : currentExtent.sign * 0.3; // Brings back the card into place

          setState(() {
            _slideAnimation = Tween<Offset>(
              begin: Offset(currentExtent, 0),
              end: Offset(targetOffset, 0),
            ).animate(CurvedAnimation(
                parent: _swipeController, curve: Curves.easeOut));
          });

          await _swipeController.forward(from: currentControllerValue);

          if (isDismissal) {
            await _handleSwipe(actionToPerform);
          } else {
            await _handleSwipe(actionToPerform);

            setState(() {
              _slideAnimation =
                  Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
                      CurvedAnimation(
                          parent: _swipeController, curve: Curves.easeOut));
            });
            _swipeController.reverse();
          }

          _dragExtent = 0.0;
        },

        // -- MAIN CONTENT OF THE CARD -- //
        child: Stack(
          children: [
            CardSwipeBackground(
              direction: TextDirection.rtl,
              action: widget.swipeRightAction,
              oppositeAction: widget.swipeLeftAction,
              dragExtent: _dragExtent,
              dismissThreshold: _dismissThreshold,
              isLiked: isLiked,
              isHidden: widget.isHidden,
              showHideBtn: widget.showHideBtn,
            ),
            CardSwipeBackground(
              direction: TextDirection.ltr,
              action: widget.swipeLeftAction,
              oppositeAction: widget.swipeRightAction,
              dragExtent: _dragExtent,
              dismissThreshold: _dismissThreshold,
              isLiked: isLiked,
              isHidden: widget.isHidden,
              showHideBtn: widget.showHideBtn,
            ),
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () => _openArticle(),
                child: Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PublicationCardContent(
                      title: widget.title,
                      abstractText: widget.abstract,
                      journalTitle: widget.journalTitle,
                      issn: widget.issn,
                      publishedDate: widget.publishedDate,
                      authors: widget.authors,
                      license: widget.license,
                      licenseName: widget.licenseName,
                      dateLiked: widget.dateLiked,
                      isLiked: isLiked,
                      showHideBtn: widget.showHideBtn,
                      isHidden: widget.isHidden,
                      showJournalTitle: widget.showJournalTitle,
                      showPublicationDate: widget.showPublicationDate,
                      showAuthorNames: widget.showAuthorNames,
                      showLicense: widget.showLicense,
                      showOptionsMenu: widget.showOptionsMenu,
                      showFavoriteButton: widget.showFavoriteButton,
                      onJournalTapped: _handleJournalTap,
                      onFavoriteToggle: _handleFavoriteToggle,
                      onLicenseTapped: _handleLicenseTap,
                      onSendToZotero: _sendToZotero,
                      onShowCopyOptions: _showCopyOptions,
                      onShareArticle: _shareArticle,
                      onHideToggle: _handleHideToggle,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openArticle() async {
    String finalAbstract = widget.abstract;
    String? newGraphAbstractPath;
    if (widget.abstract.trim().isEmpty) {
      final dbAbstract = await databaseHelper.getAbstract(widget.doi);
      if (dbAbstract != null && dbAbstract.isNotEmpty) {
        finalAbstract = dbAbstract;
      }
    }
    final graphicalAbstractPath =
        await databaseHelper.getGraphicalAbstractPath(widget.doi);
    if (graphicalAbstractPath != null && graphicalAbstractPath.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
      final customPath = prefs.getString('customDatabasePath');

      String basePath;
      if (useCustomPath && customPath != null) {
        basePath = customPath;
      } else {
        final defaultDirectory = await getApplicationDocumentsDirectory();
        basePath = defaultDirectory.path;
      }
      newGraphAbstractPath = p.join(basePath, graphicalAbstractPath);
    }

    final screen = ArticleScreen(
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
      graphicalAbstractUrl: newGraphAbstractPath,
      onAbstractChanged: () {
        widget.onAbstractChanged?.call();
      },
    );

    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final height = screenSize.height;

    if (width >= 600) {
      double dialogWidth = width * 0.7;
      double dialogHeight = height * 0.8;

      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(40),
          backgroundColor: Colors.transparent,
          elevation: 10,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(52),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: screen,
            ),
          ),
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    if (mounted) setState(() => isLiked = liked);
  }

  Future<Map<String, dynamic>?> getJournalDetails(List<String> issn) async {
    if (widget.publisher != null) return {'publisher': widget.publisher};
    final db = await databaseHelper.database;
    final id = await databaseHelper.getJournalIdByIssns(issn);
    final rows = await db.query('journals',
        columns: ['publisher'], where: 'journal_id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  void _sendToZotero() {
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

  void _shareArticle() {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text:
            '${widget.title}\n\n${widget.url}\n\n\nDOI: ${widget.doi}\n${AppLocalizations.of(context)!.sharedMessage} 👻',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}
