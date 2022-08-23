import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'services/geolocation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'data/draft.json.dart';
import 'draftstorage.dart';
import 'package:image/image.dart' as img;

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
  final locator = Get.put(AppLocator());
  GlobalKey cameraPhotoKey = GlobalKey();
  double oldCenterX = 0;
  double oldCenterY = 0;
  final TransformationController _transformationController =
      TransformationController();

  // TODO: keep shared
  DraftStorage draftStorage = DraftStorage();

/*
  @override
  void initState() {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }
*/

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
              SizedBox(
                  height: 75,
                  width: 75,
                  // Take photo button
                  child: ElevatedButton(
                    onPressed: () async {
                      onTakePhotoButton();
                    },
                    child: const Icon(Icons.check),
                  )),

              // Go two steps backward so the rephoto camera will be closed
              CloseButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, false);
                },
              )
            ]));
  }

  void onTakePhotoButton() async {
    await GallerySaver.saveImage(widget.imagePath.toString());

    DateTime now = DateTime.now();

    // why this dateformat? could just use .toIso8601String() and be done with it..
    String convertedDateTime =
        now.day.toString().padLeft(2, '0') +
            "-" +
            now.month.toString().padLeft(2, '0') +
            "-" +
            now.year.toString();

    // location may be disallowed but save photo still
    await locator.updatePosition();
    LatLng pos = locator.getLatLong();

    Draft draft = Draft(
      "",
      widget.imagePath,
      widget.historicalImagePath,
      widget.historicalImageId,
      widget.historicalPhotoFlipped! == true,
      convertedDateTime,
      widget.historicalPhotoScale ?? 1,
      pos.latitude,
      pos.longitude,
      -1,
      -1,
      false,
    );
    // keep for later if we can't upload right away
    draftStorage.store(draft);

    // async gap
    if (!mounted) return;

    // Close preview and cameraview by going two steps back
    Navigator.pop(context);
    Navigator.pop(context, draft);
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

  bool needsHeightScaling(cameraImageWidth, cameraImageHeight) {
    double heightScale = cameraImageHeight/widget.historicalPhotoSize!.height;
    double widthScale = cameraImageWidth/widget.historicalPhotoSize!.width;
    return widthScale<heightScale;
  }

  Widget getImage4(filename, context) {
    // TOdO: another hard-coded url to move..
    // TODO: try to avoid these, flutter does not like cross-domain files..
    // -> include file with app or seek alternative?
    String wikiExample = "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg";
    Image image=Image.network(wikiExample);
    bool validURL = Uri.parse(filename).host == '' ? false : true;

    if (validURL) {
      image = Image.network(filename, fit: BoxFit.cover);
    } else if (File(filename).existsSync()) {

      img.Image? sourceImage =
          img.decodeImage(File(filename).readAsBytesSync());
      if (sourceImage != null) {
        double heightScale=1.0;
        double widthScale=1.0;
        double historicaPhotoScale=widget.historicalPhotoScale!/heightScale;

        if (needsHeightScaling(sourceImage.width, sourceImage.height)) {
          print("needsHeightScale");

          double scale=sourceImage.width / widget.historicalPhotoSize!.width;
          heightScale=(widget.historicalPhotoSize!.height*scale) / sourceImage.height;

          double aspectratio=widget.historicalPhotoSize!.height/widget.historicalPhotoSize!.width;
          if (aspectratio>1) {
            historicaPhotoScale=historicaPhotoScale/aspectratio;
          }
        }
        else
        {
          print("needsWidthScale");

          double scale=sourceImage.height / widget.historicalPhotoSize!.height;
          widthScale=(widget.historicalPhotoSize!.width*scale) / sourceImage.width;

          double aspectratio=widget.historicalPhotoSize!.width/widget.historicalPhotoSize!.height;
          if (aspectratio>1) {
            historicaPhotoScale=historicaPhotoScale/aspectratio;
          }
        }

        int scaledImageWidth = (sourceImage.width*widthScale*historicaPhotoScale).toInt();
        int scaledImageHeight = (sourceImage.height*heightScale*historicaPhotoScale).toInt();

        int left = ((sourceImage.width - scaledImageWidth) / 2).toInt();
        int top = ((sourceImage.height - scaledImageHeight) / 2).toInt();

        img.Image croppedImage =
            img.copyCrop(sourceImage, left, top, scaledImageWidth, scaledImageHeight);

        String croppedFilename=filename.replaceFirst(".jpg", ".cropped.jpg");
        File(croppedFilename).writeAsBytesSync(img.encodePng(croppedImage), flush:true);

        if (File(croppedFilename).existsSync()) {
          File croppedFileNew=File(croppedFilename);
          return Image.file(croppedFileNew);
        }
        else {
          // so, why is this really here now?
          Image.network(wikiExample);
        }
      }
    }

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
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: getImage4( widget.imagePath, context))))
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
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: getImage4( widget.imagePath, context))))
      ],
    );
  }
}
