import 'package:flutter/material.dart';
import 'package:flutter_icons/font_awesome_5.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// ignore: implementation_imports
import 'package:sqflite/src/exception.dart';
import 'package:time_note/data/data_model.dart';
import 'package:time_note/pages/routine/add_routine_page.dart';
import 'package:time_note/pages/routine/update_routine_page.dart';
import 'package:time_note/widget/clock.dart';
import 'package:time_note/widget/efficiency_selector.dart';
import 'package:time_note/widget/fancy_fab.dart';

class RoutinePage extends StatefulWidget {
  final Node currentNode;

  final void Function(Routine routine) startRoutine;

  final Record latestRecord;

  final BuildContext rootContext;

  final List<Function> stackActions;

  const RoutinePage(
      {Key key,
      this.currentNode,
      this.startRoutine,
      this.latestRecord,
      this.rootContext,
      this.stackActions})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoutinePageState();
  }
}

class _RoutinePageState extends State<RoutinePage> {
  void Function() fancyFabClose;

  void setPid(Routine tmp) {
    if (this.widget.currentNode is Category) {
      tmp.pid = (this.widget.currentNode as Category).id;
    } else {
      tmp.pid = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = this.widget.currentNode.subRoutines.length == 0
        ? Center(
            child: Text(
            "该目录下没有目标",
            style: TextStyle(fontSize: 19.0),
          ))
        : GestureDetector(
            onTap: this.fancyFabClose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Clock(startTime: this.widget.latestRecord.startAt),
                Expanded(
                  child: routineList(),
                )
              ],
            ),
          );

    String appBarTitle;
    Widget appBarLeading;

    if (this.widget.currentNode is! Category) {
      appBarTitle = "目标列表";
      appBarLeading = Container();
    } else {
      appBarTitle = (this.widget.currentNode as Category).name;
      appBarLeading = IconButton(
        icon: const Icon(Icons.navigate_before),
        onPressed: () {
          this.widget.stackActions[1]();
          Navigator.of(context).pop();
        },
      );
    }

    return Scaffold(
        appBar: AppBar(
          leading: appBarLeading,
          title: Text(appBarTitle),
        ),
        body: body,
        floatingActionButton: FancyFab(
          onAddClicked: () async {
            final Routine result = await Navigator.of(this.widget.rootContext)
                .push<Routine>(MaterialPageRoute(
                    builder: (context) => AddRoutinePage(
                          type: (this.widget.currentNode is Category)
                              ? (this.widget.currentNode as Category).type
                              : null,
                        )));
            if (result != null) {
              this.setPid(result);
              Routine tmp = await DatabaseRepository.createRoutine(result);
              this.widget.currentNode.addRoutine(tmp);
              setState(() {});
            }
          },
          onSortClicked: () {},
          passCloseFunction: (void Function() close) {
            this.fancyFabClose = close;
          },
        ));
  }

  final Map<int, Color> colorByType = {
    1: Colors.green,
    2: Colors.amber,
    3: Colors.blue,
    4: Colors.red,
  };

  Widget listItem(Routine routine) {
    GestureTapCallback onListItemTap;
    Icon navigateNext;
    String secondLine;

    String displayTime(int minutes) {
      return "${minutes ~/ 60}h${minutes % 60}m";
    }

    String hoverText;
    if (routine is Category) {
      onListItemTap = () async {
        this.widget.stackActions[0](routine);
        await Navigator.of(this.context).push(MaterialPageRoute(
            builder: (context) => RoutinePage(
                  currentNode: routine,
                  stackActions: this.widget.stackActions,
                  latestRecord: this.widget.latestRecord,
                  startRoutine: this.widget.startRoutine,
                  rootContext: this.widget.rootContext,
                )));
        setState(() {});
      };
      navigateNext = new Icon(
        Icons.navigate_next,
        color: this.colorByType[routine.type],
      );

      if (routine.type == 1) {
        secondLine = displayTime(routine.totalScore);
        hoverText =
            "${displayTime(routine.minutes)}\n${displayTime(routine.score)}";
      } else {
        secondLine = "";
        hoverText = "${displayTime(routine.minutes)}";
      }
    } else {
      onListItemTap = () {
        this.fancyFabClose();
      };
      navigateNext = new Icon(
        Icons.navigate_next,
        color: Color.fromARGB(0, 128, 128, 128),
      );
      if (routine.type == 1) {
        secondLine = displayTime(routine.score);
      } else {
        secondLine = "";
      }
    }

    List<Widget> actions = routine.id == 1
        ? null
        : <Widget>[
            IconSlideAction(
              caption: '编辑',
              color: Colors.black45,
              icon: Icons.edit,
              onTap: () async {
                Routine result =
                    await Navigator.of(context).push<Routine>(MaterialPageRoute(
                        builder: (context) => UpdateRoutinePage(
                              type: routine.type,
                              name: routine.name,
                              defaultEfficiency: routine.defaultEfficiency,
                              isCategory: routine is Category,
                            )));
                if (result != null) {
                  if ((routine is Category) && (result) is! Category) {
                    DatabaseRepository.deleteSubRoutines(routine, null);
                  }
                  result.id = routine.id;
                  Routine tmp = await DatabaseRepository.updateRoutine(result);
                  int index =
                      this.widget.currentNode.subRoutines.indexOf(routine);
                  setState(() {
                    this.widget.currentNode.subRoutines[index].update(tmp);
                  });
                }
              },
            ),
            IconSlideAction(
              caption: '删除',
              color: Colors.red,
              icon: Icons.delete,
              onTap: () async {
                if (routine is Category) {
                  if (await this.showDeleteAlertDialog(context)) {
                    try {
                      await DatabaseRepository.deleteCategory(routine, null);
                    } on SqfliteDatabaseException catch (e) {
                      if (e.message.contains("FOREIGN KEY constraint failed")) {
                        showDeleteFailedDialog(context);
                      }
                      return;
                    }
                    this.widget.currentNode.subRoutines.remove(routine);
                  }
                } else if (routine is Routine) {
                  try {
                    await DatabaseRepository.deletePureRoutine(routine, null);
                  } on SqfliteDatabaseException catch (e) {
                    if (e.message.contains("FOREIGN KEY constraint failed")) {
                      showDeleteFailedDialog(context);
                    }
                    return;
                  }
                  this.widget.currentNode.subRoutines.remove(routine);
                }
                setState(() {});
              },
            ),
          ];

    Widget minutesAndScoreWithoutHover = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
            displayTime(
                (routine is Category) ? routine.totalMinutes : routine.minutes),
            style: TextStyle(
              color: Colors.black,
            )),
        Text(secondLine,
            style: TextStyle(
              color: Colors.black,
            )),
      ],
    );

    Widget minutesAndScore = (routine is Category)
        ? Tooltip(message: hoverText, child: minutesAndScoreWithoutHover)
        : minutesAndScoreWithoutHover;
    return Slidable(
      child: Container(
        color: routine.id == this.widget.latestRecord.rid
            ? Color.fromARGB(255, 207, 207, 207)
            : null,
        child: InkWell(
          onTap: onListItemTap,
          child: Padding(
            padding: EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 14),
            child: Row(
              children: <Widget>[
                IconButton(
                  iconSize: 36,
                  icon: Icon(
                      routine.id == this.widget.latestRecord.rid
                          ? FontAwesome5.getIconData("stop-circle")
                          : FontAwesome5.getIconData("play-circle"),
                      color: this.colorByType[routine.type]),
                  onPressed: () {
                    if (routine.id == this.widget.latestRecord.rid) {
                      if (routine.id == 1) {
                      } else {
                        this.widget.startRoutine(null);
                      }
                    } else {
                      this.widget.startRoutine(routine);
                    }
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      routine.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                new Spacer(),
                minutesAndScore,
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: navigateNext,
                ),
              ],
            ),
          ),
        ),
      ),
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.2,
      secondaryActions: actions,
    );
  }

  Future<bool> showDeleteAlertDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('警告'),
          content: Text("本操作将删除本目标和本目标下的所有目标！"),
          actions: <Widget>[
            FlatButton(
                child: Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                }),
            FlatButton(
                child: Text("确定"),
                onPressed: () {
                  Navigator.of(context).pop(true);
                }),
          ],
        );
      },
    );
  }

  Future<void> showDeleteFailedDialog(BuildContext context) async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('提醒'),
          content: Text("因存在与本目标相关的记录，所以无法删除"),
          actions: <Widget>[
            FlatButton(
                child: Text("确定"),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  Widget routineList() {
    int numOfSubRoutines = this.widget.currentNode.subRoutines.length;

    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        if(index == numOfSubRoutines + 1){
          return Container();
        }
        return Divider(
          height: 1,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        if(index == numOfSubRoutines){
          return SizedBox(height: 80,);
        }
        return listItem(this.widget.currentNode.subRoutines[index]);
      },
      itemCount: numOfSubRoutines + 2,
    );
  }
}

class RoutinePageHolder extends StatefulWidget {
  final BuildContext rootContext;

  @override
  State<StatefulWidget> createState() {
    return _RoutinePageHolderState();
  }

  const RoutinePageHolder({Key key, this.rootContext}) : super(key: key);
}

class _RoutinePageHolderState extends State<RoutinePageHolder> {
  Record latestRecord = Record(rid: -1);

  List<int> latestRoutineIndex = List<int>();

  List<Category> currentNodeStack = [];

  List<Routine> startedRoutineStack;

  static const String StartedRoutineStack = "started_routine_stack";

  Node root;

  final snackBar = new SnackBar(
    content: new Text('忽略一分钟以下记录'),
    action: new SnackBarAction(
      label: '确定',
      onPressed: () {},
    ),
    duration: Duration(seconds: 1),
  );

  void push(Category node) {
    this.currentNodeStack.add(node);
  }

  void pop() {
    this.currentNodeStack.removeLast();
  }

  @override
  void initState() {
    root = Node();
    root.subRoutines = <Routine>[];
    this.startedRoutineStack = [];
    DatabaseRepository.getTree().then((Node root) async {
      String value = await DatabaseRepository.get(StartedRoutineStack);
      Record tmp = await DatabaseRepository.latestRecord;
      this.root = root;
      if (value != null) {
        this.startedRoutineStack = this.stringToList(value);
      }
      this.latestRecord = tmp;
      setState(() {

      });
    });
    super.initState();
  }

  void startRoutine(Routine routine) async {
    int id;
    if (routine == null) {
      id = 1;
      routine = this
          .root
          .subRoutines
          .firstWhere((Routine routine) => routine.id == 1);
    } else {
      id = routine.id;
    }
    List<int> minutesAndScore = [0, 0];
    if (this.latestRecord.rid != -1) {
      if (DateTime.now().difference(this.latestRecord.startAt) >
          Duration(minutes: 1)) {
        Map tmp =
            await DatabaseRepository.getRoutineMapById(this.latestRecord.rid);
        double efficiency;
        if (tmp['type'] == 1) {
          efficiency = await this
              .chooseEfficiencyDialog(this.context, tmp['defaultEfficiency']);
        }
        minutesAndScore = await DatabaseRepository.startRoutine(id, efficiency);
      } else {
        await DatabaseRepository.updateLatestRecordRid(
            id, this.latestRecord.id);
        Scaffold.of(this.context).showSnackBar(this.snackBar);
      }
    } else {
      minutesAndScore = await DatabaseRepository.startRoutine(id, null);
    }
    this.latestRecord = await DatabaseRepository.latestRecord;
    await this.handleRoutineStack(routine, minutesAndScore);
    if (id == 1) {
      this.startedRoutineStack = [routine];
    } else {
      this.startedRoutineStack = List.from(this.currentNodeStack);
      this.startedRoutineStack.add(routine);
    }
    await DatabaseRepository.set(
        StartedRoutineStack, this.listToString(this.startedRoutineStack));

    //todo: to be removed
    if (await DatabaseRepository.checkIntegrity()) {
      print("All is well.");
    }
    setState(() {});
  }

  Future<void> handleRoutineStack(
      Routine routine, List<int> minutesAndScore) async {
    if (minutesAndScore[0] != 0 || minutesAndScore[1] != 0) {
      bool first = true;
      for (Routine tmp in this.startedRoutineStack.reversed) {
        if (first) {
          if (tmp is Category) {
            Category category = Category(
                id: tmp.id,
                minutes: minutesAndScore[0] + tmp.minutes,
                score: minutesAndScore[1] + tmp.score,
                totalMinutes: minutesAndScore[0] + tmp.totalMinutes,
                totalScore: minutesAndScore[1] + tmp.totalScore);
            Category newCategory =
                await DatabaseRepository.updateRoutine(category);
            tmp.update(newCategory);
          } else {
            Routine routine = Routine(
                id: tmp.id,
                minutes: minutesAndScore[0] + tmp.minutes,
                score: minutesAndScore[1] + tmp.score);
            Routine newRoutine =
                await DatabaseRepository.updateRoutine(routine);
            tmp.update(newRoutine);
          }

          first = false;
        } else {
          Category category = Category(
              id: tmp.id,
              totalMinutes: minutesAndScore[0] + (tmp as Category).totalMinutes,
              totalScore: minutesAndScore[1] + (tmp as Category).totalScore);
          Category newCategory =
              await DatabaseRepository.updateRoutine(category);
          tmp.update(newCategory);
        }
      }
    }
  }

  String listToString(List<Routine> routines) {
    if (routines.length == 0) {
      return "";
    }
    String result = routines[0].id.toString();
    for (int i = 1; i < routines.length; i++) {
      result = result + "-" + routines[i].id.toString();
    }
    return result;
  }

  List<Routine> stringToList(String value) {
    Node currentNode = this.root;
    List<int> indexList =
        value.split("-").map((String value) => int.parse(value)).toList();
    List<Routine> result = [];
    for (int i = 0; i < indexList.length - 1; i++) {
      Routine tmp = currentNode.subRoutines
          .firstWhere((Routine element) => element.id == indexList[i]);
      result.add(tmp);
      currentNode = tmp as Category;
    }
    result.add(currentNode.subRoutines.firstWhere(
        (Routine element) => element.id == indexList[indexList.length - 1]));
    return result;
  }

  Future<double> chooseEfficiencyDialog(
      BuildContext context, double defaultEfficiency) async {
    return await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EfficiencySelector(defaultEfficiency: defaultEfficiency);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Function> stackActions = [this.push, this.pop];
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
            builder: (context) => RoutinePage(
                  currentNode: root,
                  stackActions: stackActions,
                  latestRecord: this.latestRecord,
                  startRoutine: this.startRoutine,
                  rootContext: this.widget.rootContext,
                ),
            settings: settings);
      },
    );
  }
}
