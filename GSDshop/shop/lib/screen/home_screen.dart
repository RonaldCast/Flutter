import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Hpa"),
         actions: <Widget>[
           IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {},)
         ], // 
      ), 

      body: Center(child: Text('My shop body'),),
    );
  }
}