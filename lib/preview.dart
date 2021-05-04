import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// A widget that displays the picture taken by the user.

class DisplayPictureScreen extends StatelessWidget {
  final String? imagePath;
  final Orientation? cameraPhotoOrientation;
  final bool? historicalPhotoRotation;
  final Size? historicalPhotoSize;
  final Size? cameraPhotoSize;
  final double? historicalPhotoScale;

  const DisplayPictureScreen(
      {Key? key,
        this.imagePath,
        this.cameraPhotoOrientation,
        this.historicalPhotoRotation,
        this.historicalPhotoSize,
        this.cameraPhotoSize,
        this.historicalPhotoScale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
          InteractiveViewer(
              child: Image.file(
                  File(imagePath!),
                  width:MediaQuery.of(context).size.width,
                  height:MediaQuery.of(context).size.height/2,
              ),

          ) ,
            Text('cameraPhotoOrientation: $cameraPhotoOrientation'),
            Text('historicalPhotoRotation: $historicalPhotoRotation'),
            Text('historicalPhotoSize: $historicalPhotoSize'),
            Text('historicalPhotoScale: $historicalPhotoScale'),
          ]),
        ));
  }
}
