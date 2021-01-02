import 'package:BlocWithRepository/DataLayer/Repositories/PlayerRepository.dart';
import 'package:BlocWithRepository/Bloc/Player/playerListingState.dart';
import 'package:BlocWithRepository/Bloc/Player/playerListingEvent.dart';
import 'package:BlocWithRepository/DataLayer/Models/Players.dart';
import 'package:bloc/bloc.dart';

class PlayerListingBloc extends Bloc<PlayerListingEvent, PlayerListingState> {
  final PlayerRepository playerRepository;

  PlayerListingBloc({this.playerRepository})
      : assert(playerRepository != null),
        super(null);

  @override
  Stream<PlayerListingState> mapEventToState(PlayerListingEvent event) async* {
    yield PlayerFetchingState();
    List<Players> players;

    try {

      if (event is CountrySelectedEvent) {
        players = await playerRepository.fetchPlayersByCountry(event.model.countryId);
      }else if(event is SearchTextChangedEvent){
         print("Hitting service");
          players = await playerRepository.fetchPlayersByName(event.searchTerm);
      }else if(event is FetchAllPlayerEvent){
        players = await playerRepository.fetchAllPlayer();
      }
         print(players == null ? true : false);
      if(players.length == 0){
        yield PlayerEmptyState();
      }else{
        print("Hitting service");
        print(players);
        yield PlayerFetchedState(players:  players);
      }
    } catch (_) {
      yield PlayerErrorState();
    }
  }

  @override
  void onTransition(
      Transition<PlayerListingEvent, PlayerListingState> transition) {
    super.onTransition(transition);
    //print(transition);
  }
}
