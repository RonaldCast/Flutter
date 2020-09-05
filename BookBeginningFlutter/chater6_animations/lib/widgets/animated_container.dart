import 'package:flutter/material.dart';


class AnimatedContainerWidget extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<AnimatedContainerWidget> {
   double _height = 100.0;
   double _width = 100.0;
   
   _increaseWidth(){
     setState(() {
       _width = _width >= 320.0 ? 100.0 : _width +=50.0; 
     });
   }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: Duration(
        milliseconds: 200
       
       ),
       curve: Curves.bounceInOut,
       color:Colors.amber,
       height: _height,
       width: _width,
       child: FlatButton(child: Text('Tap to\nGrow Width\n$_width'),
        onPressed: (){
          _increaseWidth();
        },
       ),
    );
  }
}