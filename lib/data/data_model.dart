import 'package:sqflite/sqflite.dart';
import 'package:time_note/data/database_helper.dart';

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
    if (a.displayType == b.displayType) {
      if (a is Category && b is! Category) {
        return -1;
      } else if (b is Category && a is! Category) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    } else {
      return a.displayType - b.displayType;
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
    this.displayType,
    this.pid,
    this.defaultEfficiency,
    this.minutes,
    this.score,
  });

  int id;
  String name;
  int type;
  int displayType;
  int pid;
  double defaultEfficiency;
  int minutes;
  int score;

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
    this.displayType = this.type;
    this.pid = map['pid'];
    this.defaultEfficiency = map['defaultEfficiency'];
    this.minutes = map['minutes'];
    this.score = map['score'];
  }
}

class DatabaseRepository {
  static Future<Node> getTree() async {
    final Database _database = await DatabaseHelper().db;

    final List<Map<String, dynamic>> categories =
        await _database.rawQuery("select * from routine where isCategory=1;");
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

    List<Routine> getPureRoutines(int pid, int displayType) {
      List<Routine> result = pureRoutinesByPid[pid] == null
          ? List<Routine>()
          : pureRoutinesByPid[pid];
      if (displayType != null) {
        for (Routine routine in result) {
          routine.displayType = displayType;
        }
      }
      return result;
    }

    List<Category> getCategories(int pid, int displayType) {
      List<Category> categories = categoriesByPid[pid];
      if (categories != null) {
        for (Category category in categories) {
          if (displayType != null) {
            category.displayType = displayType;
          }
          List<Routine> tmpRoutines =
              getPureRoutines(category.id, category.displayType);
          tmpRoutines.addAll(getCategories(category.id, category.displayType));
          category.subRoutines = tmpRoutines;
        }
      } else {
        categories = List<Category>();
      }
      return categories;
    }

    Node getRootNode() {
      List<Routine> tmpRoutines = getPureRoutines(0, null);
      tmpRoutines.addAll(getCategories(0, null));
      Node tmpNode = Node();
      tmpNode.subRoutines = tmpRoutines;
      return tmpNode;
    }

    return getRootNode();
  }

  static Future<Category> _createCategory(Category category) async {
    final Database _database = await DatabaseHelper().db;
    int id = await _database.insert("routine", category.toMap());
    print(id);
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

  static Future<int> deletePureRoutine(Routine routine) async {
    final Database _database = await DatabaseHelper().db;
    return await _database
        .rawDelete("delete from routine where id = ${routine.id}");
  }

  static Future<int> deleteCategory(Category category) async {
    final Database _database = await DatabaseHelper().db;
    deleteSubRoutines(category);
    return await _database
        .rawDelete("delete from routine where id = ${category.id}");
  }



  static Future<void> deleteSubRoutines(Category category) async {
    for (Routine tmp in category.subRoutines) {
      if (tmp is Category) {
        deleteCategory(tmp);
      } else {
        deletePureRoutine(tmp);
      }
    }
  }

  static Future<Routine> _updatePureRoutine(Routine routine) async {
    final Database _database = await DatabaseHelper().db;
    _database.update("routine", routine.toMap(),where:"id = ?",whereArgs: [routine.id]);
    return Routine.fromMap(
        (await _database.rawQuery("select * from routine where id = ${routine.id}"))[0]);
  }

  static Future<Category> _updateCategory(Category category) async {
    final Database _database = await DatabaseHelper().db;
    _database.update("routine", category.toMap(),where:"id = ?",whereArgs: [category.id]);
    return Category.fromMap(
        (await _database.rawQuery("select * from routine where id = ${category.id}"))[0]).._subRoutines = List<Routine>();
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
}
