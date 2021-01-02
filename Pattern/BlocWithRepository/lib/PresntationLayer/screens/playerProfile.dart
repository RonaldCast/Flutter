import 'package:flutter/material.dart';
import 'package:BlocWithRepository/DataLayer/Models/Players.dart';

class PlayerProfile extends StatefulWidget {
  Players player = Players();
  PlayerProfile({this.player, Key key}) : super(key: key);

  @override
  _PlayerProfileState createState() => _PlayerProfileState();
}

class _PlayerProfileState extends State<PlayerProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.blue[900],
          title: Text("${widget.player.name} ${widget.player.lastName}"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Text(
                  widget.player.name.toLowerCase(),
                  style: TextStyle(
                      fontSize: 45.0,
                      color: Colors.white10,
                      letterSpacing: 12.0),
                ),
              ),
              CircleAvatar(
                child: Text(
                  widget.player.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontSize: 20),
                ),
                radius: 40,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Container(
                  height: 250.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ClipRRect(
                        borderRadius:  BorderRadius.only(
                          bottomRight: const Radius.circular(80),
                          topRight: const Radius.circular(80.0)
                        ),
                        child: Container(
                           width: MediaQuery.of(context).size.width - 50.0,
                           color: Colors.red,
                           height: 300.0,
                           child: Column()
                        ),

                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
