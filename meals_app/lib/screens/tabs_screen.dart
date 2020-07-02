import "package:flutter/material.dart";
import './categories_screen.dart';
import './favorites_screen.dart';
import '../widgets/main_drawer.dart';
import '../models/meal.dart';

class TabsScreen extends StatefulWidget {

  final List<Meal> favoritedMeals;

  TabsScreen(this.favoritedMeals);

  @override
  _TabsCreenState createState() => _TabsCreenState();
}

class _TabsCreenState extends State<TabsScreen> {
 List<Map<String, Object>> _pages;
  int _selectTabIndex = 0;
  @override
  initState(){
    _pages = [
    {
      'page': CategoriesScreen(),
      'title': "Cataegoties",
    },
    {
      'page': FavoritesScreen(widget.favoritedMeals),
      'title': "Your Favorite",
    }
  ];
  super.initState();
  }
  // [CategoriesScreen(), FavoritesScreen()];

 

  void _selectTab(int index) {
    setState(() {
      _selectTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: todo
    // TODO: implement build
   
    return Scaffold(
      appBar: AppBar(
        title:  Text(_pages[_selectTabIndex]['title']),
      ),
      drawer: MainDrawer(),
      body: _pages[_selectTabIndex]['page'],
      bottomNavigationBar: BottomNavigationBar(
          // type: BottomNavigationBarType.shifting, // animation
          onTap: _selectTab,
          backgroundColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.black87,
          currentIndex: _selectTabIndex,
          selectedItemColor: Colors.white,
          items: [
            BottomNavigationBarItem(
                backgroundColor: Theme.of(context).primaryColor,
                icon: Icon(Icons.category),
                title: Text("Categories")),
            BottomNavigationBarItem(
                backgroundColor: Theme.of(context).primaryColor,
                icon: Icon(Icons.star),
                title: Text("Favorites")),
          ]),
    );
  }
}
