import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/pages/settings/settings_state.dart';
import 'package:score_board_detect/pages/settings/update_name.dart';
import 'package:score_board_detect/service/fire_storage.dart';
import 'package:score_board_detect/service/helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<User?>(
                              stream: FirebaseAuth.instance.userChanges(),
                              builder: (context, snapshot) {
                                return Stack(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shape: const CircleBorder(),
                                      ),
                                      onPressed: () =>
                                          _updateAvatarChooseMethod(context),
                                      child: ui_auth.UserAvatar(
                                        key: ValueKey(snapshot.data?.photoURL ??
                                            'avatar'),
                                        placeholderColor: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          padding: const EdgeInsets.all(0),
                                          shape: const CircleBorder(),
                                          visualDensity: const VisualDensity(
                                            horizontal:
                                                VisualDensity.minimumDensity,
                                            vertical:
                                                VisualDensity.minimumDensity,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _updateAvatarChooseMethod(context),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 15,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Expanded(child: Container()),
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ??
                                "No name",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateName(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                padding: const EdgeInsets.all(0),
                                shape: const CircleBorder(),
                                visualDensity: const VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity,
                                )),
                            child: const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Icon(
                                Icons.edit,
                                size: 15,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                      if (FirebaseAuth.instance.currentUser?.email != null)
                        Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? "",
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                }),
            const SizedBox(
              height: 60,
            ),
            Obx(
              () {
                final settingState = Get.find<SettingsState>();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        SettingContent(
                          label: "language".tr,
                          iconLabel: Icons.language,
                          tail: Row(
                            children: [
                              Text(
                                settingState.language.name,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7),
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_sharp,
                                size: 20,
                              ),
                            ],
                          ),
                          callBack: () {
                            settingState.toggleLanguage();
                          },
                        ),
                        // SettingContent(
                        //   label: "Update",
                        //   iconLabel: Icons.update,
                        //   tail: const Icon(
                        //     Icons.arrow_forward_ios_sharp,
                        //     size: 20,
                        //   ),
                        //   callBack: () {},
                        // ),
                        SettingContent(
                          label: settingState.isDarkMode
                              ? "dark_mode".tr
                              : "light_mode".tr,
                          iconLabel: settingState.isDarkMode
                              ? Icons.nights_stay_outlined
                              : Icons.wb_sunny_outlined,
                          tail: SizedBox(
                            height: 20,
                            width: 40,
                            child: Switch(
                              value: settingState.isDarkMode,
                              onChanged: (bool value) {
                                settingState.toggleTheme();
                              },
                            ),
                          ),
                          callBack: () {
                            settingState.toggleTheme();
                          },
                        ),
                        // SettingContent(
                        //   label: "Auto save on cloud",
                        //   iconLabel: settingState.autoSaveOnCloud
                        //       ? Icons.cloud_done_rounded
                        //       : Icons.cloud_done_outlined,
                        //   tail: SizedBox(
                        //     height: 20,
                        //     width: 40,
                        //     child: Switch(
                        //       value: settingState.autoSaveOnCloud,
                        //       onChanged: (bool value) {
                        //         settingState.toggleAutoSaveOnCloud();
                        //       },
                        //     ),
                        //   ),
                        //   callBack: () {
                        //     settingState.toggleAutoSaveOnCloud();
                        //   },
                        // ),
                        SettingContent(
                          label: "sign_out".tr,
                          iconLabel: Icons.logout,
                          tail: Container(),
                          callBack: () {
                            FirebaseAuth.instance.signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _updateName(BuildContext context) {
    //show dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const UpdateName();
      },
    );
  }

  void _updateAvatarChooseMethod(BuildContext context) {
    void updateAvatar(bool useCamera) {
      Helper.pickImage(useCamera).then((value) async {
        if (value != null) {
          try {
            _showNotification(context, "uploading_avatar".tr);
            FireStorage.pushImageToMyStorage(
              value,
              FirebaseAuth.instance.currentUser!.uid,
              imageName:
                  "user_${FirebaseAuth.instance.currentUser!.uid}_avatar",
            ).then((photoUrl) {
              if (photoUrl != null) {
                FirebaseAuth.instance.currentUser!
                    .updatePhotoURL(photoUrl)
                    .then((_) => _showNotification(
                        context, "update_avatar_successfully".tr));
              } else {
                _showNotification(context, "update_avatar_failed".tr);
              }
            });
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print(e);
              print(stackTrace);
            }
            _showNotification(context, "update_avatar_failed".tr);
          }
        }
      });
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Expanded(child: Container()),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      updateAvatar(true);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      updateAvatar(false);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.photo,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
  }

  Future<bool?> _showNotification(BuildContext context, String message) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
      fontSize: 16.0,
    );
  }
}

class SettingContent extends StatelessWidget {
  const SettingContent({
    super.key,
    required this.label,
    required this.tail,
    required this.iconLabel,
    required this.callBack,
  });

  final String label;
  final Widget tail;
  final IconData iconLabel;
  final VoidCallback callBack;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: callBack,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(
          fontSize: 17,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        side: BorderSide(
          width: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
      child: Row(
        children: [
          Icon(iconLabel),
          const SizedBox(
            width: 10,
          ),
          Text(label),
          Expanded(child: Container()),
          tail,
        ],
      ),
    );
  }
}
