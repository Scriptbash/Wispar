import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wispar/screens/article_website.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart';
import '../services/database_helper.dart';
import '../publication_card.dart';
import './journals_details_screen.dart';
import '../services/zotero_api.dart';
import 'package:share_plus/share_plus.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;
  final String title;
  final String issn;
  final String abstract;
  final String journalTitle;
  final DateTime? publishedDate;
  final List<PublicationAuthor> authors;
  final String url;

  const ArticleScreen({
    Key? key,
    required this.doi,
    required this.title,
    required this.issn,
    required this.abstract,
    required this.journalTitle,
    this.publishedDate,
    required this.authors,
    required this.url,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfLiked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Share.share(
                    'Check out this article: ${widget.url}\n\n You can also find it by searching this DOI in Wispar: ${widget.doi}');
              },
              icon: Icon(Icons.share_outlined))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context)!.publishedon} ${_formattedDate(widget.publishedDate)}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(_getAuthorsNames(widget.authors),
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              SizedBox(height: 15),
              Text(
                widget.abstract.isNotEmpty
                    ? widget.abstract
                    : AppLocalizations.of(context)!.abstractunavailable,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DOI: ${widget.doi}',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              Map<String, dynamic>? journalInfo =
                                  await getJournalDetails(widget.issn);
                              if (journalInfo != null) {
                                String journalPublisher =
                                    journalInfo['publisher'];
                                List<String> journalSubjects =
                                    (journalInfo['subjects'] ?? '').split(',');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JournalDetailsScreen(
                                      title: widget.journalTitle,
                                      publisher: journalPublisher,
                                      issn: widget.issn,
                                      subjects: journalSubjects,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '${AppLocalizations.of(context)!.publishedin} ${widget.journalTitle}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: () async {
                      setState(() {
                        isLiked = !isLiked;
                      });

                      if (isLiked) {
                        await databaseHelper.insertArticle(
                          PublicationCard(
                            title: widget.title,
                            abstract: widget.abstract,
                            journalTitle: widget.journalTitle,
                            issn: widget.issn,
                            publishedDate: widget.publishedDate,
                            doi: widget.doi,
                            authors: widget.authors,
                            url: widget.url,
                          ),
                          isLiked: true,
                        );
                      } else {
                        await databaseHelper.removeFavorite(widget.doi);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isLiked
                            ? '${widget.title} ${AppLocalizations.of(context)!.favoriteadded}'
                            : '${widget.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.doi));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!.doicopied),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.copydoi,
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            Column(
              children: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(Icons.article_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleWebsite(
                          articleUrl: widget.url,
                          doi: widget.doi,
                        ),
                      ),
                    );
                  },
                ),
                Text(AppLocalizations.of(context)!.viewarticle,
                    style: TextStyle(fontSize: 10)),
              ],
            ),
            Column(
              children: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(Icons.book_outlined),
                  onPressed: () {
                    List<Map<String, dynamic>> authorsData = [];
                    for (PublicationAuthor author in widget.authors) {
                      authorsData.add({
                        'creatorType': 'author',
                        'firstName': author.given,
                        'lastName': author.family,
                      });
                    }
                    ZoteroService.sendToZotero(
                        context,
                        authorsData,
                        widget.title,
                        widget.abstract,
                        widget.journalTitle,
                        widget.publishedDate,
                        widget.doi,
                        widget.issn);
                  },
                ),
                Text('Send to Zotero', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAuthorsNames(List<PublicationAuthor> authors) {
    return authors
        .map((author) => '${author.given} ${author.family}')
        .join(', ');
  }

  String _formattedDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    setState(() {
      isLiked = liked;
    });
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
