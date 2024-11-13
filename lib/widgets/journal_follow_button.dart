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

    // Check if the journal is currently followed
    bool currentlyFollowed = await dbHelper.isJournalFollowed(item.issn.first);

    if (currentlyFollowed) {
      // Unfollow
      await dbHelper.removeJournal(item.issn.first);
    } else {
      // Follow
      List<String> subjectNames =
          item.subjects.map((subject) => subject.name).toList();
      await dbHelper.insertJournal(
        Journal(
          issn: item.issn.first,
          title: item.title,
          publisher: item.publisher,
          subjects: subjectNames.join(', '),
        ),
      );
    }

    //await dbHelper.clearCachedPublications();
    onFollowStatusChanged(!currentlyFollowed);
  }
}