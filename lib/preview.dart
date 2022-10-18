import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
  final XFile image;
  final String historicalImageDescription;
  final String historicalImagePath;
  final String historicalImageId;
  final Orientation? cameraPhotoOrientation;
  final bool? historicalPhotoRotation;
  final bool? historicalPhotoFlipped;
  final Size? historicalPhotoSize;
  final Size? cameraPhotoSize;
  final double? historicalPhotoScale;
  img.Image? croppedImage;

  DisplayPictureScreen(
      {Key? key,
      required this.image,
      required this.historicalImageDescription,
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

  //final TransformationController _transformationController = TransformationController();

  // TODO: keep shared
  DraftStorage draftStorage = DraftStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(title: Text('Display the Picture')),
        // The camera image is stored as a XFile (widget.image parameter).
        // The image is saved permanently to device when user clicks ok.
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

  void saveCroppedImage(String filename) {
    String croppedFilename = filename.replaceFirst(".jpg", ".cropped.jpg");
    img.Image? croppedImage = widget.croppedImage;

    if (croppedImage != null) {
      File(croppedFilename)
          .writeAsBytesSync(img.encodeJpg(croppedImage), flush: true);
      GallerySaver.saveImage(croppedFilename);
    }
  }

  void onTakePhotoButton() async {
    // FIXME: GallerySaver works only with iOS and Android
    if (!kIsWeb) {
      await GallerySaver.saveImage(widget.image.path.toString());
      saveCroppedImage(widget.image.path.toString());
    }
    DateTime now = DateTime.now();

    // location may be disallowed but save photo still
    await locator.updatePosition();
    LatLng pos = locator.getLatLong();

    Draft draft = Draft(
        "",
        widget.image.path,
        widget.historicalImageDescription,
        widget.historicalImagePath,
        widget.historicalImageId,
        widget.historicalPhotoFlipped! == true,
        now,
        widget.historicalPhotoScale ?? 1,
        pos.latitude,
        pos.longitude,
        -1,
        false);
    // keep for later if we can't upload right away
    draftStorage.store(draft);

    // async gap
    if (!mounted) return;

    // Close preview and cameraview by going two steps back
    Navigator.pop(context);
    Navigator.pop(context, draft);
  }

  Widget getImageComparison(BuildContext context) {
    Image oldImage = getImage(widget.historicalImagePath.toString(), context);
    Widget flippedImage =
        getFlippedImage(oldImage, widget.historicalPhotoFlipped == true);
    Widget newImage = getScaledImageBuilder(widget.image, flippedImage, context);

    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return getVerticalImageComparison(context, newImage, flippedImage);
      } else {
        return getHorizontalImageComparison(context, newImage, flippedImage);
      }
    });
  }

  Image getImage(String filename, BuildContext context, {double scale = 1}) {
    if (kIsWeb || Uri.parse(filename).host.isNotEmpty) {
      return Image.network(filename,
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    } else {
      return Image.file(File(widget.historicalImagePath),
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    }
  }

  bool needsHeightScaling(cameraImageWidth, cameraImageHeight) {
    double heightScale = cameraImageHeight / widget.historicalPhotoSize!.height;
    double widthScale = cameraImageWidth / widget.historicalPhotoSize!.width;
    return widthScale < heightScale;
  }

  // Returns scaled and cropped camera image
  // FIXME: placeholder image is for having some element for reserving space in
  // web platform so it stays intact. Looks like web platform bug and not ours.

  Widget getScaledImageBuilder(
      XFile image, Widget placeholder, BuildContext context) {
    double refScale = widget.historicalPhotoScale!;
    double refWidth = widget.historicalPhotoSize!.width;
    double refHeight = widget.historicalPhotoSize!.height;

    return FutureBuilder<Image>(
      future: getScaledImageFromXFile(image, refScale, refWidth, refHeight),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder;
        }
        if (snapshot.hasError) (snapshot.error);

        if (snapshot.hasData) {
          Image? scaledImage = snapshot.data;
          if (scaledImage != null) {
            return scaledImage;
          } else {
            return Text("VIRHE");
          }
        } else {
          print("Snapshot loading");
          return placeholder;
        }
        //              : const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<Image> getScaledImageFromXFile(
      XFile image, double refScale, double refWidth, double refHeight) async {
    // is there a real chance that decoding fails here?
    List<int> imageBytes = await image.readAsBytes();
    img.Image? cameraImage = img.decodeImage(imageBytes);
    if (cameraImage != null) {
      double heightScale = 1.0;
      double widthScale = 1.0;
      double historicaPhotoScale = refScale / heightScale;

      if (needsHeightScaling(cameraImage.width, cameraImage.height)) {
        double scale = cameraImage.width / refWidth;
        heightScale = (refHeight * scale) / cameraImage.height;

        double aspectratio = refHeight / refWidth;
        if (aspectratio > 1) {
          historicaPhotoScale = historicaPhotoScale / aspectratio;
        }
      } else {
        double scale = cameraImage.height / refHeight;
        widthScale = (refWidth * scale) / cameraImage.width;

        double aspectratio = refWidth / refHeight;
        if (aspectratio > 1) {
          historicaPhotoScale = historicaPhotoScale / aspectratio;
        }
      }

      int scaledImageWidth =
          (cameraImage.width * widthScale * historicaPhotoScale).toInt();
      int scaledImageHeight =
          (cameraImage.height * heightScale * historicaPhotoScale).toInt();

      int left = ((cameraImage.width - scaledImageWidth) / 2).toInt();
      int top = ((cameraImage.height - scaledImageHeight) / 2).toInt();

      img.Image croppedImage = img.copyCrop(
          cameraImage, left, top, scaledImageWidth, scaledImageHeight);

      // save scaled version to memory for saving to disk later
      widget.croppedImage = croppedImage;
      return Image.memory(Uint8List.fromList(img.encodeJpg(croppedImage)));
    }

    // Failback to example file if there is no image:
    File examplefile = File("assets/Example.jpg");
    return Image.file(examplefile);
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

  // Mirror image flip
  Widget getFlippedImage(Image image, bool flipped) {
    return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(flipped ? math.pi : 0),
        child: image);
  }

  Widget getHorizontalImageComparison(
      BuildContext context, Widget newImage, Widget oldImage) {
    return Row(
      children: [
        Expanded(child: oldImage),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: newImage)))
      ],
    );
  }

  Widget getVerticalImageComparison(
      BuildContext context, Widget newImage, Widget oldImage) {
    return Column(
      children: [
        Expanded(child: oldImage),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: newImage)))
      ],
    );
  }
}
