import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/openalex_api.dart';
import 'package:wispar/widgets/journal_search_results_card.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class OpenAlexJournalResultsScreen extends StatefulWidget {
  final String? domainId;
  final String? fieldId;
  final String? subfieldId;
  final String? topicId;

  const OpenAlexJournalResultsScreen({
    super.key,
    this.domainId,
    this.fieldId,
    this.subfieldId,
    this.topicId,
  });

  @override
  State<OpenAlexJournalResultsScreen> createState() =>
      _OpenAlexJournalResultsScreenState();
}

class _OpenAlexJournalResultsScreenState
    extends State<OpenAlexJournalResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<Journals.Item> _journals = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _page = 1;

  @override
  void initState() {
    super.initState();

    _fetchPage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 300 &&
          !_loadingMore &&
          _hasMore) {
        _fetchPage();
      }
    });
  }

  Future<void> _fetchPage() async {
    if (_page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final result = await OpenAlexApi.getJournalsByTopic(
        domainId: widget.domainId,
        fieldId: widget.fieldId,
        subfieldId: widget.subfieldId,
        topicId: widget.topicId,
        page: _page,
      );

      setState(() {
        final filteredJournals =
            result.journals.where((j) => j.issn.isNotEmpty).map((j) {
          return Journals.Item(
            title: j.title,
            publisher: j.publisher,
            issn: j.issn,
            lastStatusCheckTime: 0,
            counts: Journals.Counts(
              totalDois: 0,
              currentDois: 0,
              backfileDois: 0,
            ),
            breakdowns: Journals.Breakdowns(doisByIssuedYear: []),
            coverage: {},
            coverageType: Journals.CoverageType.fromJson({}),
            flags: {},
            issnType: [],
          );
        }).toList();

        if (filteredJournals.isEmpty && result.hasMore) {
          _page++;
          _loadingMore = false;
          _fetchPage();
          return;
        }

        _journals.addAll(filteredJournals);
        _hasMore = result.hasMore;
        _page++;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.journals),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _journals.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _journals.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final journal = _journals[index];

                return JournalsSearchResultCard(
                  item: journal,
                  isFollowed: false,
                );
              },
            ),
    );
  }
}
