import 'package:flutter/material.dart';
import './add_place_screen.dart';

class PlaceListScreen extends StatelessWidget{

  build(BuildContext context){

    return Scaffold(appBar: AppBar( title: Text("Your Places"), actions: <Widget>[
      IconButton(icon: Icon(Icons.add), onPressed: (){
        Navigator.of(context).pushNamed(AddPlaceScreen.routeName);
      },)
    ],),
      body: Center(child: CircularProgressIndicator(),),
    );
  }
}