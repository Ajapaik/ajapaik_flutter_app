import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data/draft.json.dart';
import 'login.dart';

class DisplayUploadScreen extends StatelessWidget {
  final controller = Get.put(Controller());
  final Draft draft;

  DisplayUploadScreen({Key? key, required this.draft}) : super(key: key);

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Save to')),
        body: saveToButtons(context));
  }

  uploadFile(BuildContext context) async {
    final controller = Get.put(Controller());

    print(draft.historicalImageId);
    print("Upload file Start");
    var postUri = Uri.parse("https://staging.ajapaik.ee/api/v1/photo/upload/");
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

    print("Upload file send");
    print(request.fields);
    Get.showSnackbar(
      GetBar(
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
                GetBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload succesful",
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              print("Upload failed " + response.statusCode.toString());
              print('response.body ' + response.body);
              Get.showSnackbar(
                GetBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload failed " + response.statusCode.toString(),
                  duration: Duration(seconds: 4),
                ),
              );
            }

            return response.body;
          });
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((err) => {
              Get.showSnackbar(
                GetBar(
                  title: "Uploading file to Ajapaik",
                  message: "upload failed " + err.toString(),
                  duration: Duration(seconds: 3),
                ),
              )
            })
        .whenComplete(() {});
  }

  Widget saveToButtons(context) {
    print("saveButtons()");
    print(draft.historicalImageId);
    return Center(
        child: Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
      SignInButtonBuilder(
        text: 'Gallery',
        icon: Icons.drafts,
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFF3366cc),
      ),
      if (draft.historicalImagePath.contains("ajapaik.ee"))
        SignInButtonBuilder(
          text: 'Ajapaik',
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
        ),
      SignInButtonBuilder(
        text: 'Wikimedia Commons',
        icon: Icons.cloud_upload,
        onPressed: () {
          if (controller.getSession() == "") {
            Get.to(DisplayLoginScreen());
          } else {
            print("Logged in");
          }
        },
        backgroundColor: const Color(0xFF3366cc),
      ),
    ]));
  }
}
