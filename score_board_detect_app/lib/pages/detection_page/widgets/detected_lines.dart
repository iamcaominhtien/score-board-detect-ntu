import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board_detect/pages/detection_page/cubit.dart';

import 'detect_table_painter.dart';

class DetectedLines extends StatelessWidget {
  const DetectedLines({
    super.key,
    required DetectionPageCubit detectionPageCubit,
    required double aspectRatio,
  })  : _detectionPageCubit = detectionPageCubit,
        _aspectRatio = aspectRatio;

  final DetectionPageCubit _detectionPageCubit;
  final double _aspectRatio;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DetectionPageCubit, DetectionPageState, List<int>?>(
      selector: (state) => state.lines,
      bloc: _detectionPageCubit,
      builder: (context, lines) {
        return AspectRatio(
          aspectRatio: 1 / _aspectRatio,
          child: CustomPaint(
            painter: DetectTablePainter(lines ?? []),
          ),
        );
      },
    );
  }
}
