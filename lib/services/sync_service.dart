import 'package:pocketbase/pocketbase.dart';
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

    return local.difference(pb).inSeconds > 1;
  }

  void triggerBackgroundSync() {
    if (pbService.isAuthenticated) {
      logger.info("Syncing in the background");
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 1), () {
        sync().catchError((e, stackTrace) =>
            logger.severe("Background sync failed.", e, stackTrace));
      });
    }
  }

  Future<void> sync() async {
    final pb = pbService.client;
    final userId = pb.authStore.record!.id;

    await _pullJournals(
      pb,
      userId,
    );
    await _pullJournalIssns(
      pb,
      userId,
    );
    await _pushJournals(pb, userId);
    await _pushJournalIssns(pb, userId);

    await dbHelper.setLastSync(DateTime.now().toIso8601String());
  }

  Future<void> _pullJournals(PocketBase pb, String userId) async {
    final db = await dbHelper.database;

    // Get all the user's journals
    final cloudRecords = await pb.collection('journals').getFullList(
          filter: 'user = "$userId"',
        );

    for (final r in cloudRecords) {
      final syncId = r.get<String>('sync_id');
      final pbUpdatedAt = DateTime.tryParse(r.get<String>('updated_at')) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateFollowedStr = r.get<String?>('date_followed');

      final journalData = {
        'title': r.get<String>('title', ''),
        'publisher': r.get<String>('publisher', ''),
        'dateFollowed': (dateFollowedStr == null || dateFollowedStr.isEmpty)
            ? null
            : dateFollowedStr,
        'sync_id': syncId,
        'is_deleted': (r.get<bool?>('is_deleted') ?? false) ? 1 : 0,
        'updated_at': r.get<String>('updated_at', ''),
      };

      final local = await db.query('journals',
          where: 'sync_id = ?', whereArgs: [syncId], limit: 1);

      if (local.isEmpty) {
        await dbHelper.syncJournalFromCloud(journalData);
      } else {
        final localUpdatedAt =
            DateTime.tryParse((local.first['updated_at'] as String?) ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        if (pbUpdatedAt.isAfter(localUpdatedAt)) {
          await dbHelper.syncJournalFromCloud(journalData);
        }
      }

      if (journalData['dateFollowed'] == null && local.isNotEmpty) {
        final localDateFollowed = local.first['dateFollowed'];

        if (localDateFollowed != null) {
          await dbHelper.removeJournalById(local.first['journal_id'] as int);
        }
      }
    }
  }

  Future<void> _pullJournalIssns(PocketBase pb, String userId) async {
    final db = await dbHelper.database;

    // Get the journal issn and the journal_id from the cloud
    final cloudIssns = await pb.collection('journal_issns').getFullList(
          filter: 'user = "$userId"',
          expand: 'journal_id',
        );

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

  Future<void> _pushJournals(PocketBase pb, String userId) async {
    final db = await dbHelper.database;
    final rows = await db.query('journals');

    // Get all cloud journal data
    final cloudRecords =
        await pb.collection('journals').getFullList(filter: 'user = "$userId"');
    final cloudMap = {for (var r in cloudRecords) r.get<String>('sync_id'): r};

    for (final j in rows) {
      final syncId = j['sync_id'];
      final existingCloud = cloudMap[syncId];
      final localDate = j['updated_at'] as String? ?? '';

      final data = {
        'journal_id': j['journal_id'],
        'title': j['title'],
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
        await pb.collection('journals').create(body: data);
      } else {
        final pbDate = existingCloud.data['updated_at'] as String? ?? '';

        if (_isNewer(localDate, pbDate)) {
          await pb.collection('journals').update(existingCloud.id, body: data);
        }
      }
    }
  }

  Future<void> _pushJournalIssns(PocketBase pb, String userId) async {
    final db = await dbHelper.database;
    final rows = await db.query('journal_issns');
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
}
