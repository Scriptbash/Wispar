import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../widgets/publication_card.dart';
import '../widgets/journal_header.dart';
import '../widgets/latest_works_header.dart';

class JournalDetailsScreen extends StatefulWidget {
  final String title;
  final String publisher;
  final String issn;

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
  bool waitingForMore = false;

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
              titlePadding: EdgeInsets.symmetric(horizontal: 50, vertical: 8.0),
              centerTitle: true,
              title: Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
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
              issn: widget.issn,
            ),
            pinned: false,
          ),
          SliverPersistentHeader(
            delegate: PersistentLatestPublicationsHeader(),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < allWorks.length) {
                  final work = allWorks[index];
                  final workTitle = work.title;
                  return PublicationCard(
                    title: workTitle,
                    abstract: work.abstract,
                    journalTitle: work.journalTitle,
                    issn: widget.issn,
                    publishedDate: work.publishedDate,
                    doi: work.doi,
                    authors: work.authors,
                    url: work.primaryUrl,
                    license: work.license,
                    licenseName: work.licenseName,
                  );
                } else {
                  return Container(); // Empty container for the loading indicator
                }
              },
              childCount: allWorks.length + (hasMoreResults ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  // Scroll Listener to detect when we're nearing the end of the list
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!isLoading && !waitingForMore) {
        _loadMoreWorks();
      }
    }
  }

  // Load more works from the API
  Future<void> _loadMoreWorks() async {
    try {
      setState(() {
        isLoading = true;
        waitingForMore = true;
      });

      // Fetch more works from the CrossRef API
      ListAndMore<journalsWorks.Item> newWorks =
          await CrossRefApi.getJournalWorks(widget.issn);

      setState(() {
        allWorks.addAll(newWorks.list);
        hasMoreResults = newWorks.hasMore;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading more items: $e');
      setState(() {
        isLoading = false;
      });
    } finally {
      // Reset the waitingForMore flag regardless of success or failure
      waitingForMore = false;
    }
  }
}
