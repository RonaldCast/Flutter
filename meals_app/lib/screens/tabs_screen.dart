import "package:flutter/material.dart";
import './categories_screen.dart';
import './favorites_screen.dart';

class TabsScreen extends StatefulWidget{

@override
_TabsCreenState createState() => _TabsCreenState();

}

class _TabsCreenState extends State<TabsScreen>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return DefaultTabController
    (
      length: 2,
      initialIndex: 1,
      child: Scaffold(appBar: AppBar(title: Text('Meals'), bottom: TabBar(tabs: <Widget>[
        Tab(icon: Icon(Icons.category), text: 'Categories',),
        Tab(icon: Icon(Icons.star), text: 'Favories',)
      ],),), 
      
      body: TabBarView(children: <Widget>[
          CategoriesScreen(),
          FavoritesScreen()
      ],),),

    );
  }
}