import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:time_note/data/data_model.dart';

class UpdateRoutinePage extends StatefulWidget {
  final int type;

  final String name;

  final double defaultEfficiency;

  final bool isCategory;

  const UpdateRoutinePage(
      {Key key, this.type, this.name, this.defaultEfficiency, this.isCategory})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _UpdateRoutinePageState();
  }
}

class _UpdateRoutinePageState extends State<UpdateRoutinePage> {
  final TextEditingController defaultEfficiencyController =
      TextEditingController();

  final TextEditingController nameController = TextEditingController();

  int selectedType = 1;
  String routineName;
  double defaultEfficiency = 1.0;
  bool isCategory = true;

  Picker picker;

  final snackBar = new SnackBar(
    content: new Text('目标名称不能为空'),
    action: new SnackBarAction(
      label: '确定',
      onPressed: () {},
    ),
    duration: Duration(seconds: 2),
  );

  @override
  void initState() {
    if (this.widget.type != null) {
      this.selectedType = this.widget.type;
    }
    if (this.widget.name != null) {
      this.routineName = this.widget.name;
      nameController.text = this.widget.name;
    }
    if (this.widget.defaultEfficiency != null) {
      this.defaultEfficiency = this.widget.defaultEfficiency;
    }
    if (this.widget.isCategory != null) {
      this.isCategory = this.widget.isCategory;
    }

    picker = new Picker(
        adapter:
            PickerDataAdapter<String>(pickerdata: <String>["投入", "固定", "浪费"]),
        changeToFirst: false,
        hideHeader: false,
        onConfirm: (Picker picker, List value) {
          setState(() {
            if (value[0] == 0) {
              this.selectedType = 1;
            }
            if (value[0] == 1) {
              this.selectedType = 2;
            }
            if (value[0] == 2) {
              this.selectedType = 4;
            }
          });
        });
    this.defaultEfficiencyController.text =
        this.defaultEfficiency.toStringAsFixed(2);
    super.initState();
  }

  Future<bool> showDeleteSubRoutinesAlertDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('警告'),
          content: Text("本操作将删除本目标下的所有目标！"),
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

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = 16.0;

    final Map<int, String> typeNameByTypeId = {1: "投入", 2: "固定", 4: "浪费"};

    List<TableRow> tableRows = [
      TableRow(
        children: <Widget>[
          Text(
            "目标名称",
            style: TextStyle(
              fontSize: titleFontSize,
            ),
          ),
          TextField(
            autocorrect: false,
            onChanged: (String input) {
              this.routineName = input;
            },
            decoration:
                InputDecoration(hintText: "请输入目标名称", border: InputBorder.none),
            controller: nameController,
          ),
          SizedBox(
            height: 48.0,
            width: 0.0,
          ),
        ],
      ),
      TableRow(children: <Widget>[
        Divider(
          height: 1,
        ),
        Divider(
          height: 1,
        ),
        Divider(
          height: 1,
        )
      ]),
      TableRow(
        children: <Widget>[
          Text(
            "可否包含子目标",
            style: TextStyle(
              fontSize: titleFontSize,
            ),
          ),
          Container(
            child: CupertinoSwitch(
              value: this.isCategory,
              onChanged: (bool value) {
                setState(() {
                  this.isCategory = value;
                });
              },
            ),
            alignment: Alignment.centerLeft,
          ),
          SizedBox(
            height: 48.0,
            width: 0.0,
          ),
        ],
      ),
      TableRow(children: <Widget>[
        Divider(
          height: 1,
        ),
        Divider(
          height: 1,
        ),
        Divider(
          height: 1,
        )
      ]),
    ];

    int insertIndex = 2;

    if (this.widget.type == null) {
      List<TableRow> selectType = [
        TableRow(
          children: <Widget>[
            Text(
              "目标类别",
              style: TextStyle(
                fontSize: titleFontSize,
              ),
            ),
            GestureDetector(
              onTap: () {
                this.picker.showModal(this.context);
              },
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  typeNameByTypeId[this.selectedType],
                  style: TextStyle(
                    fontSize: titleFontSize,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
              width: 0.0,
            ),
          ],
        ),
        TableRow(children: <Widget>[
          Divider(
            height: 1,
          ),
          Divider(
            height: 1,
          ),
          Divider(
            height: 1,
          )
        ]),
      ];
      tableRows.insertAll(insertIndex, selectType);
      insertIndex = 4;
    }

    if (this.selectedType == 1) {
      List<TableRow> selectDefaultEfficiency = [
        TableRow(
          children: <Widget>[
            Text(
              "默认效用值",
              style: TextStyle(
                fontSize: titleFontSize,
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        _UsNumberTextInputFormatter()
                      ],
                      controller: defaultEfficiencyController,
                      autocorrect: false,
                      onChanged: (String input) {
                        setState(() {
                          this.defaultEfficiency = double.parse(input);
                        });
                      },
                      decoration: InputDecoration(border: InputBorder.none)),
                ),
                Slider(
                  divisions: 100,
                  value: this.defaultEfficiency,
                  onChanged: (double value) {
                    setState(() {
                      this.defaultEfficiency = value;
                    });
                    this.defaultEfficiencyController.text =
                        value.toStringAsFixed(2);
                  },
                ),
              ],
            ),
            SizedBox(height: 48.0, width: 0.0),
          ],
        ),
        TableRow(children: <Widget>[
          Divider(
            height: 1,
          ),
          Divider(
            height: 1,
          ),
          Divider(
            height: 1,
          )
        ]),
      ];
      tableRows.insertAll(insertIndex, selectDefaultEfficiency);
    }

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.navigate_before),
            tooltip: 'Last page',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text("编辑目标"),
        ),
        body: new Builder(builder: (BuildContext context) {
          return Column(
            children: <Widget>[
              Padding(
                padding:
                    EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 14),
                child: Column(
                  children: <Widget>[
                    Table(
                        columnWidths: {
                          0: FractionColumnWidth(0.4),
                          1: FractionColumnWidth(0.6)
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: tableRows)
                  ],
                ),
              ),
              Center(
                child: RaisedButton(
                    child: const Text("完成"),
                    onPressed: () async {
                      if (this.routineName == null || this.routineName == "") {
                        Scaffold.of(context).showSnackBar(snackBar);
                        return;
                      }
                      bool commit = true;
                      if(this.widget.isCategory && !this.isCategory){
                        //todo: alert
                        commit = await this.showDeleteSubRoutinesAlertDialog(context);
                      }
                      if(commit){
                        if (this.isCategory) {
                          Category result = Category(
                              name: this.routineName,
                              defaultEfficiency: this.selectedType == 1
                                  ? this.defaultEfficiency
                                  : null);
                          Navigator.of(context).pop(result);
                        } else {
                          Routine result = Routine(
                              name: this.routineName,
                              defaultEfficiency: this.selectedType == 1
                                  ? this.defaultEfficiency
                                  : null);
                          Navigator.of(context).pop(result);
                        }
                      }
                    }),
              )
            ],
          );
        }));
  }
}

class _UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text;
    int selectionIndex = newValue.selection.end;

    void revert() {
      //keep origin value bacause of invalid input
      value = oldValue.text;
      selectionIndex = oldValue.selection.end;
    }

    if (oldValue.text == "1.00" && value == "-") {
      value = "0.00";
      return new TextEditingValue(
        text: value,
        selection: new TextSelection.collapsed(offset: 4),
      );
    }
    //only allow double input
    double parsedValue;
    try {
      parsedValue = double.parse(value);
    } catch (e) {
      revert();
      return new TextEditingValue(
        text: value,
        selection: new TextSelection.collapsed(offset: selectionIndex),
      );
    }

    if (parsedValue > 1.0) {
      value = "1.00";
    } else if (parsedValue < 0.0) {
      value = "0.00";
    } else {
      value = parsedValue.toStringAsFixed(2);
    }

    return new TextEditingValue(
      text: value,
      selection: new TextSelection.collapsed(offset: selectionIndex),
    );
  }
}