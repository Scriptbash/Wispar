import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';

class JournalInfoHeader extends SliverPersistentHeaderDelegate {
  final String publisher;
  final String issn;

  JournalInfoHeader({
    required this.publisher,
    required this.issn,
  });

  @override
  double get maxExtent => 120.0;

  @override
  double get minExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            Text('${AppLocalizations.of(context)!.publisher}: $publisher'),
            Text('ISSN: $issn'),
            SizedBox(height: 8.0),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(
                horizontal: 60,
              ),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
