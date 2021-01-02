import 'package:flutter/material.dart';
import '../../DataLayer/Models/Nations.dart';

abstract class PlayerListingEvent{}

class CountrySelectedEvent extends PlayerListingEvent{
  final Nation model;
  CountrySelectedEvent({@required this.model}):assert( model != null);
}

class SearchTextChangedEvent extends PlayerListingEvent {
  final String searchTerm;
  SearchTextChangedEvent({@required this.searchTerm}) : assert(searchTerm != null);
}

class FetchAllPlayerEvent extends PlayerListingEvent{}