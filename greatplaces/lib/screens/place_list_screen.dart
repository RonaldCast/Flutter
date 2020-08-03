import 'package:flutter/material.dart';
import './add_place_screen.dart';
import 'package:provider/provider.dart';
import '../providers/great_place.dart';

class PlaceListScreen extends StatelessWidget {
  build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Your Places"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).pushNamed(AddPlaceScreen.routeName);
              },
            )
          ],
        ),
        body: Consumer<GreatPlaces>(
            child: const Text('Got no places yet, start adding some!'),
            builder: (ctx, greatPlaces, ch) => greatPlaces.items.length <= 0
                ? ch
                : ListView.builder(
                    itemCount: greatPlaces.items.length,
                    itemBuilder: (ctx, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: FileImage(greatPlaces.items[i].image),
                      ),
                      title: Text(greatPlaces.items[i].title), 
                      onTap: (){},
                    ),
                  )));
  }
}
