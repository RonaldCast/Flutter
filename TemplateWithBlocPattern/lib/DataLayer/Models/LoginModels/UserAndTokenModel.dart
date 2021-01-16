import 'package:json_annotation/json_annotation.dart';

import './LoginUserModel.dart';

part 'UserAndTokenModel.g.dart';

@JsonSerializable()
class UserAndTokenModel {
  final String token;
  final String refreshToken;
  final LoginUserModel user;

  UserAndTokenModel(this.token, this.refreshToken, this.user);

  factory UserAndTokenModel.fromJson(Map<String, dynamic> json) =>
      _$UserAndTokenModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserAndTokenModelToJson(this);
}
