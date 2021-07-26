// https://medium.com/fabcoding/adding-an-image-picker-in-a-flutter-app-pick-images-using-camera-and-gallery-photos-7f016365d856
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

import 'camera.dart';

final picker = ImagePicker();

Future getImageFromGallery(context) async {
  final pickedFile = await picker.getImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    availableCameras().then((availableCameras) {
      CameraDescription firstCamera = availableCameras.first;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePictureScreen(
                camera: firstCamera,
                historicalPhotoId: pickedFile.path.toString(),
                historicalPhotoUri: pickedFile.path.toString())),
      );
    });
  } else {
    print('No image selected 0.');
  }
}

Future saveImageFromCamera() async {
  final pickedImage =
      await picker.getImage(source: ImageSource.camera, imageQuality: 100);
  if (pickedImage != null) {
    await GallerySaver.saveImage(pickedImage.path);
  } else {
    print('No image selected 1.');
  }
}

void showPicker(context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Photo Library'),
                    onTap: () {
                      getImageFromGallery(context);
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_camera),
                  title: new Text('Camera'),
                  onTap: () {
                    saveImageFromCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      });
}
