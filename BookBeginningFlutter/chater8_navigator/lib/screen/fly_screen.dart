import 'package:flutter/material.dart';

class FlyScreen extends StatelessWidget {
  const FlyScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.shortestSide / 2;
    return Scaffold(
      appBar: AppBar( title: Text("animation")),
      body: SafeArea(
          child: Hero(
        tag: 'format_paint',
        child: Container(
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.format_paint,
            color: Colors.lightGreen,
            size: _width,
          ),
        ),
      )),
    );
  }
}
