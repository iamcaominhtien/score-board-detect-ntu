import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detect_table_api_model.g.dart';

@JsonSerializable()
class DetectTableAPIModel extends Equatable {
  final String? stt;
  final String? id;
  final List<int>? number;
  final List<List<int>>? predicted;

  const DetectTableAPIModel({this.stt, this.id, this.number, this.predicted});

  factory DetectTableAPIModel.fromJson(Map<String, dynamic> json) =>
      _$DetectTableAPIModelFromJson(json);

  Map<String, dynamic> toJson() => _$DetectTableAPIModelToJson(this);

  @override
  List<Object?> get props => [stt, id, number, predicted];
}

extension DetectTableAPIModelExtension on DetectTableAPIModel {
  bool get isValid {
    if (stt == null && id == null) return false;
    if (predicted == null) return false;
    return true;
  }
}
