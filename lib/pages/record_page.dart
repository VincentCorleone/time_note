import 'package:flutter/material.dart';

class RecordPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RecordPageState();
  }
}

class _RecordPageState extends State<RecordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("记录"),
        ),
        body: Center(
          child: Text("Record",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        ));
  }
}
