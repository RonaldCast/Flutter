import 'package:flutter/material.dart';

class  Answer extends StatelessWidget {
  final Function selectHandler; 
  final String text;

  Answer(this.selectHandler,{this.text:"text"});

  @override
  Widget build(BuildContext context){
    return Container(
      margin: EdgeInsets.all(20),
      width: double.infinity,
      child: RaisedButton(
        
        padding: EdgeInsets.all(20),
        textColor: Colors.white,
        child: Text(text, style: TextStyle(fontSize: 18),),
        color: Colors.blue,
        onPressed:selectHandler ,
      ));
  }
}