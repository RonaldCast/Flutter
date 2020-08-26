import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContanerWithBoxDecoration extends StatelessWidget{

  const ContanerWithBoxDecoration({Key key}) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return Column( children:[
      //TODO Work with container
      Container(
         width: double.infinity,
        height: 100.0,
        decoration: BoxDecoration(
        
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(100.0),
            bottomRight: Radius.circular(10.0)
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue]),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius:6.0, offset: Offset(0.0, 5.0) )
          ]
        ),
        // wotk text and RitchRext
        child: Center(
          child: RichText( text: TextSpan(text: "Flutter world for ", 
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.deepPurpleAccent,
            decoration: TextDecoration.underline,
            decorationColor: Colors.deepPurpleAccent,
            decorationStyle: TextDecorationStyle.dashed,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic
          ), children: [
            TextSpan(text:"Mobile", style: TextStyle(color:Colors.red, fontStyle: FontStyle.normal))
          ])),
        ),
      )
    ]) ;
  }
}