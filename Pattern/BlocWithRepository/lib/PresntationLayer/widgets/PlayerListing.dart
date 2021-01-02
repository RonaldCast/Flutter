import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BlocWithRepository/Bloc/Player/exportPlayerBloc.dart';
import 'package:BlocWithRepository/PresntationLayer/widgets/Message.dart';
import 'package:BlocWithRepository/DataLayer/Models/Players.dart';
import '../screens/playerProfile.dart';


class PlayerListing extends StatelessWidget {
  const PlayerListing({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerListingBloc, PlayerListingState>(
      builder: (context, state) {

        print(state);
        print("dd");
        if(state is PlayerUninitializedState){
              return Message( message: "Unintialised State");
        }
        else if(state is PlayerEmptyState){
         return Message(message: "No Players found");
        } else if (state is PlayerErrorState) {
          return Message(message: "Something went wrong");
        } else if (state is PlayerFetchingState || state == null ) {
          return Expanded(child: Center(child: CircularProgressIndicator()));
        }
        else{
            final stateAsPlayerFetchedState = state as PlayerFetchedState; 
            final players = stateAsPlayerFetchedState.players;
            print("Hola mundo");
            return  buildPlayersList(players);
        }
      }
    );
  }
}

Widget buildPlayersList(List<Players> players){
  return Expanded(
    
      child: ListView.separated(
      itemCount: players.length,
      itemBuilder: (BuildContext context, int index) {
      Players player = players[index];
      return Container(
       
        color: Colors.white30,
        child: ListTile(
          leading: CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.blue[50],
          ),
          title: Text(
            player.name,
            style: TextStyle(fontSize: 20.0, color: Colors.black),
          ),
          subtitle: Text(
            "Age: " + player.age.toString(),
            style: TextStyle(fontSize: 14.0, color: Colors.black87),
          ),

           trailing: IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => 
               PlayerProfile(player:player)));
            },
          ),
        ),

      

      );
     },
     separatorBuilder: (context, index){
       return Divider(
         height: 8.0,
         color: Colors.transparent
       );
     },
    ),
  );
}