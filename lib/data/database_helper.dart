import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  initDb() async {
    String path = join(await getDatabasesPath(), 'time_note.db');
    print(path);
    var ourDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return ourDb;
  }

  void _onCreate(Database db, int version) async {
    //type=1 for invest, 2 for fixed time, 3 for sleep, 4 for waste
    await db.execute('''
      CREATE TABLE routine(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(31) NOT NULL,
        type TINYINT DEFAULT 0,
        pid INTEGER DEFAULT 0,
        defaultEfficiency DOUBLE,
        minutes INT DEFAULT 0,
        score INT DEFAULT 0,
        isCategory INT2 DEFAULT 0,
        totalMinutes INT DEFAULT 0,
        totalScore INT DEFAULT 0,
        createdAt DATETIME,
        FOREIGN KEY(pid) REFERENCES routine(id),
        CHECK ((type = 0 and pid <> 0) or (pid = 0 and type <> 0)),
        CHECK(defaultEfficiency >= 0.0 and defaultEfficiency <= 1.0)
      );
    ''');
    db.rawInsert('''
      INSERT INTO routine (id,name,type,defaultEfficiency,isCategory)
      VALUES (1,'浪费', 4, 0.0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (id,name,type,defaultEfficiency,isCategory)
      VALUES (2,'睡眠', 3, 0.0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory)
      VALUES ('投入', 1, 1.0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory)
      VALUES ('固定', 2, 0.0, 0);
    ''');
    int id = await db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory)
      VALUES ('音乐', 1, 1.0, 1);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory, pid)
      VALUES ('钢琴', 0, 1.0, 1, $id);
    ''');
  }
}