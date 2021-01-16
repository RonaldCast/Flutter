import 'package:json_annotation/json_annotation.dart';

part 'LoginUserModel.g.dart';

@JsonSerializable()
class LoginUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  LoginUserModel({this.id, this.firstName, this.lastName,
   this.email});

     factory LoginUserModel.fromJson(Map<String, dynamic> json) => _$LoginUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoginUserModelToJson(this);
  
}
