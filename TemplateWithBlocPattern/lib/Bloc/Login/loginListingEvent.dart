import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/RevokeTokenModel.dart';

abstract class LoginListingEvent {}

class LoginEvent extends LoginListingEvent {
  final LoginModel model;

  LoginEvent({this.model}) : assert(model != null);
}

class LogoutEvent extends LoginListingEvent {
  final RevokeTokenModel model;
  LogoutEvent({this.model}) : assert(model != null);
}

class LoginCheckEvent extends LoginListingEvent {}

class LoginError extends LoginListingEvent{ 
}
