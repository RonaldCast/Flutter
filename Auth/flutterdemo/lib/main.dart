import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool idBusy = false;
  bool isLoggedIn = false;
  String errorMessage;
  String name;
  String pircutre; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
     
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(appBar: AppBar( title: Text('Auth0 Demo'),),
        body: Center(child: Text("..."),),
      ),

    
    );
  }
}


/// -----------------------------------
///           Profile Widget
/// -----------------------------------

class Profile extends StatelessWidget {
  final logoutAction;
  final String name;
  final String picture;

  Profile(this.logoutAction, this.name, this.picture);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 4.0),
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(picture ?? ''),
            ),
          ),
        ),
        SizedBox(height: 24.0),
        Text('Name: $name'),
        SizedBox(height: 48.0),
        RaisedButton(
          onPressed: () {
            logoutAction();
          },
          child: Text('Logout'),
        ),
      ],
    );
  }
}
