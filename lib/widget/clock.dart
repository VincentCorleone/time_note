import 'dart:async';

import 'package:flutter/material.dart';

class Clock extends StatefulWidget{



  final DateTime startTime;

  Clock({Key key, this.startTime}) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return _ClockState();
  }
}

class _ClockState extends State<Clock>{

  String continuedDuration = "0:00:00";

  Duration delay;
  Timer timer;


  @override
  void dispose() {
    this.timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    this.delay = Duration(milliseconds: 1000);
    this.timer = Timer.periodic(this.delay, (Timer t) => updateClock());
    this.updateClock();
    super.initState();
  }

  void updateClock(){
    setState(() {
      this.continuedDuration = this.widget.startTime == null?"0:00:00":DateTime.now().difference(this.widget.startTime).toString().split(".")[0];
    });
  }

  Widget clock(){
    return Text(
      this.continuedDuration,
      style: TextStyle(fontSize: 54.0,fontFamily: 'Helvetica Neue'),
    );
  }


  @override
  Widget build(BuildContext context) {
    return clock();
  }
}