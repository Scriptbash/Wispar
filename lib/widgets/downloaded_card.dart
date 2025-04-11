import 'package:flutter/material.dart';
import '../screens/pdf_reader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/journals_details_screen.dart';
import 'publication_card.dart';
import '../services/database_helper.dart';
import '../services/string_format_helper.dart';

class DownloadedCard extends StatefulWidget {
  final pdfPath;
  final PublicationCard publicationCard;
  final VoidCallback onDelete;

  const DownloadedCard({
    Key? key,
    required this.pdfPath,
    required this.publicationCard,
    required this.onDelete,
  }) : super(key: key);

  @override
  _DownloadedCardState createState() => _DownloadedCardState();
}

class _DownloadedCardState extends State<DownloadedCard> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the pdfReader when the card is tapped
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PdfReader(
            pdfUrl: widget.pdfPath,
            publicationCard: widget.publicationCard,
          ),
        ));
      },
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              Map<String, dynamic>? journalInfo;

                              journalInfo = await getJournalDetails(
                                  widget.publicationCard.issn);

                              if (journalInfo != Null) {
                                String journalPublisher =
                                    journalInfo?['publisher'];

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JournalDetailsScreen(
                                        title:
                                            widget.publicationCard.journalTitle,
                                        publisher: journalPublisher,
                                        issn: widget.publicationCard.issn,
                                      ),
                                    ));
                              }
                            },
                            child: Text(
                              widget.publicationCard.journalTitle,
                              style: TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ))),
                  Expanded(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                        IconButton(
                          onPressed: () async {
                            await databaseHelper
                                .removeDownloaded(widget.publicationCard.doi);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .downloadDeleted)),
                            );
                            widget.onDelete();
                          },
                          icon: Icon(Icons.delete_outline),
                        ),
                      ]))
                ],
              ),
              Text(
                formatDate(widget.publicationCard.publishedDate!),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                widget.publicationCard.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5.0),
            ],
          ),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 8,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
                )),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> getJournalDetails(List<String> issn) async {
    final db = await databaseHelper.database;
    final id = await databaseHelper.getJournalIdByIssns(issn);
    final List<Map<String, dynamic>> rows = await db.query(
      'journals',
      columns: ['publisher'],
      where: 'journal_id = ?',
      whereArgs: [id],
    );

    return rows.isNotEmpty ? rows.first : null;
  }
}
