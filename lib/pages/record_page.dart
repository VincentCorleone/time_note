import 'package:flutter/material.dart';

class RecordPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _RecordPageState();
  }
}

class _RecordPageState extends State<RecordPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Text("chart",style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        )
    );
  }
}