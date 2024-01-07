import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;

  const ArticleScreen({
    Key? key,
    required this.doi,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<Item> articleDetailsFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    articleDetailsFuture = fetchArticleDetails();
  }

  Future<Item> fetchArticleDetails() async {
    try {
      return await CrossRefApi.getWorkByDOI(widget.doi);
    } catch (e) {
      print('Error fetching article details: $e');
      throw Exception(
          'Failed to fetch article details. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article details'),
      ),
      body: FutureBuilder<Item>(
        future: articleDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text('No data available'),
            );
          } else {
            Item articleDetails = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Text(
                      'Published on ${_formattedDate(articleDetails.publishedDate)}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      articleDetails.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _getAuthorsNames(articleDetails.authors),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Abstract',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        //decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    Text(
                      articleDetails.abstract,
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'DOI: ${articleDetails.doi}\nPublished in ${articleDetails.journalTitle}',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _getAuthorsNames(List<PublicationAuthor> authors) {
    return authors
        .map((author) => '${author.given} ${author.family}')
        .join(', ');
  }

  String _formattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
