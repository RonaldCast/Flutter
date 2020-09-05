import 'package:flutter/material.dart';
import '../screen/fly_screen.dart';

class HeroElemente extends StatelessWidget {
  const HeroElemente({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: GestureDetector(
              child: Hero(
                tag: 'format_paint',
                child: Icon(
                  Icons.format_paint,
                  color: Colors.lightGreen,
                  size: 120.0,
                ),
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (ctx) => FlyScreen()));
              }),
        ),
    );
  }
}
