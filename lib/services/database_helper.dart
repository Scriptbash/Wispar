import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:wispar/models/crossref_journals_works_models.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/widgets/downloaded_card.dart';
import 'package:wispar/models/journal_entity.dart';
import 'package:wispar/models/feed_filter_entity.dart';
import 'package:wispar/services/string_format_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const platform = MethodChannel('app.wispar.wispar/database_access');

  static Future<String?> resolveBookmarkPath(String? path) async {
    if (path == null) return null;

    if (Platform.isIOS) {
      try {
        final resolvedPath =
            await platform.invokeMethod('resolveCustomPath', path);
        return resolvedPath;
      } catch (e) {
        return null;
      }
    } else {
      return path;
    }
  }

  static Database? _database;
  final logger = LogsService().logger;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<String> getDbPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('customDatabasePath');
    String? bookmark = prefs.getString('customDatabaseBookmark');

    if (Platform.isIOS && bookmark != null) {
      final resolved = await resolveBookmarkPath(bookmark);
      if (resolved != null) customPath = resolved;
    }
    String defaultPath = await getDatabasesPath();
    if (Platform.isWindows) {
      final dir = await getApplicationSupportDirectory();
      defaultPath = dir.path;
    }
    final databasePath = join(customPath ?? defaultPath, 'wispar.db');
    return databasePath;
  }

  Future<Database> initDatabase() async {
    String databasePath = await getDbPath();

    return openDatabase(databasePath, version: 10, onOpen: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON');

      // Create the journals table
      await db.execute('''
        CREATE TABLE journals (
          journal_id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          publisher TEXT,
          dateFollowed TEXT,
          lastUpdated TEXT,
          sync_id TEXT UNIQUE NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
      // Create the journal_issns table
      await db.execute('''
       CREATE TABLE journal_issns (
          issn TEXT PRIMARY KEY,
          journal_id INTEGER,
          sync_id TEXT UNIQUE UNIQUE NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
        )
      ''');

      // Create the 'articles' table
      await db.execute('''
        CREATE TABLE articles (
          article_id INTEGER PRIMARY KEY AUTOINCREMENT,
          doi TEXT,
          title TEXT,
          translatedTitle TEXT,
          abstract TEXT,
          translatedAbstract TEXT,
          publishedDate TEXT,  
          authors TEXT,
          url TEXT,
          license TEXT,
          licenseName TEXT,
          dateLiked TEXT,
          dateDownloaded TEXT,
          pdfPath TEXT,
          dateCached TEXT,
          isSavedQuery INTEGER,
          isHidden INTEGER,
          query_id INTEGER,
          graphAbstractPath,
          journal_id,
          sync_id TEXT UNIQUE UNIQUE NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
        )
      ''');

      // Create the table for saved queries
      await db.execute('''
        CREATE TABLE savedQueries (
          query_id INTEGER PRIMARY KEY AUTOINCREMENT,
          queryName TEXT,
          queryParams TEXT,
          dateSaved TEXT,
          includeInFeed INTEGER,
          lastFetched TEXT,
          queryProvider TEXT,
          sync_id TEXT UNIQUE NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // Create the feed filters table
      await db.execute('''
        CREATE TABLE feed_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        includedKeywords TEXT,
        excludedKeywords TEXT,
        journals TEXT,
        date_mode TEXT,
        date_after TEXT,
        date_before TEXT,
        dateCreated TEXT DEFAULT CURRENT_TIMESTAMP,
        sync_id TEXT UNIQUE NOT NULL,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0
      )
      ''');

      await db.execute('''
        CREATE TABLE knownUrls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT,
          proxySuccess INTEGER,
          sync_id TEXT UNIQUE NOT NULL,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      logger.info("Upgrading DB from $oldVersion to $newVersion");
      await db.execute('PRAGMA foreign_keys = ON');
      if (oldVersion < 2) {
        // Ads the new column to the savedQueries table
        await db.execute('''
        ALTER TABLE savedQueries ADD COLUMN includeInFeed INTEGER;
      ''');
        await db.execute('''
        ALTER TABLE savedQueries ADD COLUMN lastFetched TEXT;
      ''');
        await db.execute('''
        ALTER TABLE articles ADD COLUMN isSavedQuery INTEGER;
      ''');
        await db.execute('''
        ALTER TABLE articles ADD COLUMN query_id INTEGER;
      ''');
      }
      if (oldVersion < 3) {
        List<Map<String, dynamic>> articles =
            await db.rawQuery('SELECT article_id, pdfPath FROM articles');
        for (var article in articles) {
          String pdfPath = article['pdfPath'] ?? '';
          String filename = pdfPath.split('/').last;
          await db.rawUpdate(
              'UPDATE articles SET pdfPath = ? WHERE article_id = ?',
              [filename, article['article_id']]);
        }
        await db.execute('''
        ALTER TABLE savedQueries ADD COLUMN queryProvider TEXT;
      ''');
        await db.rawUpdate('''
      UPDATE savedQueries SET queryProvider = 'Crossref';
      ''');
      }
      if (oldVersion < 4) {
        await db.execute('''
        CREATE TABLE journal_issns (
          issn TEXT PRIMARY KEY,
          journal_id INTEGER,
           FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
        );
        ''');

        // Migrate existing ISSNs
        final journals = await db.query('journals');
        for (final journal in journals) {
          final issn = journal['issn'];
          final journalId = journal['journal_id'];
          if (issn != null) {
            await db.insert('journal_issns', {
              'issn': issn,
              'journal_id': journalId,
            });
          }
        }

        // I should probably drop the issn column from the journals table
      }
      if (oldVersion < 5) {
        await db.execute('''
        ALTER TABLE articles ADD COLUMN isHidden INTEGER;
      ''');
      }
      if (oldVersion < 6) {
        await db.execute('''
        CREATE TABLE feed_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        includedKeywords TEXT,
        excludedKeywords TEXT,
        journals TEXT,
        dateCreated TEXT DEFAULT CURRENT_TIMESTAMP
      )
      ''');

        final List<Map<String, dynamic>> articles =
            await db.query('articles', columns: ['doi', 'title', 'abstract']);

        for (final article in articles) {
          final String doi = article['doi'];
          final String? rawTitle = article['title'];
          final String? rawAbstract = article['abstract'];

          String? cleanedTitle = rawTitle != null ? cleanTitle(rawTitle) : null;
          String? cleanedAbstract =
              rawAbstract != null ? cleanAbstract(rawAbstract) : null;

          await db.update(
            'articles',
            {
              if (cleanedTitle != null) 'title': cleanedTitle,
              if (cleanedAbstract != null) 'abstract': cleanedAbstract,
            },
            where: 'doi = ?',
            whereArgs: [doi],
          );
        }
      }
      if (oldVersion < 7) {
        await db.execute('''
         ALTER TABLE articles ADD COLUMN translatedTitle TEXT;
        ''');
        await db.execute('''
        ALTER TABLE articles ADD COLUMN translatedAbstract TEXT;
      ''');
      }
      if (oldVersion < 8) {
        await db.execute('''
        CREATE TABLE knownUrls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT,
          proxySuccess INTEGER
        )
      ''');
      }
      if (oldVersion < 9) {
        await db.execute('''
        ALTER TABLE articles ADD COLUMN graphAbstractPath TEXT;
      ''');
      }
      if (oldVersion < 10) {
        await db.execute('''
          ALTER TABLE feed_filters ADD COLUMN date_mode TEXT;
        ''');
        await db.execute('''
          ALTER TABLE feed_filters ADD COLUMN date_after TEXT;
        ''');
        await db.execute('''
          ALTER TABLE feed_filters ADD COLUMN date_before TEXT;
        ''');
        await db.execute('ALTER TABLE journals ADD COLUMN sync_id TEXT;');
        await db.execute('ALTER TABLE journals ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE journals ADD COLUMN is_deleted INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE journal_issns ADD COLUMN sync_id TEXT;');
        await db
            .execute('ALTER TABLE journal_issns ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE journal_issns ADD COLUMN is_deleted INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE articles ADD COLUMN sync_id TEXT;');
        await db.execute('ALTER TABLE articles ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE articles ADD COLUMN is_deleted INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE savedQueries ADD COLUMN sync_id TEXT;');
        await db
            .execute('ALTER TABLE savedQueries ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE savedQueries ADD COLUMN is_deleted INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE feed_filters ADD COLUMN sync_id TEXT;');
        await db
            .execute('ALTER TABLE feed_filters ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE feed_filters ADD COLUMN is_deleted INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE knownUrls ADD COLUMN sync_id TEXT;');
        await db.execute('ALTER TABLE knownUrls ADD COLUMN updated_at TEXT;');
        await db.execute(
            'ALTER TABLE knownUrls ADD COLUMN is_deleted INTEGER DEFAULT 0;');

        // Initialize sync_ids for existing rows
        Future<void> initSyncIds(String table, String pk) async {
          final rows = await db.query(table);
          for (final row in rows) {
            await db.update(
                table,
                {
                  'sync_id': Uuid().v7(),
                  'updated_at': DateTime.fromMillisecondsSinceEpoch(0)
                      .toUtc()
                      .toIso8601String(),
                },
                where: '$pk = ?',
                whereArgs: [row[pk]]);
          }
        }

        await initSyncIds('journals', 'journal_id');
        await initSyncIds('journal_issns', 'issn');
        await initSyncIds('articles', 'article_id');
        await initSyncIds('savedQueries', 'query_id');
        await initSyncIds('feed_filters', 'id');
        await initSyncIds('knownUrls', 'id');

        try {
          await db.execute("ALTER TABLE journals DROP COLUMN issn");
        } catch (e) {
          logger.info('Unable to drop the issn column in the journals table');
        }
        await db.delete('journals', where: 'title IS NULL OR TRIM(title) = ""');
        int deletedInvalidIssns = await db.delete('journal_issns',
            where: 'issn IS NULL OR TRIM(issn) = ""');

        logger.info(
            "Deleted $deletedInvalidIssns invalid ISSN records with empty keys.");

        // Merge duplicated journals
        final List<Map<String, dynamic>> allJournals =
            await db.query('journals');
        final Set<int> processedIds = {};

        for (var j in allJournals) {
          int currentId = j['journal_id'] as int;
          if (processedIds.contains(currentId)) continue;

          String currentTitle =
              (j['title'] ?? "").toString().toLowerCase().trim();
          String currentPub =
              (j['publisher'] ?? "").toString().toLowerCase().trim();
          if (currentTitle.isEmpty) continue;

          final List<Map<String, dynamic>> siblings = await db.query(
            'journals',
            where: 'LOWER(TRIM(title)) = ? AND journal_id != ?',
            whereArgs: [currentTitle, currentId],
          );

          for (var sibling in siblings) {
            int sibId = sibling['journal_id'] as int;
            if (processedIds.contains(sibId)) continue;

            String sibPub =
                (sibling['publisher'] ?? "").toString().toLowerCase().trim();

            bool isMatch = false;
            if (currentPub.isEmpty || sibPub.isEmpty) {
              isMatch = true;
            } else if (currentPub.contains(sibPub) ||
                sibPub.contains(currentPub)) {
              isMatch = true;
            }

            if (isMatch) {
              bool currentIsBetter = currentPub.length >= sibPub.length ||
                  j['dateFollowed'] != null;

              int keepId = currentIsBetter ? currentId : sibId;
              int deleteId = currentIsBetter ? sibId : currentId;

              await db.update('journal_issns', {'journal_id': keepId},
                  where: 'journal_id = ?', whereArgs: [deleteId]);
              await db.update('articles', {'journal_id': keepId},
                  where: 'journal_id = ?', whereArgs: [deleteId]);

              // Delete duplicate
              await db.delete('journals',
                  where: 'journal_id = ?', whereArgs: [deleteId]);
              processedIds.add(deleteId);

              logger.info(
                  "Fuzzy Merged '$currentTitle': ID $deleteId into $keepId");

              if (keepId == sibId) break;
            }
          }
          processedIds.add(currentId);
        }
      }
    });
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      logger.info('Database connection closed and reference cleared.');
    }
  }

  // Functions for journals
  Future<void> insertJournal(Journal journal) async {
    final db = await database;

    int? journalId = await getOrCreateJournalId(
      issns: journal.issn,
      title: journal.title,
      publisher: journal.publisher,
    );

    if (journalId != null) {
      await db.update(
        'journals',
        {
          'dateFollowed': journal.dateFollowed ??
              DateTime.now().toIso8601String().substring(0, 10),
          'title': journal.title,
          'publisher': journal.publisher,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'journal_id = ?',
        whereArgs: [journalId],
      );
    }
  }

  Future<int?> getOrCreateJournalId({
    required List<String> issns,
    required String? title,
    String? publisher,
  }) async {
    if ((title == null || title.trim().isEmpty) && issns.isEmpty) {
      return null; // The journal has no ISSN and no title, skip it
    }

    final db = await database;

    // Try to match by issns
    if (issns.isNotEmpty) {
      final existingIssn = await db.query(
        'journal_issns',
        where: 'issn IN (${List.filled(issns.length, '?').join(',')})',
        whereArgs: issns,
      );
      if (existingIssn.isNotEmpty) {
        return existingIssn.first['journal_id'] as int;
      }
    }

    // Try to match by title and publisher
    if (title != null && title.trim().isNotEmpty) {
      final List<Map<String, dynamic>> titleMatches = await db.query(
        'journals',
        where: 'LOWER(TRIM(title)) = ?',
        whereArgs: [title.toLowerCase().trim()],
      );

      for (var match in titleMatches) {
        String dbPub =
            (match['publisher'] ?? "").toString().toLowerCase().trim();
        String newPub = (publisher ?? "").toLowerCase().trim();

        if (dbPub.isEmpty ||
            newPub.isEmpty ||
            dbPub.contains(newPub) ||
            newPub.contains(dbPub)) {
          int journalId = match['journal_id'];

          //  Update the issns if new ones are available form the duplicate
          for (final issn in issns) {
            await db.insert(
                'journal_issns',
                {
                  'issn': issn,
                  'journal_id': journalId,
                  'sync_id': const Uuid().v7(),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          return journalId;
        }
      }
    }
    // The journal doesn't exist so insert it if it has a title
    if (title != null && title.trim().isNotEmpty) {
      final journalId = await db.insert('journals', {
        'title': title,
        'publisher': publisher,
        'sync_id': const Uuid().v7(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      for (final issn in issns) {
        // Insert the journal's issns if they are not missing
        if (issn.trim().isNotEmpty) {
          await db.insert(
            'journal_issns',
            {
              'issn': issn.trim(),
              'journal_id': journalId,
              'sync_id': const Uuid().v7(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      return journalId;
    }

    return null;
  }

  Future<List<Journal>> getFollowedJournals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT j.journal_id, j.title, j.publisher, j.dateFollowed, j.lastUpdated, 
            GROUP_CONCAT(ji.issn) as issns
      FROM journals j
      JOIN journal_issns ji ON j.journal_id = ji.journal_id
      WHERE j.dateFollowed IS NOT NULL
      GROUP BY j.journal_id
    ''');

    return List.generate(maps.length, (i) {
      return Journal(
        id: maps[i]['journal_id'],
        issn: (maps[i]['issns'] as String).split(','),
        title: maps[i]['title'],
        publisher: maps[i]['publisher'],
        dateFollowed: maps[i]['dateFollowed'],
        lastUpdated: maps[i]['lastUpdated'],
      );
    });
  }

  Future<List<Journal>> getAllJournals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT j.journal_id, j.title, j.publisher, j.dateFollowed, j.lastUpdated, 
            GROUP_CONCAT(ji.issn) as issns
      FROM journals j
      JOIN journal_issns ji ON j.journal_id = ji.journal_id
      GROUP BY j.journal_id
    ''');

    return List.generate(maps.length, (i) {
      return Journal(
        id: maps[i]['journal_id'],
        issn: (maps[i]['issns'] as String).split(','),
        title: maps[i]['title'],
        publisher: maps[i]['publisher'] ?? '',
        dateFollowed: maps[i]['dateFollowed'],
        lastUpdated: maps[i]['lastUpdated'],
      );
    });
  }

  Future<int?> getJournalIdByIssns(List<String> issns) async {
    final db = await database;

    String whereClause =
        'issn IN (${List.filled(issns.length, '?').join(', ')})';

    List<Map<String, dynamic>> result = await db.query(
      'journal_issns',
      columns: ['journal_id'],
      where: whereClause,
      whereArgs: issns,
    );

    if (result.isNotEmpty) {
      return result.first['journal_id'] as int;
    }
    return null;
  }

  Future<String?> getJournalTitleById(int journalId) async {
    final db = await database;
    final result = await db.query(
      'journals',
      columns: ['title'],
      where: 'journal_id = ?',
      whereArgs: [journalId],
    );

    if (result.isNotEmpty) {
      return result.first['title'] as String?;
    }

    return null;
  }

  Future<List<String>> getIssnsByJournalId(int journalId) async {
    final db = await database;

    final result = await db.query(
      'journal_issns',
      columns: ['issn'],
      where: 'journal_id = ?',
      whereArgs: [journalId],
    );

    if (result.isNotEmpty) {
      return result.map((row) => row['issn'] as String).toList();
    }
    return [];
  }

  Future<void> removeJournal(List<String> issns) async {
    int? journalId = await getJournalIdByIssns(issns);
    if (journalId != null) {
      await removeJournalById(journalId);
    }
  }

  Future<void> removeJournalById(int journalId) async {
    final db = await database;

    await db.update(
      'articles',
      {
        'dateCached': null,
      },
      where: 'journal_id = ?',
      whereArgs: [journalId],
    );

    await db.update(
      'journals',
      {
        'dateFollowed': null,
        'lastUpdated': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'journal_id = ?',
      whereArgs: [journalId],
    );
  }

  Future<bool> isJournalFollowed(int journalId) async {
    final db = await database;

    final query = 'SELECT COUNT(*) FROM journals '
        'WHERE journal_id = ? AND dateFollowed IS NOT NULL';

    final count = Sqflite.firstIntValue(await db.rawQuery(
      query,
      [journalId],
    ))!;

    return count > 0;
  }

  Future<void> updateJournalLastUpdated(int journalId) async {
    final db = await database;
    await db.update(
      'journals',
      {
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'journal_id = ?',
      whereArgs: [journalId],
    );
  }

  // Functions for articles
  Future<void> insertArticle(
    PublicationCard publicationCard, {
    bool isLiked = false,
    bool isDownloaded = false,
    bool isCached = false,
    bool isSavedQuery = false,
    int? queryId,
    String pdfPath = '',
  }) async {
    final db = await database;

    // Check if the article with the given DOI already exists
    final List<Map<String, dynamic>> existingArticle = await db.query(
      'articles',
      columns: ['article_id', 'dateLiked', 'dateDownloaded', 'dateCached'],
      where: 'doi = ?',
      whereArgs: [publicationCard.doi],
    );

    if (existingArticle.isNotEmpty) {
      // Article already exists, update the timestamp based on parameters
      final Map<String, dynamic> updateData = {};
      updateData['updated_at'] = DateTime.now().toUtc().toIso8601String();

      if (isLiked && existingArticle[0]['dateLiked'] == null) {
        updateData['dateLiked'] =
            DateTime.now().toIso8601String().substring(0, 10);
      }

      if (isDownloaded && existingArticle[0]['dateDownloaded'] == null) {
        updateData['dateDownloaded'] =
            DateTime.now().toIso8601String().substring(0, 10);
        updateData['pdfPath'] = pdfPath;
      }

      if (isCached && existingArticle[0]['dateCached'] == null) {
        updateData['dateCached'] = DateTime.now().toIso8601String();
      }

      if (updateData.isNotEmpty) {
        await db.update(
          'articles',
          updateData,
          where: 'article_id = ?',
          whereArgs: [existingArticle[0]['article_id']],
        );
      }
    } else {
      int? journalId = await getOrCreateJournalId(
        issns: publicationCard.issn,
        title: publicationCard.journalTitle,
        publisher: publicationCard.publisher,
      );

      // Insert the article, but store a journal_id null if it had no journal
      await db.insert('articles', {
        'doi': publicationCard.doi,
        'title': publicationCard.title,
        'abstract': publicationCard.abstract,
        'publishedDate': publicationCard.publishedDate?.toIso8601String(),
        'authors': jsonEncode(
            publicationCard.authors.map((author) => author.toJson()).toList()),
        'url': publicationCard.url,
        'license': publicationCard.license,
        'licenseName': publicationCard.licenseName,
        'dateLiked':
            isLiked ? DateTime.now().toIso8601String().substring(0, 10) : null,
        'dateDownloaded': isDownloaded
            ? DateTime.now().toIso8601String().substring(0, 10)
            : null,
        'pdfPath': pdfPath.isNotEmpty ? pdfPath : '',
        'dateCached': isCached ? DateTime.now().toIso8601String() : null,
        'isSavedQuery': isSavedQuery ? 1 : 0,
        'query_id': queryId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_id': const Uuid().v7(),
        'journal_id': journalId,
      });
    }
  }

  Future<List<PublicationCard>> getFavoriteArticles() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT articles.*, journals.title AS journalTitle, 
    GROUP_CONCAT(journal_issns.issn) AS issns
    FROM articles
    LEFT JOIN journals ON articles.journal_id = journals.journal_id
    LEFT JOIN journal_issns ON journals.journal_id = journal_issns.journal_id
    WHERE articles.dateLiked IS NOT NULL
    GROUP BY articles.article_id
  ''');

    return List.generate(maps.length, (i) {
      String? rawIssns = maps[i]['issns'] as String?;
      List<String> issns = rawIssns != null ? rawIssns.split(',') : [];

      DateTime? pubDate;
      if (maps[i]['publishedDate'] != null) {
        pubDate = DateTime.tryParse(maps[i]['publishedDate']);
      }

      return PublicationCard(
        doi: maps[i]['doi'],
        title: maps[i]['title'],
        issn: issns,
        abstract: maps[i]['abstract'],
        publishedDate: pubDate,
        authors: maps[i]['authors'] != null
            ? List<PublicationAuthor>.from(
                (jsonDecode(maps[i]['authors']) as List<dynamic>).map(
                    (authorJson) => PublicationAuthor.fromJson(authorJson)),
              )
            : [],
        dateLiked: maps[i]['dateLiked'],
        journalTitle: maps[i]['journalTitle'] ?? '',
        url: maps[i]['url'],
        license: maps[i]['license'],
        licenseName: maps[i]['licenseName'],
      );
    });
  }

  Future<int> getArticleCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM articles');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> removeFavorite(String doi) async {
    final db = await database;

    await db.update(
      'articles',
      {
        'dateLiked': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  Future<bool> isArticleFavorite(String doi) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM articles WHERE doi = ? AND dateLiked IS NOT NULL',
      [doi],
    ))!;
    return count > 0;
  }

  Future<void> insertCachedPublication(PublicationCard publicationCard) async {
    final db = await database;

    int? journalId = await getOrCreateJournalId(
      issns: publicationCard.issn,
      title: publicationCard.journalTitle,
      publisher: publicationCard.publisher,
    );

    final List<Map<String, dynamic>> publicationMaps = await db.query(
      'articles',
      where: 'doi = ?',
      whereArgs: [publicationCard.doi],
    );

    if (publicationMaps.isNotEmpty) {
      await db.update(
        'articles',
        {
          'dateCached': DateTime.now().toIso8601String(),
          'title': publicationCard.title,
          'abstract': publicationCard.abstract,
          'journal_id': journalId,
          'publishedDate': publicationCard.publishedDate?.toIso8601String(),
          'authors': jsonEncode(
            publicationCard.authors.map((author) => author.toJson()).toList(),
          ),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'doi = ?',
        whereArgs: [publicationCard.doi],
      );
    } else {
      await db.insert('articles', {
        'doi': publicationCard.doi,
        'title': publicationCard.title,
        'abstract': publicationCard.abstract,
        'journal_id': journalId,
        'publishedDate': publicationCard.publishedDate?.toIso8601String(),
        'authors': jsonEncode(
          publicationCard.authors.map((author) => author.toJson()).toList(),
        ),
        'dateCached': DateTime.now().toIso8601String(),
        'sync_id': const Uuid().v7(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<List<PublicationCard>> getCachedPublications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        articles.*,
        journals.title AS journalTitle,
        GROUP_CONCAT(journal_issns.issn) AS issns
      FROM articles
      JOIN journals ON articles.journal_id = journals.journal_id
      LEFT JOIN journal_issns ON articles.journal_id = journal_issns.journal_id
      WHERE articles.dateCached IS NOT NULL 
      AND (articles.isHidden = 0 OR articles.isHidden IS NULL)
      GROUP BY articles.doi
      ''');

    return maps.map((map) {
      final List<String> issns = (map['issns'] as String?)?.split(',') ?? [];

      return PublicationCard(
        doi: map['doi'],
        title: map['title'],
        issn: issns,
        abstract: map['abstract'],
        journalTitle: map['journalTitle'],
        publishedDate: DateTime.parse(map['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(map['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ),
        url: map['url'],
        license: map['license'],
        licenseName: map['licenseName'],
      );
    }).toList();
  }

  Future<List<PublicationCard>> getHiddenPublications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        articles.*,
        journals.title AS journalTitle,
        GROUP_CONCAT(journal_issns.issn) AS issns
      FROM articles
      LEFT JOIN journals ON articles.journal_id = journals.journal_id
      LEFT JOIN journal_issns ON articles.journal_id = journal_issns.journal_id
      WHERE articles.isHidden = 1
      GROUP BY articles.doi
      ''');

    return maps.map((map) {
      final List<String> issns = (map['issns'] as String?)?.split(',') ?? [];

      return PublicationCard(
        doi: map['doi'],
        title: map['title'],
        issn: issns,
        abstract: map['abstract'],
        journalTitle: map['journalTitle'],
        publishedDate: DateTime.parse(map['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(map['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ),
        url: map['url'],
        license: map['license'],
        licenseName: map['licenseName'],
      );
    }).toList();
  }

  Future<void> hideArticle(String doi) async {
    final db = await database;
    await db.update(
      'articles',
      {
        'isHidden': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  Future<void> unhideArticle(String doi) async {
    final db = await database;
    await db.update(
      'articles',
      {
        'isHidden': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  Future<void> updateTranslatedContent({
    required String doi,
    String? translatedTitle,
    String? translatedAbstract,
  }) async {
    final db = await database;
    final Map<String, dynamic> updateData = {};

    if (translatedTitle != null) {
      updateData['translatedTitle'] = translatedTitle;
    }
    if (translatedAbstract != null) {
      updateData['translatedAbstract'] = translatedAbstract;
    }

    if (updateData.isNotEmpty) {
      final rowsAffected = await db.update(
        'articles',
        updateData,
        where: 'doi = ?',
        whereArgs: [doi],
      );
      if (rowsAffected > 0) {
        logger.info('Updated translated content for DOI: $doi');
      } else {
        logger.warning(
            'No article found with DOI: $doi to update translated content.');
      }
    }
  }

  Future<Map<String, String?>> getTranslatedContent(String doi) async {
    final db = await database;
    final result = await db.query(
      'articles',
      columns: ['translatedTitle', 'translatedAbstract'],
      where: 'doi = ?',
      whereArgs: [doi],
    );

    if (result.isNotEmpty) {
      return {
        'translatedTitle': result.first['translatedTitle'] as String?,
        'translatedAbstract': result.first['translatedAbstract'] as String?,
      };
    }
    return {'translatedTitle': null, 'translatedAbstract': null};
  }

  Future<bool> checkIfDoiExists(String doi) async {
    final db = await database;
    final result = await db.query(
      'articles',
      columns: ['doi'],
      where: 'doi = ?',
      whereArgs: [doi],
    );

    if (result.isNotEmpty) {
      return true;
    }

    return false;
  }

  // Updates the abstract of an article after being scraped
  Future<void> updateArticleAbstract(String doi, String abstract) async {
    final db = await database;
    await db.update(
      'articles',
      {
        'abstract': abstract,
      },
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  Future<bool> isArticleDownloaded(String doi) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM articles WHERE doi = ? AND dateDownloaded IS NOT NULL AND pdfPath IS NOT NULL',
      [doi],
    ))!;
    return count > 0;
  }

  Future<List<DownloadedCard>> getDownloadedArticles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT articles.*, journals.title AS journalTitle, 
       GROUP_CONCAT(journal_issns.issn) AS issns
      FROM articles
      LEFT JOIN journals ON articles.journal_id = journals.journal_id
      LEFT JOIN journal_issns ON journals.journal_id = journal_issns.journal_id
      WHERE articles.dateDownloaded IS NOT NULL
      GROUP BY articles.article_id

  ''');

    return List.generate(maps.length, (i) {
      List<String> issns = (maps[i]['issns'] as String?)?.split(',') ?? [];

      return DownloadedCard(
        pdfPath: maps[i]['pdfPath'] ?? '',
        publicationCard: PublicationCard(
          doi: maps[i]['doi'] ?? '',
          title: maps[i]['title'] ?? '',
          issn: issns,
          abstract: maps[i]['abstract'] ?? '',
          journalTitle: maps[i]['journalTitle'] ?? '',
          publishedDate: DateTime.parse(maps[i]['publishedDate']),
          authors: [],
          url: '',
          license: '',
          licenseName: '',
        ),
        onDelete: () {},
      );
    });
  }

  Future<String?> getAbstract(String doi) async {
    final db = await database;
    final result = await db.query(
      'articles',
      columns: ['abstract'],
      where: 'doi = ?',
      whereArgs: [doi],
    );

    return result.isNotEmpty ? result.first['abstract'] as String? : null;
  }

  Future<void> updateGraphicalAbstractPath(
      String doi, File graphicalAbstractFile) async {
    final db = await database;

    final String filename = basename(graphicalAbstractFile.path);

    try {
      final rowsAffected = await db.update(
        'articles',
        {
          'graphAbstractPath': filename,
        },
        where: 'doi = ?',
        whereArgs: [doi],
      );

      if (rowsAffected > 0) {
        logger.info(
            'Updated graphical abstract path for DOI: $doi with basename: $filename');
      } else {
        logger.warning(
            'No article found with DOI: $doi to update graphical abstract path.');
      }
    } catch (e, stackTrace) {
      logger.severe('Failed to update graphical abstract path for DOI: $doi', e,
          stackTrace);
    }
  }

  Future<String?> getGraphicalAbstractPath(String doi) async {
    final db = await database;
    final result = await db.query(
      'articles',
      columns: ['graphAbstractPath'],
      where: 'doi = ?',
      whereArgs: [doi],
    );

    return result.isNotEmpty
        ? result.first['graphAbstractPath'] as String?
        : null;
  }

  Future<void> removeDownloaded(String doi) async {
    final db = await database;

    await db.update(
      'articles',
      {'dateDownloaded': null, 'pdfPath': null},
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  // Insert function for the saved search queries
  Future<void> saveSearchQuery(
      String queryName, String queryParams, String provider) async {
    final db = await database;
    final String dateSaved = DateTime.now().toIso8601String();
    await db.insert(
      'savedQueries',
      {
        'queryName': queryName,
        'queryParams': queryParams,
        'dateSaved': dateSaved,
        'includeInFeed': 0,
        'queryProvider': provider,
        'sync_id': const Uuid().v7(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  // Get the saved search queries
  Future<List<Map<String, dynamic>>> getSavedQueries() async {
    final db = await database;
    return await db.query('savedQueries', orderBy: 'dateSaved DESC');
  }

  // Remove a saved search query
  Future<void> deleteQuery(int id) async {
    final db = await database;
    await db.delete(
      'savedQueries',
      where: 'query_id = ?',
      whereArgs: [id],
    );
    await deleteArticlesForSavedQuery(id);
  }

  Future<List<Map<String, dynamic>>> getSavedQueriesToUpdate() async {
    final db = await database;
    return await db.query(
      'savedQueries',
      columns: [
        'query_id',
        'queryName',
        'queryParams',
        'queryProvider',
        'lastFetched'
      ],
      where: 'includeInFeed = ?',
      whereArgs: [1], // Only include queries with "includeInFeed"
    );
  }

  Future<void> updateSavedQueryLastFetched(int queryId) async {
    final db = await database;
    await db.update(
      'savedQueries',
      {'lastFetched': DateTime.now().toIso8601String()},
      where: 'query_id = ?',
      whereArgs: [queryId],
    );
  }

  // Updates the includeInFeed column in the Saved queries table
  Future<void> updateIncludeInFeed(int id, bool includeInFeed) async {
    final db = await database;
    await db.update(
      'savedQueries',
      {
        'includeInFeed': includeInFeed ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'query_id = ?',
      whereArgs: [id],
    );
    // Clears the lastFetched when the include in feed toggle is off
    if (!includeInFeed) {
      await db.update(
        'savedQueries',
        {
          'lastFetched': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'query_id = ?',
        whereArgs: [id],
      );

      await deleteArticlesForSavedQuery(id);
    }
  }

  Future<void> deleteArticlesForSavedQuery(int queryId) async {
    final db = await database;

    // Delete articles that belong to a specific saved query
    List<Map<String, dynamic>> articlesToDelete = await db.query(
      'articles',
      columns: ['doi'],
      where:
          'isSavedQuery = 1 AND query_id = ? AND dateLiked IS NULL AND dateDownloaded IS NULL',
      whereArgs: [queryId],
    );

    if (articlesToDelete.isNotEmpty) {
      for (var article in articlesToDelete) {
        await db.delete(
          'articles',
          where: 'doi = ?',
          whereArgs: [article['doi']],
        );
      }
    }
  }

  // Get the inludeInFeed status
  Future<bool> getIncludeInFeed(int queryId) async {
    final db = await database;
    final result = await db.query(
      'savedQueries',
      where: 'query_id = ?',
      whereArgs: [queryId],
      columns: ['includeInFeed'],
    );

    if (result.isNotEmpty) {
      return result.first['includeInFeed'] == 1;
    }
    return false;
  }

  // Cleanup the database, removing old articles + PDFs + graphical abstracts
  Future<void> cleanupOldArticles() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();

    final int cleanupThreshold =
        prefs.getInt('cleanupThreshold') ?? 90; // Default to 3 months (90 days)
    final useCustomPath = prefs.getBool('useCustomDatabasePath') ?? false;
    final customPath = prefs.getString('customDatabasePath');

    String baseDirPath;
    if (useCustomPath && customPath != null) {
      baseDirPath = customPath;
    } else if (Platform.isWindows) {
      final dir = await getApplicationSupportDirectory();
      baseDirPath = dir.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      baseDirPath = dir.path;
    }

    final String graphicalAbstractsPath =
        p.join(baseDirPath, 'graphical_abstracts');

    final DateTime thresholdDate =
        DateTime.now().subtract(Duration(days: cleanupThreshold));
    final String thresholdDateString =
        thresholdDate.toIso8601String().substring(0, 10);

    try {
      if (cleanupThreshold != 0) {
        final List<Map<String, dynamic>> oldArticles = await db.rawQuery('''
        SELECT article_id, pdfPath, graphAbstractPath FROM articles
        WHERE dateCached < ? 
          AND dateLiked IS NULL 
          AND dateDownloaded IS NULL 
          AND (isHidden IS NULL OR isHidden = 0)
      ''', [thresholdDateString]);

        if (oldArticles.isNotEmpty) {
          final List<int> articlesToDelete = [];
          for (var article in oldArticles) {
            String? pdfFilename = article['pdfPath'];
            if (pdfFilename != null && pdfFilename.isNotEmpty) {
              final fullPdfPath = p.join(baseDirPath, pdfFilename);
              try {
                final file = File(fullPdfPath);
                if (await file.exists()) {
                  await file.delete();
                  logger.info(
                      'Deleted PDF: $fullPdfPath (linked to old article)');
                }
              } catch (e, stackTrace) {
                logger.severe(
                    'Error deleting PDF file at $fullPdfPath', e, stackTrace);
              }
            }

            String? gaFilename = article['graphAbstractPath'];
            if (gaFilename != null && gaFilename.isNotEmpty) {
              final fullGaPath = p.join(graphicalAbstractsPath, gaFilename);
              try {
                final file = File(fullGaPath);
                if (await file.exists()) {
                  await file.delete();
                  logger.info(
                      'Deleted Graphical Abstract: $fullGaPath (linked to old article)');
                }
              } catch (e, stackTrace) {
                logger.severe(
                    'Error deleting GA file at $fullGaPath', e, stackTrace);
              }
            }

            articlesToDelete.add(article['article_id'] as int);
          }

          await db.delete(
            'articles',
            where: 'article_id IN (${articlesToDelete.join(',')})',
          );
          logger.info(
              'Deleted ${articlesToDelete.length} old articles from database.');
        } else {
          logger.info("No old articles to clean up in the database.");
        }
      } else {
        logger.info(
            "Cleanup threshold is set to 0. Skipping DB cleanup, proceeding with orphaned files.");
      }

      logger.info('Starting cleanup for orphaned PDF files.');

      final List<Map<String, dynamic>> allPdfPathsDb = await db.query(
        'articles',
        columns: ['pdfPath'],
        where: 'pdfPath IS NOT NULL',
      );
      final Set<String> dbLinkedPdfFilenames = allPdfPathsDb
          .map((row) => row['pdfPath'] as String)
          .where((filename) => filename.isNotEmpty)
          .toSet();

      final Directory pdfDir = Directory(baseDirPath);
      if (await pdfDir.exists()) {
        await for (final FileSystemEntity entity in pdfDir.list()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            final filename = p.basename(entity.path);

            if (!dbLinkedPdfFilenames.contains(filename)) {
              try {
                await entity.delete();
                logger.info('Deleted orphaned PDF: ${entity.path}');
              } catch (e, stackTrace) {
                logger.severe(
                    'Error deleting orphaned PDF file at ${entity.path}',
                    e,
                    stackTrace);
              }
            }
          }
        }
      }
      logger.info('Completed cleanup for orphaned PDF files.');

      logger.info('Starting cleanup for orphaned graphical abstracts.');

      final List<Map<String, dynamic>> allGaFilenamesDb = await db.query(
        'articles',
        columns: ['graphAbstractPath'],
        where: 'graphAbstractPath IS NOT NULL',
      );
      final Set<String> dbLinkedGaFilenames = allGaFilenamesDb
          .map((row) => row['graphAbstractPath'] as String)
          .where((filename) => filename.isNotEmpty)
          .toSet();

      final Directory gaDir = Directory(graphicalAbstractsPath);
      if (await gaDir.exists()) {
        await for (final FileSystemEntity entity in gaDir.list()) {
          if (entity is File) {
            final filename = p.basename(entity.path);

            if (!dbLinkedGaFilenames.contains(filename)) {
              try {
                await entity.delete();
                logger.info(
                    'Deleted orphaned graphical abstract: ${entity.path}');
              } catch (e, stackTrace) {
                logger.severe(
                    'Error deleting orphaned graphical abstract file at ${entity.path}',
                    e,
                    stackTrace);
              }
            }
          }
        }
      }
      logger.info('Completed cleanup for orphaned graphical abstracts.');
    } catch (e, stackTrace) {
      logger.severe('Error during DB cleanup', e, stackTrace);
    }
  }

  Future<void> insertFeedFilter({
    required String name,
    required String include,
    required String exclude,
    required Set<String> journals,
    String? dateMode,
    String? dateAfter,
    String? dateBefore,
  }) async {
    final db = await database;

    await db.insert('feed_filters', {
      'name': name,
      'includedKeywords': include,
      'excludedKeywords': exclude,
      'journals': journals.join(','),
      'date_mode': dateMode,
      'date_after': dateAfter,
      'date_before': dateBefore,
      'sync_id': const Uuid().v7(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFeedFilters() async {
    final db = await database;
    return await db.query(
      'feed_filters',
      orderBy: 'dateCreated DESC',
      where: 'is_deleted = 0',
    );
  }

  Future<List<FeedFilter>> getParsedFeedFilters() async {
    final raw = await getFeedFilters();
    return raw.map((row) {
      return FeedFilter(
        id: row['id'],
        name: row['name'],
        include: row['includedKeywords'] ?? '',
        exclude: row['excludedKeywords'] ?? '',
        journals: (row['journals'] ?? '').split(',').toSet(),
        dateMode: row['date_mode'],
        dateAfter: row['date_after'],
        dateBefore: row['date_before'],
        dateCreated: row['dateCreated'],
      );
    }).toList();
  }

  Future<void> updateFeedFilter({
    required int id,
    required String name,
    required String include,
    required String exclude,
    required Set<String> journals,
    String? dateMode,
    String? dateAfter,
    String? dateBefore,
  }) async {
    final db = await database;

    await db.update(
      'feed_filters',
      {
        'name': name,
        'includedKeywords': include,
        'excludedKeywords': exclude,
        'journals': journals.join(','),
        'date_mode': dateMode,
        'date_after': dateAfter,
        'date_before': dateBefore,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFeedFilter(int id) async {
    final db = await database;
    await db.update(
      'feed_filters',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertKnownUrl(String url, int proxySuccess) async {
    final db = await database;

    final existing = await db.query(
      'knownUrls',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      return await db.update(
        'knownUrls',
        {
          'proxySuccess': proxySuccess,
          'is_deleted': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return await db.insert(
      'knownUrls',
      {
        'url': url,
        'proxySuccess': proxySuccess,
        'sync_id': const Uuid().v7(),
        'is_deleted': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<int> updateKnownUrl(int id, {String? url, int? proxySuccess}) async {
    final db = await database;
    final updateData = <String, Object?>{
      'is_deleted': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (url != null) updateData['url'] = url;
    if (proxySuccess != null) updateData['proxySuccess'] = proxySuccess;

    return await db.update(
      'knownUrls',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteKnownUrl(int id) async {
    final db = await database;
    return await db.update(
      'knownUrls',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getKnownUrlByString(String url) async {
    final db = await database;
    final results = await db.query(
      'knownUrls',
      where: 'url = ? AND is_deleted = 0',
      whereArgs: [url],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<String?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sync');
  }

  Future<void> setLastSync(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync', timestamp);
  }

  Future<void> syncJournalFromCloud(Map<String, dynamic> data) async {
    final db = await database;
    final syncId = data['sync_id'];

    final existingJournals = await db.query(
      'journals',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (existingJournals.isEmpty) {
      await db.insert('journals', data);
    } else {
      await db.update(
        'journals',
        data,
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );
    }
  }

  Future<void> syncJournalIssnFromCloud(Map<String, dynamic> data) async {
    final db = await database;

    final syncId = data['sync_id'];

    final existingIssns = await db.query(
      'journal_issns',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (existingIssns.isEmpty) {
      await db.insert('journal_issns', data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'journal_issns',
        data,
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );
    }
  }
}
