import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../publication_card.dart';

class JournalDetailsScreen extends StatefulWidget {
  final String title;
  final String publisher;
  final String issn;
  final List<String> subjects;

  const JournalDetailsScreen({
    Key? key,
    required this.title,
    required this.publisher,
    required this.issn,
    required this.subjects,
  }) : super(key: key);

  @override
  _JournalDetailsScreenState createState() => _JournalDetailsScreenState();
}

class _JournalDetailsScreenState extends State<JournalDetailsScreen> {
  late List<journalsWorks.Item> allWorks;
  bool isLoading = false;
  late ScrollController _scrollController;
  bool hasMoreResults = true;
  bool reachedEnd = false;
  bool waitingForMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    allWorks = [];
    CrossRefApi.resetCursor();
    loadMoreWorks();
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
                overflow: TextOverflow.fade,
              ),
            ),
            backgroundColor: Colors.deepPurple,
          ),
          SliverPersistentHeader(
            delegate: JournalInfoHeader(
              publisher: widget.publisher,
              issn: widget.issn,
              subjects: widget.subjects,
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
                    publishedDate: work.publishedDate,
                    doi: work.doi,
                    authors: work.authors,
                  );
                } else {
                  return Container();
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
    if (hasMoreResults &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      if (!isLoading && !waitingForMore) {
        loadMoreWorks();
      }
    }
  }

  Future<void> loadMoreWorks() async {
    try {
      setState(() {
        isLoading = true;
        waitingForMore = true;
      });

      if (reachedEnd) {
        // Clear the flag if we are making a new API call
        reachedEnd = false;
      }

      ListAndMore<journalsWorks.Item> newWorks =
          await CrossRefApi.getJournalWorks(widget.issn);

      setState(() {
        allWorks.addAll(newWorks.list);
        hasMoreResults = newWorks.hasMore;
        hasMoreResults = newWorks.hasMore && newWorks.list.length >= 25;
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

class JournalInfoHeader extends SliverPersistentHeaderDelegate {
  final String publisher;
  final String issn;
  final List<String> subjects;

  JournalInfoHeader({
    required this.publisher,
    required this.issn,
    required this.subjects,
  });

  @override
  double get maxExtent => 120.0;

  @override
  double get minExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            Text('Publisher: $publisher'),
            Text('ISSN: $issn'),
            Text('Subjects: ${subjects.join(', ')}'),
            SizedBox(height: 8.0),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(
                horizontal: 60,
              ),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class PersistentLatestPublicationsHeader
    extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 40.0;

  @override
  double get minExtent => 40.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Text(
          'Latest publications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
