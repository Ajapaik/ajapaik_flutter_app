import 'dart:io';
import 'package:ajapaik_flutter_app/localization.dart';
import 'package:ajapaik_flutter_app/rephotocompareview.dart';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:ajapaik_flutter_app/settings.dart';
import 'package:ajapaik_flutter_app/upload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'camera.dart';
import 'data/draft.json.dart';
import 'data/album.geojson.dart';
import 'map.dart';
import 'fullscreenimageview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'draftstorage.dart';

class Photoview extends StatefulWidget {
  final String historicalPhotoId;
  final String historicalPhotoUri;
  final String historicalName;
  final String historicalDate;
  final String historicalAuthor;
  final String historicalLabel;
  final String historicalSurl;
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
      required this.historicalSurl,
      required this.historicalCoordinates,
      required this.numberOfRephotos})
      : super(key: key);

  @override
  PhotoviewState createState() => PhotoviewState();
}

class PhotoviewState extends State<Photoview> {
  bool boolValue = true;
  bool mapInfoVisibility = false;
  bool newMapInfoValue = true;
  double imageLatitude = 0; // image being viewed, not the one just taken?
  double imageLongitude = 0;
  String dataSourceUrl = "https://ajapaik.toolforge.org/api/ajapaikimageinfo.php?id=";

  // TODO: keep shared
  DraftStorage draftStorage = DraftStorage();

  final locator = Get.put(AppLocator());

  getTooltipPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var prefsValue = prefs.getBool("tooltip");
    if (prefsValue != tooltip) {
      setState(() {
        tooltip = prefsValue!;
      });
      return prefsValue;
    }
  }

  /* there is no point to this:
  only place the stored value is retrieved is when initializing
  right after resetting and saving it first
  -> just remove it

  saveMapInfoVisibility() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('MapInfoVisibility', mapInfoVisibility);
  }

  void getMapInfoVisibility() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    mapInfoVisibility = prefs.getBool("MapInfoVisibility")!;
    setState(() {});
  }
  */

  void takeRephoto(context) {
    availableCameras().then((availableCameras) async {
      CameraDescription firstCamera = availableCameras.first;
      var rephoto = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TakePictureScreen(
                    camera: firstCamera,
                    historicalPhotoId: widget.historicalPhotoId,
                    historicalPhotoUri: widget.historicalPhotoUri,
                  )));
      // TODO: if user has no network connectivity or is in standalone mode
      // -> just keep draft and let user upload later
      //draftStorage.
      if (rephoto.runtimeType == Draft) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayUploadScreen(draft: rephoto)));
      }
    });
  }

  void launchInfo() async {
    Uri url = Uri.parse(widget.historicalSurl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $widget.historicalSurl';
    }
  }

  @override
  void initState() {
    if (widget.historicalCoordinates.coordinates.isNotEmpty) {
      imageLatitude = widget.historicalCoordinates.coordinates[0];
      imageLongitude = widget.historicalCoordinates.coordinates[1];
    }
    locator.init();

    // this same thing is first set, saved and then retrieved again?
    // -> just remove storing since this is only place where it is retrieved
    // .. right after resetting it..
    mapInfoVisibility = false;
    //saveMapInfoVisibility();
    //getMapInfoVisibility();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          /* title: Text(
              AppLocalizations.of(context)!.translate('rePhoto-appbarTitle'),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              )),*/
          actions: [
            PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (result) async {
                  if (result == 0) {
                    final url = Uri.parse(widget.historicalPhotoUri);
                    final response = await http.get(url);

                    final temp = await getTemporaryDirectory();
                    final path = '${temp.path}/image.jpg';
                    File(path).writeAsBytesSync(response.bodyBytes);

                    await Share.shareFiles([path], text: widget.historicalName);
                    void _main() {
                      final dir = Directory(path);
                      dir.deleteSync(recursive: true);
                    }

                    _main();
                  }
                  if (result == 1) {
                    launchInfo();
                  }
                  if (result == 3) {
                    openImageMapScreen();
                  }
                  if (result == 4) {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()))
                        .then((_) {
                      setState(() {
                        getTooltipPrefs();
                      });
                    });
                  }
                },
                itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 0,
                          child: ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu1')))),
                      PopupMenuItem(
                          value: 1,
                          child: ListTile(
                              leading: const Icon(Icons.info),
                              title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu2')))),
                      /*        PopupMenuItem(
                        value: 2,
                        child: ListTile(
                          leading: const Icon(Icons.enhance_photo_translate),
                          title: Text(AppLocalizations.of(context)!
                              .translate('rePhoto-popupMenu3')),
                        ),
                      ),*/
                      PopupMenuItem(
                          value: 3,
                          child: ListTile(
                            leading: const Icon(Icons.map),
                            title: Text(AppLocalizations.getText(context, 'rePhoto-popupMenu4')),
                          )),
                      /*       PopupMenuItem(
                          value: 4,
                          child: ListTile(
                            leading: const Icon(Icons.settings),
                            title: Text(AppLocalizations.of(context)!
                                .translate('rePhoto-popupMenu5')),
                          )),*/
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

  void openImageMapScreen() async {
    print(imageLatitude);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Map(
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
      double calcDistance = distance / 1000;

      if (distance >= 1000) {
        distanceToImage = calcDistance.toStringAsFixed(2) + ' Km';
      } else {
        distanceToImage = distance.toStringAsFixed(2) + ' M';
      }
    }

    return distanceToImage;
  }

  Widget getRephotoNumberIconBottomLeft(numberOfRephotos) {
    IconData numberOfRephotosIcon;

    switch (numberOfRephotos) {
      case 1:
        numberOfRephotosIcon = Icons.filter_1;
        break;
      case 2:
        numberOfRephotosIcon = Icons.filter_2;
        break;
      case 3:
        numberOfRephotosIcon = Icons.filter_3;
        break;
      case 4:
        numberOfRephotosIcon = Icons.filter_4;
        break;
      case 5:
        numberOfRephotosIcon = Icons.filter_5;
        break;
      case 6:
        numberOfRephotosIcon = Icons.filter_6;
        break;
      case 7:
        numberOfRephotosIcon = Icons.filter_7;
        break;
      case 8:
        numberOfRephotosIcon = Icons.filter_8;
        break;
      case 9:
        numberOfRephotosIcon = Icons.filter_9;
        break;
      default:
        numberOfRephotosIcon = Icons.filter_9_plus;
        break;
    }

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
    var url = dataSourceUrl +
            widget.historicalPhotoId.toString();

    url = addLocationToUrl(url, locator.getLatLong());
    //print("fetchAlbum location: $position.toString()");

    // TODO: check if there are permissions to use network and/or session is active
    // can this be activated if there isn't connection?
    return fetchAlbum(http.Client(), url);
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
                Image.network(widget.historicalPhotoUri, fit: BoxFit.contain),
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
                CachedNetworkImage(imageUrl: widget.historicalPhotoUri),
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
                          Uri url = Uri.parse(widget.historicalSurl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            throw 'Could not launch $widget.historicalSurl';
                          }
                        }),
                ),
              ])),
    );
  }

  // because we show markers with the map lets call it marked map, not "toolkitmap"
  // TODO: compare with the one in map.dart, duplication?
  Widget buildMarkedMap(BuildContext context) {
    return MapState.buildMarkedMap(context, locator.getLatLong(), LatLng(imageLatitude, imageLongitude));
  }
}
