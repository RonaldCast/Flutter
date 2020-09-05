import 'package:flutter/material.dart';

class AnimatedBalloonWidget extends StatefulWidget {
  @override
  AnimatedBalloonWidgetState createState() => AnimatedBalloonWidgetState();
}

class AnimatedBalloonWidgetState extends State<AnimatedBalloonWidget>
    with TickerProviderStateMixin {
  AnimationController _controllerFloatUp;
  AnimationController _controllerGrowSize;
  Animation<double> _animationFloatUp;
  Animation<double> _animationGrowSize;

  @override
  void initState() {
    super.initState();
    _controllerFloatUp =
        AnimationController(duration: Duration(seconds: 4), vsync: this);
    _controllerGrowSize =
        AnimationController(duration: Duration(seconds: 2), vsync: this);

  }

  @override
  void dispose() {
    super.dispose();
    _controllerGrowSize.dispose();
    _controllerFloatUp.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _balloonHeight = MediaQuery.of(context).size.height / 2;
    double _balloonWidth = MediaQuery.of(context).size.height / 3;
    double _balloonBottomLocation =
        MediaQuery.of(context).size.height - _balloonHeight;

    _animationFloatUp = Tween(begin: _balloonBottomLocation, end: 0.0)
    .animate(CurvedAnimation(parent: _controllerFloatUp, curve: Curves.fastOutSlowIn));
    _animationGrowSize = Tween(begin: 50.0, end:_balloonWidth)
    .animate(CurvedAnimation(parent: _controllerGrowSize, curve:Curves.elasticOut));
    
  _controllerFloatUp.forward();
  _controllerGrowSize.forward();

    return AnimatedBuilder(animation: _animationFloatUp, 
    builder: (ctx, child){
      return Container(child: child,
       margin: EdgeInsets.only(top:_animationFloatUp.value),
       width: _animationGrowSize.value,
      );
    }, 
    child: GestureDetector(
    onTap: (){
      if(_controllerFloatUp.isCompleted){
        _controllerFloatUp.reverse();
        _controllerGrowSize.reverse();
      }else{
        _controllerFloatUp.forward();
        _controllerGrowSize.forward();
      }
    },
    child: Image.asset('assets/images/globo.png', height: _balloonHeight, 
    width: _balloonWidth,),
    ),
    );
  }
}
