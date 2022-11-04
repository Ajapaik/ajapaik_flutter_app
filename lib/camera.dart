// A screen that allows users to take a picture using a given camera.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ajapaik_flutter_app/preview.dart';
import 'data/draft.json.dart';
import 'draftstorage.dart';
import 'imagestorage.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String historicalPhotoUri;
  final String historicalPhotoId;
  final String historicalPhotoDescription;

  const CameraScreen({
    Key? key,
    required this.camera,
    required this.historicalPhotoId,
    required this.historicalPhotoUri,
    required this.historicalPhotoDescription,
  }) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  // Camera
  late CameraController cameraController;
  Future<void>? initializeCameraControllerFuture;

  // Orientation tracking value
  Orientation? lastKnownOrientation;

  // Interactive viewer overlay
  TransformationController historicalPhotoController = TransformationController();
  GlobalKey historicalPhotoKey = GlobalKey();
  bool historicalPhotoFlipped = false;
  double historicalPhotoTransparency = 0.65;
  int transparencyOnOff=1;
  bool pinchToZoomBusy = false;
  late Size historicalPhotoImageSize;

  final draftStorage = Get.find<DraftStorage>();
  final imageStorage = Get.find<ImageStorage>();

  /* TAKE PHOTO */
  void onTakePicture() async {
    // camera handling can take exception for a number of reasons:
    // a) no permissions b) no camera on the device c) any other reason..
    // -> maybe should informat the user somehow as well?
    try {
      // Ensure that the camera is initialized.
      await initializeCameraControllerFuture;
      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await cameraController.takePicture();

      // keep track of current photo
      imageStorage.putCurrent(image);

      // keep for later if we can't upload right away
      Draft draft = makeDraft(image.path);
      draftStorage.store(draft);

      final context = historicalPhotoKey.currentContext!;

      // TODO: following uses historicalPhotoImageSize
      // but it isn't updated here (updateImageInfo() isn't called before)
      // -> either set it to something or don't use
      // ->

      MaterialPageRoute mpr = MaterialPageRoute(
        builder: (context) => PreviewScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
            imagePath: image.path,
            historicalImagePath: widget.historicalPhotoUri,
            cameraPhotoOrientation: lastKnownOrientation,
            historicalPhotoRotation: false,
            historicalPhotoFlipped: historicalPhotoFlipped,
            historicalPhotoSize: historicalPhotoImageSize,
            historicalPhotoScale:
            historicalPhotoController.value.getMaxScaleOnAxis()
        ));

      // suggestion: use in gap with async action
      if (!mounted) return;

      Navigator.push(context, mpr);
    } catch (e) {
      // If an error occurs, log the error to the console.
      (e);
    }
  }

  Draft makeDraft(String imagepath) {
    Draft draft = Draft(
        imagepath,
        widget.historicalPhotoDescription,
        widget.historicalPhotoUri,
        widget.historicalPhotoId,
        historicalPhotoFlipped,
        false, // rotation
        lastKnownOrientation == Orientation.portrait, // true: portrait, false: landscape
        DateTime.now(),
        historicalPhotoController.value.getMaxScaleOnAxis(),
        0, // position added later
        0, // position added later
        -1, // accuracy of position
        false // is new picture flipped?
    );
    return draft;
  }

  // Center the historicalPhoto to the center of the screen
  void movehistoricalPhotoToCenter() {
    // get historicalPhoto's context
    final context = historicalPhotoKey.currentContext!;

    // Get size of the image layer. Positioning is correct only for fullscreen images
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    // Calculate correct X,Y position in the screen
    // https://medium.com/flutter-community/advanced-flutter-matrix4-and-perspective-transformations-a79404a0d828

    final Matrix4 translationMatrix = historicalPhotoController.value;
    final currentScaleValue = translationMatrix.getMaxScaleOnAxis();
    final double centerX = (w - w * currentScaleValue) / 2;
    final double centerY = (h - h * currentScaleValue) / 2;
    translationMatrix.setTranslationRaw(centerX, centerY, 0.0);

    // Move the oldImage
    historicalPhotoController.value = translationMatrix;
  }

  // Force-sync the camera orientation to the device orientation
  Future<void> setCameraOrientation(orientation) async {
    await initializeCameraControllerFuture;
    if (orientation == Orientation.portrait) {
      cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } else {
      cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
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

    File imageFile = File(filename);
    if (kIsWeb==false && imageFile.existsSync()) {
      image = Image.file(
        imageFile,
        color: Color.fromRGBO(255, 255, 255, historicalPhotoTransparency*transparencyOnOff),
        colorBlendMode: BlendMode.modulate,
        height: 8000,
        width: 8000,
      );
    } else {
      image = Image.network(
        filename,
        color: Color.fromRGBO(255, 255, 255, historicalPhotoTransparency*transparencyOnOff),
        colorBlendMode: BlendMode.modulate,
        height: 8000,
        width: 8000,
      );
    }

    getImageInfo(image).then(updateImageInfo);
    return image;
  }

  void updateImageInfo(info) {
    historicalPhotoImageSize = Size(info.width.toDouble(), info.height.toDouble());
    double aspectratio = info.width / info.height;
    if (aspectratio > 1) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        widget.camera,

        // Define the resolution to use.
        ResolutionPreset.max,

        // Do not ask permission for the audio
        enableAudio: false);
    // Next, initialize the controller. This returns a Future.
    initializeCameraControllerFuture = cameraController.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    cameraController.dispose();

    SystemChrome.setPreferredOrientations([
      //  DeviceOrientation.landscapeRight,
      //  DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
      //  DeviceOrientation.portraitDown,
      ]);

    super.dispose();
  }

  void toggleTransparency() {
    setState(() {
       transparencyOnOff = transparencyOnOff == 1 ? 0 : 1;
    });
  }

  void onPointerMove(details) {
    //print("onPointerMove: " + pinchToZoomBusy.toString());
    //double diffX=details.localDelta.dx;
    if (pinchToZoomBusy == true) {
      return;
    }

    setState(() {
      if (details.delta.dy > 1) {
        historicalPhotoTransparency = historicalPhotoTransparency + 0.02;
        if (historicalPhotoTransparency > 1) {
          historicalPhotoTransparency = 1;
        }
      } else if (details.delta.dy < -1) {
        historicalPhotoTransparency = historicalPhotoTransparency - 0.02;
        if (historicalPhotoTransparency < 0) {
          historicalPhotoTransparency = 0;
        }
      }
    });
  }

  Widget buildCameraUi(BuildContext context) {
    return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Center(

            // Red borders for debugging
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
//                      color: Colors.pink[800]!,
                        width: 1,
                      )), //             <--- BoxDecoration here

                  // Camera preview window
                  child: FutureBuilder<void>(
                    future: initializeCameraControllerFuture,
                    builder: (context, snapshot) {
                      /* Initialize camera */
                      if (snapshot.connectionState == ConnectionState.done) {
                        // If the Future is complete, disable flash and  display the preview.
                        cameraController.setFlashMode(FlashMode.off);
                        return CameraPreview(cameraController);
                      } else {
                        // Otherwise, display a loading indicator.
                        return const Center(
                            child: CircularProgressIndicator());
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
//                      color: Colors.red[800]!,
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
                            onPointerMove(details);
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
          // TODO: should show as "greyed out" or similar when it isn't possible
          // (no permissions or no camera on device)
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
                        child: const Icon(Icons.camera, size: 85),
                        style: ElevatedButton.styleFrom(
                            shape: const CircleBorder()),
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
                              historicalPhotoFlipped = !historicalPhotoFlipped;
                            });
                          })))),
        ]);
  }

  // FIXME: Orientation builder makes browser as fullscreen in web platform.
  // as workaround we don't use it on web.
  Widget addOrientationBuilderIfNotWeb(BuildContext context) {
    if (kIsWeb) {
      return buildCameraUi(context);
    } else {
      return OrientationBuilder(builder: (context, orientation)
      {
        onOrientationChange(context, orientation);
        return buildCameraUi(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner
    // until the controller has finished initializing.

    Scaffold s = Scaffold(
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: toggleTransparency ,
        child: addOrientationBuilderIfNotWeb(context)));
    return s;
  }
}
