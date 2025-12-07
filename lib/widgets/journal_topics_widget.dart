import 'package:flutter/material.dart';
import 'package:wispar/models/journal_topics_models.dart';
import 'package:wispar/screens/journals_search_results_screen.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class TopicsListWidget extends StatelessWidget {
  final Map<String, List<JournalTopicsCsv>> categories;

  const TopicsListWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final keys = categories.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final category = keys[index];
          final journals = categories[category]!;

          // Converts the topics into a Journals.Item for the results screen
          final List<Journals.Item> converted = journals.map((j) {
            return Journals.Item(
              title: j.journal,
              issn: [j.issn, j.eissn].where((s) => s.isNotEmpty).toList(),
              publisher: '',
              lastStatusCheckTime: 0,
              counts: Journals.Counts(
                currentDois: 0,
                backfileDois: 0,
                totalDois: 0,
              ),
              breakdowns: Journals.Breakdowns(
                doisByIssuedYear: [],
              ),
              coverage: {},
              coverageType: Journals.CoverageType(
                all: {},
                backfile: {},
                current: {},
              ),
              flags: {},
              issnType: [],
            );
          }).toList();

          return Card(
            child: ListTile(
              title: Text(category),
              subtitle: Text(
                  AppLocalizations.of(context)!.countJournals(journals.length)),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchResultsScreen(
                      searchQuery: category,
                      searchResults: ListAndMore<Journals.Item>(
                        list: converted,
                        hasMore: false,
                        totalResults: converted.length,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
