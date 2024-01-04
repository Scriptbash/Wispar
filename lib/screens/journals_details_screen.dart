import 'package:flutter/material.dart';

class JournalDetailsScreen extends StatelessWidget {
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
                '$title',
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
              publisher: publisher,
              issn: issn,
              subjects: subjects,
            ),
            pinned: false,
          ),
          SliverPersistentHeader(
            delegate: PersistentLatestPublicationsHeader(),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
                ListTile(
                  title: Text('Latest Publication 1'),
                ),
                ListTile(
                  title: Text('Latest Publication 2'),
                ),
              ],
            ),
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
