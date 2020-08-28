import 'package:flutter/material.dart';

class DecorationScreen extends StatelessWidget {
  static const String routeName ="/decoration";
  const DecorationScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("Decoration")),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            
         Center(
           child: Container(
             height: 100.0,
             width: 100.0,
             decoration: BoxDecoration(
               color: Colors.orange,
               borderRadius: BorderRadius.all(Radius.circular(20.0)),
               boxShadow: [
                 BoxShadow(color: Colors.grey, blurRadius:10.0,offset: Offset(0.0, 3.0)  )
               ]
             ),
           ),
         ),
         Center(child: 
          Padding(
            padding: const EdgeInsets.all(42.0),
            child: TextField(
              keyboardType: TextInputType.text,
              style: TextStyle(
                color: Colors.grey.shade100,
                fontSize: 16.0
              ),
              decoration: InputDecoration(
                labelText: "Notes",
                labelStyle: TextStyle(color:Colors.purple),
                border: OutlineInputBorder()
              ),
            ),
          )
         ,),
         Padding(
           padding: const EdgeInsets.all(42.0),
           child: TextFormField(decoration: InputDecoration(
             labelText: "Enter your notes"
           ),),
         )
      ],),
    );
  }
}