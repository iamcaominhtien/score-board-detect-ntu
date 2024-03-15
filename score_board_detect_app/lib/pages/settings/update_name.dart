import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class UpdateName extends StatefulWidget {
  const UpdateName({super.key});

  @override
  State<UpdateName> createState() => _UpdateNameState();
}

class _UpdateNameState extends State<UpdateName> {
  String newName = FirebaseAuth.instance.currentUser?.displayName ?? "";
  bool isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("update_name".tr),
      content: TextField(
        controller: TextEditingController(
          text: newName,
        ),
        decoration: InputDecoration(
          hintText: "enter_your_new_name".tr,
        ),
        onChanged: (value) {
          newName = value;
        },
        autofocus: true,
      ),
      actions: [
        Row(
          children: [
            Expanded(child: Container()),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: Text("cancel".tr),
            ),
            const SizedBox(
              width: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                  isUpdating = true;
                });
                var primaryContainer =
                    Theme.of(context).colorScheme.primaryContainer;
                var onPrimaryContainer =
                    Theme.of(context).colorScheme.onPrimaryContainer;
                try {
                  await FirebaseAuth.instance.currentUser
                      ?.updateDisplayName(newName);
                  setState(() {
                    isUpdating = false;
                  });
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                } catch (e) {
                  setState(() {
                    isUpdating = false;
                  });
                  Fluttertoast.showToast(
                    msg: "update_failed".tr,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: primaryContainer,
                    textColor: onPrimaryContainer,
                    fontSize: 16.0,
                  );
                }
              },
              child: Row(
                children: [
                  Text("update".tr),
                  if (isUpdating)
                    const SizedBox(
                      width: 10,
                    ),
                  if (isUpdating)
                    SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }
}
