import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart';

class ArticleScreen extends StatefulWidget {
  final String doi;
  final String title;

  const ArticleScreen({
    Key? key,
    required this.doi,
    required this.title,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<Item> articleDetailsFuture;
  bool isLoading = true;
  late Item articleDetails;

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
        title: Text(widget.title),
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
            articleDetails = snapshot.data!; // Assign value here
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      articleDetails.abstract.isNotEmpty
                          ? articleDetails.abstract
                          : 'Abstract unavailable. The publisher does not provide abstracts to Crossref. The full text should still be available.',
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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.copy_outlined),
            label: 'Copy DOI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Full text',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            label: 'Favorite',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Handle copy DOI button tap
              if (articleDetails != null) {
                Clipboard.setData(ClipboardData(text: articleDetails.doi));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('DOI copied to clipboard'),
                ));
              }
              break;
            case 1:
              // Handle full text button tap
              break;
            case 2:
              // Handle favorite button tap
              break;
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
