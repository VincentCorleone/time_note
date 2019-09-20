import 'package:flutter/material.dart';

class FancyFab extends StatefulWidget {
  final VoidCallback onAddClicked;

  final VoidCallback onSortClicked;

  final void Function(void Function()) passCloseFunction;

  const FancyFab({Key key, this.onAddClicked, this.onSortClicked, this.passCloseFunction})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FancyFabState();
  }
}

class _FancyFabState extends State<FancyFab>
    with SingleTickerProviderStateMixin {
  bool isOpened = false;
  AnimationController _animationController;
  Animation<Color> _buttonColor;
  Animation<double> _animateIcon;
  Animation<double> _translateButton;
  Curve _curve = Curves.easeOut;
  double _fabHeight = 56.0;

  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(() {
            setState(() {});
          });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _buttonColor = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.linear,
      ),
    ));
    _translateButton = Tween<double>(
      begin: _fabHeight,
      end: -14.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.0,
        0.75,
        curve: _curve,
      ),
    ));
    this.widget.passCloseFunction(this.close);
    super.initState();
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  animate() {
    if (!isOpened) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    isOpened = !isOpened;
  }

  close(){
    if(isOpened){
      _animationController.reverse();
      isOpened = false;
    }
  }

  Widget add() {
    if (isOpened) {
      return Container(
          child: FloatingActionButton.extended(
              onPressed: (){
                this.widget.onAddClicked();
                animate();
              },
              heroTag: "add",
              label: Text("添加目标"),
              icon: Icon(Icons.add)));
    } else {
      return Container(child: FloatingActionButton( heroTag: "closedAdd",child: Icon(Icons.add)));
    }
  }

  Widget sort() {
    if (isOpened) {
      return Container(
          child: FloatingActionButton.extended(
              onPressed: (){
                this.widget.onSortClicked();
                animate();
              },
              heroTag: "sort",
              label: SizedBox(
                  width: 61,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[Text("排"), Text("序")])),
              icon: Icon(Icons.sort)));
    } else {
      return Container(child: FloatingActionButton(heroTag: "closedSort",child: Icon(Icons.sort)));
    }
  }

  Widget inbox() {
    return Container(
      child: FloatingActionButton(
        heroTag: "inbox",
        onPressed: null,
        tooltip: 'Inbox',
        child: Icon(Icons.inbox),
      ),
    );
  }

  Widget toggle() {
    return Container(
      child: FloatingActionButton(
        heroTag: "toggle",
        backgroundColor: _buttonColor.value,
        onPressed: animate,
        tooltip: 'Toggle',
        child: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _animateIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 3.0,
            0.0,
          ),
          child: add(),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 2.0,
            0.0,
          ),
          child: sort(),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value,
            0.0,
          ),
          child: inbox(),
        ),
        toggle(),
      ],
    );
  }
}
