import 'package:flutter/foundation.dart';
import '../models/place.dart';
import 'dart:io';
import '../helpers/db_helper.dart';
import '../models/place.dart';
import '../helpers/location_helper.dart';


class GreatPlaces with ChangeNotifier {
  List<Place> _items = [];
  List<Place> get items {
    return [..._items];
  }

  Future<void> addPlace(String pickertitle, File pickerImage, PlaceLocation pickedLocation) async {

    final address = await LocationHelper.getPlaceAdress(pickedLocation.latitud, pickedLocation.longitude);
    final updatedLocation = PlaceLocation
    (latitud: pickedLocation.latitud, 
    longitude: pickedLocation.longitude, address: address);

    final newPlace = Place(
        id: DateTime.now().toString(),
        image: pickerImage,
        title: pickertitle,
        location: updatedLocation);
    _items.add(newPlace);
    notifyListeners();
    DBHelper.insert("user_places", {
      'id': newPlace.id,
      'title': newPlace.title,
      "image": newPlace.image.path,
      "loc_lat": newPlace.location.latitud,
      'loc_lng': newPlace.location.longitude,
      'address': newPlace.location.address
    });
  }

  Place findById(String id){
    return _items.firstWhere((place) => place.id == id);
  }

  Future<void> fetchAndSetPlaces() async {
    final dataList = await DBHelper.getData('user_places');
    _items = dataList
        .map((item) => Place(
            id: item["id"],
            title: item["title"],
            image: File(item["image"]),
            location: PlaceLocation(latitud: item["loc_lat"], 
            longitude: item['loc_lng'], address: item['address'])))
        .toList();
    notifyListeners();
  }
}
