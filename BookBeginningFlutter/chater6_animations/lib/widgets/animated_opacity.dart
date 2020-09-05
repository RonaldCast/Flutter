import 'package:flutter/material.dart';

class AnimatedOpacityWidget extends StatefulWidget {
  @override
  _AnimatedOpacityWidgetState createState() => _AnimatedOpacityWidgetState();
}

class _AnimatedOpacityWidgetState extends State<AnimatedOpacityWidget> {
  double _opacity = 1.0;

  void _animatedOpacity() {
    setState(() {
      _opacity = _opacity == 1.0 ? 0.3 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
        AnimatedOpacity(duration: Duration(milliseconds: 500),
          opacity: _opacity,
          child: Container(color:Colors.amber,
           height: 100.0,
           width: 100.0,
           child: FlatButton(child: Text("Tap to fade"),onPressed: (){
             _animatedOpacity();
           },),
          ),
        )
    ],);
  }
}
