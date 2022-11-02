import 'dart:io';
import 'package:ajapaik_flutter_app/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:ajapaik_flutter_app/localization.dart';
import 'package:ajapaik_flutter_app/rephotocompareview.dart';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:ajapaik_flutter_app/upload.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera.dart';
import 'data/draft.json.dart';
import 'data/album.geojson.dart';
import 'services/crossplatformshare.dart';
import 'geomap.dart';
import 'fullscreenimageview.dart';
import 'sessioncontroller.dart';
import 'draftstorage.dart';
import 'httpcontroller.dart';
import 'preferences.dart';
import 'imagestorage.dart';

class Photoview extends StatefulWidget {
  final String historicalPhotoId;
  final String historicalPhotoUri;
  final String historicalName;
  final String historicalDate;
  final String historicalAuthor;
  final String historicalLabel;
  final String historicalSrcUrl;
  final int numberOfRephotos;

  final Geometry historicalCoordinates;

  const Photoview(
      {Key? key,
      required this.historicalPhotoId,
      required this.historicalPhotoUri,
      required this.historicalName,
      required this.historicalDate,
      required this.historicalAuthor,
      required this.historicalLabel,
      required this.historicalSrcUrl,
      required this.historicalCoordinates,
      required this.numberOfRephotos})
      : super(key: key);

  @override
  PhotoviewState createState() => PhotoviewState();
}

// TODO: check redoing menu
enum ImageMenu { menuShare, menuInfo, menuMap, menuSettings }

class PhotoviewState extends State<Photoview> {
  bool boolValue = true;
  bool mapInfoVisibility = false;
  bool newMapInfoValue = true;
  double imageLatitude = 0; // image being viewed, not the one just taken?
  double imageLongitude = 0;

  final locator = Get.find<AppLocator>();
  final prefs = Get.find<Preferences>();
  final sessionController = Get.find<SessionController>();
  final draftStorage = Get.find<DraftStorage>();
  final imageStorage = Get.find<ImageStorage>();
  //late Map map;

  String getDatasource() {
    String dataSourceUrl = sessionController.getDatasourceUri();
    dataSourceUrl += "/ajapaikimageinfo.php?id=";
    return dataSourceUrl;
  }

  LatLng getImagePosition() {
    return LatLng(imageLatitude, imageLongitude);
  }

  // only reason to have this is that setState()
  // which could be removed entirely?
  getTooltipPrefs() async {
    bool? prefsValue = prefs.getTooltipPrefs();
    if (prefsValue != prefs.tooltip) {
      setState(() {
        prefs.tooltip = prefsValue!;
      });
      return prefsValue;
    }
  }
  String generateDescription() {
    List<String> parts=[];
    if (widget.historicalName !="") parts.add(widget.historicalName);
    if (widget.historicalDate !="") parts.add(widget.historicalDate);
    if (widget.historicalAuthor !="") parts.add(widget.historicalAuthor);
    if (widget.historicalLabel !="") parts.add(widget.historicalLabel);
    if (widget.historicalSrcUrl !="") parts.add(widget.historicalSrcUrl);

    return parts.join("\n");
  }

  // opens camera mode, which shows preview before returning here
  void takeRephoto(context) {
    // this should be the place to check if there are permissions to use a camera
    // or if there are cameras at all..

    // try to update location now so we have something when photo is taken
    locator.updatePosition();

    availableCameras().then((availableCameras) async {

      // check that there is at least one
      if (availableCameras.isEmpty) {
        return;
      }
      CameraDescription firstCamera = availableCameras.first;
      var rephoto = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CameraScreen(
                    camera: firstCamera,
                    historicalPhotoId: widget.historicalPhotoId,
                    historicalPhotoUri: widget.historicalPhotoUri,
                    historicalPhotoDescription:  generateDescription()
                  )));

      // TODO: if user has no network connectivity or is in standalone mode
      // -> just keep draft and let user upload later

      // this is expected to return from DisplayPictureScreenState::onTakePhotoButton() ?
      // -> null if user backs off
      if (rephoto.runtimeType == Draft) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayUploadScreen(draft: rephoto)));
      }
    });
  }

  @override
  void initState() {
    if (widget.historicalCoordinates.hasCoordinates()) {
      imageLatitude = widget.historicalCoordinates.getLatitude();
      imageLongitude = widget.historicalCoordinates.getLongitude();
    }
    locator.init();

    mapInfoVisibility = false;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // TODO: if user presses share but system is slow user can change to other screen
  // and then will get into confusing situation when it finally responds
  // -> either make it clear UI is waiting or avoid opening after user has navigated
  // out of the view to avoid tricky situations later
  void onSelectedImageMenu(result) async {
    //ImageMenu.menuShare
    if (result == 0) {
      // disable sharing when using web-application?
      // build time constant kIsWeb == true ?

      CrossplatformShare.shareFile(widget.historicalPhotoUri, widget.historicalName );
      // TODO: when share the photo is already known
      // -> look it up in the DOM or whatever without asking server for it again..
    }
    //ImageMenu.menuInfo
    if (result == 1) {
      launchInfoUrl();
    }
    //ImageMenu.menuMap
    if (result == 2) {
      openImageMapScreen();
    }
  }

  // this makes the top-right corner dropdown menu and related actions to it
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          actions: [
            PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (result) async {
                  onSelectedImageMenu(result);
                },
                itemBuilder: (context) => [
                      // disable sharing when using web-application?
                      // build time constant kIsWeb == true ?
                      PopupMenuItem(
                          value: 0, // ImageMenu.menuShare
                          child: ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu1')))),
                      PopupMenuItem(
                          value: 1, // ImageMenu.menuInfo
                          child: ListTile(
                              leading: const Icon(Icons.info),
                              title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu2')))),
                      PopupMenuItem(
                          value: 2, //ImageMenu.menuMap
                          child: ListTile(
                            leading: const Icon(Icons.map),
                            title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu4')),
                          )),
                    ])
          ]),
      body: Column(children: [
        Flexible(child: getImageComparison(context)),
      ]),
    );
  }

  Widget getImageComparison(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return verticalPreview(context);
      } else {
        return horizontalPreview(context);
      }
    });
  }

  // build map for embedding in to view
  /*
  GeoMap buildMap() {
    GeoMap map = GeoMap(
        imageLatitude: imageLatitude,
        imageLongitude: imageLongitude,
        historicalPhotoUri: widget.historicalPhotoUri);
    return map;
  }
  */

  // open map from top-right dropdown while looking at single image:
  // app view is changed to a map instead of showing photo + map
  openImageMapScreen() async {
    locator.updatePosition();
    return await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GeoMap(
                  imageLatitude: imageLatitude,
                  imageLongitude: imageLongitude,
                  historicalPhotoUri: widget.historicalPhotoUri,
                )));
  }

  String getDistanceToImage() {
    String distanceToImage = '';

    LatLng pos = locator.getLatLong();
    if (imageLatitude != 0 &&
        imageLongitude != 0 &&
        pos.latitude != 0 &&
        pos.longitude != 0) {
      double distance = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, imageLatitude, imageLongitude);

      if (distance >= 1000) {
        double calcDistance = distance / 1000;
        distanceToImage = calcDistance.toStringAsFixed(2);
        distanceToImage += ' Km';
      } else {
        distanceToImage = distance.toStringAsFixed(2);
        distanceToImage += ' M';
      }
    }

    return distanceToImage;
  }

  Widget getRephotoNumberIconBottomLeft(numberOfRephotos) {
    IconData numberOfRephotosIcon=getNumberOfRephotosIcon(numberOfRephotos);

    return Visibility(
        visible: numberOfRephotos > 0,
        child: Positioned(
            right: 5.0,
            bottom: 10.0,
            child: IconButton(
                icon: new Icon(numberOfRephotosIcon),
                onPressed: () async {
                  List<Album> _rephotoAlbumData = await onFetchAlbum();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              RephotoCompareView(album: _rephotoAlbumData)));
                })));
  }
  onFetchAlbum() async {
    String url = getDatasource();
    url += widget.historicalPhotoId.toString();

    url = addLocationToUrl(url, locator.getLatLong());
    //print("fetchAlbum location: $position.toString()");

    // TODO: check if there are permissions to use network and/or session is active
    // can this be activated if there isn't connection?
    return fetchAlbum(url);
  }

  Widget verticalPreview(BuildContext context) {
    String distanceToImage = getDistanceToImage();

    return Column(children: [
      ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 350,
          ),
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullScreenImageView(
                              historicalPhotoUri: widget.historicalPhotoUri,
                            )));
              },
              child: Stack(children: [
                // another one that could use caching
                imageStorage.getImageBoxed(widget.historicalPhotoUri),
                getRephotoNumberIconBottomLeft(widget.numberOfRephotos)
              ]))),
      Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(distanceToImage),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: IconButton(
                  alignment: Alignment.center,
                  iconSize: 50,
                  onPressed: () {
                    takeRephoto(context);
                  },
                  icon: const Icon(Icons.camera)),
            ),
            IconButton(
                iconSize: 50,
                icon: mapInfoVisibility
                    ? const Icon(Icons.info_outline)
                    : const Icon(Icons.map),
                onPressed: () {
                  //saveMapInfoVisibility();
                  setState(() {
                    mapInfoVisibility = !mapInfoVisibility;
                  });
                }),
          ])),
      Visibility(
          visible: mapInfoVisibility == true,
          child: Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                      onDoubleTap: openImageMapScreen,
                      child: buildMarkedMap(context))))),
      Visibility(visible: mapInfoVisibility == false, child: buildInfoText()),
    ]);
  }

  Widget horizontalPreview(BuildContext context) {
    String distanceToImage = getDistanceToImage();

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullScreenImageView(
                              historicalPhotoUri: widget.historicalPhotoUri,
                            )));
              },
              child: Stack(children: [
                imageStorage.getCachedNetworkImage(widget.historicalPhotoUri),
                getRephotoNumberIconBottomLeft(widget.numberOfRephotos)
              ])),
        ),
        Visibility(
            visible: mapInfoVisibility == true,
            child: Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                        onDoubleTap: openImageMapScreen,
                        child: buildMarkedMap(context))))),
        Visibility(
            visible: mapInfoVisibility == false, child: buildInfoText()),
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
            left: 30,
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(distanceToImage),
                IconButton(
                    alignment: Alignment.center,
                    iconSize: 50,
                    onPressed: () {
                      takeRephoto(context);
                    },
                    icon: const Icon(Icons.camera)),
                IconButton(
                    iconSize: 50,
                    icon: mapInfoVisibility
                        ? const Icon(Icons.info_outline)
                        : const Icon(Icons.map),
                    onPressed: () {
                      //saveMapInfoVisibility();
                      setState(() {
                        mapInfoVisibility = !mapInfoVisibility;
                      });
                    }),
              ]),
        )
      ],
    );
  }

  Widget buildInfoText() {
    return Expanded(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.historicalAuthor + ', ' + widget.historicalDate,
                  maxLines: 9,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.historicalName,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: widget.historicalLabel,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          launchInfoUrl();
                        }),
                ),
              ])),
    );
  }

  void launchInfoUrl() async {
    Uri url = Uri.parse(widget.historicalSrcUrl);
    bool isLaunchable = await canLaunchUrl(url);
    if (isLaunchable) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $widget.historicalSurl';
    }
  }

  // because we show markers with the map lets call it marked map, not "toolkitmap"
  // TODO: compare with the one in geomap.dart, duplication?
  // this is for some reason different from when opening from dropdown menu?
  // this shows map embedded in the photo view, but map contents should be same
  // regardless how the view is showing it..
  // -> unify, map contents should be same either way..
  Widget buildMarkedMap(BuildContext context) {
    locator.updatePosition();
    return GeoMapState.buildMarkedMap(locator, getImagePosition());
  }
}
