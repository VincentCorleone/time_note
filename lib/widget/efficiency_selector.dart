import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:time_note/util/efficiency_formatter.dart';

class EfficiencySelector extends StatefulWidget {
  final double defaultEfficiency;

  const EfficiencySelector({Key key, this.defaultEfficiency}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EfficiencySelectorState();
  }
}

class _EfficiencySelectorState extends State<EfficiencySelector> {
  double efficiency;

  TextEditingController efficiencyController = TextEditingController();

  @override
  void initState() {
    this.efficiency = this.widget.defaultEfficiency;
    this.efficiencyController.text =
        this.widget.defaultEfficiency.toStringAsFixed(2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('请评估刚结束的任务的效用值'),
      content: Table(
          columnWidths: {
            0: FractionColumnWidth(0.2),
            1: FractionColumnWidth(0.8)
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: <Widget>[
                TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      EfficiencyFormatter()
                    ],
                    controller: efficiencyController,
                    autocorrect: false,
                    onChanged: (String input) {
                      setState(() {
                        this.efficiency = double.parse(input);
                      });
                    },
                    decoration: InputDecoration(border: InputBorder.none)),
                Slider(
                  divisions: 100,
                  value: this.efficiency,
                  onChanged: (double value) {
                    setState(() {
                      this.efficiency = value;
                    });
                    efficiencyController.text = value.toStringAsFixed(2);
                  },
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
            ])
          ]),
      actions: <Widget>[
        FlatButton(
            child: Text("确定"),
            onPressed: () {
              Navigator.of(context).pop(this.efficiency);
            }),
      ],
    );
  }
}
