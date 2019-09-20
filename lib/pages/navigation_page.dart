import 'package:flutter/material.dart';
import 'package:time_note/pages/chart_page.dart';
import 'package:time_note/pages/me_page.dart';
import 'package:time_note/pages/message_page.dart';
import 'package:time_note/pages/routine_page.dart';
import 'package:time_note/pages/record_page.dart';



class NavigationPage extends StatefulWidget {
  NavigationPage({Key key}) : super(key: key);

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _selectedIndex = 0;



  List<Widget> _widgetOptions;

  void  _onItemTapped(int index){
    setState(() {
      this._selectedIndex = index;
    });
  }

  @override
  void initState() {
    _widgetOptions = <Widget>[
      RoutinePageHolder(rootContext: this.context),
      RecordPage(),
      ChartPage(),
      MessagePage(),
      MePage()
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex)
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.today),
              title: Text("项目")
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.today),
              title: Text("记录")
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.multiline_chart),
              title: Text("图表")
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              title: Text("消息")
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              title: Text("我")
          ),
        ],
        unselectedItemColor: Colors.blue,
        selectedItemColor: Colors.amber[800],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}