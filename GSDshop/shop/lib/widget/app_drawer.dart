import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget{

  @override
  build(BuildContext context){
    return Drawer(child: Column(children: <Widget>[
      SizedBox(height: 60,),
      ListTile(
        leading: CircleAvatar(child: Icon(Icons.person),
        ),
        title: Text("sdsdsd"),
        subtitle: Text("Ronald"),
      )
    ],));
  }
}