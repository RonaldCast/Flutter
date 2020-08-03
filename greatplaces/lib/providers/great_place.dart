import 'package:flutter/foundation.dart';
import '../models/place.dart';
import 'dart:io';

class GreatPlaces with ChangeNotifier {
  List<Place> _items = [];
  List<Place> get items {
    return [..._items];
  }

  void addPlace(String pickertitle, File pickerImage){
    final newPlace = Place(id: DateTime.now().toString(), image: pickerImage, 
    title: pickertitle, location: null);
    _items.add(newPlace); 
    notifyListeners();
  }
}
