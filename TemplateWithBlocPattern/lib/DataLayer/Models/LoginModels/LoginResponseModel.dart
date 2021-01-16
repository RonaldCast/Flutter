import 'package:json_annotation/json_annotation.dart';
import './UserAndTokenModel.dart';

part 'LoginResponseModel.g.dart';

@JsonSerializable()
class LoginResponseModel  {
  final String message; 
  final UserAndTokenModel response; 

  LoginResponseModel({this.message, this.response});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) => _$LoginResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
  

}

