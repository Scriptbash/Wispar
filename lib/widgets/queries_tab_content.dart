import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/journal_entity.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
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
                onPressed: () => _showSortByDialog(context),
                icon: Icon(Icons.sort),
                label: Text(AppLocalizations.of(context)!.sortby),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              TextButton.icon(
                onPressed: () => _showSortOrderDialog(context),
                icon: Icon(
                  widget.initialSortOrder == 0
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
                label: Text(AppLocalizations.of(context)!.sortorder),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text:
                                  AppLocalizations.of(context)!.noSavedQueries,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      queryName: query['queryName'],
                      queryParams: query['queryParams'],
                      dateSaved: query['dateSaved'],
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

  void _showSortByDialog(BuildContext context) {
    showSortByDialog(
      context: context,
      initialSortBy: widget.initialSortBy,
      onSortByChanged: widget.onSortByChanged,
      sortOptions: [
        AppLocalizations.of(context)!.queryName,
        AppLocalizations.of(context)!.dateSaved,
      ],
    );
  }

  void _showSortOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SortOrderDialog(
          initialSortOrder: widget.initialSortOrder,
          sortOrderOptions: [
            AppLocalizations.of(context)!.ascending,
            AppLocalizations.of(context)!.descending,
          ],
          onSortOrderChanged: widget.onSortOrderChanged,
        );
      },
    );
  }
}
