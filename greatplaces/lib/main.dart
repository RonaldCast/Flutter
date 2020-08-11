import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/great_place.dart';
import './screens/place_list_screen.dart';
import './screens/add_place_screen.dart';
import './screens/place_detail_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: GreatPlaces() ,
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          accentColor: Colors.amber,
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: PlaceListScreen(),
        routes: {
           AddPlaceScreen.routeName: (ctx) => AddPlaceScreen(),
           PlaceDetailScreen.routeName: (ctx)=> PlaceDetailScreen()
        },
      ),
    );
  }
}
