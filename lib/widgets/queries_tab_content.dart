import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/sort_dialog.dart';
import '../services/database_helper.dart';
import '../widgets/search_query_card.dart';

class QueriesTabContent extends StatefulWidget {
  final int initialSortBy;
  final int initialSortOrder;
  final Function(int) onSortByChanged;
  final Function(int) onSortOrderChanged;

  const QueriesTabContent({
    Key? key,
    required this.initialSortBy,
    required this.initialSortOrder,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
  }) : super(key: key);

  @override
  _QueriesTabContentState createState() => _QueriesTabContentState();
}

class _QueriesTabContentState extends State<QueriesTabContent> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> savedQueriesFuture;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    savedQueriesFuture = dbHelper.getSavedQueries();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sort options row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _showSortDialog(context),
                icon: Icon(Icons.swap_vert),
                label: Text(AppLocalizations.of(context)!.sort),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                icon: Icon(_isEditing ? Icons.check : Icons.edit),
                label: Text(_isEditing
                    ? AppLocalizations.of(context)!.done
                    : AppLocalizations.of(context)!.edit),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        // Saved queries list
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: savedQueriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.noSavedQueries,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                );
              } else {
                // Sorting logic
                List<Map<String, dynamic>> savedQueries =
                    List.from(snapshot.data!);
                savedQueries.sort((a, b) {
                  switch (widget.initialSortBy) {
                    case 0: // Sort by query name
                      return a['queryName'].compareTo(b['queryName']);
                    case 1: // Sort by date saved
                      return a['dateSaved'].compareTo(b['dateSaved']);
                    default:
                      return 0;
                  }
                });

                if (widget.initialSortOrder == 1) {
                  savedQueries = savedQueries.reversed.toList();
                }

                // Display saved queries
                return ListView.builder(
                  itemCount: savedQueries.length,
                  itemBuilder: (context, index) {
                    final query = savedQueries[index];
                    return SearchQueryCard(
                      queryId: query['query_id'],
                      queryName: query['queryName'],
                      queryParams: query['queryParams'],
                      queryProvider: query['queryProvider'],
                      dateSaved: query['dateSaved'],
                      showDeleteButton: _isEditing,
                      onDelete: () async {
                        await dbHelper.deleteQuery(query['query_id']);
                        setState(() {
                          savedQueriesFuture = dbHelper.getSavedQueries();
                        });
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showSortDialog(BuildContext context) {
    showSortDialog(
      context: context,
      initialSortBy: widget.initialSortBy,
      initialSortOrder: widget.initialSortOrder,
      sortByOptions: [
        AppLocalizations.of(context)!.queryName,
        AppLocalizations.of(context)!.dateSaved,
      ],
      sortOrderOptions: [
        AppLocalizations.of(context)!.ascending,
        AppLocalizations.of(context)!.descending,
      ],
      onSortByChanged: widget.onSortByChanged,
      onSortOrderChanged: widget.onSortOrderChanged,
    );
  }
}
