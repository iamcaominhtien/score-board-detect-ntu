import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board_detect/pages/all_images/bloc/bloc.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';

import 'image_preview.dart';

class ImagePreviewAnimation extends StatefulWidget {
  const ImagePreviewAnimation(
      this.file, this.keyDay, this.haveSelected, this.selectedMode,
      {Key? key})
      : super(key: key);
  final ManageFile file;
  final KeyDay keyDay;
  final bool haveSelected;
  final bool selectedMode;

  @override
  State<ImagePreviewAnimation> createState() => _ImagePreviewAnimationState();
}

class _ImagePreviewAnimationState extends State<ImagePreviewAnimation> {
  final ContainerTransitionType _transitionType = ContainerTransitionType.fade;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: _transitionType,
      openBuilder: (BuildContext context, VoidCallback _) {
        return ImagePreview(widget.file.path, widget.file);
      },
      tappable: false,
      closedBuilder: (context, action) {
        return _ImageCard(
          widget: widget,
          action: action,
          haveSelected: widget.haveSelected,
          keyDay: widget.keyDay,
          selectedMode: widget.selectedMode,
        );
      },
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.widget,
    required this.action,
    required this.haveSelected,
    this.keyDay,
    required this.selectedMode,
  });

  final ImagePreviewAnimation widget;
  final VoidCallback action;
  final bool haveSelected;
  final KeyDay? keyDay;
  final bool selectedMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      onLongPress: () => _toggleSelectImage(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(widget.file.path),
              fit: BoxFit.cover,
            ),
          ),
          if (selectedMode)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(),
                  if (haveSelected)
                    Container(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ElevatedButton(
                      onPressed: () => _toggleSelectImage(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: const CircleBorder(
                          side: BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(0),
                        visualDensity: const VisualDensity(
                          horizontal: VisualDensity.minimumDensity,
                          vertical: VisualDensity.minimumDensity,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          backgroundColor:
                              haveSelected ? Colors.blue : Colors.transparent,
                          radius: 8,
                          child: Container(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSelectImage(BuildContext context) {
    var allImagesBloc = context.read<AllImagesBloc>();
    if (haveSelected) {
      if (keyDay == KeyDay.today) {
        allImagesBloc.add(UnSelectImageOfToday({widget.file}));
      } else if (keyDay == KeyDay.yesterday) {
        allImagesBloc.add(UnSelectImageOfYesterday({widget.file}));
      } else if (keyDay == KeyDay.last7Days) {
        allImagesBloc.add(UnSelectImageOfLast7Days({widget.file}));
      } else if (keyDay == KeyDay.last30Days) {
        allImagesBloc.add(UnSelectImageOfLast30Days({widget.file}));
      } else if (keyDay == KeyDay.older) {
        allImagesBloc.add(UnSelectImageOfOlder({widget.file}));
      }
    } else {
      if (keyDay == KeyDay.today) {
        allImagesBloc.add(SelectImageOfToday({widget.file}));
      } else if (keyDay == KeyDay.yesterday) {
        allImagesBloc.add(SelectImageOfYesterday({widget.file}));
      } else if (keyDay == KeyDay.last7Days) {
        allImagesBloc.add(SelectImageOfLast7Days({widget.file}));
      } else if (keyDay == KeyDay.last30Days) {
        allImagesBloc.add(SelectImageOfLast30Days({widget.file}));
      } else if (keyDay == KeyDay.older) {
        allImagesBloc.add(SelectImageOfOlder({widget.file}));
      }
    }
  }
}
