import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'getxnavigation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data/draft.json.dart';
import 'login.dart';

class DisplayUploadScreen extends StatelessWidget {
  final controller = Get.put(Controller());
  final Draft draft;

  DisplayUploadScreen({Key? key, required this.draft}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Save to')),
        body: saveToButtons(context));
  }

  uploadFile(BuildContext context) async {
    // before uploading, check if user has logged in,
    // relogin if expired

    final controller = Get.put(Controller());

    /* if there is no session user could try to relogin
    or save data for later when near better connection
    -> check saving data in caller
    if (controller.getSession() == "")
      return;

     */

    (draft.historicalImageId);
    ("Upload file Start");
    var postUri = Uri.parse("https://ajapaik.ee/api/v1/photo/upload/");
    var request = http.MultipartRequest("POST", postUri);
    request.headers['Cookie'] = 'sessionid=' + controller.getSession();
//    request.headers['Content-Type']="application/json; charset=UTF-8";
    request.fields['id'] =
        draft.historicalImageId; // Historical photo id in Ajapaik or Finna_url
    request.fields['latitude'] = draft.lat.toString(); // optional
    request.fields['longitude'] = draft.lon.toString(); // optional
//    request.fields['accuracy'] = 'blah'; //optional
//    request.fields['age'] = 'blah'; // optional, coordinates_age
    request.fields['date'] =
        draft.date; //'01-01-1999'; // optional, coordinate_accuracy
    request.fields['scale'] = draft.scale.toString();
    request.fields['yaw'] = '0'; // device_yaw
    request.fields['pitch'] = '0'; // device_pitch
    request.fields['roll'] = '0'; // device_roll
    request.fields['flip'] = '0';
    /* (draft.historicalPhotoFlipped == true)
        ? '1'
        : '0'; // is rephoto flipped, optional*/
    var multipart = await http.MultipartFile.fromPath(
        'original', File(draft.imagePath).path);
    request.files.add(multipart);

    ("Upload file send");
    (request.fields);
    Get.showSnackbar(
      const GetSnackBar(
        title: "Uploading file to Ajapaik",
        message: "upload started",
        duration: Duration(seconds: 3),
      ),
    );

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
          if (controller.getSession() == "") {
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
/*      SignInButtonBuilder sibWiki = SignInButtonBuilder(
        text: 'Wikimedia Commons',
        icon: Icons.cloud_upload,
        onPressed: () {
          if (controller.getSession() == "") {
            Get.to(DisplayLoginScreen());
          } else {
            ("Logged in");
          }
        },
        backgroundColor: const Color(0xFF3366cc),
      );
      buttons.add(sibWiki)
 */

    Center c = Center(
        child: Wrap(spacing: 10, runSpacing: 10, children: buttons));
    return c;
  }
}
