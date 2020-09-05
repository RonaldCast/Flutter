import 'package:flutter/material.dart';
import './screen/gratitude_screen.dart';
import './widgets/heroElement.dart' ;
void main() {
  runApp(MyApp());
}

class About extends StatelessWidget {
  const About({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("About")),
      body: SafeArea(child: Text("Hola")),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
  String _howAreYou = "...";

  void _openPageAbout({bool fullScreenDailog}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: fullScreenDailog, builder: (context) => About()));
  }

  void _openPageGratitude({bool fullscreenDialog = false}) async {
    final String _gratitudeResponse = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: fullscreenDialog,
            builder: (ctx) => GratitudeScreen(-1)));

    setState(() {
      _howAreYou = _gratitudeResponse ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Navigator"),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _openPageAbout(fullScreenDailog: true),
            )
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(23.0),
            child: Column(children: [
              Text(
                "Grateful for: $_howAreYou",
                style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
              ),
              HeroElemente()
            ]),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _openPageGratitude();
          },
          tooltip: 'About',
          child: Icon(Icons.sentiment_very_satisfied),
        ));
  }
}
