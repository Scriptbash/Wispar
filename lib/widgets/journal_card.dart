import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated_l10n/app_localizations.dart';
import '../screens/journals_details_screen.dart';
import '../models/journal_entity.dart';

class JournalCard extends StatelessWidget {
  final Journal journal;
  final Function(BuildContext, Journal) unfollowCallback;

  const JournalCard({required this.journal, required this.unfollowCallback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailsScreen(
                title: journal.title,
                publisher: journal.publisher,
                issn: journal.issn,
              ),
            ),
          );
        },
        onLongPress: () {
          Clipboard.setData(
              ClipboardData(text: journal.issn.toSet().join(', ')));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.issnCopied)),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                journal.title,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                // Perform the unfollow action
                unfollowCallback(context, journal);
              },
              child: Text(AppLocalizations.of(context)!.unfollow),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context)!.publisher}: ${journal.publisher}'),
            Text('ISSN: ${journal.issn.toSet().join(',')}'),
            Text(AppLocalizations.of(context)!
                .followingsince(DateTime.parse(journal.dateFollowed!))),
          ],
        ),
      ),
    );
  }
}
