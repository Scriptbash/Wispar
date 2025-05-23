import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../services/database_helper.dart';
import '../models/journal_entity.dart';

enum ButtonType { text, outlined }

class FollowButton extends StatelessWidget {
  final Journals.Item item;
  final bool isFollowed;
  final Function(bool) onFollowStatusChanged;
  final ButtonType buttonType;

  const FollowButton({
    Key? key,
    required this.item,
    required this.isFollowed,
    required this.onFollowStatusChanged,
    this.buttonType = ButtonType.text,
  }) : super(key: key);

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

    //await dbHelper.clearCachedPublications();
    onFollowStatusChanged(!currentlyFollowed);
  }
}
