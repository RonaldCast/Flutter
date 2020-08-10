//get File
import 'dart:io';

import 'package:flutter/foundation.dart';

class PlaceLocation{
  final double latitud;
  final double longitude;
  final String address;

  const PlaceLocation({@required this.latitud, @required this.longitude, 
   @required this.address
  });
}

class Place {
  final String id;
  final String title;
  final PlaceLocation location;
  final File image; 

  Place({
    @required this.id,
    @required this.title,
    @required this.location, 
    @required this.image

  });
}