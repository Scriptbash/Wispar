import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/crossref_journals_works_models.dart';
import '../widgets/publication_card.dart';
import '../widgets/downloaded_card.dart';
import '../models/journal_entity.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'wispar.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
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
          dateSaved TEXT
        )
      ''');
      },
    );
  }

  // Functions for journals
  Future<void> insertJournal(Journal journal) async {
    final db = await database;
    // Check if the journal is already in the database
    final List<Map<String, dynamic>> journalMaps = await db.query(
      'journals',
      columns: ['journal_id', 'dateFollowed'],
      where: 'issn = ?',
      whereArgs: [journal.issn],
    );

    if (journalMaps.isNotEmpty) {
      // Journal found, retrieve its ID
      final int journalId = journalMaps.first['journal_id'];

      // If the journal wasn't followed before, update the dateFollowed
      if (journalMaps.first['dateFollowed'] == null) {
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
      }
    } else {
      // Journal not found, insert it
      await db.insert('journals', journal.toMap());
    }
  }

  Future<List<Journal>> getJournals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * FROM journals
    WHERE dateFollowed IS NOT NULL
  ''');
    return List.generate(maps.length, (i) {
      return Journal(
        id: maps[i]['id'],
        issn: maps[i]['issn'],
        title: maps[i]['title'],
        publisher: maps[i]['publisher'],
        dateFollowed: maps[i]['dateFollowed'],
        lastUpdated: maps[i]['lastUpdated'],
      );
    });
  }

  Future<void> removeJournal(String issn) async {
    final db = await database;

    await db.update(
      'articles',
      {'dateCached': null},
      where: 'journal_id IN (SELECT journal_id FROM journals WHERE issn = ?)',
      whereArgs: [issn],
    );

    await db.update(
      'journals',
      {'dateFollowed': null, 'lastUpdated': null},
      where: 'issn = ?',
      whereArgs: [issn],
    );
  }

  Future<bool> isJournalFollowed(String issn) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM journals WHERE issn = ? AND dateFollowed IS NOT NULL',
      [issn],
    ))!;
    return count > 0;
  }

  Future<void> updateJournalLastUpdated(String issn) async {
    final db = await database;
    await db.update(
      'journals',
      {'lastUpdated': DateTime.now().toIso8601String()},
      where: 'issn = ?',
      whereArgs: [issn],
    );
  }

  // Functions for articles
  Future<void> insertArticle(
    PublicationCard publicationCard, {
    bool isLiked = false,
    bool isDownloaded = false,
    bool isCached = false,
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
      // Article does not exist, proceed with inserting
      final List<Map<String, dynamic>> journalMaps = await db.query(
        'journals',
        columns: ['journal_id'],
        where: 'issn = ?',
        whereArgs: [publicationCard.issn],
      );

      int journalId;

      if (journalMaps.isNotEmpty) {
        // Journal found, retrieve its ID
        journalId = journalMaps.first['journal_id'];
      } else {
        // Journal not found, insert it
        final Map<String, dynamic> journalData = {
          'issn': publicationCard.issn,
          'title': publicationCard.journalTitle, // default title
          'publisher': '',
        };

        journalId = await db.insert('journals', journalData);
      }
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
        'journal_id': journalId,
      });
    }
  }

  Future<List<PublicationCard>> getFavoriteArticles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT articles.*, journals.title AS journalTitle, journals.issn
    FROM articles
    JOIN journals ON articles.journal_id = journals.journal_id
    WHERE articles.dateLiked IS NOT NULL
  ''');

    return List.generate(maps.length, (i) {
      return PublicationCard(
        doi: maps[i]['doi'],
        title: maps[i]['title'],
        issn: maps[i]['issn'],
        abstract: maps[i]['abstract'],
        publishedDate: DateTime.parse(maps[i]['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(maps[i]['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ), // Deserialize authors from JSON
        dateLiked: maps[i]['dateLiked'],
        journalTitle: maps[i]['journalTitle'],
        url: maps[i]['url'],
        license: maps[i]['license'],
        licenseName: maps[i]['licenseName'],
      );
    });
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
        await db.update(
          'articles',
          {
            'dateCached': DateTime.now().toIso8601String(),
            'title': publicationCard.title,
            'abstract': publicationCard.abstract,
            'journal_id': // Get the corresponding journal_id based on issn
                (await db.query('journals',
                    columns: ['journal_id'],
                    where: 'issn = ?',
                    whereArgs: [publicationCard.issn]))[0]['journal_id'],
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
      await db.insert('articles', {
        'doi': publicationCard.doi,
        'title': publicationCard.title,
        'abstract': publicationCard.abstract,
        'journal_id': // Get the corresponding journal_id based on issn
            (await db.query('journals',
                columns: ['journal_id'],
                where: 'issn = ?',
                whereArgs: [publicationCard.issn]))[0]['journal_id'],
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
    SELECT articles.*, journals.title AS journalTitle, journals.issn
    FROM articles
    JOIN journals ON articles.journal_id = journals.journal_id
    WHERE articles.dateCached IS NOT NULL
  ''');
    return List.generate(maps.length, (i) {
      return PublicationCard(
        doi: maps[i]['doi'],
        title: maps[i]['title'],
        issn: maps[i]['issn'],
        abstract: maps[i]['abstract'],
        journalTitle: maps[i]['journalTitle'],
        publishedDate: DateTime.parse(maps[i]['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(maps[i]['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ),
        url: maps[i]['url'],
        license: maps[i]['license'],
        licenseName: maps[i]['licenseName'],
      );
    });
  }

  /*Future<void> clearCachedPublications() async {
    final db = await database;
    await db.delete(
      'articles',
      where:
          'dateCached IS NOT NULL AND (dateLiked IS NULL AND dateDownloaded IS NULL)',
    );
  }*/

// Functions for downloaded articles

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
    SELECT articles.*, journals.title AS journalTitle, journals.issn
    FROM articles
    JOIN journals ON articles.journal_id = journals.journal_id
    WHERE articles.dateDownloaded IS NOT NULL
  ''');
    return List.generate(maps.length, (i) {
      return DownloadedCard(
        pdfPath: maps[i]['pdfPath'],
        publicationCard: PublicationCard(
          doi: maps[i]['doi'],
          title: maps[i]['title'],
          issn: maps[i]['issn'],
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
  Future<void> saveSearchQuery(String queryName, String queryParams) async {
    final db = await database;
    final String dateSaved = DateTime.now().toIso8601String();
    await db.insert(
      'savedQueries',
      {
        'queryName': queryName,
        'queryParams': queryParams,
        'dateSaved': dateSaved,
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
  }

  // Cleanup the database, removing old articles
  Future<void> cleanupOldArticles(BuildContext context) async {
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
      WHERE dateCached < ? AND dateLiked IS NULL AND dateDownloaded IS NULL
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
            } catch (e) {
              debugPrint('Error deleting PDF file at $pdfPath: $e');
            }
          }

          // Delete the article entry from the database
          await db.delete(
            'articles',
            where: 'article_id = ?',
            whereArgs: [article['article_id']],
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("The database cleanup was successful.")),
        );
      } /*else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No old articles to clean up.")),
        );
      }*/
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during database cleanup: $e")),
      );
    }
  }
}
