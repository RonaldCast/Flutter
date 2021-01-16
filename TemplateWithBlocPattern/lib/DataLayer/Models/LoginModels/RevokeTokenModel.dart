import 'package:json_annotation/json_annotation.dart';

part 'RevokeTokenModel.g.dart';

@JsonSerializable()
class  RevokeTokenModel{
  final String refreshToken;
   
  RevokeTokenModel({this.refreshToken});
  
   factory RevokeTokenModel.fromJson(Map<String, dynamic> json) => _$RevokeTokenModelFromJson(json);
  Map<String, dynamic> toJson() => _$RevokeTokenModelToJson(this);
}