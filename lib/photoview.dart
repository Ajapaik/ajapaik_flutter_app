import 'dart:async';
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
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:get/get.dart';

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
  final locator = Get.put(AppLocator());

  _getTooltipValue() async {
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

  void _takeRephoto(context) {
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
      if (rephoto.runtimeType == Draft) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayUploadScreen(draft: rephoto)));
      }
    });
  }

  void _launchInfo() async {
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
                    final urlImage = widget.historicalPhotoUri;
                    final url = Uri.parse(urlImage);
                    final response = await http.get(url);
                    final bytes = response.bodyBytes;

                    final temp = await getTemporaryDirectory();
                    final path = '${temp.path}/image.jpg';
                    File(path).writeAsBytesSync(bytes);

                    await Share.shareFiles([path], text: widget.historicalName);
                    void _main() {
                      final dir = Directory(path);
                      dir.deleteSync(recursive: true);
                    }

                    _main();
                  }
                  if (result == 1) {
                    _launchInfo();
                  }
                  if (result == 3) {
                    _openImageMapScreen();
                  }
                  if (result == 4) {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()))
                        .then((_) {
                      setState(() {
                        _getTooltipValue();
                      });
                    });
                  }
                },
                itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 0,
                          child: ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(AppLocalizations.of(context)!
                                  .translate('rePhoto-popupMenu1')))),
                      PopupMenuItem(
                          value: 1,
                          child: ListTile(
                              leading: const Icon(Icons.info),
                              title: Text(AppLocalizations.of(context)!
                                  .translate('rePhoto-popupMenu2')))),
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
                            title: Text(AppLocalizations.of(context)!
                                .translate('rePhoto-popupMenu4')),
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

  void _openImageMapScreen() async {
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

    if (imageLatitude != 0 &&
        imageLongitude != 0 &&
        locator.getLatitude() != 0 &&
        locator.getLongitude() != 0) {
      double distance = Geolocator.distanceBetween(
          locator.getLatitude(), locator.getLongitude(), imageLatitude, imageLongitude);
      double calcDistance = distance / 1000;

      if (distance >= 1000) {
        distanceToImage = calcDistance.toStringAsFixed(2) + ' Km';
      } else {
        distanceToImage = distance.toStringAsFixed(2) + ' M';
      }
    }

    return distanceToImage;
  }

  Widget _getRephotoNumberIconBottomLeft(numberOfRephotos) {
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
    // TODO: another hard-coded url that needs changing if server changes..
    var url = "https://ajapaik.toolforge.org/api/ajapaikimageinfo.php?id=" +
            widget.historicalPhotoId.toString();

    // TODO: check if there are permissions to use network and/or session is active
    // can this be activated if there isn't connection?

    return fetchAlbum(http.Client(), url, locator.getLatitude(), locator.getLongitude());
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
                _getRephotoNumberIconBottomLeft(widget.numberOfRephotos)
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
                    _takeRephoto(context);
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
                      onDoubleTap: _openImageMapScreen,
                      child: _buildFlutterMap())))),
      Visibility(visible: mapInfoVisibility == false, child: _buildInfoText()),
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
                _getRephotoNumberIconBottomLeft(widget.numberOfRephotos)
              ])),
        ),
        Visibility(
            visible: mapInfoVisibility == true,
            child: Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                        onDoubleTap: _openImageMapScreen,
                        child: _buildFlutterMap())))),
        Visibility(
            visible: mapInfoVisibility == false, child: _buildInfoText()),
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
                      _takeRephoto(context);
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

  Widget _buildInfoText() {
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

  Widget _buildFlutterMap() {
    List<Marker> markerList = [];

    if (locator.getLatitude() != 0 && locator.getLongitude() != 0) {
      Marker userMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(locator.getLatitude(), locator.getLongitude()),
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (imageLatitude != 0 && imageLongitude != 0) {
      Marker imageMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(imageLatitude, imageLongitude),
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red));
      markerList.add(imageMarker);
    }

    return FlutterMap(
        options: MapOptions(
          bounds: LatLngBounds(LatLng(imageLatitude, imageLongitude),
              LatLng(locator.getLatitude(), locator.getLongitude())),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
          ),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']
          ),
          MarkerLayerOptions(
            markers: markerList,
          ),
        ]);
  }
}
