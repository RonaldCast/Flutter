import "package:flutter/material.dart";
import './categories_screen.dart';
import './favorites_screen.dart';

class TabsScreen extends StatefulWidget {
  @override
  _TabsCreenState createState() => _TabsCreenState();
}

class _TabsCreenState extends State<TabsScreen> {
  final List<Map<String, Object>> _pages = [
    {
      'page': CategoriesScreen(),
      'title': "Cataegoties",
    },
    {
      'page': FavoritesScreen(),
      'title': "Your Favorite",
    }
  ];
  // [CategoriesScreen(), FavoritesScreen()];

  int _selectTabIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _selectTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
   
    return Scaffold(
      appBar: AppBar(
        title:  Text(_pages[_selectTabIndex]['title']),
      ),
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
