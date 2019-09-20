import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _MessagePageState();
  }
}

class _MessagePageState extends State<MessagePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Text("message",style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        )
    );
  }
}