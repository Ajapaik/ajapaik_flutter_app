import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'services/geolocation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';
import 'data/draft.json.dart';

// A widget that displays the picture taken by the user.

// ignore: must_be_immutable
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final String historicalImagePath;
  final String historicalImageId;
  final Orientation? cameraPhotoOrientation;
  final bool? historicalPhotoRotation;
  final bool? historicalPhotoFlipped;
  final Size? historicalPhotoSize;
  final Size? cameraPhotoSize;
  final double? historicalPhotoScale;

  const DisplayPictureScreen(
      {Key? key,
      required this.imagePath,
      required this.historicalImagePath,
      required this.historicalImageId,
      this.cameraPhotoOrientation,
      this.historicalPhotoRotation,
      this.historicalPhotoFlipped,
      this.historicalPhotoSize,
      this.cameraPhotoSize,
      this.historicalPhotoScale})
      : super(key: key);

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}

class DisplayPictureScreenState extends State<DisplayPictureScreen>
    with TickerProviderStateMixin {
  final controller = Get.put(Controller());
  GlobalKey cameraPhotoKey = GlobalKey();
  double oldCenterX = 0;
  double oldCenterY = 0;
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: getImageComparison(context),
        bottomNavigationBar: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Go back to cameraview
              const BackButton(),

              // Take photo button
              ElevatedButton(
                onPressed: () async {
                  await GallerySaver.saveImage(widget.imagePath.toString());
                  DateTime now = DateTime.now();
                  String convertedDateTime =
                      now.day.toString().padLeft(2, '0') +
                          "-" +
                          now.month.toString().padLeft(2, '0') +
                          "-" +
                          now.year.toString();
                  Position position = await determinePosition();
                  ("Flipped");
                  (widget.historicalPhotoFlipped);
                  Draft draft = Draft(
                    "",
                    widget.imagePath,
                    widget.historicalImagePath,
                    widget.historicalImageId,
                    widget.historicalPhotoFlipped! == true,
                    convertedDateTime,
                    widget.historicalPhotoScale ?? 1,
                    position.longitude,
                    position.latitude,
                    -1,
                    -1,
                    false,
                  );

                  // Close preview and cameraview by going two steps back
                  Navigator.pop(context);
                  Navigator.pop(context, draft);
                },
                child: const Icon(Icons.check),
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

  Image getImage(String filename, BuildContext context, {double scale = 1}) {
    if (File(filename).existsSync()) {
      return Image.file(File(widget.historicalImagePath),
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    } else {
      return Image.network(filename,
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    }
  }

  Image getImage2(String filename, BuildContext context) {
    ("getImage2");
    Image image;
    bool validURL = Uri.parse(filename).host == '' ? false : true;

    if (validURL) {
      image = Image.network(filename, fit: BoxFit.cover);
    } else if (File(filename).existsSync()) {
      image = Image.file(
        File(filename),
      );
    } else {
      image = Image.network(
        "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg",
      );
    }

    getImageInfo(image).then((info) {
      final box = context.findRenderObject() as RenderBox;

      //       final double w = MediaQuery.of(context).size.width;
      //       final double h = MediaQuery.of(context).size.height;

      final double w = box.size.width;
      final double h = box.size.height;

      double scale = widget.historicalPhotoScale ?? 1.0;
      double centerX = 0;
      double centerY = 0;

      if (h > w) {
        ("h>w");
        scale = (h / w) / (widget.historicalPhotoScale ?? 1.0);
        centerX = (w - w * scale) / 2;
        centerY = (h - h * scale) / 4;
      } else {
        ("h<w+");
        scale = (w / h) / (widget.historicalPhotoScale ?? 1.0);
        centerX = (w - w * scale) / 4;
        centerY = (h - h * scale) / 2;
      }

      if (oldCenterX != centerX || oldCenterY != centerY) {
        oldCenterX = centerX;
        oldCenterY = centerY;
        setState(() {
          _transformationController.value = Matrix4.identity()
            ..translate(centerX, centerY)
            ..scale(scale);
        });
      }
    });

    return image;
  }

  Future<ui.Image> getImageInfo(Image image) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      completer.complete(info.image);
    }));

    ui.Image imageInfo = await completer.future;
    return imageInfo;
  }

  Widget getHorizontalImageComparison(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(
                    widget.historicalPhotoFlipped == true ? math.pi : 0),
                child:
                    getImage(widget.historicalImagePath.toString(), context))),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: Colors.pink[600]!,
                      width: 5,
                    )),
                    child: InteractiveViewer(
                        key: cameraPhotoKey,
                        scaleEnabled: false,
                        panEnabled: false,
                        transformationController: _transformationController,
                        maxScale: 20,
                        minScale: 0.1,
                        child: getImage2(widget.imagePath, context)))))
      ],
    );
  }

  Widget getVerticalImageComparison(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(
                    widget.historicalPhotoFlipped == true ? math.pi : 0),
                child:
                    getImage(widget.historicalImagePath.toString(), context))),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: Colors.pink[600]!,
                      width: 5,
                    )),
                    child: InteractiveViewer(
                        key: cameraPhotoKey,
                        scaleEnabled: false,
                        panEnabled: false,
                        transformationController: _transformationController,
                        maxScale: 20,
                        minScale: 0.1,
                        child: getImage2(widget.imagePath, context)))))
      ],
    );
  }
}
