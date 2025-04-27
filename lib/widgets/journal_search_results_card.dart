import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../services/database_helper.dart';
import '../screens/journals_details_screen.dart';
import './journal_follow_button.dart';

class JournalsSearchResultCard extends StatefulWidget {
  final Journals.Item item;
  final bool isFollowed;

  const JournalsSearchResultCard(
      {Key? key, required this.item, required this.isFollowed})
      : super(key: key);

  @override
  _JournalsSearchResultCardState createState() =>
      _JournalsSearchResultCardState();
}

class _JournalsSearchResultCardState extends State<JournalsSearchResultCard> {
  late bool _isFollowed = false; // Initialize with false by default

  @override
  void initState() {
    super.initState();
    _initFollowStatus();
  }

  Future<void> _initFollowStatus() async {
    final dbHelper = DatabaseHelper();
    int? journalId = await dbHelper.getJournalIdByIssns(widget.item.issn);
    bool isFollowed = false;
    if (journalId != null) {
      isFollowed = await dbHelper.isJournalFollowed(journalId);
    }

    if (mounted) {
      setState(() {
        _isFollowed = isFollowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          widget.item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context)!.publisher}: ${widget.item.publisher}'),
            if (widget.item.issn.isNotEmpty)
              Text('ISSN: ${widget.item.issn.toSet().join(', ')}'),
          ],
        ),
        trailing: FollowButton(
          item: widget.item,
          isFollowed: _isFollowed,
          onFollowStatusChanged: (isFollowed) {
            // Handle follow status changes
            setState(() {
              _isFollowed = isFollowed;
            });
          },
        ),
        onTap: () {
          // Navigate to the detailed screen when the card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailsScreen(
                title: widget.item.title,
                publisher: widget.item.publisher,
                issn: widget.item.issn,
                onFollowStatusChanged: (isFollowed) {
                  setState(() {
                    _isFollowed = isFollowed;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
