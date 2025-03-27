import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/openAlex_api.dart';
import '../screens/article_search_results_screen.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../services/database_helper.dart';

class OpenAlexSearchForm extends StatefulWidget {
  @override
  _OpenAlexSearchFormState createState() => _OpenAlexSearchFormState();
}

class _OpenAlexSearchFormState extends State<OpenAlexSearchForm> {
  List<Map<String, dynamic>> queryParts = [];
  String searchScope = 'Everything';
  String selectedSortField = '-';
  String selectedSortOrder = '-';
  bool _filtersExpanded = false;
  bool saveQuery = false;

  final TextEditingController queryNameController = TextEditingController();

  void _addQueryPart(String type) {
    setState(() {
      // Avoid adding an operator at the beginning or after a deleted keyword
      if (queryParts.isNotEmpty && queryParts.last['type'] != 'operator') {
        queryParts
            .add({'type': 'operator', 'value': 'AND'}); // Default operator
      }
      queryParts.add({'type': type, 'value': ''});
    });
  }

  void _updateQueryValue(int index, String value) {
    setState(() {
      queryParts[index]['value'] = value;
    });
  }

  void _toggleOperator(int index, int selectedIndex) {
    setState(() {
      queryParts[index]['value'] = ['AND', 'OR', 'NOT'][selectedIndex];
    });
  }

  void _removeQueryPart(int index) {
    setState(() {
      var removedPart = queryParts.removeAt(index);

      // If the removed part was a keyword and there's an operator right after it, remove that operator
      if (removedPart['type'] == 'keyword' &&
          index < queryParts.length &&
          queryParts[index]['type'] == 'operator') {
        queryParts.removeAt(index);
      }

      // If the operator is the last item and there's no valid keyword before it, remove it
      if (queryParts.isNotEmpty && queryParts.last['type'] == 'operator') {
        queryParts.removeAt(queryParts.length - 1); // Remove the last operator
      }
    });
  }

  void _executeSearch() async {
    String query = queryParts.map((part) => part['value']).join(' ');
    final scopeMap = {
      'Everything': 1,
      'Title and Abstract': 2,
      'Title': 3,
      'Abstract': 4,
    };
    int scope = scopeMap[searchScope] ?? 1;

    String? sortField = selectedSortField == '-' ? null : selectedSortField;
    String? sortOrder = selectedSortOrder == '-' ? null : selectedSortOrder;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final dbHelper = DatabaseHelper();
      List<journalsWorks.Item> results = [];
      if (saveQuery) {
        final queryName = queryNameController.text.trim();
        if (queryName != '') {
          final scopeMap = {
            1: 'search=', // Everything
            2: 'filter=title_and_abstract.search:', // Title and Abstract
            3: 'filter=title.search:', // Title only
            4: 'filter=abstract.search:', // Abstract only
          };
          String selectedSortBy = '';
          String selectedSortOrder = '';

          String searchField = scopeMap[scope] ?? 'search=';
          String queryString;

          if (sortField != null) {
            selectedSortBy = '&sort=$sortField';
          }
          if (sortOrder != null) {
            selectedSortOrder = ':$sortOrder';
          }

          queryString = '$searchField$query$selectedSortBy$selectedSortOrder';
          await dbHelper.saveSearchQuery(queryName, queryString, 'OpenAlex');
          results = await OpenAlexApi.getOpenAlexWorksByQuery(
            query,
            scope,
            sortField,
            sortOrder,
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.queryHasNoNameError)),
          );
          return;
        }
      } else {
        results = await OpenAlexApi.getOpenAlexWorksByQuery(
          query,
          scope,
          sortField,
          sortOrder,
        );
      }
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleSearchResultsScreen(
              initialSearchResults: results,
              initialHasMore: results.isNotEmpty,
              queryParams: {'query': query},
              source: 'OpenAlex',
            ),
          ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching results: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: searchScope,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    searchScope = newValue;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                    value: "Everything",
                    child: Text(AppLocalizations.of(context)!.everything)),
                DropdownMenuItem(
                    value: "Title and Abstract",
                    child:
                        Text(AppLocalizations.of(context)!.titleAndAbstract)),
                DropdownMenuItem(
                    value: "Title",
                    child: Text(AppLocalizations.of(context)!.title)),
                DropdownMenuItem(
                    value: "Abstract",
                    child: Text(AppLocalizations.of(context)!.abstract)),
              ],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchIn,
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSortField,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSortField = newValue;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(value: "-", child: Text("-")),
                      DropdownMenuItem(
                          value: "display_name",
                          child:
                              Text(AppLocalizations.of(context)!.displayName)),
                      DropdownMenuItem(
                          value: "cited_by_count",
                          child:
                              Text(AppLocalizations.of(context)!.citedByCount)),
                      DropdownMenuItem(
                          value: "works_count",
                          child:
                              Text(AppLocalizations.of(context)!.worksCount)),
                      DropdownMenuItem(
                          value: "publication_date",
                          child: Text(
                              AppLocalizations.of(context)!.publicationDate)),
                    ],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.sortby,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSortOrder,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSortOrder = newValue;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(value: '-', child: Text('-')),
                      DropdownMenuItem(
                          value: 'asc',
                          child: Text(AppLocalizations.of(context)!.ascending)),
                      DropdownMenuItem(
                          value: 'desc',
                          child:
                              Text(AppLocalizations.of(context)!.descending)),
                    ],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.sortorder,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Dynamic query builder
            Column(
              children: queryParts.asMap().entries.map((entry) {
                int index = entry.key;
                var part = entry.value;

                if (part['type'] == 'operator') {
                  // Only show operator if the previous part is a valid keyword
                  if (index == 0 ||
                      queryParts[index - 1]['type'] != 'keyword' ||
                      part['value'] == '') {
                    return SizedBox
                        .shrink(); // Hides the operator if it is not valid
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToggleButtons(
                          isSelected: [
                            part['value'] == 'AND',
                            part['value'] == 'OR',
                            part['value'] == 'NOT'
                          ],
                          onPressed: (int i) => _toggleOperator(index, i),
                          borderRadius: BorderRadius.circular(8),
                          children: [Text('AND'), Text('OR'), Text('NOT')],
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.enterKeyword,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateQueryValue(index, value),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _removeQueryPart(index),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _addQueryPart('keyword'),
                  child: Text(AppLocalizations.of(context)!.addKeyword),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.queryPreview,
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  queryParts
                      .where((part) =>
                          part['value'] != '' &&
                          // Ensure that operators are only shown if a keyword comes before it
                          !(part['type'] == 'operator' &&
                              (queryParts.indexOf(part) == 0 ||
                                  queryParts[queryParts.indexOf(part) - 1]
                                          ['type'] !=
                                      'keyword')))
                      .map((part) => part['value'])
                      .join(' '),
                ),
              ),
            ),
            SizedBox(height: 10),

            ExpansionTile(
              title: Text('Filters'),
              leading: Icon(
                _filtersExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              trailing: SizedBox(),
              onExpansionChanged: (bool expanded) {
                setState(() {
                  _filtersExpanded = expanded;
                });
              },
              children: [
                SizedBox(height: 8),
                Text("Coming soon!"),
                SizedBox(height: 16),
              ],
            ),
            SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.saveQuery,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              value: saveQuery,
              onChanged: (bool value) {
                setState(() {
                  saveQuery = value;
                });
              },
            ),
            SizedBox(height: 8),
            if (saveQuery)
              TextFormField(
                controller: queryNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.queryName,
                  border: OutlineInputBorder(),
                ),
              ),
            SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _executeSearch,
        child: Icon(Icons.search),
        shape: CircleBorder(),
      ),
    );
  }
}
