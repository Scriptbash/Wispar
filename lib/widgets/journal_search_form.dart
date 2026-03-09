import 'package:flutter/material.dart';
import 'package:wispar/screens/openalex_journal_results_screen.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/screens/crossref_journals_search_results_screen.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/widgets/openalex_topics_selector.dart';
import 'package:wispar/models/openalex_domain_models.dart';

class JournalSearchForm extends StatefulWidget {
  const JournalSearchForm({super.key});

  @override
  JournalSearchFormState createState() => JournalSearchFormState();
}

class JournalSearchFormState extends State<JournalSearchForm> {
  final logger = LogsService().logger;
  bool saveQuery = false;
  int selectedSearchIndex = 0; // 0 for 'topics', 1 for 'title', 2 for 'issn'
  late Journals.Item selectedJournal;
  final TextEditingController _searchController = TextEditingController();
  final List<Journals.Item> _topicResults = [];
  final bool _loadingTopicsResults = false;
  final ScrollController _scrollController = ScrollController();
  OpenAlexDomain? _selectedDomain;
  OpenAlexField? _selectedField;
  OpenAlexSubfield? _selectedSubfield;
  OpenAlexField? _selectedLevel;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ToggleButtons(
                    isSelected: [
                      selectedSearchIndex == 0,
                      selectedSearchIndex == 1,
                      selectedSearchIndex == 2,
                    ],
                    onPressed: (int index) {
                      setState(() {
                        selectedSearchIndex = index;
                        _searchController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(15.0),
                    children: [
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.searchByTopic,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.searchByTitle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: constraints.maxWidth / 3 - 1.5,
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.searchByISSN,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 32),
            if (selectedSearchIndex == 0) ...[
              OpenAlexTopicSelector(
                scrollController: _scrollController,
                onSelectionChanged: ({
                  OpenAlexDomain? domain,
                  OpenAlexField? field,
                  OpenAlexSubfield? subfield,
                  OpenAlexField? topic,
                }) {
                  setState(() {
                    _selectedDomain = domain;
                    _selectedField = field;
                    _selectedSubfield = subfield;

                    _selectedLevel = topic ??
                        (subfield != null
                            ? OpenAlexField(
                                id: subfield.id,
                                shortId: subfield.shortId,
                                displayName: subfield.displayName,
                              )
                            : field ??
                                (domain != null
                                    ? OpenAlexField(
                                        id: domain.id,
                                        shortId: domain.shortId,
                                        displayName: domain.displayName,
                                      )
                                    : null));
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_loadingTopicsResults)
                const Center(child: CircularProgressIndicator()),
              if (_topicResults.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topicResults.length,
                  itemBuilder: (context, index) {
                    final journal = _topicResults[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(journal.title),
                        subtitle: Text(journal.issn.join(", ")),
                      ),
                    );
                  },
                ),
            ] else
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: selectedSearchIndex == 1
                      ? AppLocalizations.of(context)!.journaltitle
                      : 'ISSN',
                  border: const OutlineInputBorder(),
                ),
              ),
            SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: selectedSearchIndex == 0 && _selectedLevel != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _searchByTopicSelection();
                  },
                  child: const Icon(Icons.search),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(maxWidth: 140),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedLevel!.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () async {
                if (selectedSearchIndex == 0) {
                  if (_selectedLevel == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.selectTopicFirst),
                      ),
                    );
                    return;
                  }

                  _searchByTopicSelection();
                  return;
                }

                final query = _searchController.text.trim();

                if (query.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.emptySearchQuery,
                      ),
                    ),
                  );
                  return;
                }

                _handleSearch(query);
              },
              child: const Icon(Icons.search),
            ),
    );
  }

  void _handleSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrossrefJournalResultsScreen(
          searchQuery: query,
        ),
      ),
    );
  }

  void _searchByTopicSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenAlexJournalResultsScreen(
          domainId: _selectedDomain?.id,
          fieldId: _selectedField?.id,
          subfieldId: _selectedSubfield?.id,
          topicId: _selectedLevel?.id,
        ),
      ),
    );
  }
}
