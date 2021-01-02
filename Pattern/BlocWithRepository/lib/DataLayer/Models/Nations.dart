import 'package:meta/meta.dart';


class Nation {
  final String name;
  final String imagePath;
  final String countryId; 

  Nation({@required this.name, @required this.imagePath, @required this.countryId});

}

List<Nation> nations = [
  Nation(name: "Argentina", imagePath: "images/flags/argentina.png", countryId: "52"),
  Nation(name: "Brazil", imagePath: "images/flags/brazil.png", countryId: "54"),
  Nation(name: "Germany", imagePath: "images/flags/germany.png", countryId: "21"),
  Nation(name: "England", imagePath: "images/flags/england.png", countryId: "14"),
  Nation(name: "France", imagePath: "images/flags/france.png", countryId: "18"),
  Nation(name: "Italy", imagePath: "images/flags/italy.png", countryId: "27"),
  Nation(name: "Spain", imagePath: "images/flags/spain.png", countryId: "45")
];