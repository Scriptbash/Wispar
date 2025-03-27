import 'package:flutter/material.dart';
import '../models/journal_entity.dart';
import '../models/crossref_journals_works_models.dart' as journalWorks;
import '../services/feed_api.dart';
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/publication_card.dart';

class FeedService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Gather journals that will need to have their articles fetched
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

  // Gather savedQueries that will need to have their articles fetched
  Future<List<Map<String, dynamic>>> checkSavedQueriesToUpdate(
      List<Map<String, dynamic>> savedQueries, int fetchIntervalInHours) async {
    List<Map<String, dynamic>> queriesToUpdate = [];

    for (var query in savedQueries) {
      String? lastFetched = query['lastFetched'] as String?;

      if (lastFetched == null ||
          lastFetched.isEmpty ||
          DateTime.now().difference(DateTime.parse(lastFetched)).inHours >=
              fetchIntervalInHours) {
        queriesToUpdate.add({
          'query_id': query['query_id'],
          'queryParams': query['queryParams'],
          'queryName': query['queryName'],
          'queryProvider': query['queryProvider'],
        });
      }
    }

    return queriesToUpdate;
  }

  Future<void> updateFeed(
      BuildContext context,
      List<Journal> followedJournals,
      void Function(String journalName) onJournalUpdate,
      int fetchIntervalInHours) async {
    try {
      // Check which journals need updating
      final journalsToUpdate =
          await checkJournalsToUpdate(followedJournals, fetchIntervalInHours);
      if (journalsToUpdate.isNotEmpty) {
        _dbHelper.cleanupOldArticles();
      }

      for (String issn in journalsToUpdate) {
        final journal = followedJournals.firstWhere((j) => j.issn == issn);

        // Notify the UI of the current journal being updated
        onJournalUpdate(journal.title);

        // Update journal's last updated time
        await _dbHelper.updateJournalLastUpdated(journal.issn);

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
              publisher: item.publisher,
            ),
            isCached: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating feed: $e');
    }
  }

  Future<void> updateSavedQueryFeed(
      BuildContext context,
      List<Map<String, dynamic>> savedQueries,
      void Function(String queryName) onQueryUpdate,
      int fetchIntervalInHours) async {
    try {
      // Check which queries need updating
      final queriesToUpdate =
          await checkSavedQueriesToUpdate(savedQueries, fetchIntervalInHours);
      List<journalWorks.Item> queryArticles;

      for (var query in queriesToUpdate) {
        debugPrint('Updating query: ${query['queryName']}');
        onQueryUpdate(query['queryName']);
        await _dbHelper.updateSavedQueryLastFetched(query['query_id']);
        String provider = query['queryProvider'];
        Map<String, dynamic> queryMap;
        if (provider == "Crossref") {
          queryMap = Uri.splitQueryString(query['queryParams']);
          queryArticles = await FeedApi.getSavedQueryWorks(queryMap);
        } else if (provider == "OpenAlex") {
          queryArticles =
              await FeedApi.getSavedQueryOpenAlex(query['queryParams']);
        } else {
          debugPrint("Unknown provider: $provider");
          continue;
        }
        for (journalWorks.Item item in queryArticles) {
          if (item.title.isNotEmpty && item.journalTitle.isNotEmpty) {
            await _dbHelper.insertArticle(
              PublicationCard(
                title: item.title,
                abstract: item.abstract,
                journalTitle: item.journalTitle,
                issn: item.issn,
                publishedDate: item.publishedDate,
                doi: item.doi,
                authors: item.authors,
                url: item.primaryUrl,
                license: item.license,
                licenseName: item.licenseName,
                publisher: item.publisher,
              ),
              isCached: true,
              isSavedQuery: true,
              queryId: query['query_id'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating saved queries feed: $e');
    }
  }

  Future<List<PublicationCard>> getCachedFeed(
      BuildContext context, VoidCallback? onAbstractChanged) async {
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
        onAbstractChanged: onAbstractChanged,
      );
    }).toList());
  }
}
