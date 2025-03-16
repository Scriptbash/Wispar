import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../services/crossref_api.dart';
import '../services/openAlex_api.dart';
import '../services/string_format_helper.dart';
import '../screens/article_search_results_screen.dart';
import '../services/database_helper.dart';

class SearchQueryCard extends StatefulWidget {
  final int queryId;
  final String queryName;
  final String queryParams;
  final String queryProvider;
  final String dateSaved;
  final VoidCallback? onDelete;

  const SearchQueryCard({
    Key? key,
    required this.queryId,
    required this.queryName,
    required this.queryParams,
    required this.queryProvider,
    required this.dateSaved,
    this.onDelete,
  }) : super(key: key);

  @override
  _SearchQueryCardState createState() => _SearchQueryCardState();
}

class _SearchQueryCardState extends State<SearchQueryCard> {
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

        if (widget.queryProvider == 'Crossref') {
          // Convert the params string to the needed mapstring
          queryMap = Uri.splitQueryString(widget.queryParams);
          CrossRefApi.resetWorksQueryCursor(); // Reset the cursor on new search
          response = await CrossRefApi.getWorksByQuery(queryMap);
        } else if (widget.queryProvider == 'OpenAlex') {
          return; // Todo Finish this once lazy loading is inplemented
          /*queryMap = Uri.splitQueryString(widget.queryParams);

          String query = queryMap['search'] ?? '';
          String? sortField = queryMap['sortField'];
          String? sortOrder = queryMap['sortOrder'];
          response = await OpenAlexApi.getOpenAlexWorksByQuery(
              query, scope, sortField, sortOrder);*/
        }

        Navigator.pop(context);
        // Navigate to the search results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleSearchResultsScreen(
              initialSearchResults: response.list,
              initialHasMore: response.hasMore,
              queryParams: queryMap,
            ),
          ),
        );
      },
      onLongPress: () {
        // Copy the API request to clipboard
        String request =
            'https://api.crossref.org/works?${widget.queryParams}&rows=50';
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
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.queryParams,
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.includeInFeed,
                    style: const TextStyle(
                        fontSize: 14.0, fontWeight: FontWeight.w500),
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
              const SizedBox(height: 8.0),
              Text('Source: ${widget.queryProvider}'),
              const SizedBox(height: 8.0),
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
