// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountModel _$AccountModelFromJson(Map<String, dynamic> json) =>
    _AccountModel(
      id: json['id'] as String,
      email: json['email'] as String,
      uniqueName: json['uniqueName'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$AccountModelToJson(_AccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'uniqueName': instance.uniqueName,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'token': instance.token,
    };
