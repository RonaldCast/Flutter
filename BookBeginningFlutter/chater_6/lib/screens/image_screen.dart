import 'dart:ui';

import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  static const String routeName = "/image";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Images"),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              height: 200.0,
              child: Image.asset("assets/images/splash_icon.png", fit: BoxFit.cover,
              color:Colors.red
              ),
            ),
            Container(child: Image.network("https://article.images.consumerreports.org/f_auto/prod/content/dam/CRO%20Images%202018/Cars/November/CR-Cars-InlineHero-2019-Honda-Insight-driving-trees-11-18"),),
            Icon(Icons.brush, color: Colors.blue, size: 48.0,)
          ],
        ),
      ),
    );
  }
}
