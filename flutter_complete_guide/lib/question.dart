
import 'package:flutter/material.dart';

class  Question extends StatelessWidget {
  final String questionText;

  Question(this.questionText);

  @override
  Widget build(BuildContext context){
    return Container(
       padding: EdgeInsets.all(10),
       
       width: double.infinity, //va a tomar el ancho total de la pantalla
       child:Text(questionText, 
       textAlign: TextAlign.center,
       style: TextStyle(
         fontSize: 20,  
       ),)
      );
  }
}