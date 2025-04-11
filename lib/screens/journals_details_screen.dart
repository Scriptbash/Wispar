import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../services/abstract_helper.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../widgets/publication_card.dart';
import '../widgets/journal_header.dart';
import '../widgets/latest_works_header.dart';

class JournalDetailsScreen extends StatefulWidget {
  final String title;
  final String publisher;
  final List<String> issn;

  const JournalDetailsScreen({
    Key? key,
    required this.title,
    required this.publisher,
    required this.issn,
  }) : super(key: key);

  @override
  _JournalDetailsScreenState createState() => _JournalDetailsScreenState();
}

class _JournalDetailsScreenState extends State<JournalDetailsScreen> {
  late List<journalsWorks.Item> allWorks;
  bool isLoading = false;
  late ScrollController _scrollController;
  bool hasMoreResults = true;
  Map<String, String> abstractCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    allWorks = [];
    CrossRefApi.resetJournalWorksCursor();
    _loadMoreWorks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 8.0,
              ),
              centerTitle: true,
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
            ),
            backgroundColor: Colors.deepPurple,
          ),
          SliverPersistentHeader(
            delegate: JournalInfoHeader(
              publisher: widget.publisher,
              issn: widget.issn.toSet().join(', '),
            ),
            pinned: false,
          ),
          SliverPersistentHeader(
            delegate: PersistentLatestPublicationsHeader(),
            pinned: true,
          ),
          allWorks.isEmpty && !isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noPublicationFound,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < allWorks.length) {
                        final work = allWorks[index];
                        String? cachedAbstract = abstractCache[work.doi];
                        if (cachedAbstract == null) {
                          return FutureBuilder<String>(
                            future: AbstractHelper.buildAbstract(
                                context, work.abstract),
                            builder: (context, abstractSnapshot) {
                              if (abstractSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              } else if (abstractSnapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Error: ${abstractSnapshot.error}'));
                              } else if (!abstractSnapshot.hasData) {
                                return const Center(
                                    child: Text('No abstract available'));
                              } else {
                                String formattedAbstract =
                                    abstractSnapshot.data!;
                                // Cache the abstract
                                abstractCache[work.doi] = formattedAbstract;

                                return PublicationCard(
                                  title: work.title,
                                  abstract: formattedAbstract,
                                  journalTitle: work.journalTitle,
                                  issn: widget.issn,
                                  publishedDate: work.publishedDate,
                                  doi: work.doi,
                                  authors: work.authors,
                                  url: work.primaryUrl,
                                  license: work.license,
                                  licenseName: work.licenseName,
                                  publisher: work.publisher,
                                );
                              }
                            },
                          );
                        } else {
                          return PublicationCard(
                            title: work.title,
                            abstract: cachedAbstract,
                            journalTitle: work.journalTitle,
                            issn: widget.issn,
                            publishedDate: work.publishedDate,
                            doi: work.doi,
                            authors: work.authors,
                            url: work.primaryUrl,
                            license: work.license,
                            licenseName: work.licenseName,
                            publisher: work.publisher,
                          );
                        }
                      } else if (hasMoreResults) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: allWorks.length + (hasMoreResults ? 1 : 0),
                  ),
                ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMoreResults) {
      _loadMoreWorks();
    }
  }

  Future<void> _loadMoreWorks() async {
    setState(() => isLoading = true);

    try {
      ListAndMore<journalsWorks.Item> newWorks =
          await CrossRefApi.getJournalWorks(widget.issn);

      setState(() {
        allWorks.addAll(newWorks.list);
        hasMoreResults = newWorks.hasMore && newWorks.list.isNotEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.failLoadMorePublication),
        ));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
