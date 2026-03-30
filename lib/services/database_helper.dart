import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/project.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dub_projects.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Increased version to 2 for the database upgrade
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      mediaPath TEXT NOT NULL,
      englishTranscript TEXT NOT NULL,
      translatedText TEXT NOT NULL,
      targetLanguage TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Safely upgrade existing users' databases without losing data
      await db.execute('ALTER TABLE projects RENAME COLUMN hausaTranslation TO translatedText');
      await db.execute('ALTER TABLE projects ADD COLUMN targetLanguage TEXT DEFAULT "Hausa"');
    }
  }

  Future<int> create(Project project) async {
    final db = await instance.database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> readAllProjects() async {
    final db = await instance.database;
    final result = await db.query('projects', orderBy: 'createdAt DESC');
    return result.map((json) => Project.fromMap(json)).toList();
  }
}
