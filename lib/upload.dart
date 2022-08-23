import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'sessioncontroller.dart';
import 'uploadcontroller.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data/draft.json.dart';
import 'login.dart';

class DisplayUploadScreen extends StatelessWidget {
  final sessionController = Get.put(SessionController());
  final uploadController = Get.put(UploadController());
  final Draft draft;

  DisplayUploadScreen({Key? key, required this.draft}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TOOD: see about handling session/login here
    // to simplify save/upload things later
    // -> might need some major refactoring..?
    return Scaffold(
        appBar: AppBar(title: const Text('Save to')),
        body: saveToButtons(context));
  }


  uploadFile(BuildContext context) async {
    // before uploading, check if user has logged in,
    // relogin if expired

    final controller = Get.put(SessionController());

    /* if there is no session user could try to relogin
    or save data for later when near better connection
       -> check saving data in caller
    TODO: ask for login (in caller) ?
    */
    if (controller.isExpired()) {
      return false; // what do we want respond with here?
    }

    (draft.historicalImageId);
    ("Upload file Start");

    // TODO: user might want to change destination (ajapaik/commons)
    // AND user might want to upload to multiple destinations
    // including social media etc. -> may have multiple uploads needed depending on destination
    // or just sharing a link at minimum?
    // -> must have session to appropriate server
    // -> may need to login now if was in standalone before
    // -> may need multiple session for different uploads
    // etc.
    var request = uploadController.generateUploadRequest(controller, draft);
    if (request == null) {
      // destination not yet implemented
      return false;
    }

    ("Upload file send");
    (request.fields);
    Get.showSnackbar(
      const GetSnackBar(
        title: "Uploading file to Ajapaik",
        message: "upload started",
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: move the actual upload to controller too, split it from the UI things..

    request
        .send()
        .then((result) async {
          http.Response.fromStream(result).then((response) {
            if (response.statusCode == 200) {
              print("Uploaded! ");
              print('response.body ' + response.body);
              Get.showSnackbar(
                const GetSnackBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload succesful",
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ("Upload failed " + response.statusCode.toString());
              ('response.body ' + response.body);
              Get.showSnackbar(
                GetSnackBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload failed " + response.statusCode.toString(),
                  duration: const Duration(seconds: 4),
                ),
              );
            }

            // TODO: parse response to something that we can show to user,
            // don't use it directly: especially if commons differs from ajapaik
            return response.body;
          });
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((err) => {
              Get.showSnackbar(
                GetSnackBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload failed " + err.toString(),
                  duration: const Duration(seconds: 3),
                ),
              )
            })
        .whenComplete(() {});
  }

  Widget saveToButtons(context) {
    ("saveButtons()");
    (draft.historicalImageId);

    // TODO: saving should be first, only proceed to upload if there is session active
    // (user near network), otherwise just save the data for later:
    // also uploading from saved data later..
    // -> save first, upload decide where to upload after
    // -> user might want to upload to social media AND commons or ajapaik
    // -> not just one destination

    const EdgeInsets padding = EdgeInsets.all(11.0);
    List<Widget> buttons = [];
    SignInButtonBuilder sibGallery = SignInButtonBuilder(
      text: 'Gallery',
      innerPadding: padding,
      fontSize: 25,

      icon: Icons.drafts,
      onPressed: () {
        Navigator.pop(context);
      },
      backgroundColor: const Color(0xFF3366cc),
    );
    buttons.add(sibGallery);

    if (draft.historicalImagePath.contains("ajapaik.ee")) {
      SignInButtonBuilder sibAjapaik = SignInButtonBuilder(
        text: 'Ajapaik',
        fontSize: 25,
        innerPadding: padding,
        icon: Icons.cloud_upload,
        onPressed: () async {
          if (sessionController.isExpired()) {
            Get.to(DisplayLoginScreen());
          } else {
            uploadFile(context);
            Navigator.pop(context);
          }
        },
        backgroundColor: const Color(0xFF3366cc),
      );
      buttons.add(sibAjapaik);
    }
    SignInButtonBuilder sibWiki = SignInButtonBuilder(
      text: 'Wikimedia Commons',
      icon: Icons.cloud_upload,
      onPressed: () {
        if (sessionController.isExpired()) {
          Get.to(DisplayLoginScreen());
        } else {
          ("Logged in");
          uploadFile(context);
          Navigator.pop(context);
        }
      },
      backgroundColor: const Color(0xFF3366cc),
    );
    buttons.add(sibWiki);

    Center c = Center(
        child: Wrap(spacing: 10, runSpacing: 10, children: buttons));
    return c;
  }
}
