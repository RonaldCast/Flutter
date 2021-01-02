import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BlocWithRepository/Bloc/Player/exportPlayerBloc.dart';
import 'package:BlocWithRepository/DataLayer/Repositories/PlayerRepository.dart';
import 'package:BlocWithRepository/PresntationLayer/widgets/horizontalBar.dart';
import 'package:BlocWithRepository/PresntationLayer/widgets/searchBar.dart';
import 'package:BlocWithRepository/PresntationLayer/widgets/PlayerListing.dart';

class HomeScreen extends StatefulWidget {
  final PlayerRepository playerRepository;
  HomeScreen({@required this.playerRepository, Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlayerListingBloc _playerListingBloc;

  @override
  void initState() {
    super.initState();
    _playerListingBloc=PlayerListingBloc(playerRepository: widget.playerRepository);
    _playerListingBloc.add(FetchAllPlayerEvent());
 }
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _playerListingBloc,
      child: Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(
          elevation: 0.0,
          title: Text(
            'Football Players',
            style: TextStyle(color: Colors.white, fontSize: 25.0),
          ),
          backgroundColor: Colors.transparent,
         
        ),
        body: Column(
          children:<Widget>[
             HorizontalBar(),
             SizedBox(height: 20.0,),
             SearchBar(), 
             PlayerListing()
          ]
        ),
        
      ),
    );
  }
}
