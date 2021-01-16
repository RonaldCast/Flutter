// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoginUserModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginUserModel _$LoginUserModelFromJson(Map<String, dynamic> json) {
  return LoginUserModel(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$LoginUserModelToJson(LoginUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
    };
