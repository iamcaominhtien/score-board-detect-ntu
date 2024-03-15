import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show UniqueKey;

class RowExcel extends Equatable {
  final UniqueKey uniqueId = UniqueKey();
  final String? stt;
  final String? id;
  final String? dKt;
  final String? dGk;
  final String? dThi;

  RowExcel({this.stt, this.id, this.dKt, this.dGk, this.dThi});

  @override
  List<Object?> get props => [
        uniqueId,
        stt,
        id,
        dKt,
        dGk,
        dThi,
      ];

  int compareTo(RowExcel other) {
    int result = 0;

    for (var pair in [(dKt, other.dKt), (dGk, other.dGk), (dThi, other.dThi)]) {
      if (pair.$1 != null &&
          pair.$1!.isNotEmpty &&
          pair.$2 != null &&
          pair.$2!.isNotEmpty) {
        double t1 = double.parse(pair.$1!);
        double t2 = double.parse(pair.$2!);
        if ((t1 - t2).abs() > 0.001) {
          result += 1;
        }
      }
    }
    return result;
  }

  double compareIDWith(RowExcel other) {
    //id must not be null
    if (id!.length != other.id!.length) return 0;
    if (id!.length != 8) return 0; //id must be 8 characters (ex: 61134486)
    if (id == other.id) return 1;

    int countEqualElements = 0;
    for (int index = 0; index < id!.length; index++) {
      if (id![index] == other.id![index]) {
        countEqualElements++;
      }
    }
    return countEqualElements / id!.length;
  }
}
