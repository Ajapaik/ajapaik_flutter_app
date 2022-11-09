import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart'; // constants like kIsWeb
import 'package:image/image.dart' as img;
import 'package:cross_file/cross_file.dart';

import 'services/geolocation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'data/draft.json.dart';
import 'draftstorage.dart';
import 'imagestorage.dart';

// A widget that displays the picture taken by the user.
// Preview and compare taken picture (after taken with camera which has continuously updating view),
// then save final result if suitable.

// ignore: must_be_immutable
class PreviewScreen extends StatefulWidget {
  final XFile imageFile;
  final String imagePath;
  final String historicalImagePath;
  final Draft draft;
  final Orientation? cameraPhotoOrientation;
  final bool? historicalPhotoRotation;
  final bool? historicalPhotoFlipped;
  final Size? historicalPhotoSize;
  final double? historicalPhotoScale;
  img.Image? croppedImage;

  PreviewScreen(
      {Key? key,
      required this.imageFile,
      required this.imagePath,
      required this.historicalImagePath,
      required this.draft,
      this.cameraPhotoOrientation,
      this.historicalPhotoRotation,
      this.historicalPhotoFlipped,
      this.historicalPhotoSize,
      this.historicalPhotoScale})
      : super(key: key);

  @override
  PreviewScreenState createState() => PreviewScreenState();
}

class PreviewScreenState extends State<PreviewScreen>
    with TickerProviderStateMixin {
  final locator = Get.find<AppLocator>();
  final draftStorage = Get.find<DraftStorage>();
  final imageStorage = Get.find<ImageStorage>();
  GlobalKey cameraPhotoKey = GlobalKey();
  double oldCenterX = 0;
  double oldCenterY = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onSavePhotoFromPreview();
                    },
                    child: const Icon(Icons.check),
                  )),

              // Go two steps backward so the rephoto camera will be closed:
              // this returns to PhotoviewState::takeRephoto() ?
              CloseButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, false);
                },
              )
            ]));
  }

  // when pressing to actually save the taken photo:
  // (confirmation after preview).
  // actual photo must be already taken in TakePictureScreenState::onTakePicture().
  //
  // all of the information must be passed from Camera to here already so..
  void onSavePhotoFromPreview() async {
    //final image = imageStorage.getCurrent();

    // not available in web-version
    if (kIsWeb == false) {
      await GallerySaver.saveImage(widget.imageFile.path);
      widget.draft.isInGallery = true; // saved to gallery -> keep track of (accepted image)
    }

    // location may be disallowed but save photo still
    await locator.updatePosition();
    LatLng pos = locator.getLatLong();

    widget.draft.latitude = pos.latitude;
    widget.draft.longitude = pos.longitude;
    widget.draft.accuracy = -1;

    // async gap
    if (!mounted) return;

    // Close preview and cameraview by going two steps back
    // So this returns to PhotoviewState::takeRephoto() ?
    Navigator.pop(context);
    Navigator.pop(context, widget.draft);
  }

  Widget getImageComparison(BuildContext context) {
    Widget oldImage = imageStorage.getImageBoxed(widget.historicalImagePath);
    Widget flippedImage =
    getFlippedImage(oldImage, widget.historicalPhotoFlipped == true);
    Widget newImage = getScaledImageBuilder(widget.imageFile, flippedImage, context);

    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return getVerticalImageComparison(context, newImage, flippedImage);
      } else {
        return getHorizontalImageComparison(context, newImage, flippedImage);
      }
    });
  }
  /*
  Widget getImageComparison(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return getVerticalImageComparison(context);
      } else {
        return getHorizontalImageComparison(context);
      }
    });
  }
   */

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
  // this is called when creating image comparison after taking a picture with camera
  //
  /*
  Widget getScaledImage(String filename, context) {
    if (Uri.parse(filename).host.isNotEmpty) {
      return Image.network(filename, fit: BoxFit.cover);
    }

    // is there a situation where the file might not exist when coming here?
    File imageFile = File(filename);
    if (imageFile.existsSync()) {
      // is there a real chance that decoding fails here?
      img.Image? sourceImage = img.decodeImage(imageFile.readAsBytesSync());
      if (sourceImage != null) {
        double heightScale = 1.0;
        double widthScale = 1.0;
        double historicaPhotoScale = widget.historicalPhotoScale! / heightScale;

        if (needsHeightScaling(sourceImage.width, sourceImage.height)) {
          double scale = sourceImage.width / widget.historicalPhotoSize!.width;
          heightScale =
              (widget.historicalPhotoSize!.height * scale) / sourceImage.height;

          double aspectratio = widget.historicalPhotoSize!.height /
              widget.historicalPhotoSize!.width;
          if (aspectratio > 1) {
            historicaPhotoScale = historicaPhotoScale / aspectratio;
          }
        } else {
          double scale = sourceImage.height / widget.historicalPhotoSize!.height;
          widthScale =  (widget.historicalPhotoSize!.width * scale) / sourceImage.width;

          double aspectratio = widget.historicalPhotoSize!.width /
              widget.historicalPhotoSize!.height;
          if (aspectratio > 1) {
            historicaPhotoScale = historicaPhotoScale / aspectratio;
          }
        }

        int scaledImageWidth =
            (sourceImage.width * widthScale * historicaPhotoScale).toInt();
        int scaledImageHeight =
            (sourceImage.height * heightScale * historicaPhotoScale).toInt();

        int left = ((sourceImage.width - scaledImageWidth) / 2).toInt();
        int top = ((sourceImage.height - scaledImageHeight) / 2).toInt();

        img.Image croppedImage = img.copyCrop(
            sourceImage, left, top, scaledImageWidth, scaledImageHeight);

        // try to look whatever ending is used (if camera takes avif, jpeg or png, account for naming)
        // and save cropped image under new name
        String croppedFilename =
            filename.substring(0, filename.lastIndexOf('.'));
        croppedFilename += ".cropped.png";
        File croppedFile = File(croppedFilename);

        // throws exception if writing fails so checks after this should be pointless?
        croppedFile.writeAsBytesSync(img.encodePng(croppedImage), flush: true);

        // it was just written, is there a case where it might not exist? out of space?
        if (croppedFile.existsSync()) {
          return Image.file(croppedFile);
        }
      }
    }

    // old used network access to file:
    // "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg";
    // instead, keep it with app:
    File examplefile = File("assets/Example.jpg");
    return Image.file(examplefile);
  }
    */

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
  Widget getFlippedImage(Widget image, bool flipped) {
    return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(flipped ? math.pi : 0),
        child: image);
  }
  double getRotationY() {
    return widget.historicalPhotoFlipped == true ? math.pi : 0;
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
  /*
  Widget getHorizontalImageComparison(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(getRotationY()),
                child:
                imageStorage.getImageBoxed(widget.historicalImagePath))),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: getScaledImage(widget.imagePath, context))))
      ],
    );
  }

   */

  /*
  Widget getVerticalImageComparison(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(getRotationY()),
                child:
                imageStorage.getImageBoxed(widget.historicalImagePath))),
        Expanded(
            child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
//                      color: Colors.pink[600]!,
                      width: 0,
                    )),
                    child: getScaledImage(widget.imagePath, context))))
      ],
    );
  }
  */
}
