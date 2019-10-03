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
    var ourDb = await openDatabase(path, version: 1, onCreate: _onCreate, onConfigure: _onConfigure);
    return ourDb;
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }


  void _onCreate(Database db, int version) async {
    //type=1 for invest, 2 for fixed time, 3 for sleep, 4 for waste
    await db.execute('''
      CREATE TABLE routine(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(31) NOT NULL,
        type TINYINT NOT NULL,
        pid INTEGER,
        defaultEfficiency DOUBLE,
        minutes INT DEFAULT 0,
        score INT DEFAULT 0,
        isCategory INT2 DEFAULT 0,
        totalMinutes INT DEFAULT 0,
        totalScore INT DEFAULT 0,
        FOREIGN KEY(pid) REFERENCES routine(id),
        CHECK ((type = null and pid <> null and pid <> 0) or (type <> null and pid = 0)),
        CHECK(defaultEfficiency >= 0.0 and defaultEfficiency <= 1.0)
      );
    ''');
    db.rawInsert('''
      INSERT INTO routine (id,name,type,defaultEfficiency,isCategory, pid)
      VALUES (0,'根', 0, 0.0, 1, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (id,name,type,defaultEfficiency,isCategory, pid)
      VALUES (1,'浪费', 4, 0.0, 0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (id,name,type,defaultEfficiency,isCategory, pid)
      VALUES (2,'睡眠', 3, 0.0, 0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory, pid)
      VALUES ('固定', 2, 0.0, 0, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory, pid)
      VALUES ('投入', 1, 1.0, 0, 0);
    ''');
    int id = await db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory, pid)
      VALUES ('音乐', 1, 1.0, 1, 0);
    ''');
    db.rawInsert('''
      INSERT INTO routine (name,type,defaultEfficiency,isCategory, pid)
      VALUES ('钢琴',1, 1.0, 1, $id);
    ''');

    //duration is in minutes
    await db.execute('''
      CREATE TABLE record(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startAt INTEGER NOT NULL,
        rid INTEGER NOT NULL,
        last INTEGER NOT NULL,
        minutes INT DEFAULT 0,
        score INT DEFAULT 0,
        FOREIGN KEY(rid) REFERENCES routine(id),
        FOREIGN KEY(last) REFERENCES record(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE map(
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
//
//    await db.execute('''
//      CREATE TRIGGER record_minute_and_score AFTER INSERT
//      ON record
//      BEGIN
//          update record set minutes = (new.startAt - (select startAt from record where id = new.last))/60 where id = new.last;
//          update record set score = case (select type from routine where id = (select rid from record where id = new.last)) when 1 then round(minutes * new.lastRecordEfficiency) else 0 end where id = new.last;
//      END;
//      CREATE TRIGGER routine_minutes AFTER UPDATE OF minutes
//      ON record
//      BEGIN
//          update routine set minutes = minutes + new.minutes - old.minutes where id = new.rid;
//          update routine set totalMinutes = case isCategory when 1 then totalMinutes + new.minutes - old.minutes else totalMinutes end where id = new.rid;
//      END;
//      CREATE TRIGGER routine_score AFTER UPDATE OF score
//      ON record
//      BEGIN
//          update routine set score = score + new.score - old.score where id = new.rid;
//          update routine set totalScore = case isCategory when 1 then totalScore + new.score - old.score else totalScore end where id = new.rid;
//      END;
//      CREATE TRIGGER routine_totalMinutes AFTER UPDATE OF totalMinutes
//      ON routine
//      BEGIN
//          update routine set totalMinutes = totalMinutes + new.totalMinutes - old.totalMinutes where id = case (select pid from routine where id = new.pid) when 0 then -1 else new.pid end;
//      END;
//      CREATE TRIGGER routine_totalScore AFTER UPDATE OF totalScore
//      ON routine
//      BEGIN
//          update routine set totalScore = totalScore + new.totalScore - old.totalScore where id = case (select pid from routine where id = new.pid) when 0 then -1 else new.pid end;
//      END;
//    ''');
  }
}