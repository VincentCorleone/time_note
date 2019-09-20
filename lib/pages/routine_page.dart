import 'package:flutter/material.dart';
import 'package:flutter_icons/font_awesome_5.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:time_note/data/data_model.dart';
import 'package:time_note/pages/routine/add_routine_page.dart';
import 'package:time_note/pages/routine/update_routine_page.dart';
import 'package:time_note/widget/clock.dart';
import 'package:time_note/widget/fancy_fab.dart';

class RoutinePage extends StatefulWidget {
  final Node currentNode;

  final void Function(int id) startRoutine;

  final int activeRoutineId;

  final BuildContext rootContext;

  const RoutinePage(
      {Key key,
      this.currentNode,
      this.startRoutine,
      this.activeRoutineId,
      this.rootContext})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoutinePageState();
  }
}

class _RoutinePageState extends State<RoutinePage> {
  Node currentNode = Node();

  DateTime startTime;

  String continuedDuration;

  @override
  void initState() {
    super.initState();
    if (this.widget.currentNode != null) {
      this.currentNode = this.widget.currentNode;
    } else {
      this.currentNode.subRoutines = <Routine>[];
    }

    if ((this.currentNode is! Category) &&
        (this.currentNode.subRoutines.length == 0)) {
      print("load data");
      DatabaseRepository.getTree().then((Node root) {
        setState(() {
          this.currentNode = root;
        });
      });
    }
  }

  void Function() fancyFabClose;

  void setPid(Routine tmp) {
    if (this.currentNode is Category) {
      tmp.pid = (this.currentNode as Category).id;
    }
  }

  void setDisplayType(Routine tmp) {
    if (this.currentNode is Category) {
      tmp.displayType = (this.currentNode as Category).displayType;
    } else {
      tmp.displayType = tmp.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = this.currentNode.subRoutines.length == 0
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
                Clock(startTime: this.startTime),
                Expanded(
                  child: routineList(),
                )
              ],
            ),
          );

    String appBarTitle;
    Widget appBarLeading;

    if (this.currentNode is! Category) {
      appBarTitle = "目标列表";
      appBarLeading = Container();
    } else {
      appBarTitle = (this.currentNode as Category).name;
      appBarLeading = IconButton(
        icon: const Icon(Icons.navigate_before),
        tooltip: 'Last page',
        onPressed: () {
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
            bool canTypeSelect = !(this.currentNode is Category);

            final Routine result = await Navigator.of(this.widget.rootContext)
                .push<Routine>(MaterialPageRoute(
                    builder: (context) => AddRoutinePage(
                          type: (this.currentNode is Category)
                              ? (this.currentNode as Category).type
                              : null,
                        )));
            if (result != null) {
              this.setPid(result);
              Routine tmp = await DatabaseRepository.createRoutine(result);

              this.setDisplayType(tmp);
              this.currentNode.addRoutine(tmp);
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
    if (routine is Category) {
      onListItemTap = () {
        Navigator.of(this.context).push(MaterialPageRoute(
            builder: (context) => RoutinePage(
                  currentNode: routine as Category,
                  activeRoutineId: this.widget.activeRoutineId,
                  startRoutine: this.widget.startRoutine,
                  rootContext: this.widget.rootContext,
                )));
      };
      navigateNext = new Icon(
        Icons.navigate_next,
        color: this.colorByType[routine.displayType],
      );

      if (routine.displayType == 1) {
        secondLine = (routine as Category).totalScore.toString() +
            " points = " +
            ((routine as Category).totalScore / 60).toStringAsFixed(1) +
            "h";
      } else {
        secondLine = "";
      }
    } else {
      onListItemTap = () {
        this.fancyFabClose();
      };
      navigateNext = new Icon(
        Icons.navigate_next,
        color: Color.fromARGB(0, 128, 128, 128),
      );
      if (routine.displayType == 1) {
        secondLine = routine.score.toString() +
            " points = " +
            (routine.score / 60).toStringAsFixed(1) +
            "h";
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
                if ((routine is Category) && (result) is! Category) {
                  DatabaseRepository.deleteSubRoutines(routine);
                }
                result.id = routine.id;
                Routine tmp = await DatabaseRepository.updateRoutine(result);
                int index = this.currentNode.subRoutines.indexOf(routine);
                setState(() {this.currentNode.subRoutines[index] = tmp;});
              },
            ),
            IconSlideAction(
              caption: '删除',
              color: Colors.red,
              icon: Icons.delete,
              onTap: () async {
                if (routine is Category) {
                  if (await this.showDeleteAlertDialog(context)) {
                    DatabaseRepository.deleteCategory(routine);
                    this.currentNode.subRoutines.remove(routine);
                  }
                } else if (routine is Routine) {
                  DatabaseRepository.deletePureRoutine(routine);
                  this.currentNode.subRoutines.remove(routine);
                }
                setState(() {});
              },
            ),
          ];

    return Slidable(
      child: Container(
        color: routine.id == this.widget.activeRoutineId
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
                      routine.id == this.widget.activeRoutineId
                          ? FontAwesome5.getIconData("stop-circle")
                          : FontAwesome5.getIconData("play-circle"),
                      color: this.colorByType[routine.displayType]),
                  onPressed: () {
                    this.widget.startRoutine(routine.id);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text((routine.minutes / 60).toStringAsFixed(1) + "h",
                        style: TextStyle(
                          color: Colors.black,
                        )),
                    Text(secondLine,
                        style: TextStyle(
                          color: Colors.black,
                        )),
                  ],
                ),
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
      actionExtentRatio: 0.15,
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

  int compare(Routine a, Routine b) {
    if (a.displayType == b.displayType) {
      if (a is Category && b is! Category) {
        return 1;
      } else if (b is Category && a is! Category) {
        return -1;
      } else {
        return 0;
      }
    } else {
      return a.displayType - b.displayType;
    }
  }

  Widget routineList() {
    int numOfSubRoutines = this.currentNode.subRoutines.length;

    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        return Divider(
          height: 1,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return listItem(this.currentNode.subRoutines[index]);
      },
      itemCount: numOfSubRoutines + 1,
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
  int activeRoutineId = -1;

  void startRoutine(int id) {
    setState(() {
      this.activeRoutineId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
            builder: (context) => RoutinePage(
                  activeRoutineId: this.activeRoutineId,
                  startRoutine: this.startRoutine,
                  rootContext: this.widget.rootContext,
                ));
      },
    );
  }
}
