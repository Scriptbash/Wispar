import 'package:flutter/material.dart';
import 'package:latext/latext.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/models/crossref_journals_works_models.dart';
import 'package:wispar/services/string_format_helper.dart';

class PublicationCardContent extends StatelessWidget {
  final String title;
  final String abstractText;
  final String journalTitle;
  final List<String> issn;
  final DateTime? publishedDate;
  final List<PublicationAuthor> authors;
  final String license;
  final String licenseName;
  final String? dateLiked;
  final bool isLiked;
  final bool? showHideBtn;
  final bool? isHidden;
  final bool showJournalTitle;
  final bool showPublicationDate;
  final bool showAuthorNames;
  final bool showLicense;
  final bool showOptionsMenu;
  final bool showFavoriteButton;

  final VoidCallback onJournalTapped;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onLicenseTapped;
  final VoidCallback onSendToZotero;
  final VoidCallback onShowCopyOptions;
  final VoidCallback onShareArticle;
  final VoidCallback onHideToggle;

  const PublicationCardContent({
    super.key,
    required this.title,
    required this.abstractText,
    required this.journalTitle,
    required this.issn,
    this.publishedDate,
    required this.authors,
    required this.license,
    required this.licenseName,
    this.dateLiked,
    required this.isLiked,
    this.showHideBtn,
    this.isHidden,
    required this.onJournalTapped,
    required this.onFavoriteToggle,
    required this.onLicenseTapped,
    required this.onSendToZotero,
    required this.onShowCopyOptions,
    required this.onShareArticle,
    required this.onHideToggle,
    this.showJournalTitle = true,
    this.showPublicationDate = true,
    this.showAuthorNames = true,
    this.showLicense = true,
    this.showOptionsMenu = true,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty || authors.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showJournalTitle || showOptionsMenu) _buildHeader(context),
          if (showPublicationDate && publishedDate != null)
            Text(
              AppLocalizations.of(context)!.publishedon(publishedDate!),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          const SizedBox(height: 6),
          LaTexT(
            breakDelimiter: r'\nl',
            laTeXCode: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 4),
          if (showAuthorNames)
            Text(
              getAuthorsNames(authors),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          if (abstractText.isNotEmpty)
            LaTexT(
              breakDelimiter: r'\nl',
              laTeXCode: Text(
                abstractText,
                softWrap: true,
                textAlign: TextAlign.justify,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 8),
          if (showLicense || showFavoriteButton) _buildFooter(context),
          if (dateLiked != null)
            Text(
              AppLocalizations.of(context)!
                  .addedtoyourfav(DateTime.parse(dateLiked!)),
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isContentVisible = showJournalTitle || showOptionsMenu;
    if (!isContentVisible) return const SizedBox.shrink();
    return Row(
      children: [
        if (showJournalTitle)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onJournalTapped,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  journalTitle,
                  style: const TextStyle(fontSize: 16),
                  softWrap: true,
                ),
              ),
            ),
          )
        else
          const Spacer(),
        if (showOptionsMenu)
          PopupMenuButton<int>(
            onSelected: (result) {
              switch (result) {
                case 0:
                  onSendToZotero();
                  break;
                case 1:
                  onShowCopyOptions();
                  break;
                case 2:
                  onShareArticle();
                  break;
                case 3:
                  onHideToggle();
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              PopupMenuItem(
                value: 0,
                child: ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(AppLocalizations.of(context)!.sendToZotero),
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(AppLocalizations.of(context)!.copy),
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(AppLocalizations.of(context)!.shareArticle),
                ),
              ),
              if (showHideBtn == true)
                PopupMenuItem(
                  value: 3,
                  child: ListTile(
                    leading: isHidden == true
                        ? const Icon(Icons.visibility_outlined)
                        : const Icon(Icons.visibility_off_outlined),
                    title: Text(isHidden == true
                        ? AppLocalizations.of(context)!.unhideArticle
                        : AppLocalizations.of(context)!.hideArticle),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final bool isContentVisible = showLicense || showFavoriteButton;
    if (!isContentVisible) return const SizedBox.shrink();

    return Row(
      children: [
        if (showLicense)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onLicenseTapped,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  licenseName.isNotEmpty
                      ? licenseName
                      : (license.isNotEmpty
                          ? AppLocalizations.of(context)!.otherLicense
                          : AppLocalizations.of(context)!.unknownLicense),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          )
        else
          const Spacer(),
        if (showFavoriteButton)
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: onFavoriteToggle,
          ),
      ],
    );
  }
}
