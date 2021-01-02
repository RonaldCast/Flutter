import 'package:flutter/material.dart';
import 'package:BlocWithRepository/PresntationLayer/screens/home.dart';
import 'package:BlocWithRepository/DataLayer/Repositories/PlayerRepository.dart';

void main() {
  PlayerRepository _repository = PlayerRepository();
  runApp(MyApp(playerRepository:_repository));
}

class MyApp extends StatelessWidget {
  
  final PlayerRepository playerRepository;
  MyApp({this.playerRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "GoogleSans",
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(playerRepository:playerRepository),
    );
  }
}
