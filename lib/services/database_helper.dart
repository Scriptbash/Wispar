import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/crossref_journals_works_models.dart';
import '../publication_card.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'journals_database.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE journals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          issn TEXT,
          title TEXT,
          publisher TEXT,
          subjects TEXT
        )
      ''');

        // Create the 'favorites' table
        await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doi TEXT,
          title TEXT,
          abstract TEXT,
          journalTitle TEXT,
          publishedDate TEXT,  
          authors TEXT,
          FOREIGN KEY (doi) REFERENCES journals(issn)
        )
      ''');
      },
    );
  }

  Future<void> insertJournal(Journal journal) async {
    final db = await database;
    await db.insert('journals', journal.toMap());
  }

  Future<List<Journal>> getJournals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('journals');

    return List.generate(maps.length, (i) {
      return Journal(
        id: maps[i]['id'],
        issn: maps[i]['issn'],
        title: maps[i]['title'],
        publisher: maps[i]['publisher'],
        subjects: maps[i]['subjects'],
      );
    });
  }

  Future<void> removeJournal(String issn) async {
    final db = await database;
    await db.delete('journals', where: 'issn = ?', whereArgs: [issn]);
    ;
  }

  Future<bool> isJournalFollowed(String issn) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM journals WHERE issn = ?',
      [issn],
    ))!;
    return count > 0;
  }

  Future<void> createFavoritesTable(Database db) async {
    await db.execute('''
    CREATE TABLE favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      doi TEXT,
      title TEXT,
      abstract TEXT,
      journalTitle TEXT,
      publishedDate TEXT,  -- Store as TEXT or INTEGER (timestamp) based on your needs
      authors TEXT,  -- Store authors as a serialized string or use a separate table for authors
      FOREIGN KEY (doi) REFERENCES journals(issn)
    )
  ''');
  }

  Future<void> insertFavorite(PublicationCard publicationCard) async {
    final db = await database;
    await db.insert('favorites', {
      'doi': publicationCard.doi,
      'title': publicationCard.title,
      'abstract': publicationCard.abstract,
      'journalTitle': publicationCard.journalTitle,
      'publishedDate': publicationCard.publishedDate?.toIso8601String(),
      'authors': jsonEncode(publicationCard.authors
          .map((author) => author.toJson())
          .toList()), // Serialize authors to JSON
    });
  }

  Future<List<PublicationCard>> getFavoriteArticles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');

    return List.generate(maps.length, (i) {
      return PublicationCard(
        doi: maps[i]['doi'],
        title: maps[i]['title'],
        abstract: maps[i]['abstract'],
        journalTitle: maps[i]['journalTitle'],
        publishedDate: DateTime.parse(maps[i]['publishedDate']),
        authors: List<PublicationAuthor>.from(
          (jsonDecode(maps[i]['authors']) as List<dynamic>)
              .map((authorJson) => PublicationAuthor.fromJson(authorJson)),
        ), // Deserialize authors from JSON
      );
    });
  }

  Future<void> removeFavorite(String doi) async {
    final db = await database;
    await db.delete('favorites', where: 'doi = ?', whereArgs: [doi]);
  }

  Future<bool> isArticleFavorite(String doi) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM favorites WHERE doi = ?',
      [doi],
    ))!;
    return count > 0;
  }
}

class Journal {
  final int? id;
  final String issn;
  final String title;
  final String publisher;
  final String subjects;

  Journal(
      {this.id,
      required this.issn,
      required this.title,
      required this.publisher,
      required this.subjects});

  Map<String, dynamic> toMap() {
    return {
      'issn': issn,
      'title': title,
      'publisher': publisher,
      'subjects': subjects,
    };
  }
}

class FavoriteArticle {
  final int? id;
  final String doi;
  final String title;
  final String abstract;
  final String journalTitle;
  final DateTime publishedDate;
  final List<PublicationAuthor> authors;

  FavoriteArticle({
    this.id,
    required this.doi,
    required this.title,
    required this.abstract,
    required this.journalTitle,
    required this.publishedDate,
    required this.authors,
  });
}
