import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';

class MapScreen extends StatefulWidget {
  final PlaceLocation initialLocation;
  final bool isSelecting;

  MapScreen({
      this.initialLocation =
          const PlaceLocation(latitud: 18.5270084, longitude: -69.993233),
      this.isSelecting = false});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
// 2

static final CameraPosition _myLocation =
  CameraPosition(target: LatLng(0, 0),);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Maps"),
      ),
      body: GoogleMap(
         myLocationEnabled : true,
        initialCameraPosition: CameraPosition(
            target: LatLng(widget.initialLocation.latitud,
                widget.initialLocation.longitude), zoom: 15),
      ),
    );
  }
}
