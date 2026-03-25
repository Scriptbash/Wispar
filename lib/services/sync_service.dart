import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/pocketbase_service.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/logs_helper.dart';
import 'dart:async';

class SyncManager {
  final PocketBaseService pbService = PocketBaseService();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final logger = LogsService().logger;
  Timer? _debounce;

  // Little function to compare the slightly rounded time,
  //otherwise patches are sent every sync when unnecessary
  bool _isNewer(String localStr, String pbStr) {
    final local = DateTime.tryParse(localStr)?.toUtc();
    final pb = DateTime.tryParse(pbStr)?.toUtc();

    if (local == null) return false;
    if (pb == null) return true;

    return local.difference(pb).inSeconds > 2;
  }

  Future<bool> isBackgroundSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('background_sync_enabled') ?? true;
  }

  void triggerBackgroundSync() async {
    if (!await isBackgroundSyncEnabled()) {
      return;
    }
    if (pbService.isAuthenticated) {
      logger.info("Syncing in the background");
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 1), () {
        sync(isFullSync: false).catchError((e, stackTrace) =>
            logger.severe("Background sync failed.", e, stackTrace));
      });
    }
  }

  Future<void> sync({bool isFullSync = true}) async {
    final pb = pbService.client;
    final userId = pb.authStore.record!.id;
    final lastSyncTime = isFullSync ? null : await dbHelper.getLastSync();

    await _pullJournals(pb, userId, lastSyncTime);
    await _pullJournalIssns(pb, userId, lastSyncTime);
    await _pushJournals(pb, userId, lastSyncTime);
    await _pushJournalIssns(pb, userId, lastSyncTime);

    await _pullSavedQueries(pb, userId, lastSyncTime);
    await _pushSavedQueries(pb, userId, lastSyncTime);

    await _pullArticles(pb, userId, lastSyncTime);
    await _pushArticles(pb, userId, lastSyncTime);

    await _pullFeedFilters(pb, userId, lastSyncTime);
    await _pushFeedFilters(pb, userId, lastSyncTime);

    await _pullKnownUrls(pb, userId, lastSyncTime);
    await _pushKnownUrls(pb, userId, lastSyncTime);

    await dbHelper.setLastSync(DateTime.now().toUtc().toIso8601String());
  }

  Future<void> _pullJournals(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    // Get all the user's journals
    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final formattedDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$formattedDate"';
    }

    final cloudRecords = await pb.collection('journals').getFullList(
          filter: filter,
        );

    if (cloudRecords.isEmpty) return;

    logger.info("Delta pull: Found ${cloudRecords.length} updated journals.");

    // I first get the issns to compare locally. If they already exist,
    // the local sync_id must be updated so the device match with the cloud
    final cloudIssns = await pb.collection('journal_issns').getFullList(
          filter: 'user = "$userId"',
        );

    for (final r in cloudRecords) {
      final cloudSyncId = r.get<String>('sync_id');
      final cloudTitle = r.get<String>('title');
      final pbUpdatedAt = r.get<String>('updated_at');
      final dateFollowedStr = r.get<String?>('date_followed');

      final journalData = {
        'title': cloudTitle,
        'publisher': r.get<String>('publisher', ''),
        'dateFollowed':
            (dateFollowedStr?.isEmpty ?? true) ? null : dateFollowedStr,
        'sync_id': cloudSyncId,
        'is_deleted': (r.get<bool?>('is_deleted') ?? false) ? 1 : 0,
        'updated_at': pbUpdatedAt,
      };

      // Check if sync_id match
      var local = await db.query('journals',
          where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);

      // If nothing matches the sync_id, try to match by title/issn
      if (local.isEmpty) {
        final titleMatches = await db.query('journals',
            where: 'LOWER(title) = ?', whereArgs: [cloudTitle.toLowerCase()]);

        for (final potentialMatch in titleMatches) {
          final localId = potentialMatch['journal_id'] as int;

          final localIssns = await db.query('journal_issns',
              where: 'journal_id = ?', whereArgs: [localId]);
          final localIssnSet =
              localIssns.map((i) => i['issn'] as String).toSet();

          final cloudIssnSet = cloudIssns
              .where((i) => i.get<String>('journal_id') == r.id)
              .map((i) => i.get<String>('issn'))
              .toSet();

          // If an issn match I merge them to avoid duplicates
          if (localIssnSet.intersection(cloudIssnSet).isNotEmpty) {
            logger.info(
                "Merging local journal ${potentialMatch['sync_id']} into cloud ID $cloudSyncId via ISSN match.");
            await db.update('journals', {'sync_id': cloudSyncId},
                where: 'journal_id = ?', whereArgs: [localId]);

            local = await db.query('journals',
                where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);
            break;
          }
        }
      }

      if (local.isEmpty) {
        await dbHelper.syncJournalFromCloud(journalData);
      } else {
        final localUpdatedAt = local.first['updated_at'] as String? ?? '';

        if (_isNewer(pbUpdatedAt, localUpdatedAt)) {
          await dbHelper.syncJournalFromCloud(journalData);

          if (journalData['dateFollowed'] == null &&
              local.first['dateFollowed'] != null) {
            await dbHelper.removeJournalById(local.first['journal_id'] as int);
          }
        }
      }
    }
  }

  Future<void> _pullJournalIssns(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final formattedDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$formattedDate"';
    }

    // Get the journal issn and the journal_id from the cloud
    final cloudIssns = await pb.collection('journal_issns').getFullList(
          filter: filter,
          expand: 'journal_id',
        );

    if (cloudIssns.isEmpty) return;

    for (final r in cloudIssns) {
      final syncId = r.get<String>('sync_id');

      final expandedJournal = r.get<RecordModel?>('expand.journal_id');
      if (expandedJournal == null) continue;
      final parentSyncId = expandedJournal.get<String>('sync_id');

      final localJournal = await db.query('journals',
          where: 'sync_id = ?', whereArgs: [parentSyncId], limit: 1);
      if (localJournal.isEmpty) continue;

      final journalData = {
        'issn': r.get<String>('issn', ''),
        'journal_id': localJournal.first['journal_id'] as int,
        'sync_id': syncId,
        'is_deleted': (r.get<bool?>('is_deleted') ?? false) ? 1 : 0,
        'updated_at': r.get<String>('updated_at', ''),
      };

      await dbHelper.syncJournalIssnFromCloud(journalData);
    }
  }

  Future<void> _pushJournals(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'journals',
      where: lastSync != null ? 'updated_at > ?' : null,
      whereArgs: lastSync != null ? [lastSync] : null,
    );

    if (rows.isEmpty) return;

    final cloudRecords =
        await pb.collection('journals').getFullList(filter: 'user = "$userId"');
    final cloudMap = {for (var r in cloudRecords) r.get<String>('sync_id'): r};

    for (final j in rows) {
      final title = j['title'] as String?;

      if (title == null || title.trim().isEmpty) {
        logger.warning(
            "Skipping push for journal ID ${j['journal_id']} due to empty title.");
        continue;
      }
      final syncId = j['sync_id'];
      final existingCloud = cloudMap[syncId];
      final localDate = j['updated_at'] as String? ?? '';
      final data = {
        'title': title,
        'journal_id': j['journal_id'],
        'publisher': j['publisher'] ?? '',
        'date_followed': (j['dateFollowed'] as String?)?.isNotEmpty == true
            ? j['dateFollowed']
            : null,
        'sync_id': syncId,
        'is_deleted': j['is_deleted'] == 1,
        'user': userId,
      };

      if (existingCloud == null) {
        // Journal doesn't exist in cloud -> Create it
        logger.info("Pushing new journal to cloud: ${data['title']}");
        await pb.collection('journals').create(body: data);
      } else {
        final pbDate = existingCloud.data['updated_at'] as String? ?? '';

        if (_isNewer(localDate, pbDate)) {
          logger.info("Pushing update for journal: ${data['title']}");
          await pb.collection('journals').update(existingCloud.id, body: data);
        }
      }
    }
  }

  Future<void> _pushJournalIssns(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'journal_issns',
      where: lastSync != null ? 'updated_at > ?' : null,
      whereArgs: lastSync != null ? [lastSync] : null,
    );

    if (rows.isEmpty) return;

    // Get all the issns data from cloud
    final cloudIssns = await pb
        .collection('journal_issns')
        .getFullList(filter: 'user = "$userId"');
    final cloudIssnMap = {
      for (var r in cloudIssns) r.get<String>('sync_id'): r
    };

    final cloudJournals =
        await pb.collection('journals').getFullList(filter: 'user = "$userId"');
    final journalSyncToPbId = {
      for (var r in cloudJournals) r.get<String>('sync_id'): r.id
    };

    for (final issn in rows) {
      final journalId = issn['journal_id'];
      final journal = await db.query('journals',
          where: 'journal_id = ?', whereArgs: [journalId], limit: 1);
      if (journal.isEmpty) continue;

      final journalSyncId = journal.first['sync_id'];
      final pbJournalRecordId = journalSyncToPbId[journalSyncId];
      if (pbJournalRecordId == null) continue;

      final data = {
        'issn': issn['issn'] ?? '',
        'journal_id': pbJournalRecordId,
        'sync_id': issn['sync_id'],
        'is_deleted': issn['is_deleted'] == 1,
        'user': userId,
      };
      // Create the issn in cloud
      final existingCloud = cloudIssnMap[issn['sync_id']];
      if (existingCloud == null) {
        await pb.collection('journal_issns').create(body: data);
      } else {
        final pbDate = existingCloud.data['updated_at'] as String? ?? '';
        final localDate = issn['updated_at'] as String? ?? '';

        if (_isNewer(localDate, pbDate)) {
          await pb
              .collection('journal_issns')
              .update(existingCloud.id, body: data);
        }
      }
    }
  }

  Future<void> _pullArticles(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final pbDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$pbDate"';
    }

    final cloudArticles = await pb.collection('articles').getFullList(
          filter: filter,
          expand: 'journal_id,query_id',
        );

    logger.info("Delta pull results: ${cloudArticles.length} articles found.");

    for (final r in cloudArticles) {
      final syncId = r.get<String>('sync_id');
      final cloudDoi = r.get<String>('doi', '');
      final pbUpdatedAt = r.get<String>('updated_at');

      final rawDateLiked = r.get<String?>('date_liked');
      final cloudDateLiked =
          (rawDateLiked?.isEmpty ?? true) ? null : rawDateLiked;
      final cloudIsHidden = r.get<bool>('is_hidden', false) ? 1 : 0;

      List<Map<String, Object?>> localMatches = await db.query(
        'articles',
        where: 'sync_id = ? OR (doi = ? AND doi != "")',
        whereArgs: [syncId, cloudDoi],
        limit: 1,
      );

      int? localJournalId;
      final expandedJournal = r.get<RecordModel?>('expand.journal_id');
      if (expandedJournal != null) {
        final res = await db.query('journals',
            where: 'sync_id = ?',
            whereArgs: [expandedJournal.get<String>('sync_id')],
            limit: 1);
        if (res.isNotEmpty) localJournalId = res.first['journal_id'] as int;
      }

      int? localQueryId;
      final expandedQuery = r.get<RecordModel?>('expand.query_id');
      if (expandedQuery != null) {
        final res = await db.query('savedQueries',
            where: 'sync_id = ?',
            whereArgs: [expandedQuery.get<String>('sync_id')],
            limit: 1);
        if (res.isNotEmpty) localQueryId = res.first['query_id'] as int;
      }

      final articleData = {
        'doi': cloudDoi,
        'title': r.get<String>('title', ''),
        'abstract': r.get<String>('abstract', ''),
        'authors': r.get<String>('authors', ''),
        'publishedDate': r.get<String>('published_date', ''),
        'url': r.get<String>('url', ''),
        'license': r.get<String>('license', ''),
        'licenseName': r.get<String>('license_name', ''),
        'isSavedQuery': r.get<bool>('is_saved_query', false) ? 1 : 0,
        'query_id': localQueryId,
        'dateLiked': cloudDateLiked,
        'isHidden': cloudIsHidden,
        'journal_id': localJournalId,
        'sync_id': syncId,
        'updated_at': pbUpdatedAt,
      };

      if (localMatches.isEmpty) {
        if (cloudDateLiked != null || cloudIsHidden == 1) {
          await db.insert('articles', articleData);
        }
      } else {
        final localRecord = localMatches.first;
        final localUpdatedAt = localRecord['updated_at'] as String? ?? '';
        final localSyncId = localRecord['sync_id'] as String?;

        if (localSyncId != syncId) {
          await db.update('articles', {'sync_id': syncId},
              where: 'doi = ? AND doi != ""', whereArgs: [cloudDoi]);
        }

        if (_isNewer(pbUpdatedAt, localUpdatedAt)) {
          await db.update(
            'articles',
            {
              'dateLiked': cloudDateLiked,
              'isHidden': cloudIsHidden,
              'updated_at': pbUpdatedAt,
              'journal_id': localJournalId,
              'query_id': localQueryId,
            },
            where: 'sync_id = ?',
            whereArgs: [syncId],
          );
          logger.info("Updated existing article: ${r.get<String>('title')}");
        }
      }
    }
  }

  Future<void> _pushArticles(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'articles',
      where: 'updated_at > ?',
      whereArgs: [lastSync ?? '1970-01-01T00:00:00Z'],
    );

    if (rows.isEmpty) return;

    final cloudJournals =
        await pb.collection('journals').getFullList(filter: 'user = "$userId"');
    final journalSyncToPbId = {
      for (var r in cloudJournals) r.get<String>('sync_id'): r.id
    };

    final cloudQueries = await pb
        .collection('saved_queries')
        .getFullList(filter: 'user = "$userId"');
    final querySyncToPbId = {
      for (var r in cloudQueries) r.get<String>('sync_id'): r.id
    };

    final cloudArticles =
        await pb.collection('articles').getFullList(filter: 'user = "$userId"');
    final cloudMap = {for (var r in cloudArticles) r.get<String>('sync_id'): r};

    for (final a in rows) {
      try {
        final syncId = a['sync_id'] as String;
        final existingCloud = cloudMap[syncId];
        final localDateLiked = a['dateLiked'] as String?;
        final localIsHidden = a['isHidden'] == 1;
        final isSavedQuery = a['isSavedQuery'] == 1;

        String? pbJournalRecordId;
        if (a['journal_id'] != null) {
          final journalRes = await db.query('journals',
              where: 'journal_id = ?', whereArgs: [a['journal_id']], limit: 1);
          if (journalRes.isNotEmpty) {
            pbJournalRecordId = journalSyncToPbId[journalRes.first['sync_id']];
          }
        }

        String? pbQueryRecordId;
        if (isSavedQuery && a['query_id'] != null) {
          final queryRes = await db.query('savedQueries',
              where: 'query_id = ?', whereArgs: [a['query_id']], limit: 1);
          if (queryRes.isNotEmpty) {
            pbQueryRecordId = querySyncToPbId[queryRes.first['sync_id']];
          }
        }

        if (existingCloud == null) {
          if (localDateLiked == null && !localIsHidden) {
            continue;
          }

          final data = {
            'doi': a['doi'] ?? '',
            'title': a['title'] ?? '',
            'abstract': a['abstract'] ?? '',
            'authors': a['authors'] ?? '',
            'published_date': a['publishedDate'] ?? '',
            'url': a['url'] ?? '',
            'license': a['license'] ?? '',
            'license_name': a['licenseName'] ?? '',
            'is_saved_query': isSavedQuery,
            'date_liked': localDateLiked,
            'is_hidden': localIsHidden,
            'sync_id': syncId,
            'user': userId,
            'journal_id': pbJournalRecordId,
            'query_id': pbQueryRecordId,
          };
          await pb.collection('articles').create(body: data);
          logger.info("Created new article in cloud: ${a['title']}");
        } else {
          final pbUpdatedAt = existingCloud.data['updated_at'] as String? ?? '';
          final localUpdatedAt = a['updated_at'] as String? ?? '';

          if (_isNewer(localUpdatedAt, pbUpdatedAt)) {
            await pb.collection('articles').update(existingCloud.id, body: {
              'date_liked': localDateLiked,
              'is_hidden': localIsHidden,
              if (pbJournalRecordId != null) 'journal_id': pbJournalRecordId,
              if (pbQueryRecordId != null) 'query_id': pbQueryRecordId,
              'is_saved_query': isSavedQuery,
            });
            logger.info(
                "Pushed article update: $syncId (Hidden: $localIsHidden, Liked: $localDateLiked)");
          }
        }
      } catch (e) {
        logger.warning("Failed to push article ${a['sync_id']}: $e");
      }
    }
  }

  Future<void> _pullFeedFilters(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final pbDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$pbDate"';
    }

    final cloudRecords = await pb.collection('feed_filters').getFullList(
          filter: filter,
        );

    if (cloudRecords.isEmpty) return;

    logger
        .info("Delta pull: Found ${cloudRecords.length} updated feed filters.");

    for (final r in cloudRecords) {
      final cloudSyncId = r.get<String>('sync_id');
      final cloudName = r.get<String>('name');
      final pbUpdatedAt = r.get<String>('updated_at');

      final filterData = {
        'name': cloudName,
        'includedKeywords': r.get<String?>('included_keywords'),
        'excludedKeywords': r.get<String?>('excluded_keywords'),
        'journals': r.get<String?>('journals'),
        'date_mode': r.get<String?>('date_mode'),
        'date_after': r.get<String?>('date_after'),
        'date_before': r.get<String?>('date_before'),
        'dateCreated': r.get<String>('date_created'),
        'sync_id': cloudSyncId,
        'is_deleted': r.get<bool>('is_deleted') ? 1 : 0,
        'updated_at': pbUpdatedAt,
      };

      var local = await db.query('feed_filters',
          where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);

      if (local.isEmpty) {
        final nameMatches = await db.query(
          'feed_filters',
          where: 'LOWER(name) = ?',
          whereArgs: [cloudName.toLowerCase()],
          limit: 1,
        );

        if (nameMatches.isNotEmpty) {
          final localId = nameMatches.first['id'];
          logger.info(
              "Merging local filter '$cloudName' into cloud sync_id: $cloudSyncId via name match.");
          await db.update('feed_filters', {'sync_id': cloudSyncId},
              where: 'id = ?', whereArgs: [localId]);

          local = await db.query('feed_filters',
              where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);
        }
      }

      if (local.isEmpty) {
        if (filterData['is_deleted'] == 0) {
          await db.insert('feed_filters', filterData);
          logger.info("Inserted new feed filter: ${filterData['name']}");
        }
      } else {
        final localUpdatedAt = local.first['updated_at'] as String? ?? '';

        if (_isNewer(pbUpdatedAt, localUpdatedAt)) {
          await db.update('feed_filters', filterData,
              where: 'sync_id = ?', whereArgs: [cloudSyncId]);
          logger.info("Updated feed filter: ${filterData['name']}");
        }
      }
    }
  }

  Future<void> _pushFeedFilters(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'feed_filters',
      where: lastSync != null ? 'updated_at > ?' : null,
      whereArgs: lastSync != null ? [lastSync] : null,
    );

    if (rows.isEmpty) return;

    final cloudRecords = await pb.collection('feed_filters').getFullList(
          filter: 'user = "$userId"',
        );
    final cloudMap = {for (var r in cloudRecords) r.get<String>('sync_id'): r};

    for (final f in rows) {
      final syncId = f['sync_id'] as String;
      final existingCloud = cloudMap[syncId];
      final localUpdatedAt = f['updated_at'] as String? ?? '';

      final data = {
        'name': f['name'],
        'included_keywords': f['includedKeywords'],
        'excluded_keywords': f['excludedKeywords'],
        'journals': f['journals'],
        'date_mode': f['date_mode'],
        'date_after': f['date_after'],
        'date_before': f['date_before'],
        'date_created': f['dateCreated'],
        'sync_id': syncId,
        'is_deleted': f['is_deleted'] == 1,
        'user': userId,
      };

      if (existingCloud == null) {
        logger.info("Pushing new feed filter to cloud: ${data['name']}");
        await pb.collection('feed_filters').create(body: data);
      } else {
        final pbUpdatedAt = existingCloud.get<String>('updated_at');
        if (_isNewer(localUpdatedAt, pbUpdatedAt)) {
          logger.info("Pushing update for feed filter: ${data['name']}");
          await pb
              .collection('feed_filters')
              .update(existingCloud.id, body: data);
        }
      }
    }
  }

  Future<void> _pullKnownUrls(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final pbDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$pbDate"';
    }

    final cloudRecords = await pb.collection('known_urls').getFullList(
          filter: filter,
        );

    if (cloudRecords.isEmpty) return;

    logger.info("Delta pull: Found ${cloudRecords.length} updated known URLs.");

    for (final r in cloudRecords) {
      final cloudSyncId = r.get<String>('sync_id');
      final cloudUrl = r.get<String>('url');
      final pbUpdatedAt = r.get<String>('updated_at');

      final urlData = {
        'url': cloudUrl,
        'proxySuccess': r.get<int>('proxy_success', 0),
        'sync_id': cloudSyncId,
        'is_deleted': r.get<bool>('is_deleted') ? 1 : 0,
        'updated_at': pbUpdatedAt,
      };

      if (r.get<bool>('is_deleted')) {
        await db.update(
          'knownUrls',
          {'is_deleted': 1, 'updated_at': pbUpdatedAt},
          where: 'sync_id = ? AND is_deleted = 0',
          whereArgs: [cloudSyncId],
        );
        continue;
      }

      // Similar to the others, checks for existing URLs, if there are
      // their local sync_id is updated with the cloud value to merge them and
      // avoid duplicates
      var local = await db.query('knownUrls',
          where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);

      if (local.isEmpty) {
        final urlMatches = await db.query(
          'knownUrls',
          where: 'url = ?',
          whereArgs: [cloudUrl],
          limit: 1,
        );

        if (urlMatches.isNotEmpty) {
          final localId = urlMatches.first['id'];
          logger.info(
              "Merging local URL for '$cloudUrl' into cloud sync_id: $cloudSyncId");

          await db.update(
            'knownUrls',
            {'sync_id': cloudSyncId},
            where: 'id = ?',
            whereArgs: [localId],
          );

          local = await db.query('knownUrls',
              where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);
        }
      }

      if (local.isEmpty) {
        await db.insert('knownUrls', urlData);
        logger.info("Inserted new known URL: ${urlData['url']}");
      } else {
        final localUpdatedAt = local.first['updated_at'] as String? ?? '';
        if (_isNewer(pbUpdatedAt, localUpdatedAt)) {
          await db.update('knownUrls', urlData,
              where: 'sync_id = ?', whereArgs: [cloudSyncId]);
        }
      }
    }
  }

  Future<void> _pushKnownUrls(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'knownUrls',
      where: lastSync != null ? 'updated_at > ?' : null,
      whereArgs: lastSync != null ? [lastSync] : null,
    );

    if (rows.isEmpty) return;

    final cloudRecords = await pb.collection('known_urls').getFullList(
          filter: 'user = "$userId"',
        );
    final cloudMap = {for (var r in cloudRecords) r.get<String>('sync_id'): r};

    for (final row in rows) {
      final syncId = row['sync_id'] as String;
      final existingCloud = cloudMap[syncId];
      final localUpdatedAt = row['updated_at'] as String? ?? '';

      final data = {
        'url': row['url'],
        'proxy_success': row['proxySuccess'],
        'sync_id': syncId,
        'is_deleted': row['is_deleted'] == 1,
        'user': userId,
      };

      if (existingCloud == null) {
        logger.info("Pushing new known URL: ${data['url']}");
        await pb.collection('known_urls').create(body: data);
      } else {
        final pbUpdatedAt = existingCloud.get<String>('updated_at');
        if (_isNewer(localUpdatedAt, pbUpdatedAt)) {
          logger.info("Pushing update for known URL: ${data['url']}");
          await pb
              .collection('known_urls')
              .update(existingCloud.id, body: data);
        }
      }
    }
  }

  Future<void> _pullSavedQueries(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    String filter = 'user = "$userId"';
    if (lastSync != null) {
      final pbDate = lastSync.replaceAll('T', ' ').substring(0, 19);
      filter += ' && updated_at > "$pbDate"';
    }

    final cloudRecords = await pb.collection('saved_queries').getFullList(
          filter: filter,
        );

    if (cloudRecords.isEmpty) return;

    logger.info(
        "Delta pull: Found ${cloudRecords.length} updated saved queries.");

    for (final r in cloudRecords) {
      final cloudSyncId = r.get<String>('sync_id');
      final pbUpdatedAt = r.get<String>('updated_at');

      final queryData = {
        'queryName': r.get<String>('query_name'),
        'queryParams': r.get<String>('query_params'),
        'dateSaved': r.get<String?>('date_saved'),
        'includeInFeed': r.get<bool>('include_in_feed') ? 1 : 0,
        'queryProvider': r.get<String>('query_provider'),
        'sync_id': cloudSyncId,
        'is_deleted': r.get<bool>('is_deleted') ? 1 : 0,
        'updated_at': pbUpdatedAt,
      };

      var local = await db.query('savedQueries',
          where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);

      if (local.isEmpty) {
        final match = await db.query(
          'savedQueries',
          where: 'queryName = ? AND queryParams = ?',
          whereArgs: [queryData['queryName'], queryData['queryParams']],
          limit: 1,
        );

        if (match.isNotEmpty) {
          logger.info(
              "Merging local query '${queryData['queryName']}' into cloud sync_id: $cloudSyncId");
          await db.update('savedQueries', {'sync_id': cloudSyncId},
              where: 'query_id = ?', whereArgs: [match.first['query_id']]);

          local = await db.query('savedQueries',
              where: 'sync_id = ?', whereArgs: [cloudSyncId], limit: 1);
        }
      }

      if (local.isEmpty) {
        if (queryData['is_deleted'] == 0) {
          await db.insert('savedQueries', queryData);
          logger.info("Inserted new saved query: ${queryData['queryName']}");
        }
      } else {
        final localUpdatedAt = local.first['updated_at'] as String? ?? '';

        if (_isNewer(pbUpdatedAt, localUpdatedAt)) {
          await db.update('savedQueries', queryData,
              where: 'sync_id = ?', whereArgs: [cloudSyncId]);
          logger.info("Updated saved query: ${queryData['queryName']}");
        }
      }
    }
  }

  Future<void> _pushSavedQueries(
      PocketBase pb, String userId, String? lastSync) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'savedQueries',
      where: lastSync != null ? 'updated_at > ?' : null,
      whereArgs: lastSync != null ? [lastSync] : null,
    );

    if (rows.isEmpty) return;

    final cloudRecords = await pb.collection('saved_queries').getFullList(
          filter: 'user = "$userId"',
        );
    final cloudMap = {for (var r in cloudRecords) r.get<String>('sync_id'): r};

    for (final row in rows) {
      final syncId = row['sync_id'] as String;
      final existingCloud = cloudMap[syncId];
      final localUpdatedAt = row['updated_at'] as String? ?? '';

      final data = {
        'query_name': row['queryName'],
        'query_params': row['queryParams'],
        'date_saved': row['dateSaved'],
        'include_in_feed': row['includeInFeed'] == 1,
        'query_provider': row['queryProvider'],
        'sync_id': syncId,
        'is_deleted': row['is_deleted'] == 1,
        'user': userId,
      };

      if (existingCloud == null) {
        logger.info("Pushing new saved query: ${data['query_name']}");
        await pb.collection('saved_queries').create(body: data);
      } else {
        final pbUpdatedAt = existingCloud.get<String>('updated_at');
        if (_isNewer(localUpdatedAt, pbUpdatedAt)) {
          logger.info("Pushing update for saved query: ${data['query_name']}");
          await pb
              .collection('saved_queries')
              .update(existingCloud.id, body: data);
        }
      }
    }
  }
}
