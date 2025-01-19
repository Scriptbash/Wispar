import 'package:flutter/material.dart';
import '../models/journal_entity.dart';
import '../models/crossref_journals_works_models.dart' as journalWorks;
import '../services/feed_api.dart';
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/publication_card.dart';

class FeedService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<String>> checkJournalsToUpdate(
      List<Journal> followedJournals, int fetchIntervalInHours) async {
    final db = await _dbHelper.database;
    List<String> journalsToUpdate = [];

    for (Journal journal in followedJournals) {
      List<Map<String, dynamic>> result = await db.query(
        'journals',
        columns: ['issn', 'lastUpdated'],
        where: 'issn = ?',
        whereArgs: [journal.issn],
      );

      if (result.isNotEmpty) {
        String? lastUpdated = result.first['lastUpdated'] as String?;
        if (lastUpdated == null ||
            DateTime.now().difference(DateTime.parse(lastUpdated)).inHours >=
                fetchIntervalInHours) {
          journalsToUpdate.add(journal.issn);
        }
      }
    }

    return journalsToUpdate;
  }

  Future<void> updateFeed(BuildContext context, List<Journal> followedJournals,
      void Function(String journalName) onJournalUpdate) async {
    try {
      for (Journal journal in followedJournals) {
        // Notify the UI of the current journal being updated
        onJournalUpdate(journal.title);

        // Fetch recent feed from API
        List<journalWorks.Item> recentFeed =
            await FeedApi.getRecentFeed(journal.issn);

        // Cache the articles into the DB
        for (journalWorks.Item item in recentFeed) {
          await _dbHelper.insertArticle(
            PublicationCard(
              title: item.title,
              abstract: item.abstract,
              journalTitle: item.journalTitle,
              issn: journal.issn,
              publishedDate: item.publishedDate,
              doi: item.doi,
              authors: item.authors,
              url: item.primaryUrl,
              license: item.license,
              licenseName: item.licenseName,
            ),
            isCached: true,
          );
        }
        // Update journal's last updated time
        await _dbHelper.updateJournalLastUpdated(journal.issn);
      }
    } catch (e) {
      debugPrint('Error updating feed: $e');
    }
  }

  Future<List<PublicationCard>> getCachedFeed(BuildContext context) async {
    final cachedPublications = await _dbHelper.getCachedPublications();

    return Future.wait(cachedPublications.map((item) async {
      return PublicationCard(
        title: item.title,
        abstract: await AbstractHelper.buildAbstract(context, item.abstract),
        journalTitle: item.journalTitle,
        issn: item.issn,
        publishedDate: item.publishedDate,
        doi: item.doi,
        authors: item.authors,
        url: item.url,
        license: item.license,
        licenseName: item.licenseName,
      );
    }).toList());
  }
}
