import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/orders_screem.dart';
import '../screens/user_product_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(child: Column(children: <Widget>[
      AppBar(title: Text("hello friend"),
      automaticallyImplyLeading: false,),
      Divider(),
      ListTile(leading:Icon(Icons.shopping_cart), title: Text("shop"),
      onTap: () {
        Navigator.of(context).pushReplacementNamed("/");
      },),
      ListTile(leading:Icon(Icons.payment), title: Text("orders"),
      onTap: () {
        Navigator.of(context).pushReplacementNamed(OrdersScreen.routeName);
      },),
      ListTile(leading:Icon(Icons.edit), title: Text("Manage Product"),
      onTap: () {
        Navigator.of(context).pushReplacementNamed(UserProductScreen.routeName);
      },),
    ],),);
  }
}