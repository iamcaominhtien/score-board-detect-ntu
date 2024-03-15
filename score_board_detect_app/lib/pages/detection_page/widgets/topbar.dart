import 'package:flutter/material.dart';

class TopBarDetectionPage extends StatelessWidget {
  const TopBarDetectionPage({
    super.key,
    required this.flashIcon,
    required this.flashToggle,
  });

  final IconData flashIcon;
  final Function() flashToggle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
                foregroundColor: Colors.black,
                backgroundColor: Colors.transparent,
                elevation: 0),
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: flashToggle,
            style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.white.withOpacity(0.3),
                padding: const EdgeInsets.all(10),
                foregroundColor: Colors.white,
                elevation: 0),
            child: Icon(flashIcon),
          ),
        ],
      ),
    );
  }
}
