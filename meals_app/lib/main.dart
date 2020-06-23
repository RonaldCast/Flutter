import 'package:flutter/material.dart';
import 'package:meals_app/category_meals_scree.dart';
import './categories_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliMeals',
      theme: ThemeData(
         primarySwatch: Colors.blue,
          accentColor: Colors.blue,
          canvasColor: Colors.white,
          fontFamily: 'Raleway', 
          textTheme: ThemeData.light().textTheme.copyWith(
              body1: TextStyle(color: Color.fromARGB(255, 51, 51, 1)),
              body2: TextStyle(color: Color.fromARGB(50, 51, 51, 1)),
              title: TextStyle(
                fontSize: 20,
                fontFamily: 'RobotoCondensed',
                 fontWeight: FontWeight.bold,
                
              ))), 
      
      initialRoute: "/", //default router 
      routes:{
        "/": (ctx) => CategoriesScreen(), //default router
       CategoryMealsScreen.routeName: (ctx) => CategoryMealsScreen(), 
      },
    );
  }
}
