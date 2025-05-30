import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import 'article_doi_search_form.dart';
import 'article_query_search_form.dart';
import '../services/crossref_api.dart';
import '../screens/article_screen.dart';
import '../services/logs_helper.dart';

class CrossRefSearchForm extends StatefulWidget {
  @override
  _CrossRefSearchFormState createState() => _CrossRefSearchFormState();
}

class _CrossRefSearchFormState extends State<CrossRefSearchForm> {
  final logger = LogsService().logger;
  int selectedSearchIndex = 0; // 0 for Query, 1 for DOI
  final TextEditingController doiController = TextEditingController();
  final GlobalKey<QuerySearchFormState> _queryFormKey =
      GlobalKey<QuerySearchFormState>(); // GlobalKey for QuerySearchForm

  @override
  void dispose() {
    doiController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      if (selectedSearchIndex == 0) {
        // Query search
        if (_queryFormKey.currentState != null) {
          _queryFormKey.currentState!
              .submitForm(); // Call the search function in QuerySearchForm
        } else {}
        Navigator.pop(context);
      } else {
        // DOI-based search
        String doi = doiController.text.trim();

        if (doi.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.emptyDOIError)),
          );
          return;
        }
        try {
          String extractedDoi;
          if (doi.startsWith('https://doi.org/')) {
            extractedDoi = doi.replaceFirst('https://doi.org/', '');
          } else {
            extractedDoi = doi;
          }
          final article = await CrossRefApi.getWorkByDOI(extractedDoi);

          // Dismiss the loading dialog
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleScreen(
                doi: article.doi,
                title: article.title,
                issn: article.issn,
                abstract: article.abstract,
                journalTitle: article.journalTitle,
                publishedDate: article.publishedDate,
                authors: article.authors,
                url: article.url,
                license: article.license,
                licenseName: article.licenseName,
                publisher: article.publisher,
              ),
            ),
          );
        } catch (e, stackTrace) {
          logger.severe(
              'Error searching by DOI for DOI ${doi}.', e, stackTrace);
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorOccured)),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.severe('Error searching articles using ${selectedSearchIndex}.', e,
          stackTrace);
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccured)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget searchForm = selectedSearchIndex == 0
        ? QuerySearchForm(key: _queryFormKey)
        : DOISearchForm(doiController: doiController);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ToggleButtons(
                    children: [
                      Container(
                        width: constraints.maxWidth / 2 - 1.5,
                        alignment: Alignment.center,
                        child:
                            Text(AppLocalizations.of(context)!.searchByQuery),
                      ),
                      Container(
                        width: constraints.maxWidth / 2 - 1.5,
                        alignment: Alignment.center,
                        child: Text(AppLocalizations.of(context)!.searchByDOI),
                      ),
                    ],
                    isSelected: [
                      selectedSearchIndex == 0,
                      selectedSearchIndex == 1,
                    ],
                    onPressed: (int index) {
                      setState(() {
                        selectedSearchIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            // Display the selected search form here
            searchForm,
            SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSearch,
        child: Icon(Icons.search),
        shape: CircleBorder(),
      ),
    );
  }
}
