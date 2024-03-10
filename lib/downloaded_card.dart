import 'package:flutter/material.dart';
import './screens/pdf_reader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './screens/journals_details_screen.dart';
import './publication_card.dart';
import './services/database_helper.dart';

class DownloadedCard extends StatefulWidget {
  final pdfPath;
  final PublicationCard publicationCard;

  const DownloadedCard({
    Key? key,
    required this.pdfPath,
    required this.publicationCard,
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
                              Map<String, dynamic>? journalInfo =
                                  await getJournalDetails(
                                      widget.publicationCard.issn);
                              if (journalInfo != Null) {
                                String journalPublisher =
                                    journalInfo?['publisher'];
                                List<String> journalSubjects =
                                    (journalInfo?['subjects'] ?? '').split(',');

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JournalDetailsScreen(
                                        title:
                                            widget.publicationCard.journalTitle,
                                        publisher: journalPublisher,
                                        issn: widget.publicationCard.issn,
                                        subjects: journalSubjects,
                                      ),
                                    ));
                              }
                            },
                            child: Text(
                              widget.publicationCard.journalTitle,
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
                              await databaseHelper.removeDownloaded(
                                widget.publicationCard.doi,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('The article was deleted!')));
                            },
                            icon: Icon(Icons.delete_outline))
                      ]))
                ],
              ),
              Text(
                _formattedDate(widget.publicationCard.publishedDate!),
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

  String _formattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>?> getJournalDetails(String issn) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'journals',
      columns: ['publisher', 'subjects'],
      where: 'issn = ?',
      whereArgs: [issn],
    );

    return rows.isNotEmpty ? rows.first : null;
  }
}
