import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE journals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            issn TEXT,
            title TEXT,
            publisher TEXT,
            subjects TEXT
          )
          ''',
        );
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
