// https://medium.com/fabcoding/adding-an-image-picker-in-a-flutter-app-pick-images-using-camera-and-gallery-photos-7f016365d856
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

import 'camera.dart';
import 'localization.dart';

final picker = ImagePicker();

Future getImageFromGallery(context) async {
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    availableCameras().then((availableCameras) {
      CameraDescription firstCamera = availableCameras.first;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePictureScreen(
                camera: firstCamera,
                historicalPhotoId: pickedFile.path,
                historicalPhotoUri: pickedFile.path,
                historicalPhotoDescription: "Historical image is from gallery"
            )),
      );
    });
  } else {
    ('No image selected 0.');
  }
}

Future saveImageFromCamera() async {
  final pickedImage =
      await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
  if (pickedImage != null) {
    await GallerySaver.saveImage(pickedImage.path);
  } else {
    ('No image selected 1.');
  }
}

void showPicker(context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(AppLocalizations.getText(context, 'localFileSelect-option1')),
                  onTap: () {
                    getImageFromGallery(context);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(AppLocalizations.getText(context, 'localFileSelect-option2')),
                onTap: () {
                  saveImageFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      });
}
