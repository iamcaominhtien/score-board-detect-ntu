import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'manage_file.g.dart';

enum FileType {
  image,
  documentExcel,
  documentOthers,
  others,
}

@JsonSerializable()
class ManageFile extends Equatable {
  final int? id;
  final String path;
  final String? pathOnFly;
  final String? name;
  final FileType type;
  final DateTime? lastModified;
  final DateTime? created;
  final double? size;

  const ManageFile(this.path, this.type,
      {this.name,
      this.lastModified,
      this.created,
      this.size,
      this.pathOnFly,
      this.id});

  factory ManageFile.fromJson(Map<String, dynamic> json) =>
      _$ManageFileFromJson(json);

  Map<String, dynamic> toJson() => _$ManageFileToJson(this);

  @override
  List<Object?> get props => [
        path,
        name,
        type,
        lastModified,
        created,
        size,
        pathOnFly,
        id,
      ];

  String get getSize {
    if (size == null) {
      return '0 kB';
    }
    if (size! < 1) {
      return '${(size! * 1024).toStringAsFixed(2)} kB';
    }
    if (size! < 1024) {
      return '${size!.toStringAsFixed(2)} MB';
    }
    return '${(size! / 1024).toStringAsFixed(2)} GB';
  }

  //copyWith
  ManageFile copyWith({
    int? id,
    String? path,
    String? pathOnFly,
    String? name,
    FileType? type,
    DateTime? lastModified,
    DateTime? created,
    double? size,
  }) {
    return ManageFile(
      path ?? this.path,
      type ?? this.type,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      created: created ?? this.created,
      size: size ?? this.size,
      pathOnFly: pathOnFly ?? this.pathOnFly,
      id: id ?? this.id,
    );
  }
}
