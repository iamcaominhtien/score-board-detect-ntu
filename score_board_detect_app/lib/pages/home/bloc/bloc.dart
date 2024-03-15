import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part "state.dart";

part "action.dart";

class BottomBarBloc extends Bloc<BottomBarAction, BottomBarState> {
  bool _statusBarAtIndex2 = true;
  bool _statusBarAtIndex1 = true;

  BottomBarBloc() : super(const BottomBarState(0)) {
    on<ChangeIndex>((event, emit) {
      if (event.index == 1) {
        emit(state.copyWith(
            currentIndex: event.index, show: _statusBarAtIndex1));
      } else if (event.index == 2) {
        emit(state.copyWith(
            currentIndex: event.index, show: _statusBarAtIndex2));
      } else {
        emit(state.copyWith(currentIndex: event.index, show: true));
      }
      if (state.currentIndex == 2) {
        _statusBarAtIndex2 = state.show;
      } else if (state.currentIndex == 1) {
        _statusBarAtIndex1 = state.show;
      }
    });
    on<ChangeShow>((event, emit) {
      if (state.currentIndex == 2) {
        _statusBarAtIndex2 = event.show;
      } else if (state.currentIndex == 1) {
        _statusBarAtIndex1 = event.show;
      }
      emit(state.copyWith(show: event.show));
    });
    on<EndBottomBarAction>((event, emit) {
      _statusBarAtIndex2 = true;
      _statusBarAtIndex1 = true;
      emit(const BottomBarState(0));
    });
  }
}
