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
      appBar: AppBar(
        title: Text('Journal Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: $title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            Text('Publisher: $publisher'),
            Text('ISSN: $issn'),
            Text('Subjects: ${subjects.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
