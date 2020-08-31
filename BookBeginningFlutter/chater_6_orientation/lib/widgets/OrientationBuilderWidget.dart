import 'package:flutter/material.dart';

class OrientationBuilderWidget extends StatelessWidget {
  const OrientationBuilderWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (ctx, orientation) {
      return orientation == Orientation.portrait
          ? Container(
              alignment: Alignment.center,
              color: Colors.yellow,
              height: 100.0,
              width: 100.0,
              child: Text('Portrait'),
            )
          : Container(
              alignment: Alignment.center,
              color: Colors.lightGreen,
              height: 100.0,
              width: 200.0,
              child: Text('Landscape'),
            );
    });
  }
}
