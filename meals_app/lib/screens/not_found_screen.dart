



import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget{
 @override
  Widget build(BuildContext context) {
    // ignore: todo
    // TODO: implement build
    return 
    Scaffold(body: Container(
        width: double.infinity,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
        Text("Screen no found", style: TextStyle( fontSize: 20),),
        SizedBox(height: 15),
        RaisedButton(child: Text("Go home page"),
        textColor: Colors.white,
        color: Theme.of(context).primaryColor,
        onPressed: () => {
          Navigator.of(context).pushNamed("/")
        },)
      ],),
    ));

    
  }
}