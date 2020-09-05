import 'package:flutter/material.dart';

class AnimatedCrossFadeWidget extends StatefulWidget {
  @override
  _AnimatedCrossFadeWidgetState createState() => _AnimatedCrossFadeWidgetState();
}

class _AnimatedCrossFadeWidgetState extends State<AnimatedCrossFadeWidget> {
bool _crossFadeStateShowFirst = true;

void _crossFade(){
  setState(() {
    _crossFadeStateShowFirst = _crossFadeStateShowFirst ? false : true;
  });
}

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Stack(
        alignment: Alignment.center,
        children: [
          AnimatedCrossFade(
          sizeCurve: Curves.bounceOut,
          crossFadeState: _crossFadeStateShowFirst ? CrossFadeState.showFirst :
            CrossFadeState.showSecond,
            duration: Duration(milliseconds: 500),
            firstChild: Container(
              color:Colors.amber,
              height: 100.0,
              width: 100.0

            ),
            secondChild: Container(
              color:Colors.lime,
              height: 200.0,
              width: 200.0,
            ),
            
          ),
          Positioned.fill(child: FlatButton(
            child: Text("Tap to\nFade Color & Size $_crossFadeStateShowFirst"),
            onPressed: (){
              _crossFade();
            },
          ))
        ],
      )
    ],);
  }
}