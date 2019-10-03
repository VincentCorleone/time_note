import 'package:sqflite/sqflite.dart';
import 'package:time_note/data/database_helper.dart';
import 'package:time_note/data/integrity_exception.dart';

class Node {
  List<Routine> _subRoutines;

  List<Routine> get subRoutines => this._subRoutines;

  set subRoutines(List<Routine> value) {
    if (this is! Category) {
      value.sort(this._compare);
    }

    this._subRoutines = value;
  }

  void addRoutine(Routine routine) {
    int insertIndex = -1;
    for (Routine subRoutine in subRoutines) {
      if (_compare(routine, subRoutine) <= 0) {
        insertIndex = this.subRoutines.indexOf(subRoutine);
        break;
      }
    }
    if (insertIndex == -1) {
      insertIndex = subRoutines.length;
    }
    this.subRoutines.insert(insertIndex, routine);
  }

  int _compare(Routine a, Routine b) {
    //return positive represent a > b
    if (a.type == b.type) {
      if (a is Category && b is! Category) {
        return -1;
      } else if (b is Category && a is! Category) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    } else {
      return a.type - b.type;
    }
  }
}

class Category extends Routine with Node {
  Category({
    id,
    name,
    type,
    pid,
    defaultEfficiency,
    minutes,
    score,
    this.totalMinutes,
    this.totalScore,
    routines,
    categories,
  }) : super(
            id: id,
            name: name,
            type: type,
            pid: pid,
            defaultEfficiency: defaultEfficiency,
            minutes: minutes,
            score: score);

  int totalMinutes;
  int totalScore;

  Map<String, dynamic> toMap() {
    Map tmp = super.toMap();
    Map tmp2 = new Map<String, dynamic>.from({
      'totalMinutes': totalMinutes,
      'totalScore': totalScore,
      'isCategory': 1,
    });
    List<String> keysToRemove = <String>[];
    for (String key in tmp2.keys) {
      if (tmp2[key] == null) {
        keysToRemove.add(key);
      }
    }
    for (String key in keysToRemove) {
      tmp2.remove(key);
    }
    tmp.addAll(tmp2);
    return tmp;
  }

  @override
  void update(Routine routine) {
    super.update(routine);
    if (routine is Category) {
      if (routine.totalMinutes != null) {
        this.totalMinutes = routine.totalMinutes;
      }
      if (routine.totalScore != null) {
        this.totalScore = routine.totalScore;
      }
    }
  }

  Category.fromMap(Map map) : super.fromMap(map) {
    this.totalMinutes = map['totalMinutes'];
    this.totalScore = map['totalScore'];
  }
}

class Routine {
  Routine({
    this.id,
    this.name,
    this.type,
    this.pid,
    this.defaultEfficiency,
    this.minutes,
    this.score,
  });

  int id;
  String name;
  int type;
  int pid;
  double defaultEfficiency;
  int minutes;
  int score;

  void update(Routine routine) {
    if (routine.name != null) {
      this.name = routine.name;
    }
    if (routine.type != null) {
      this.type = routine.type;
    }
    if (routine.pid != null) {
      this.pid = routine.pid;
    }
    if (routine.defaultEfficiency != null) {
      this.defaultEfficiency = routine.defaultEfficiency;
    }
    if (routine.minutes != null) {
      this.minutes = routine.minutes;
    }
    if (routine.score != null) {
      this.score = routine.score;
    }
  }

  @override
  String toString() {
    return this.name;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> tmp = {
      'id': this.id,
      'name': this.name,
      'type': this.type,
      'pid': this.pid,
      'isCategory': 0,
      'defaultEfficiency': defaultEfficiency,
      'minutes': this.minutes,
      'score': this.score,
    };
    List<String> keysToRemove = <String>[];
    for (String key in tmp.keys) {
      if (tmp[key] == null) {
        keysToRemove.add(key);
      }
    }
    for (String key in keysToRemove) {
      tmp.remove(key);
    }
    return tmp;
  }

  Routine.fromMap(Map map) {
    this.id = map['id'];
    this.name = map['name'];
    this.type = map['type'];
    this.pid = map['pid'];
    this.defaultEfficiency = map['defaultEfficiency'];
    this.minutes = map['minutes'];
    this.score = map['score'];
  }
}

class Record {
  int id;
  DateTime startAt;
  int rid;
  int last;
  Record lastRecord;
  Record nextRecord;

  Record({this.id, this.startAt, this.rid, this.last});

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'startAt': this.startAt.millisecondsSinceEpoch ~/ 1000,
      'rid': this.rid,
      'last': this.last,
    };
  }

  Record.fromMap(Map map) {
    this.id = map['id'];
    this.startAt = DateTime.fromMillisecondsSinceEpoch(map['startAt'] * 1000);
    this.rid = map['rid'];
    this.last = map['last'];
  }
}

class DatabaseRepository {
  static Future<Node> getTree() async {
    final Database _database = await DatabaseHelper().db;

    final List<Map<String, dynamic>> categories = await _database
        .rawQuery("select * from routine where isCategory=1 and id <> 0;");
    Map<int, List<Category>> categoriesByPid = Map();
    for (Map<String, dynamic> map in categories) {
      Category tmp = Category.fromMap(map);
      if (categoriesByPid[tmp.pid] == null) {
        categoriesByPid[tmp.pid] = List<Category>();
      }
      categoriesByPid[tmp.pid].add(tmp);
    }

    final List<Map<String, dynamic>> routines =
        await _database.rawQuery("select * from routine where isCategory=0;");
    Map<int, List<Routine>> pureRoutinesByPid = Map();
    for (Map<String, dynamic> map in routines) {
      Routine tmp = Routine.fromMap(map);
      if (pureRoutinesByPid[tmp.pid] == null) {
        pureRoutinesByPid[tmp.pid] = List<Routine>();
      }
      pureRoutinesByPid[tmp.pid].add(tmp);
    }

    List<Routine> getPureRoutines(int pid) {
      List<Routine> result = pureRoutinesByPid[pid] == null
          ? List<Routine>()
          : pureRoutinesByPid[pid];
      return result;
    }

    List<Category> getCategories(int pid) {
      List<Category> categories = categoriesByPid[pid];
      if (categories != null) {
        for (Category category in categories) {
          List<Routine> tmpRoutines = getPureRoutines(category.id);
          tmpRoutines.addAll(getCategories(category.id));
          category.subRoutines = tmpRoutines;
        }
      } else {
        categories = List<Category>();
      }
      return categories;
    }

    Node getRootNode() {
      List<Routine> tmpRoutines = getPureRoutines(0);
      tmpRoutines.addAll(getCategories(0));
      Node tmpNode = Node();
      tmpNode.subRoutines = tmpRoutines;
      return tmpNode;
    }

    return getRootNode();
  }

  static Future<Category> _createCategory(Category category) async {
    final Database _database = await DatabaseHelper().db;
    int id = await _database.insert("routine", category.toMap());
    return Category.fromMap(
        (await _database.rawQuery("select * from routine where id = $id"))[0])
      .._subRoutines = List<Routine>();
  }

  static Future<Routine> _createPureRoutine(Routine routine) async {
    final Database _database = await DatabaseHelper().db;
    int id = await _database.insert("routine", routine.toMap());
    return Routine.fromMap(
        (await _database.rawQuery("select * from routine where id = $id"))[0]);
  }

  static Future<Routine> createRoutine(Routine routine) async {
    final Database _database = await DatabaseHelper().db;
    if (routine.pid != 0) {
      print("select type from routine where id = ${routine.pid}");
      int type = (await _database.rawQuery(
          "select type from routine where id = ${routine.pid}"))[0]['type'];
      routine.type = type;
    }
    Routine tmp;
    if (routine is Category) {
      tmp = await _createCategory(routine);
    } else if (routine is Routine) {
      tmp = await DatabaseRepository._createPureRoutine(routine);
    } else {
      throw Exception("Invalid routine type");
    }
    return tmp;
  }

  static Future<void> deletePureRoutine(
      Routine routine, Transaction txn) async {
    Future<void> __deletePureRoutine(Transaction txn) async {
      await txn.rawDelete("delete from routine where id = ${routine.id}");
    }

    if (txn == null) {
      final Database _database = await DatabaseHelper().db;
      await _database.transaction((txn) async {
        await __deletePureRoutine(txn);
      });
    } else {
      await __deletePureRoutine(txn);
    }
  }

  static Future<void> deleteCategory(Category category, Transaction txn) async {
    Future<void> __deleteCategory(Transaction txn) async {
      await deleteSubRoutines(category, txn);
      await txn.rawDelete("delete from routine where id = ${category.id}");
    }

    if (txn == null) {
      final Database _database = await DatabaseHelper().db;
      await _database.transaction((txn) async {
        await __deleteCategory(txn);
      });
    } else {
      await __deleteCategory(txn);
    }
  }

  static Future<Map> getRoutineMapById(int id) async {
    final Database _database = await DatabaseHelper().db;
    return (await _database.rawQuery(
        "select type,defaultEfficiency from routine where id = $id;"))[0];
  }

  static Future<void> deleteSubRoutines(
      Category category, Transaction txn) async {
    Future<void> __deleteSubRoutines(Transaction txn) async {
      for (Routine tmp in category.subRoutines) {
        if (tmp is Category) {
          deleteCategory(tmp, txn);
        } else {
          deletePureRoutine(tmp, txn);
        }
      }
    }

    if (txn == null) {
      final Database _database = await DatabaseHelper().db;
      await _database.transaction((txn) async {
        await __deleteSubRoutines(txn);
      });
    } else {
      await __deleteSubRoutines(txn);
    }
  }

  static Future<Routine> _updatePureRoutine(Routine routine) async {
    final Database _database = await DatabaseHelper().db;
    _database.update("routine", routine.toMap(),
        where: "id = ?", whereArgs: [routine.id]);
    return Routine.fromMap((await _database
        .rawQuery("select * from routine where id = ${routine.id}"))[0]);
  }

  static Future<Category> _updateCategory(Category category) async {
    final Database _database = await DatabaseHelper().db;
    _database.update("routine", category.toMap(),
        where: "id = ?", whereArgs: [category.id]);
    return Category.fromMap((await _database
        .rawQuery("select * from routine where id = ${category.id}"))[0])
      .._subRoutines = List<Routine>();
  }

  static Future<Routine> updateRoutine(Routine routine) async {
    Routine tmp;
    if (routine is Category) {
      tmp = await _updateCategory(routine);
    } else if (routine is Routine) {
      tmp = await DatabaseRepository._updatePureRoutine(routine);
    } else {
      throw Exception("Invalid routine type");
    }
    return tmp;
  }

  static Record _latestRecord = Record(rid: -1);

  static Future<void> updateLatestRecordRid(int rid, int latestId) async {
    final Database _database = await DatabaseHelper().db;
    await _database
        .rawUpdate("update record set rid = $rid where id = $latestId");
    await _updateLatestRecord(latestId);
  }

  static Future<List<int>> startRoutine(int rid, double efficiency) async {
    final Database _database = await DatabaseHelper().db;

    Record tmp = await latestRecord;
    if (tmp.rid == -1) {
      int id = await _database.rawInsert(
          "insert into record (id, startAt, rid, last) values (1, (SELECT strftime('%s','now')), $rid, 1);");
      await _updateLatestRecord(id);
      return [0, 0];
    } else {
      int id = await _database.rawInsert(
          "insert into record (startAt, rid, last) values ((SELECT strftime('%s','now')), $rid, ${tmp.id});");

      await _database.rawUpdate(
          "update record set minutes = ((select startAt from record where id = $id) - (select startAt from record where id = ${tmp.id}))/60 where id =${tmp.id}");
      if (efficiency != null) {
        await _database.rawUpdate(
            "update record set score = round(minutes * $efficiency) where id =${tmp.id}");
      }
      Map result = (await _database.rawQuery(
          "select minutes, score from record where id = ${tmp.id}"))[0];
      await _updateLatestRecord(id);
      return List<int>.from([result["minutes"], result["score"]]);
    }
  }

  static Future<Record> get latestRecord async {
    final Database _database = await DatabaseHelper().db;
    if (_latestRecord.rid == -1) {
      List<Map<String, dynamic>> results = await _database.rawQuery(
          "select * from record where startAt = (select max(startAt) from record);");
      if (results.length > 0) {
        _latestRecord = Record.fromMap(results[0]);
      }
    }
    return _latestRecord;
  }

  static Future<void> _updateLatestRecord(int id) async {
    final Database _database = await DatabaseHelper().db;
    List<Map> results =
        await _database.rawQuery("select * from record where id = $id");
    if (results.length == 0) {
      throw "There are not records matched.";
    } else {
      _latestRecord = Record.fromMap(results[0]);
    }
  }

  static Future<String> get(String key) async {
    final Database _database = await DatabaseHelper().db;
    List results =
        await _database.rawQuery("select value from map where key = '$key'");
    if (results.length > 0) {
      return results[0]["value"];
    } else {
      return null;
    }
  }

  static Future<void> set(String key, String value) async {
    final Database _database = await DatabaseHelper().db;
    await _database.rawInsert(
        "INSERT OR REPLACE INTO map (key, value) VALUES ('$key','$value');");
  }

  static Future<bool> checkIntegrity() async {
    final Database _database = await DatabaseHelper().db;
    List<Map> results = await _database.rawQuery(
        "select id,((endAt - startAt)/60 - minutes) as difference from (select id,startAt,minutes from record where startAt <> (select max(startAt) from record)) as a,(select last,startAt as endAt from record where id<>last) as b where a.id = b.last;");
    for (Map result in results) {
      if (result['difference'] != 0) {
        throw IntegrityException(1, result['id']);
      }
    }
    //check minutes and score
    results = await _database.rawQuery(
        "select id,type, (s_minutes -minutes) as d_minutes,(s_score - score) as d_score from (select id,type,minutes,score from routine where isCategory = 0) as a,(select rid,sum(minutes) as s_minutes,sum(score) as s_score from record group by rid) as b where a.id = b.rid;");
    for (Map result in results) {
      if (result['d_minutes'] != 0) {
        throw IntegrityException(2, result['id']);
      }
      if (result['type'] == 1 && result['d_score'] != 0) {
        throw IntegrityException(3, result['id']);
      }
    }
    //check type
    results = await _database.rawQuery(
        "select a.id,(a.type - b.type) as difference from (select id,pid,type from routine where pid<>0) as a,(select id,type from routine) as b where b.id = a.pid;");
    for (Map result in results) {
      if (result['difference'] != 0) {
        throw IntegrityException(4, result['id']);
      }
    }
    //check totalMinutes
    results = await _database.rawQuery(
        "select id,case when sm is null then 0 else sm end + case when stm is null then 0 else stm end + minutes - totalMinutes as difference from (select id,minutes,totalMinutes from routine where id<>0 and isCategory=1) as aa left outer join (select a.pid,sm,stm from (select pid,sum(minutes) as sm from routine where pid<>0 and isCategory=0 group by pid) as a left outer join (select pid,sum(totalMinutes) as stm from routine where pid<>0 and isCategory=1 group by pid) as b on a.pid = b.pid union select a.pid,sm,stm from (select pid,sum(totalMinutes) as stm from routine where pid<>0 and isCategory=1 group by pid) as b left outer join  (select pid,sum(minutes) as sm from routine where pid<>0 and isCategory=0 group by pid) as a on a.pid = b.pid) as bb on aa.id = bb.pid;");
    for (Map result in results) {
      if (result['difference'] != 0) {
        throw IntegrityException(5, result['id']);
      }
    }
    //check totalScore
    results = await _database.rawQuery(
        "select id,case when sm is null then 0 else sm end + case when stm is null then 0 else stm end + score - totalScore as difference from (select id,score,totalScore from routine where id<>0 and isCategory=1 and type=1) as aa left outer join (select a.pid,sm,stm from (select pid,sum(score) as sm from routine where pid<>0 and isCategory=0 and type=1 group by pid) as a left outer join (select pid,sum(totalScore) as stm from routine where pid<>0 and isCategory=1 and type=1 group by pid) as b on a.pid = b.pid union select a.pid,sm,stm from (select pid,sum(totalScore) as stm from routine where pid<>0 and isCategory=1 and type=1 group by pid) as b left outer join  (select pid,sum(score) as sm from routine where pid<>0 and isCategory=0 and type=1 group by pid) as a on a.pid = b.pid) as bb on aa.id = bb.pid;");
    for (Map result in results) {
      if (result['difference'] != 0) {
        throw IntegrityException(6, result['id']);
      }
    }

    return true;
  }
}
