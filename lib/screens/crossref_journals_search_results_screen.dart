import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/widgets/journal_search_results_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class CrossrefJournalResultsScreen extends StatefulWidget {
  final String searchQuery;

  const CrossrefJournalResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  CrossrefJournalResultsScreenState createState() =>
      CrossrefJournalResultsScreenState();
}

class CrossrefJournalResultsScreenState
    extends State<CrossrefJournalResultsScreen> {
  final logger = LogsService().logger;
  late final PagingController<String?, Journals.Item> _pagingController;

  String? _latestNextCursor;

  @override
  void initState() {
    super.initState();

    _pagingController = PagingController<String?, Journals.Item>(
      getNextPageKey: (state) {
        if (state.pages == null || state.pages!.isEmpty) {
          return '*';
        }
        return _latestNextCursor;
      },
      fetchPage: _fetchPage,
    );
  }

  Future<List<Journals.Item>> _fetchPage(String? cursor) async {
    try {
      final issnRegex = RegExp(r'^\d{4}-\d{3}[\dXx]$');

      if (issnRegex.hasMatch(widget.searchQuery.trim())) {
        final journal =
            await CrossRefApi.queryJournalByISSN(widget.searchQuery.trim());

        if (journal != null) {
          return [journal];
        } else {
          return [];
        }
      }
      final response = await CrossRefApi.queryJournalsByName(
        query: widget.searchQuery,
        cursor: cursor ?? '*',
      );

      _latestNextCursor = response.nextCursor == null || response.items.isEmpty
          ? null
          : response.nextCursor;

      final filteredItems = response.items.where((item) {
        return item.issn.isNotEmpty;
      }).toList();

      return filteredItems;
    } catch (e, stackTrace) {
      logger.severe(
        'Failed to fetch journals',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: PagingListener<String?, Journals.Item>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) {
          return PagedListView<String?, Journals.Item>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate<Journals.Item>(
              itemBuilder: (context, item, index) => JournalsSearchResultCard(
                item: item,
                isFollowed: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
