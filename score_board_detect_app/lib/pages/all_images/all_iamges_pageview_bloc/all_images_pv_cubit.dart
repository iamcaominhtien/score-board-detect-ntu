import 'package:flutter_bloc/flutter_bloc.dart';

class AllIMGPVCubit extends Cubit<int> {
  AllIMGPVCubit() : super(0);

  void local() => emit(0);
  void cloud() => emit(1);
}
