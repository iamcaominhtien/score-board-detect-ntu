part of 'bloc.dart';

@immutable
class BottomBarState extends Equatable {
  final int currentIndex;
  final bool show;

  const BottomBarState(this.currentIndex, {this.show = true});

  @override
  List<Object?> get props => [currentIndex, show];

  //copyWith
  BottomBarState copyWith({int? currentIndex, bool? show}) {
    return BottomBarState(
      currentIndex ?? this.currentIndex,
      show: show ?? this.show,
    );
  }
}
