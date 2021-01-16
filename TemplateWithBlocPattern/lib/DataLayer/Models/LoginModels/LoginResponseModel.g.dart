// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoginResponseModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseModel _$LoginResponseModelFromJson(Map<String, dynamic> json) {
  return LoginResponseModel(
    message: json['message'] as String,
    response: json['response'] == null
        ? null
        : UserAndTokenModel.fromJson(json['response'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$LoginResponseModelToJson(LoginResponseModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'response': instance.response,
    };
