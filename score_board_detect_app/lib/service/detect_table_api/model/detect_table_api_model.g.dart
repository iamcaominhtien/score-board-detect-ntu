// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detect_table_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectTableAPIModel _$DetectTableAPIModelFromJson(Map<String, dynamic> json) =>
    DetectTableAPIModel(
      stt: json['stt'] as String?,
      id: json['id'] as String?,
      number: (json['number'] as List<dynamic>?)?.map((e) => e as int).toList(),
      predicted: (json['predicted'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((e) => e as int).toList())
          .toList(),
    );

Map<String, dynamic> _$DetectTableAPIModelToJson(
        DetectTableAPIModel instance) =>
    <String, dynamic>{
      'stt': instance.stt,
      'id': instance.id,
      'number': instance.number,
      'predicted': instance.predicted,
    };
