import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:score_board_detect/service/detect_table_api/bloc/bloc.dart';
import 'package:score_board_detect/service/helper.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview(this.path, this.file, {Key? key}) : super(key: key);
  final String path;
  final ManageFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview>
    with SingleTickerProviderStateMixin {
  bool _showAppBar = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  late final DetectTableAPIBloc _detectTableAPIBloc;

  @override
  void initState() {
    super.initState();
    _detectTableAPIBloc = BlocProvider.of<DetectTableAPIBloc>(context);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });

    if (_showAppBar) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleAppBar,
        child: Stack(
          children: [
            Container(),
            Center(
              child: Image.file(
                File(widget.path),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  height: kToolbarHeight + 30,
                  color: Colors.transparent,
                  child: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: share,
                        icon: const Icon(Icons.share),
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: _scan,
                        icon: const Icon(Icons.document_scanner_outlined),
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: _save,
                        icon: const Icon(Icons.save_alt),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scan() async {
    _detectTableAPIBloc.add(AddNewTaskAction(Task(widget.file)));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _save() async {
    await GallerySaver.saveImage(widget.path, albumName: "TableScanner")
        .catchError((e) {
      debugPrint("save image error");
      return null;
    });
    Fluttertoast.showToast(
        msg: "Image saved!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey.shade700,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void share() {
    Helper.shareFile(widget.path);
  }
}
