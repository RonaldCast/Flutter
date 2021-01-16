// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserAndTokenModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAndTokenModel _$UserAndTokenModelFromJson(Map<String, dynamic> json) {
  return UserAndTokenModel(
    json['token'] as String,
    json['refreshToken'] as String,
    json['user'] == null
        ? null
        : LoginUserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$UserAndTokenModelToJson(UserAndTokenModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
