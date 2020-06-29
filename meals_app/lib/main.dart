import 'package:flutter/material.dart';
import 'package:meals_app/screens/tabs_screen.dart';
// import './screens/tabs_screen.dart';
import './screens/category_meals_scree.dart';
import './screens/meal_detail_screen.dart';
import './screens/not_found_screen.dart';

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
        "/": (ctx) =>  TabsScreen(),//default router CategoriesScreen(),
       CategoryMealsScreen.routeName: (ctx) => CategoryMealsScreen(),
       MealDetailScreen.routeName: (ctx) => MealDetailScreen() 
      },
      //genera la ruta mapea todo las rutas que no estan registradas
      // ignore: missing_return
      onGenerateRoute: (setting) {
        print(setting.arguments);
        // return MaterialPageRoute(builder: (ctx) => CategoriesScreen());
      },
      onUnknownRoute: (setting){
        return MaterialPageRoute(builder: (ctx) => NotFoundScreen());
      },
    );
  }
}
