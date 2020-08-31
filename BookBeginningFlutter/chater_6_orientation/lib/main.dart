import 'package:flutter/material.dart';
import './widgets/OrientationLayoutIconsWidget.dart';
import './widgets/OrientationLayoutWidget.dart';
import './widgets/GridViewWidget.dart';
import './widgets/OrientationBuilderWidget.dart';

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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              const OrientationLayoutIconsWidget(),
              const Divider(height: 10.0,),
              const OrientationLayoutWidget(),
              const Divider(height: 10.0,),
              const GridViewWidget(),
              const OrientationBuilderWidget()
            ],
          ),
        ),
      ),)
    );
  }
}
