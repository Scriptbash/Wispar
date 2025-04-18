import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../models/crossref_journals_models.dart' as Journals;
import './journal_follow_button.dart';

class JournalInfoHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final String publisher;
  final String issn;
  final bool isFollowed;
  final Function(bool) onFollowStatusChanged;

  JournalInfoHeader({
    required this.title,
    required this.publisher,
    required this.issn,
    required this.isFollowed,
    required this.onFollowStatusChanged,
  });

  @override
  double get maxExtent => 120.0;

  @override
  double get minExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // a little bit hacky, but oh well :(
    final journalItem = Journals.Item(
      lastStatusCheckTime: 0,
      counts: Journals.Counts(currentDois: 0, backfileDois: 0, totalDois: 0),
      breakdowns: Journals.Breakdowns(doisByIssuedYear: [
        [0]
      ]),
      publisher: publisher,
      coverage: {},
      title: title,
      coverageType: Journals.CoverageType(all: {}, backfile: {}, current: {}),
      flags: {},
      issn: issn.split(','),
      issnType: [],
    );

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      Text(
                          '${AppLocalizations.of(context)!.publisher}: ${publisher}'),
                      Text('ISSN: ${issn}'),
                      SizedBox(height: 8.0),
                    ],
                  ),
                ),
                title.isNotEmpty && publisher.isNotEmpty && issn.isNotEmpty
                    ? FollowButton(
                        item: journalItem,
                        isFollowed: isFollowed,
                        onFollowStatusChanged: onFollowStatusChanged,
                        buttonType: ButtonType.outlined,
                      )
                    : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 8.0),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 60),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant JournalInfoHeader oldDelegate) {
    return oldDelegate.isFollowed != isFollowed ||
        oldDelegate.issn != issn ||
        oldDelegate.publisher != publisher;
  }
}
