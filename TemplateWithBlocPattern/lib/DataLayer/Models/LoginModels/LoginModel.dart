import 'package:json_annotation/json_annotation.dart';

part 'LoginModel.g.dart';

@JsonSerializable()
class LoginModel{
   final String email;
   final String password; 

  LoginModel({this.email, this.password}); 
  
  factory LoginModel.fromJson(Map<String, dynamic> json) => _$LoginModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoginModelToJson(this);
  
}
 