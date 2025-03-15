import 'package:flutter/material.dart';
import '../services/openAlex_api.dart';
import '../screens/article_search_results_screen.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;

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

  void _addQueryPart(String type) {
    setState(() {
      if (queryParts.isNotEmpty) {
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
      if (index > 0 && queryParts[index - 1]['type'] == 'operator') {
        queryParts.removeAt(index - 1); // Remove preceding operator
        index--;
      }
      queryParts.removeAt(index);
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
      List<SearchResult> results = await OpenAlexApi.getOpenAlexWorksByQuery(
        query,
        scope,
        sortField,
        sortOrder,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleSearchResultsScreen(
            initialSearchResults: results
                .map((result) => journalsWorks.Item(
                      title: result.title,
                      abstract: result.abstract ?? '',
                      journalTitle: result.journalTitle ?? '',
                      publishedDate: result.publishedDate != null
                          ? DateTime.tryParse(result.publishedDate!) ??
                              DateTime(1970, 1, 1)
                          : DateTime(1970, 1, 1),
                      doi: result.doi ?? '',
                      authors: result.authors.map((fullName) {
                        List<String> parts = fullName.split(' ');
                        String given = parts.isNotEmpty ? parts.first : '';
                        String family =
                            parts.length > 1 ? parts.sublist(1).join(' ') : '';
                        return journalsWorks.PublicationAuthor(
                            given: given, family: family);
                      }).toList(),
                      url: result.url ?? '',
                      primaryUrl: result.url ?? '',
                      license: '',
                      licenseName: result.license ?? '',
                      publisher: result.publisher ?? '',
                      issn: result.issn?.isNotEmpty == true
                          ? result.issn!.last
                          : '',
                    ))
                .toList(),
            initialHasMore: results.isNotEmpty,
            queryParams: {'query': query},
          ),
        ),
      );
    } catch (e) {
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
              items: ['Everything', 'Title and Abstract', 'Title', 'Abstract']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Search in',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 12),
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
                      '-',
                      'display_name',
                      'cited_by_count',
                      'works_count',
                      'publication_date'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Sort by',
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
                      DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                      DropdownMenuItem(
                          value: 'desc', child: Text('Descending')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Order',
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
                          hintText: 'Enter keyword...',
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
                  child: Text('Add keyword'),
                ),
              ],
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

            SizedBox(height: 10),
            Text('Query preview:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  queryParts.map((part) => part['value']).join(' '),
                ),
              ),
            ),

            SizedBox(height: 20),
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
