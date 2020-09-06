import 'package:flutter/material.dart';
import './menu_list_tile.dart';

class RigthDrawer extends StatelessWidget {
  const RigthDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: Icon(
              Icons.face,
              size: 128.0,
              color: Colors.white54,
            ),
            decoration: BoxDecoration(color: Colors.blue),
          ),
          MenuListTile(),
        ],
      ),
    );
  }
}
