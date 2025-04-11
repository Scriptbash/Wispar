import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../models/journal_entity.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
import '../services/database_helper.dart';
import '../widgets/journal_card.dart';

class JournalsTabContent extends StatefulWidget {
  final int initialSortBy;
  final int initialSortOrder;
  final Function(int) onSortByChanged;
  final Function(int) onSortOrderChanged;

  const JournalsTabContent({
    Key? key,
    required this.initialSortBy,
    required this.initialSortOrder,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
  }) : super(key: key);

  @override
  _JournalsTabContentState createState() => _JournalsTabContentState();
}

class _JournalsTabContentState extends State<JournalsTabContent> {
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sort options row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _showSortByDialog(context),
                icon: Icon(Icons.sort),
                label: Text(AppLocalizations.of(context)!.sortby),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              TextButton.icon(
                onPressed: () => _showSortOrderDialog(context),
                icon: Icon(
                  widget.initialSortOrder == 0
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
                label: Text(AppLocalizations.of(context)!.sortorder),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        // Journal list
        Expanded(
          child: FutureBuilder<List<Journal>>(
            future: dbHelper.getJournals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.journalLibraryEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                );
              } else {
                List<Journal> journals = snapshot.data!;
                journals.sort((a, b) {
                  switch (widget.initialSortBy) {
                    case 0:
                      return a.title.compareTo(b.title);
                    case 1:
                      return a.publisher.compareTo(b.publisher);
                    case 2:
                      return a.dateFollowed!.compareTo(b.dateFollowed!);
                    case 3:
                      final aIssn = a.issn.isNotEmpty ? a.issn.first : '';
                      final bIssn = b.issn.isNotEmpty ? b.issn.first : '';
                      return aIssn.compareTo(bIssn);
                    default:
                      return 0;
                  }
                });

                if (widget.initialSortOrder == 1) {
                  journals = journals.reversed.toList();
                }

                return ListView.builder(
                  itemCount: journals.length,
                  itemBuilder: (context, index) {
                    final currentJournal = journals[index];
                    return Column(
                      children: [
                        JournalCard(
                          journal: currentJournal,
                          unfollowCallback: _unfollowJournal,
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showSortByDialog(BuildContext context) {
    showSortByDialog(
      context: context,
      initialSortBy: widget.initialSortBy,
      onSortByChanged: widget.onSortByChanged,
      sortOptions: [
        AppLocalizations.of(context)!.journaltitle,
        AppLocalizations.of(context)!.publisher,
        AppLocalizations.of(context)!.followingdate,
        'ISSN',
      ],
    );
  }

  void _showSortOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SortOrderDialog(
          initialSortOrder: widget.initialSortOrder,
          sortOrderOptions: [
            AppLocalizations.of(context)!.ascending,
            AppLocalizations.of(context)!.descending,
          ],
          onSortOrderChanged: widget.onSortOrderChanged,
        );
      },
    );
  }

  Future<void> _unfollowJournal(BuildContext context, Journal journal) async {
    await dbHelper.removeJournal(journal.issn);
    setState(() {});
  }
}
