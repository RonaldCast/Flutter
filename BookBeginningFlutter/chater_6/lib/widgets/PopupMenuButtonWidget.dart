import 'package:flutter/material.dart';

class PopupMenuButtonWidget extends StatelessWidget
    implements PreferredSizeWidget {
  PopupMenuButtonWidget({Key key}) : super(key: key);
  List<TodoMenuItem> foodMenuList = [
    TodoMenuItem(title: 'Fast Food', icon: Icon(Icons.fastfood)),
    TodoMenuItem(title: 'Remind Me', icon: Icon(Icons.add_alarm)),
    TodoMenuItem(title: 'Flight', icon: Icon(Icons.flight)),
    TodoMenuItem(title: 'Music', icon: Icon(Icons.audiotrack)),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      child: PopupMenuButton<TodoMenuItem>(itemBuilder: (BuildContext ctx){
        return foodMenuList.map((e){
          return PopupMenuItem<TodoMenuItem>(value: e, child: Row(children:[
            Icon(e.icon.icon),
            Padding(padding: EdgeInsets.all(8.0),),
            Text(e.title)
          ]),);
        }).toList();
      },),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(75.0);
}

class TodoMenuItem {
  final String title;
  final Icon icon;
  TodoMenuItem({this.title, this.icon});
}
