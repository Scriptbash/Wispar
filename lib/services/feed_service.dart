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
  Future<List<int>> checkJournalsToUpdate(
      List<Journal> followedJournals, int fetchIntervalInHours) async {
    final db = await _dbHelper.database;
    List<int> journalsToUpdate = [];

    for (Journal journal in followedJournals) {
      try {
        final journalId = await _dbHelper.getJournalIdByIssns(journal.issn);

        if (journalId != null) {
          List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT journals.lastUpdated
        FROM journals
        WHERE journals.journal_id = ?
      ''', [journalId]);

          if (result.isNotEmpty) {
            String? lastUpdated = result.first['lastUpdated'] as String?;
            if (lastUpdated == null ||
                DateTime.now()
                        .difference(DateTime.parse(lastUpdated))
                        .inHours >=
                    fetchIntervalInHours) {
              journalsToUpdate.add(journalId);
            }
          } else {
            debugPrint('No journal found for journal_id: $journalId');
          }
        } else {
          debugPrint('No journalId found for ISSN: ${journal.issn}');
        }
      } catch (e) {
        debugPrint('Error retrieving journal_id for ISSN ${journal.issn}: $e');
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
    List<Journal> followedJournals,
    void Function(List<String> journalNames) onJournalUpdate,
    int fetchIntervalInHours,
    int maxConcurrentUpdates,
  ) async {
    try {
      // Check which journals need updating
      final journalsToUpdate =
          await checkJournalsToUpdate(followedJournals, fetchIntervalInHours);
      if (journalsToUpdate.isNotEmpty) {
        _dbHelper.cleanupOldArticles();
      }

      for (int i = 0; i < journalsToUpdate.length; i += maxConcurrentUpdates) {
        final batch = journalsToUpdate.sublist(
            i,
            (i + maxConcurrentUpdates) > journalsToUpdate.length
                ? journalsToUpdate.length
                : i + maxConcurrentUpdates);

        // Collect all journal names for the current batch
        List<String> journalNamesToUpdate =
            await Future.wait(batch.map((journalIdInBatch) async {
          final journalTitle =
              await _dbHelper.getJournalTitleById(journalIdInBatch);
          return journalTitle ?? 'Unknown Journal';
        }).toList());

        // Notify the UI with the list of journal names
        onJournalUpdate(journalNamesToUpdate);

        await Future.wait(batch.map((journalIdInBatch) async {
          final journalIssns =
              await _dbHelper.getIssnsByJournalId(journalIdInBatch);
          final journal = followedJournals.firstWhere(
            (j) => journalIssns.any((issn) => j.issn.contains(issn)),
          );
          final journalTitle =
              await _dbHelper.getJournalTitleById(journalIdInBatch);
          await _dbHelper.updateJournalLastUpdated(journalIdInBatch);

          List<journalWorks.Item> recentFeed =
              await FeedApi.getRecentFeed(journal.issn);

          // Cache the articles into the DB
          for (journalWorks.Item item in recentFeed) {
            await _dbHelper.insertArticle(
              PublicationCard(
                title: item.title,
                abstract: item.abstract,
                journalTitle: journalTitle ?? 'Unknown Journal',
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
        }));
      }
    } catch (e) {
      debugPrint('Error updating feed: $e');
    }
  }

  Future<void> updateSavedQueryFeed(
      List<Map<String, dynamic>> savedQueries,
      void Function(List<String> queryNames) onQueryUpdate,
      int fetchIntervalInHours,
      int maxConcurrentUpdates) async {
    try {
      // Check which queries need updating
      final queriesToUpdate =
          await checkSavedQueriesToUpdate(savedQueries, fetchIntervalInHours);

      if (queriesToUpdate.isNotEmpty) {
        // Loop through the queries in batches
        for (int i = 0; i < queriesToUpdate.length; i += maxConcurrentUpdates) {
          final batch = queriesToUpdate.sublist(
              i,
              (i + maxConcurrentUpdates) > queriesToUpdate.length
                  ? queriesToUpdate.length
                  : i + maxConcurrentUpdates);

          // Collect all the query names for the current batch
          List<String> queryNamesToUpdate =
              batch.map((query) => query['queryName'] as String).toList();

          // Notify the UI with the list of query names
          onQueryUpdate(queryNamesToUpdate);

          await Future.wait(batch.map((query) async {
            // Update saved query's last fetched time
            await _dbHelper.updateSavedQueryLastFetched(query['query_id']);

            String provider = query['queryProvider'];
            List<journalWorks.Item> queryArticles = [];

            if (provider == "Crossref") {
              Map<String, dynamic> queryMap =
                  Uri.splitQueryString(query['queryParams']);
              queryArticles = await FeedApi.getSavedQueryWorks(queryMap);
            } else if (provider == "OpenAlex") {
              queryArticles =
                  await FeedApi.getSavedQueryOpenAlex(query['queryParams']);
            } else {
              debugPrint("Unknown provider: $provider");
              return;
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
          }));
        }
      }
    } catch (e) {
      debugPrint('Error updating saved queries feed: $e');
    }
  }
}
