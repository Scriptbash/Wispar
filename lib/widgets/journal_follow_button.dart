import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../services/database_helper.dart';
import '../models/journal_entity.dart';

class FollowButton extends StatelessWidget {
  final Journals.Item item;
  final bool isFollowed;
  final Function(bool) onFollowStatusChanged;

  const FollowButton({
    Key? key,
    required this.item,
    required this.isFollowed,
    required this.onFollowStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        toggleFollowStatus(context);
      },
      child: Text(isFollowed
          ? AppLocalizations.of(context)!.unfollow
          : AppLocalizations.of(context)!.follow),
    );
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
