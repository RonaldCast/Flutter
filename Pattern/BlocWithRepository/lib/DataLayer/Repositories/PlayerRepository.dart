import '../Models/Players.dart';
import '../DataProvider/PlayerApiProvider.dart';

class PlayerRepository {
    PlayerApiProvider _playerApiProvider = PlayerApiProvider();

    Future<List<Players>> fetchPlayersByCountry(String countryId) async 
     => _playerApiProvider.fetchPlayersByCountry(countryId);

    Future<List<Players>> fetchPlayersByName(String name) async => 
      _playerApiProvider.fetchPlayersByName(name);

    Future<List<Players>> fetchAllPlayer() async => _playerApiProvider.fetchAllPlayer();


}