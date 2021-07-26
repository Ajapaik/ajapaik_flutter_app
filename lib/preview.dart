import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';
import 'data/draft.json.dart';
import 'services/geolocation.dart';

// A widget that displays the picture taken by the user.

class DisplayPictureScreen extends StatelessWidget {
  final controller = Get.put(Controller());
  final String imagePath;
  final String historicalImagePath;
  final String historicalImageId;
  final Orientation? cameraPhotoOrientation;
  final bool? historicalPhotoRotation;
  final Size? historicalPhotoSize;
  final Size? cameraPhotoSize;
  final double? historicalPhotoScale;

  DisplayPictureScreen(
      {Key? key,
      required this.imagePath,
      required this.historicalImagePath,
      required this.historicalImageId,
      this.cameraPhotoOrientation,
      this.historicalPhotoRotation,
      this.historicalPhotoSize,
      this.cameraPhotoSize,
      this.historicalPhotoScale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: getImageComparison(context),
        bottomNavigationBar:
//          child: Container (
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
              // Go back to cameraview
              BackButton(),

              // Take photo button
              ElevatedButton(
                onPressed: () async {
                  if (imagePath != null) {
                    await GallerySaver.saveImage(imagePath.toString());
/*                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DisplayUploadScreen(imagePath: imagePath,
                            historicalPhotoScale:historicalPhotoScale
                              ,)),
                    );*/
                    DateTime now = DateTime.now();
                    String convertedDateTime =
                        now.day.toString().padLeft(2, '0') +
                            "-" +
                            now.month.toString().padLeft(2, '0') +
                            "-" +
                            now.year.toString();
                    Position position = await determinePosition();

                    Draft draft = Draft(
                      "",
                      imagePath,
                      historicalImagePath,
                      historicalImageId,
                      convertedDateTime,
                      1,
                      position.longitude,
                      position.latitude,
                      -1,
                      -1,
                      false,
                    );

                    // Close preview and cameraview by going two steps back
                    Navigator.pop(context);
                    Navigator.pop(context, draft);
                  } else {
                    // Some errorhandling
                  }
                },
                child: Icon(Icons.check),
              ),

              // Go two steps backward so the rephoto camera will be closed
              CloseButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, false);
                },
              )
            ]));
  }

  Widget getImageComparison(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return getVerticalImageComparison(context);
      } else {
        return getHorizontalImageComparison(context);
      }
    });
  }

  Image getImage(String filename, BuildContext context) {
    if (File(filename).existsSync()) {
      return Image.file(File(historicalImagePath),
          fit: BoxFit.contain, height: 8000, width: 8000);
    } else {
      return Image.network(filename,
          fit: BoxFit.contain, height: 8000, width: 8000);
    }
  }

  Widget getHorizontalImageComparison(BuildContext context) {
    return Center(
        child: FittedBox(
      child: Row(children: [
        getImage(historicalImagePath.toString(), context),
        Image.file(File(imagePath),
            fit: BoxFit.contain, height: 8000, width: 8000)
      ]),
    ));
  }

  Widget getVerticalImageComparison(BuildContext context) {
    return Center(
        child: FittedBox(
      fit: BoxFit.contain,
      child: Column(children: [
        getImage(historicalImagePath.toString(), context),
        Image.file(File(imagePath),
            fit: BoxFit.contain, height: 8000, width: 8000)
      ]),
    ));
  }
}
