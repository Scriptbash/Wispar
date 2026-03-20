import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/models/journal_entity.dart';
import 'package:wispar/services/sync_service.dart';

enum ButtonType { text, outlined }

class FollowButton extends StatelessWidget {
  final Journals.Item item;
  final bool isFollowed;
  final Function(bool) onFollowStatusChanged;
  final ButtonType buttonType;

  const FollowButton({
    super.key,
    required this.item,
    required this.isFollowed,
    required this.onFollowStatusChanged,
    this.buttonType = ButtonType.text,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (buttonType == ButtonType.text) {
      button = TextButton(
        onPressed: () {
          toggleFollowStatus(context);
        },
        child: Text(isFollowed
            ? AppLocalizations.of(context)!.unfollow
            : AppLocalizations.of(context)!.follow),
      );
    } else {
      button = OutlinedButton(
        onPressed: () {
          toggleFollowStatus(context);
        },
        child: Text(isFollowed
            ? AppLocalizations.of(context)!.unfollow
            : AppLocalizations.of(context)!.follow),
      );
    }

    return button;
  }

  void toggleFollowStatus(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    final syncManager = SyncManager();
    int? journalId = await dbHelper.getJournalIdByIssns(item.issn);
    bool currentlyFollowed = false;
    if (journalId != null) {
      // Check if the journal is currently followed
      currentlyFollowed = await dbHelper.isJournalFollowed(journalId);
    }

    if (currentlyFollowed) {
      // Unfollow
      await dbHelper.removeJournal(item.issn);
    } else {
      // Follow
      await dbHelper.insertJournal(
        Journal(
          issn: item.issn,
          title: item.title,
          publisher: item.publisher,
        ),
      );
    }
    syncManager.triggerBackgroundSync();

    //await dbHelper.clearCachedPublications();
    onFollowStatusChanged(!currentlyFollowed);
  }
}
