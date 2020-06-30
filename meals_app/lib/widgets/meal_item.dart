import 'package:flutter/material.dart';

import '../screens/meal_detail_screen.dart';
import '../models/meal.dart';

class MealItem extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final int duration;
  final Complexity complexity;
  final Affordability affordability;
  final Function removeItem;

  MealItem(
      {
        @required this.id,
      @required this.title,
      @required this.imageUrl,
      @required this.duration,
      @required this.complexity,
      @required this.affordability, 
      @required  this.removeItem}
      );

  String get complexityText {
    switch (complexity) {
      case Complexity.Simple:
        return 'Simple';

      case Complexity.Challenging:
        return "Simple";

      case Complexity.Hard:
        return "Simple";
      default:
        return 'Unknow';
    }
  }

  String get affordabilityText{
     switch (affordability) {
      case Affordability.Affordable:
        return 'Affordable';

      case Affordability.Luxurious:
        return "Simple";

      case Affordability.Pricey:
        return "Simple";
      default:
        return 'Unknow';
    }
  }

  void selectMeal(BuildContext ctx) {
    Navigator.of(ctx).pushNamed(MealDetailScreen.routeName, arguments:  id).then( (result) => {
      if(result != null){
         removeItem(result)
      }
     
    });
  }
  @override
  Widget build(BuildContext context) {
    return Material(
          child: InkWell(
        onTap: () => selectMeal(context),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          margin: EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  ClipRRect(
                    child: Image.network(
                      imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      width: 300,
                      color: Colors.black54,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text('$duration min')
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.work,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(complexityText)
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.attach_money,
                          ),
                          Text(affordabilityText)
                        ],
                      )
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
