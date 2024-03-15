// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manage_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManageFile _$ManageFileFromJson(Map<String, dynamic> json) => ManageFile(
      json['path'] as String,
      $enumDecode(_$FileTypeEnumMap, json['type']),
      name: json['name'] as String?,
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      size: (json['size'] as num?)?.toDouble(),
      pathOnFly: json['pathOnFly'] as String?,
      id: json['id'] as int?,
    );

Map<String, dynamic> _$ManageFileToJson(ManageFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'pathOnFly': instance.pathOnFly,
      'name': instance.name,
      'type': _$FileTypeEnumMap[instance.type]!,
      'lastModified': instance.lastModified?.toIso8601String(),
      'created': instance.created?.toIso8601String(),
      'size': instance.size,
    };

const _$FileTypeEnumMap = {
  FileType.image: 'image',
  FileType.documentExcel: 'documentExcel',
  FileType.documentOthers: 'documentOthers',
  FileType.others: 'others',
};
