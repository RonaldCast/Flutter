import 'package:flutter/material.dart';
import 'package:BlocWithRepository/Bloc/Player/exportPlayerBloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchBar extends StatefulWidget{

  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>{

  @override
  Widget build(BuildContext context) {

    return  Container(
      margin: EdgeInsets.only(top:5.0, bottom: 20.0,left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.all(Radius.circular(20.0))
      ),
      child: TextField(
        style: TextStyle(color: Colors.white70, fontSize: 18.0),
        onChanged: (term){
          BlocProvider.of<PlayerListingBloc>(context)
          .add(SearchTextChangedEvent(searchTerm:term));
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          hintText: "Search",
          hintStyle: TextStyle(color: Colors.white70, fontSize: 18,),
          prefixIcon: Icon(Icons.search, size: 30.0, color: Colors.white70)
        ),
      ),
    );
  }
}