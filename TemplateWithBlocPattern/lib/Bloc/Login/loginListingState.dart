import 'package:flutter/material.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginResponseModel.dart';

class LoginListingState {}

class LoginState extends LoginListingState {
  final LoginResponseModel model;
  LoginState({@required this.model});
}

class LoginErrorState extends LoginListingState {
  final String message; 
  LoginErrorState({@required this.message});
}

class LogoutState extends LoginListingState {
}
