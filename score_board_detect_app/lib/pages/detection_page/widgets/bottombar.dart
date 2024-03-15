import 'package:flutter/material.dart';

class BottomBarDetectionPage extends StatelessWidget {
  const BottomBarDetectionPage({
    super.key,
    required this.pickImage,
    required this.takePicture,
  });
  final Function() pickImage;
  final Function() takePicture;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.grey,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              child: const Icon(
                Icons.photo_size_select_actual_outlined,
                size: 25,
              ),
            ),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: takePicture,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
            ),
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(
                Icons.camera_alt,
                size: 40,
              ),
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}
