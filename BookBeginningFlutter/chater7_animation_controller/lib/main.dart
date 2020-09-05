import 'package:flutter/material.dart';
import './widgets/animated_balloon.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Ballon"),
      ),
      body:  SafeArea(
           child: SingleChildScrollView(
             physics: NeverScrollableScrollPhysics(),
             child: Padding(
               padding: EdgeInsets.all(16.0),
               child: Column(children:[ AnimatedBalloonWidget()])))
        )
      
    );
  }
}
