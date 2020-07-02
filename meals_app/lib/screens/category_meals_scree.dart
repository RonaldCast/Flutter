import 'package:flutter/material.dart';

import '../dummy_data.dart';

import '../widgets/meal_item.dart';
import '../models/meal.dart';

class CategoryMealsScreen extends StatefulWidget {
  static const routeName = "/category-meals";
  final List<Meal> availableMeals ;

  CategoryMealsScreen(this.availableMeals);

  @override
  _CategoryMealsScreenState createState() => _CategoryMealsScreenState();
}

class _CategoryMealsScreenState extends State<CategoryMealsScreen> {
  String categoryTitle;
  List<Meal> displayedMeals;
  bool flag = true;
  

  void _removeMeal(String mealId) {
    print(mealId);
    setState(() {
      displayedMeals.removeWhere((meal) {
        print(meal.id == mealId);
        return meal.id == mealId;
      });
    });
  }

  @override
  void didChangeDependencies() {
    if (flag) {
      final routeArgs =
          ModalRoute.of(context).settings.arguments as Map<String, String>;
      final categoryId = routeArgs["id"];
      categoryTitle = routeArgs["title"];

      displayedMeals = widget.availableMeals.where((meal) {
        return meal.categories.contains(categoryId);
      }).toList();
      this.flag = false;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(categoryTitle),
        ),
        body: ListView.builder(
            itemBuilder: (ctx, index) {
              return MealItem(
                id: displayedMeals[index].id,
                title: displayedMeals[index].title,
                imageUrl: displayedMeals[index].imageUrl,
                duration: displayedMeals[index].duration,
                affordability: displayedMeals[index].affordability,
                complexity: displayedMeals[index].complexity,
             
              );
            },
            itemCount: displayedMeals.length));
  }
}
