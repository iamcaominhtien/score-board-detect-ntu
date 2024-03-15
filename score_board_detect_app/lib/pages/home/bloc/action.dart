part of "bloc.dart";

@immutable
abstract class BottomBarAction extends Equatable {
  const BottomBarAction();

  @override
  List<Object> get props => [];
}

class ChangeIndex extends BottomBarAction {
  final int index;

  const ChangeIndex({required this.index});

  @override
  List<Object> get props => [index];
}

class ChangeShow extends BottomBarAction {
  final bool show;

  const ChangeShow(this.show);

  @override
  List<Object> get props => [show];
}

class EndBottomBarAction extends BottomBarAction {}
