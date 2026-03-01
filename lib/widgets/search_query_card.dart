import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/services/openAlex_api.dart';
import 'package:wispar/services/string_format_helper.dart';
import 'package:wispar/screens/article_search_results_screen.dart';
import 'package:wispar/services/database_helper.dart';

class SearchQueryCard extends StatefulWidget {
  final int queryId;
  final String queryName;
  final String queryParams;
  final String queryProvider;
  final String dateSaved;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const SearchQueryCard({
    super.key,
    required this.queryId,
    required this.queryName,
    required this.queryParams,
    required this.queryProvider,
    this.showDeleteButton = false,
    required this.dateSaved,
    this.onDelete,
  });

  @override
  SearchQueryCardState createState() => SearchQueryCardState();
}

class SearchQueryCardState extends State<SearchQueryCard> {
  bool _includeInFeed = false;
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadIncludeInFeed();
  }

  Future<void> _loadIncludeInFeed() async {
    bool includeInFeed = await databaseHelper.getIncludeInFeed(widget.queryId);
    setState(() {
      _includeInFeed = includeInFeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime? parsedDate = DateTime.tryParse(widget.dateSaved);
    String formattedDate = formatDate(parsedDate);

    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );
        var response;
        Map<String, String> queryMap = {};
        String? query;
        int scope = 1;
        String? sortField;
        String? sortOrder;
        String? dateFilter;
        String? filterValue;

        if (widget.queryProvider == 'Crossref') {
          // Convert the params string to the needed mapstring
          queryMap = Uri.splitQueryString(widget.queryParams);
          CrossRefApi.resetWorksQueryCursor(); // Reset the cursor on new search
          response = await CrossRefApi.getWorksByQuery(queryMap);
        } else if (widget.queryProvider == 'OpenAlex') {
          queryMap = Uri.splitQueryString(widget.queryParams);

          String? sortParam = queryMap['sort'];
          String? filterValue = queryMap['filter'];
          String? searchValue = queryMap['search'];

          sortField = null;
          sortOrder = null;

          if (sortParam != null && sortParam.contains(':')) {
            final parts = sortParam.split(':');
            sortField = parts[0];
            sortOrder = parts.length > 1 ? parts[1] : null;
          }

          query = searchValue ?? '';
          scope = 1;

          if (filterValue != null) {
            List<String> filters = filterValue.split(',');
            List<String> remainingFilters = [];

            for (var f in filters) {
              if (f.startsWith('title.search:')) {
                query = f.replaceFirst('title.search:', '');
                scope = 3;
              } else if (f.startsWith('title_and_abstract.search:')) {
                query = f.replaceFirst('title_and_abstract.search:', '');
                scope = 2;
              } else if (f.startsWith('abstract.search:')) {
                query = f.replaceFirst('abstract.search:', '');
                scope = 4;
              } else if (f.startsWith('from_publication_date:') ||
                  f.startsWith('to_publication_date:')) {
                remainingFilters.add(f);
              }
            }
            if (remainingFilters.isNotEmpty) {
              dateFilter = remainingFilters.join(',');
            }
          }

          response = await OpenAlexApi.getOpenAlexWorksByQuery(
              query ?? '', scope, sortField, sortOrder, dateFilter);
        }

        Navigator.pop(context);
        // Navigate to the search results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (widget.queryProvider == 'Crossref') {
                return ArticleSearchResultsScreen(
                  initialSearchResults: response.list,
                  initialHasMore: response.hasMore,
                  queryParams: queryMap,
                  source: widget.queryProvider,
                );
              } else {
                return ArticleSearchResultsScreen(
                  initialSearchResults: response,
                  initialHasMore: response.isNotEmpty,
                  queryParams: {
                    'query': query,
                    'scope': scope,
                    'sortField': sortField,
                    'sortOrder': sortOrder,
                    'dateFilter': dateFilter,
                    'filter': filterValue,
                  },
                  source: widget.queryProvider,
                );
              }
            },
          ),
        );
      },
      onLongPress: () {
        // Copy the API request to clipboard
        String request = '';
        if (widget.queryProvider == "Crossref") {
          request =
              'https://api.crossref.org/works?${widget.queryParams}&rows=50';
          Clipboard.setData(ClipboardData(text: request));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.apiQueryCopied)),
          );
        } else {
          Map<String, String> queryMap =
              Uri.splitQueryString(widget.queryParams);

          String baseUrl = 'https://api.openalex.org/works';
          String query = queryMap['search'] ?? '';
          String? sortField = queryMap['sort'];
          String? sortOrder = queryMap['sortOrder'];
          String? filterValue = queryMap['filter'];

          List<String> filters = [];
          if (filterValue != null) {
            filters.add(filterValue);
          }

          String filterParam =
              filters.isNotEmpty ? 'filter=${filters.join(",")}' : '';
          String sortParam = (sortField != null && sortOrder != null)
              ? 'sort=$sortField:$sortOrder'
              : '';

          // Build query string
          List<String> queryParams = [];
          if (query.isNotEmpty) queryParams.add('search=$query');
          if (filterParam.isNotEmpty) queryParams.add(filterParam);
          if (sortParam.isNotEmpty) queryParams.add(sortParam);

          request = '$baseUrl?${queryParams.join("&")}';
        }

        Clipboard.setData(ClipboardData(text: request));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.apiQueryCopied)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.queryName,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Visibility(
                    visible: widget.showDeleteButton && widget.onDelete != null,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: widget.onDelete,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.queryParams,
                style: const TextStyle(fontSize: 14.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.includeInFeed,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _includeInFeed,
                    onChanged: (bool value) async {
                      setState(() {
                        _includeInFeed = value;
                      });

                      await databaseHelper.updateIncludeInFeed(
                          widget.queryId, _includeInFeed);
                    },
                  )
                ],
              ),
              Text(
                AppLocalizations.of(context)!.source(widget.queryProvider),
              ),
              Text(
                AppLocalizations.of(context)!
                    .savedOn(DateTime.parse(formattedDate)),
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
