import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data/draft.json.dart';

class DisplayUploadScreen extends StatelessWidget {
  final controller = Get.put(Controller());
  final Draft draft;

  DisplayUploadScreen({Key? key, required this.draft}) : super(key: key);

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Save to')),
        body: saveToButtons(context));
  }

  uploadFile() async {
    final controller = Get.put(Controller());

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
    //request.fields['flip'] = '0'; // is rephoto flipped, optional
    var multipart = await http.MultipartFile.fromPath(
        'original', File(draft.imagePath).path);
    request.files.add(multipart);

    print("Upload file send");
    print(request.fields);
    request
        .send()
        .then((result) async {
          http.Response.fromStream(result).then((response) {
            if (response.statusCode == 200) {
              print("Uploaded! ");
              print('response.body ' + response.body);
            } else {
              print("Upload failed " + response.statusCode.toString());
              print('response.body ' + response.body);
            }

            return response.body;
          });
        })
        .catchError((err) => print('error : ' + err.toString()))
        .whenComplete(() {});
  }

  Widget saveToButtons(context) {
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
      SignInButtonBuilder(
        text: 'Ajapaik',
        icon: Icons.cloud_upload,
        onPressed: () async {
          await uploadFile();
        },
        backgroundColor: const Color(0xFF3366cc),
      ),
      SignInButtonBuilder(
        text: 'Wikimedia Commons',
        icon: Icons.cloud_upload,
        onPressed: () {},
        backgroundColor: const Color(0xFF3366cc),
      ),
    ]));
  }
}
