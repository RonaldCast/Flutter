import 'package:flutter/material.dart';
import './dummy_data.dart';
import './screens/tabs_screen.dart';
import './models/meal.dart';
// import './screens/tabs_screen.dart';
import './screens/category_meals_scree.dart';
import './screens/meal_detail_screen.dart';
import './screens/not_found_screen.dart';
import './screens/filters_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, bool> _filters ={
    'gluten':false,
    'lactose':false,
    'vegan':false,
    'vegetarian':false
  };
 
 List<Meal> _availableMeals = DUMMY_MEALS;
 List<Meal> _favoritedMeals = [];

  void _setFilters(Map<String, bool> filterData){
    setState(() {
       _filters = filterData;
       _availableMeals = DUMMY_MEALS.where((meal) {
          if(_filters['gluten'] && !meal.isGlutenFree){
            return false;
          }
          if(_filters['lactose'] && !meal.isLactoseFree){
            return false;
          }
          if(_filters['vegan'] && !meal.isVegan){
            return false;
          }
          if(_filters['vegetarian'] && !meal.isVegetarian){
            return false;
          }

          return true;
       }).toList();
    });
  }
  void _toggleFavorite(String mealID ){
    final existingIndex =_favoritedMeals.indexWhere((meal) => meal.id == mealID);


    if(existingIndex >= 0){
      setState(() {
        _favoritedMeals.removeAt(existingIndex);
      });
           
    }else{
      setState(() {
         _favoritedMeals.add( 
           DUMMY_MEALS.firstWhere((meal) => meal.id == mealID)
         );
      });

    }
   
  }
   
   bool _isMealFavorite(String id){
     return _favoritedMeals.any((meal) => meal.id == id);
   }

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
        "/": (ctx) =>  TabsScreen(_favoritedMeals),//default router CategoriesScreen(),
      FiltersScreen.routeName: (ctx) => FiltersScreen(_filters,_setFilters),
       CategoryMealsScreen.routeName: (ctx) => CategoryMealsScreen(_availableMeals),
       MealDetailScreen.routeName: (ctx) => MealDetailScreen(_toggleFavorite, _isMealFavorite) 
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
