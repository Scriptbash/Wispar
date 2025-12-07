import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/screens/journals_search_results_screen.dart';
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/widgets/journal_topics_widget.dart';
import 'package:wispar/models/journal_topics_models.dart';
import 'package:wispar/services/journal_topics_helper.dart';

class JournalSearchForm extends StatefulWidget {
  const JournalSearchForm({super.key});

  @override
  JournalSearchFormState createState() => JournalSearchFormState();
}

class JournalSearchFormState extends State<JournalSearchForm> {
  final logger = LogsService().logger;
  bool saveQuery = false;
  int selectedSearchIndex = 0; // 0 for 'name', 1 for topics, 2 for 'issn'
  late Journals.Item selectedJournal;
  final TextEditingController _searchController = TextEditingController();
  Map<String, List<JournalTopicsCsv>>? _topicCategories;
  bool showCategories = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ToggleButtons(
                    isSelected: [
                      selectedSearchIndex == 0,
                      selectedSearchIndex == 1,
                      selectedSearchIndex == 2,
                    ],
                    onPressed: (index) {
                      setState(() {
                        selectedSearchIndex = index;
                        _searchController.clear();
                        if (index == 1) _loadTopics();
                      });
                    },
                    borderRadius: BorderRadius.circular(15),
                    children: [
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child:
                            Text(AppLocalizations.of(context)!.searchByTitle),
                      ),
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child:
                            Text(AppLocalizations.of(context)!.searchByTopic),
                      ),
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child: Text(AppLocalizations.of(context)!.searchByISSN),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            if (selectedSearchIndex == 1)
              _topicCategories == null
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : TopicsListWidget(categories: _topicCategories!),
            if (selectedSearchIndex != 1)
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: selectedSearchIndex == 0
                      ? AppLocalizations.of(context)!.journaltitle
                      : "ISSN",
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: selectedSearchIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: () {
                String query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  _handleSearch(query);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.emptySearchQuery)),
                  );
                }
              },
              child: Icon(Icons.search),
            ),
    );
  }

  void _handleSearch(String query) async {
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

      CrossRefApi.resetJournalCursor();

      ListAndMore<Journals.Item> searchResults;
      if (selectedSearchIndex == 0) {
        searchResults = await CrossRefApi.queryJournalsByName(query);
      } else if (selectedSearchIndex == 2) {
        searchResults = await CrossRefApi.queryJournalsByISSN(query);
      } else {
        throw Exception('Invalid search type selected');
      }

      if (mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsScreen(
              searchResults: searchResults,
              searchQuery: query,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.severe("Unable to search for journals.", e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.journalSearchError)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _loadTopics() async {
    setState(() => _topicCategories = null);
    try {
      final entries = await fetchCsvCategories();
      final Map<String, List<JournalTopicsCsv>> grouped = {};
      for (final e in entries) {
        for (final c in e.categories) {
          grouped.putIfAbsent(c, () => []).add(e);
        }
      }
      if (mounted) setState(() => _topicCategories = grouped);
    } catch (e) {
      logger.severe("Failed to load topics: $e");
    }
  }
}
