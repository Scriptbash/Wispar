import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/crossref_journals_works_models.dart';
import '../widgets/publication_card.dart';
import '../widgets/downloaded_card.dart';
import '../models/journal_entity.dart';
import '../models/feed_filter_entity.dart';
import './string_format_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import './logs_helper.dart';

class DatabaseHelper {
  static Database? _database;
  final logger = LogsService().logger;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'wispar.db');

    return openDatabase(databasePath, version: 6, onOpen: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON');

      // Create the journals table
      await db.execute('''
        CREATE TABLE journals (
          journal_id INTEGER PRIMARY KEY AUTOINCREMENT,
          issn TEXT,
          title TEXT,
          publisher TEXT,
          dateFollowed TEXT,
          lastUpdated TEXT
        )
      ''');
      // Create the journal_issns table
      await db.execute('''
       CREATE TABLE journal_issns (
          issn TEXT PRIMARY KEY,
          journal_id INTEGER,
          FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
        )
      ''');

      // Create the 'articles' table
      await db.execute('''
        CREATE TABLE articles (
          article_id INTEGER PRIMARY KEY AUTOINCREMENT,
          doi TEXT,
          title TEXT,
          abstract TEXT,
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
          journal_id,
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
          queryProvider TEXT
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
        dateCreated TEXT DEFAULT CURRENT_TIMESTAMP
      )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      logger.info("Upgrading DB from ${oldVersion} to ${newVersion}");
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
    });
  }

  // Functions for journals
  Future<void> insertJournal(Journal journal) async {
    final db = await database;

    final existingIssn = await db.query(
      'journal_issns',
      where: 'issn IN (${List.filled(journal.issn.length, '?').join(',')})',
      whereArgs: journal.issn,
    );

    if (existingIssn.isNotEmpty) {
      final int journalId = existingIssn.first['journal_id'] as int;

      final journalMap = await db.query(
        'journals',
        where: 'journal_id = ?',
        whereArgs: [journalId],
      );

      if (journalMap.isNotEmpty && journalMap.first['dateFollowed'] == null) {
        await db.update(
          'journals',
          {
            'dateFollowed': DateTime.now().toIso8601String().substring(0, 10),
            'title': journal.title,
            'publisher': journal.publisher,
          },
          where: 'journal_id = ?',
          whereArgs: [journalId],
        );

        await db.delete(
          'journal_issns',
          where: 'journal_id = ?',
          whereArgs: [journalId],
        );

        for (final issn in journal.issn) {
          await db.insert(
            'journal_issns',
            {
              'issn': issn,
              'journal_id': journalId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } else {
      final journalId = await db.insert('journals', journal.toMap());

      for (final issn in journal.issn) {
        await db.insert(
          'journal_issns',
          {
            'issn': issn,
            'journal_id': journalId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
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
    final db = await database;

    int? journalId = await getJournalIdByIssns(issns);

    if (journalId != null) {
      await db.update(
        'articles',
        {'dateCached': null},
        where: 'journal_id = ?',
        whereArgs: [journalId],
      );

      await db.update(
        'journals',
        {'dateFollowed': null, 'lastUpdated': null},
        where: 'journal_id = ?',
        whereArgs: [journalId],
      );
    }
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
      {'lastUpdated': DateTime.now().toIso8601String()},
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
      int? journalId = await getJournalIdByIssns(publicationCard.issn);
      if (journalId == null) {
        // Journal not found, insert it
        final Map<String, dynamic> journalData = {
          'title': publicationCard.journalTitle,
          'publisher': publicationCard.publisher,
        };

        journalId = await db.insert('journals', journalData);

        // Insert the ISSNs into the journal_issns table
        for (final issn in publicationCard.issn) {
          await db.insert('journal_issns', {
            'issn': issn,
            'journal_id': journalId,
          });
        }
      }

      // Insert the article
      await db.insert('articles', {
        'doi': publicationCard.doi,
        'title': publicationCard.title,
        'abstract': publicationCard.abstract,
        'publishedDate': publicationCard.publishedDate?.toIso8601String(),
        'authors': jsonEncode(publicationCard.authors
            .map((author) => author.toJson())
            .toList()), // Serialize authors to JSON
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
        'journal_id': journalId,
      });
    }
  }

  Future<List<PublicationCard>> getFavoriteArticles() async {
    final Database db = await DatabaseHelper().database;

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
      List<String> issns = (maps[i]['issns'] as String?)?.split(',') ?? [];

      return PublicationCard(
        doi: maps[i]['doi'],
        title: maps[i]['title'],
        issn: issns,
        abstract: maps[i]['abstract'],
        publishedDate: DateTime.parse(maps[i]['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(maps[i]['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ),
        dateLiked: maps[i]['dateLiked'],
        journalTitle: maps[i]['journalTitle'],
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
      {'dateLiked': null},
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
    final List<Map<String, dynamic>> publicationMaps = await db.query(
      'articles',
      columns: ['article_id', 'dateCached'],
      where: 'doi = ?',
      whereArgs: [publicationCard.doi],
    );

    if (publicationMaps.isNotEmpty) {
      // Publication found, retrieve its ID
      final int articleId = publicationMaps.first['article_id'];

      // If the publication wasn't cached before, update the dateCached
      if (publicationMaps.first['dateCached'] == null) {
        final int? journalId = await getJournalIdByIssns(publicationCard.issn);

        if (journalId == null) {
          throw Exception('No matching journal found for the given ISSNs.');
        }

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
          },
          where: 'article_id = ?',
          whereArgs: [articleId],
        );
      }
    } else {
      // Publication not found, insert it
      final int? journalId = await getJournalIdByIssns(publicationCard.issn);

      if (journalId == null) {
        throw Exception('No matching journal found for the given ISSNs.');
      }

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
      JOIN journals ON articles.journal_id = journals.journal_id
      LEFT JOIN journal_issns ON articles.journal_id = journal_issns.journal_id
      WHERE articles.dateCached IS NOT NULL 
      AND articles.isHidden = 1
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
      {'isHidden': 1},
      where: 'doi = ?',
      whereArgs: [doi],
    );
  }

  Future<void> unhideArticle(String doi) async {
    final db = await database;
    await db.update(
      'articles',
      {'isHidden': 0},
      where: 'doi = ?',
      whereArgs: [doi],
    );
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
        pdfPath: maps[i]['pdfPath'],
        publicationCard: PublicationCard(
          doi: maps[i]['doi'],
          title: maps[i]['title'],
          issn: issns,
          abstract: maps[i]['abstract'],
          journalTitle: maps[i]['journalTitle'],
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
      {'includeInFeed': includeInFeed ? 1 : 0},
      where: 'query_id = ?',
      whereArgs: [id],
    );
    // Clears the lastFetched when the include in feed toggle is off
    if (!includeInFeed) {
      await db.update(
        'savedQueries',
        {'lastFetched': null},
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

  // Cleanup the database, removing old articles
  Future<void> cleanupOldArticles() async {
    final db = await database;

    // Retrieve CleanupInterval from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final int cleanupInterval =
        prefs.getInt('CleanupInterval') ?? 7; // Default to 7 days if not set

    final DateTime thresholdDate =
        DateTime.now().subtract(Duration(days: cleanupInterval));
    final String thresholdDateString =
        thresholdDate.toIso8601String().substring(0, 10);

    try {
      final List<Map<String, dynamic>> oldArticles = await db.rawQuery('''
      SELECT * FROM articles
      WHERE dateCached < ? AND dateLiked IS NULL AND dateDownloaded IS NULL AND (isHidden IS NULL OR isHidden = 0)
    ''', [thresholdDateString]);

      // Delete the old articles
      if (oldArticles.isNotEmpty) {
        for (var article in oldArticles) {
          // If pdfPath is not null, try to delete the file
          String? pdfPath = article['pdfPath'];
          if (pdfPath != null && pdfPath.isNotEmpty) {
            try {
              final file = File(pdfPath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e, stackTrace) {
              logger.severe(
                  'Error deleting PDF file at $pdfPath', e, stackTrace);
            }
          }

          // Delete the article entry from the database
          await db.delete(
            'articles',
            where: 'article_id = ?',
            whereArgs: [article['article_id']],
          );
        }
      } else {
        logger.info("No old articles to clean up");
      }
    } catch (e, stackTrace) {
      logger.severe('Error cleaning up the database', e, stackTrace);
    }
  }

  Future<void> insertFeedFilter({
    required String name,
    required String include,
    required String exclude,
    required Set<String> journals,
  }) async {
    final db = await database;

    await db.insert('feed_filters', {
      'name': name,
      'includedKeywords': include,
      'excludedKeywords': exclude,
      'journals': journals.join(','),
    });
  }

  Future<List<Map<String, dynamic>>> getFeedFilters() async {
    final db = await database;
    return await db.query('feed_filters', orderBy: 'dateCreated DESC');
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
  }) async {
    final db = await database;

    await db.update(
      'feed_filters',
      {
        'name': name,
        'includedKeywords': include,
        'excludedKeywords': exclude,
        'journals': journals.join(','),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFeedFilter(int id) async {
    final db = await database;
    await db.delete('feed_filters', where: 'id = ?', whereArgs: [id]);
  }
}
