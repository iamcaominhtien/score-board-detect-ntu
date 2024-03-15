import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:score_board_detect/service/detect_table_api/bloc/bloc.dart';

class TopPanel extends StatefulWidget {
  const TopPanel({Key? key}) : super(key: key);

  @override
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int total = 1;
  int finishedProgresses = 0;
  int numberOfSuccess = 0;
  int numberOfFail = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => SizedBox(
        width: double.infinity,
        height: 80 * _animation.value,
        child: BlocConsumer<DetectTableAPIBloc, DetectTableApiState?>(
          builder: (context, state) {
            if (state is UpdateProgressState) {
              total = state.total == 0 ? 1 : state.total;
              finishedProgresses = state.finishedProgresses;
              numberOfSuccess = state.numberOfSuccess;
              numberOfFail = state.numberOfFail;
            } else if (state is AddNewTaskState) {
              total = state.total == 0 ? 1 : state.total;
            }
            return LiquidLinearProgressIndicator(
              value: finishedProgresses / total,
              valueColor: AlwaysStoppedAnimation(Colors.lime[400]!),
              backgroundColor: Colors.white,
              direction: Axis.horizontal,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${'top_panel_finished'.tr}... $finishedProgresses/$total",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Roboto",
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${'top_panel_success'.tr}: $numberOfSuccess/$total",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Roboto",
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${'top_panel_failed'.tr}: $numberOfFail/$total",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Roboto",
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            );
          },
          buildWhen: (previous, current) =>
              previous != current &&
              (current is UpdateProgressState || current is AddNewTaskState),
          listener: (context, state) {
            if (state is FinishAllTaskState) {
              _animationController.reverse();
            }
          },
          listenWhen: (previous, current) =>
              previous != current && current is FinishAllTaskState,
        ),
      ),
    );
  }
}
