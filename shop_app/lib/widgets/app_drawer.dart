import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/orders_screem.dart';
import '../screens/user_product_screen.dart';
import '../providers/auth.dart';
import "package:provider/provider.dart";

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
      ListTile(leading:Icon(Icons.edit), title: Text("Logout"),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed("/");
        // Navigator.of(context).pushReplacementNamed(UserProductScreen.routeName);
          Provider.of<Auth>(context, listen: false).logout();
      },),
    ],),);
  }
}