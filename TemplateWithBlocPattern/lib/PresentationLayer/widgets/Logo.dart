import 'package:flutter/material.dart';

class Logo extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
   double sizeLogo =MediaQuery.of(context).size.width * 0.4 > 180.0 
   ? 180.0 :MediaQuery.of(context).size.width * 0.4 ;
   return Container(
     width: sizeLogo,
     child: Image.asset("images/logo.png",),
   );

  }
}