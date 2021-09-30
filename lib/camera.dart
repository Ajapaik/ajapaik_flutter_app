// A screen that allows users to take a picture using a given camera.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ajapaik_flutter_app/preview.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String historicalPhotoUri;
  final String historicalPhotoId;

  const TakePictureScreen({
    Key? key,
    required this.camera,
    required this.historicalPhotoId,
    required this.historicalPhotoUri,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  // Camera
  late CameraController _cameraController;
  Future<void>? _initializeCameraControllerFuture;

  // Orientation tracking value
  Orientation? lastKnownOrientation;

  // Interactive viewer overlay
  TransformationController historicalPhotoController =
      TransformationController();
  GlobalKey historicalPhotoKey = GlobalKey();
  bool historicalPhotoFlipped = false;
  double historicalPhotoTransparency = 0.65;
  bool pinchToZoomBusy = false;
  late Size historicalPhotoImageSize;

  /* TAKE PHOTO */
  void onTakePicture() async {
    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Ensure that the camera is initialized.
      await _initializeCameraControllerFuture;
      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await _cameraController.takePicture();

      final context = historicalPhotoKey.currentContext!;
      // If the picture was taken, display it on a new screen.
      (historicalPhotoController.value.getMaxScaleOnAxis());
      (historicalPhotoImageSize);
      (MediaQuery.of(context).size);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
              // Pass the automatically generated path to
              // the DisplayPictureScreen widget.
              imagePath: image.path.toString(),
              historicalImagePath: widget.historicalPhotoUri,
              historicalImageId: widget.historicalPhotoId,
              cameraPhotoOrientation: lastKnownOrientation,
              historicalPhotoRotation: false,
              historicalPhotoFlipped: historicalPhotoFlipped,
              historicalPhotoSize: historicalPhotoImageSize,
              historicalPhotoScale:
                  historicalPhotoController.value.getMaxScaleOnAxis()),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      (e);
    }
  }

  // Center the historicalPhoto to the center of the screen
  void movehistoricalPhotoToCenter() {
    // get historicalPhoto's context
    final context = historicalPhotoKey.currentContext!;

    // Get size of the image layer. Positioning is correct only for fullscreen images
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    (w.toString() + " " + h.toString());

    // Calculate correct X,Y position in the screen
    // https://medium.com/flutter-community/advanced-flutter-matrix4-and-perspective-transformations-a79404a0d828

    final Matrix4 translationMatrix = historicalPhotoController.value;
    final currentScaleValue =
        historicalPhotoController.value.getMaxScaleOnAxis();
    final double centerX = (w - w * currentScaleValue) / 2;
    final double centerY = (h - h * currentScaleValue) / 2;
    translationMatrix.setTranslationRaw(centerX, centerY, 0.0);

    // Move the oldImage
    historicalPhotoController.value = translationMatrix;
  }

  // Force-sync the camera orientation to the device orientation
  Future<void> setCameraOrientation(orientation) async {
    await _initializeCameraControllerFuture;
    if (orientation == Orientation.portrait) {
      _cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } else {
      _cameraController
          .lockCaptureOrientation(DeviceOrientation.landscapeRight);
    }
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

  Image getImage(String filename) {
    Image image;
    //"https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Grundsteinlegung_MiQua-7004_%28cropped%29.jpg/690px-Grundsteinlegung_MiQua-7004_%28cropped%29.jpg",
    //                          "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Katarina_Taikon_1953.jpg/596px-Katarina_Taikon_1953.jpg",

    if (File(filename).existsSync()) {
      image = Image.file(
        File(filename),
        color: Color.fromRGBO(255, 255, 255, historicalPhotoTransparency),
        colorBlendMode: BlendMode.modulate,
        height: 8000,
        width: 8000,
      );
    } else {
      image = Image.network(
        filename,
        color: Color.fromRGBO(255, 255, 255, historicalPhotoTransparency),
        colorBlendMode: BlendMode.modulate,
        height: 8000,
        width: 8000,
      );
    }

    getImageInfo(image).then((info) => {
          historicalPhotoImageSize =
              Size(info.height.toDouble(), info.width.toDouble())
        });
    return image;
  }

  /* Update screen elements on orientation change */
  void onOrientationChange(context, currentDeviceOrientation) {
    // Rendering widget first time
    if (lastKnownOrientation == null) {
      lastKnownOrientation = MediaQuery.of(context).orientation;
      setCameraOrientation(lastKnownOrientation);
    }

    // re-rendering widget. Fix historicalPhoto position after orientation change
    else if (lastKnownOrientation != currentDeviceOrientation) {
      lastKnownOrientation = currentDeviceOrientation;
      setCameraOrientation(currentDeviceOrientation);
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        // Re-render the page with new orientation
        setState(() {
          movehistoricalPhotoToCenter();
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        widget.camera,

        // Define the resolution to use.
        ResolutionPreset.max,

        // Do not ask permission for the audio
        enableAudio: false);
    // Next, initialize the controller. This returns a Future.
    _initializeCameraControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
//      Future.delayed(Duration(milliseconds: 1500), () => fixposition(context) );

    return Scaffold(
        //   appBar: AppBar(title: Text('Take a picture')),
        // Wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner
        // until the controller has finished initializing.
//      body:
        body: OrientationBuilder(builder: (context, orientation) {
      onOrientationChange(context, orientation);

      return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Center(

                // Red borders for debugging
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: Colors.pink[800]!,
                      width: 1,
                    )), //             <--- BoxDecoration here

                    // Camera preview window
                    child: FutureBuilder<void>(
                      future: _initializeCameraControllerFuture,
                      builder: (context, snapshot) {
                        /* Initialize camera */
                        if (snapshot.connectionState == ConnectionState.done) {
                          // If the Future is complete, display the preview.
                          return CameraPreview(_cameraController);
                        } else {
                          // Otherwise, display a loading indicator.
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    ))),

            // Old image
            Center(
                // Red borders for debugging
                child: Container(
                    key: historicalPhotoKey,
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: Colors.red[800]!,
                      width: 1,
                    )), //             <--- BoxDecoration here

                    // Actual pinch-to-zoom image
                    child: InteractiveViewer(
                        panEnabled: false,
                        maxScale: 2,
                        minScale: 0.3,
                        transformationController: historicalPhotoController,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
//                        clipBehavior: Clip.none,

                        onInteractionUpdate: (details) {
                          //print("onInteractionUpdate:" + details.toString());
                          if (details.scale != 1) {
                            pinchToZoomBusy = true;
                          }
                          movehistoricalPhotoToCenter();
                        },
                        onInteractionStart: (details) {
                          // pinchToZoomBusy=true;
                        },
                        onInteractionEnd: (details) {
                          pinchToZoomBusy = false;
                        },
                        child: Listener(
                            onPointerMove: (details) {
                              //print("onPointerMove: " + pinchToZoomBusy.toString());
                              //double diffX=details.localDelta.dx;

                              if (pinchToZoomBusy == false) {
                                setState(() {
                                  if (details.delta.dy > 1) {
                                    historicalPhotoTransparency =
                                        historicalPhotoTransparency + 0.01;
                                    if (historicalPhotoTransparency > 1) {
                                      historicalPhotoTransparency = 1;
                                    }
                                  } else if (details.delta.dy < -1) {
                                    historicalPhotoTransparency =
                                        historicalPhotoTransparency - 0.01;
                                    if (historicalPhotoTransparency < 0) {
                                      historicalPhotoTransparency = 0;
                                    }
                                  }
                                });
                              }
                            },
                            child: Transform.rotate(
                                angle: 0, // 90 degree angle in radians
                                child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(
                                        historicalPhotoFlipped == true
                                            ? math.pi
                                            : 0),
                                    child: getImage(
                                        widget.historicalPhotoUri))))))),
            // Take photo button
            Positioned.fill(
                child: Align(
                    alignment: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: const CircleBorder(),
                        ),
                        margin: const EdgeInsets.all(10),
                        child: ElevatedButton(
                          child: const Icon(Icons.camera, size: 50),
                          style:
                              ElevatedButton.styleFrom(shape: const CircleBorder()),
                          onPressed: onTakePicture,
                        )))),

            // Move to previous view button
            Positioned.fill(
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        decoration: ShapeDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: const CircleBorder(),
                        ),
                        margin: const EdgeInsets.only(top: 32),
                        child: const BackButton()))),

            // Flip old photo button
            Positioned.fill(
                child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                        decoration: ShapeDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: const CircleBorder(),
                        ),
                        margin: const EdgeInsets.only(top: 32),
                        child: IconButton(
                            color: historicalPhotoFlipped
                                ? Colors.green
                                : Colors.white,
                            icon: const Icon(Icons.flip),
                            iconSize: 36.0,
                            onPressed: () {
                              setState(() {
                                historicalPhotoFlipped =
                                    !historicalPhotoFlipped;
                              });
                            })))),
          ]);
    }));
  }
}
