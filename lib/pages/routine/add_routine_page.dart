import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:time_note/data/data_model.dart';
import 'package:time_note/util/efficiency_formatter.dart';

class AddRoutinePage extends StatefulWidget {
  final int type;

  const AddRoutinePage({Key key, this.type}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddRoutinePageState();
  }
}

class _AddRoutinePageState extends State<AddRoutinePage> {
  final TextEditingController defaultEfficiencyController =
      TextEditingController();

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
                        EfficiencyFormatter()
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
          title: Text("添加目标"),
        ),
        body: new Builder(builder: (BuildContext context) {
          return Column(
            children: <Widget>[
              Padding(
                  padding:
                      EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 14),
                  child: Table(
                      columnWidths: {
                        0: FractionColumnWidth(0.4),
                        1: FractionColumnWidth(0.6)
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: tableRows)),
              Center(
                child: RaisedButton(
                    child: const Text("完成"),
                    onPressed: () {
                      if (this.routineName == null || this.routineName == "") {
                        Scaffold.of(context).showSnackBar(snackBar);
                        return;
                      }
                      if (this.isCategory) {
                        Category result = Category(
                            name: this.routineName,
                            type: this.widget.type == null
                                ? this.selectedType
                                : 0,
                            defaultEfficiency: this.selectedType == 1
                                ? this.defaultEfficiency
                                : null);
                        Navigator.of(context).pop(result);
                      } else {
                        Routine result = Routine(
                            name: this.routineName,
                            type: this.widget.type == null
                                ? this.selectedType
                                : 0,
                            defaultEfficiency: this.selectedType == 1
                                ? this.defaultEfficiency
                                : null);
                        Navigator.of(context).pop(result);
                      }
                    }),
              )
            ],
          );
        }));
  }
}
