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
  late Future<ListAndMore<journalsWorks.Item>> journalWorksFuture;

  @override
  void initState() {
    super.initState();
    // Call the API when the widget is initialized
    journalWorksFuture = CrossRefApi.getJournalWorks(widget.issn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
          FutureBuilder<ListAndMore<journalsWorks.Item>>(
            future: journalWorksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                print('Error loading journal works: ${snapshot.error}');
                return SliverToBoxAdapter(
                  child: Text('Error loading journal works'),
                );
              } else if (!snapshot.hasData || snapshot.data!.list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Text('No journal works available'),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final work = snapshot.data!.list[index];
                      final workTitle = work.title;
                      return PublicationCard(
                        title: workTitle,
                        abstract: work.abstract,
                      );
                    },
                    childCount: snapshot.data!.list.length,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
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
