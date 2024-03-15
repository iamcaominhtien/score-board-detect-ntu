import 'package:flutter/material.dart';
import 'package:score_board_detect/service/detect_table_api/detect_table_api.dart';
import 'package:score_board_detect/service/manage_files/excel/my_excel.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(onPressed: _press, child: const Text('press'))),
    );
  }

  void _press() async {
    var url =
        'https://firebasestorage.googleapis.com/v0/b/score-board-detect.appspot.com/o/admin%2Fimages%2Ftest%2FAnh1.jpg?alt=media&token=4d4da783-32b3-40df-9c6d-50a16c748def';
    var result = await DetectTableAPI.detectTable(url);
    if (result != null) {
      MyExcel.createDataExcel(result);
    }
  }
}
