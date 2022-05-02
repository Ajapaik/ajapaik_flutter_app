import 'dart:async';
import 'dart:io';
import 'package:ajapaik_flutter_app/demolocalization.dart';
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
import 'imagemapscreen.dart';
import 'photomanipulation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RephotoScreen extends StatefulWidget {
  final String historicalPhotoId;
  final String historicalPhotoUri;
  final String historicalName;
  final String historicalDate;
  final String historicalAuthor;
  final String historicalLabel;
  final String historicalSurl;

  final Geometry historicalCoordinates;

  const RephotoScreen({
    Key? key,
    required this.historicalPhotoId,
    required this.historicalPhotoUri,
    required this.historicalName,
    required this.historicalDate,
    required this.historicalAuthor,
    required this.historicalLabel,
    required this.historicalSurl,
    required this.historicalCoordinates,
  }) : super(key: key);

  @override
  RephotoScreenState createState() => RephotoScreenState();
}

class RephotoScreenState extends State<RephotoScreen> {
  bool boolValue = true;
  bool mapInfoVisibility = false;
  bool newMapInfoValue = true;
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  StreamSubscription<Position>? _positionStream;

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


  _saveMapInfoBool() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('MapInfoVisibility', mapInfoVisibility);
  }

  void getMapInfoValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    mapInfoVisibility = prefs.getBool("MapInfoVisibility")!;
    setState(() {});
  }

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

  void _launchTIFY() async {
     Uri url =
        Uri.parse('https://demo.tify.rocks/demo.html?manifest=https://ajapaik.ee/photo/199152/v2/manifest.json&tify={%22panX%22:0.5,%22panY%22:0.375,%22view%22:%22info%22,%22zoom%22:0.001}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchInfo() async {
    Uri url = Uri.parse(widget.historicalSurl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $widget.historicalSurl';
    }
  }

  void getCurrentLocation() async {
    var geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLatitudeData = geoPosition.latitude;
      userLongitudeData = geoPosition.longitude;
    });
  }

  void listenCurrentLocation() {
    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 10));
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position geoPosition) {
      if (geoPosition.latitude != userLatitudeData &&
          geoPosition.longitude != userLongitudeData) {
        return getCurrentLocation();
      }
    });
  }
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
  @override
  void initState() {
//    listenCurrentLocation();
     getCurrentLocation();
    mapInfoVisibility=false;
    _saveMapInfoBool();
    getMapInfoValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (widget.historicalCoordinates.coordinates.isNotEmpty) {
      latitude = widget.historicalCoordinates.coordinates[0];
      longitude = widget.historicalCoordinates.coordinates[1];
    }

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
                /*  if (result == 2) {
                    _launchTIFY();
                  }*/
                  if (result == 3) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ImageMapScreen(
                                  imageLatitude: latitude,
                                  imageLongitude: longitude,
                                  historicalPhotoUri: widget.historicalPhotoUri,
                                )));
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

  Widget verticalPreview(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (widget.historicalCoordinates.coordinates.isNotEmpty) {
      latitude = widget.historicalCoordinates.coordinates[0];
      longitude = widget.historicalCoordinates.coordinates[1];
    }

    double distance = Geolocator.distanceBetween(
        userLatitudeData, userLongitudeData, latitude, longitude);
    double calcDistance = distance / 1000;
    String distanceToImage = '';
    if (distance >= 1000) {
      distanceToImage = calcDistance.toStringAsFixed(2) + ' Km';
    } else {
      distanceToImage = distance.toStringAsFixed(2) + ' M';
    }

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
                      builder: (context) => ManiPhoto(
                            historicalPhotoUri: widget.historicalPhotoUri,
                          )));
            },
            child:
                Image.network(widget.historicalPhotoUri, fit: BoxFit.contain),
          )),
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
                  _saveMapInfoBool();
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
                    onDoubleTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImageMapScreen(
                                    imageLatitude: latitude,
                                    imageLongitude: longitude,
                                    historicalPhotoUri:
                                        widget.historicalPhotoUri,
                                  )));
                    },
                    child: FutureBuilder(
                        future: Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high),
                        builder: (BuildContext context,
                            AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) (snapshot.error);
                          return _buildFlutterMap(context, snapshot);
                        })))),
      ),
      Visibility(
          visible: mapInfoVisibility == false,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 25),
            child: Column(children: [
              Text(widget.historicalAuthor + ', ' + widget.historicalDate,
                  maxLines: 2),
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
                        Uri url=Uri.parse(widget.historicalSurl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Could not launch $widget.historicalSurl';
                        }
                      }),
              ),
            ]),
          ))
    ]);
  }

  Widget horizontalPreview(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (widget.historicalCoordinates.coordinates.isNotEmpty) {
      // https://datatracker.ietf.org/doc/html/rfc7946
      // GeoJSON longitude = 0, latitude = 1
      latitude = widget.historicalCoordinates.coordinates[1];
      longitude = widget.historicalCoordinates.coordinates[0];
    }

    double distance = Geolocator.distanceBetween(
        userLatitudeData, userLongitudeData, latitude, longitude);
    double calcDistance = distance / 1000;
    String distanceToImage = '';
    if (distance >= 1000) {
      distanceToImage = calcDistance.toStringAsFixed(2) + ' Km';
    } else {
      distanceToImage = distance.toStringAsFixed(2) + ' M';
    }



    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ManiPhoto(
                            historicalPhotoUri: widget.historicalPhotoUri,
                          )));
            },
            child: CachedNetworkImage(imageUrl: widget.historicalPhotoUri),
          ),
        ),
        Visibility(
            visible: mapInfoVisibility == true,
            child: Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                        onDoubleTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ImageMapScreen(
                                        imageLatitude: latitude,
                                        imageLongitude: longitude,
                                        historicalPhotoUri:
                                            widget.historicalPhotoUri,
                                      )));
                        },
                        child: FutureBuilder(
                            future: Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.hasError) (snapshot.error);
                              return _buildFlutterMap(
                                  context, snapshot);
                            }))))),
        Visibility(
            visible: mapInfoVisibility == false,
            child: Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.historicalAuthor +
                              ', ' +
                              widget.historicalDate,
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
                                  if (await canLaunch(widget.historicalSurl)) {
                                    await launch(widget.historicalSurl);
                                  } else {
                                    throw 'Could not launch $widget.historicalSurl';
                                  }
                                }),
                        ),
                      ])),
            )),
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
                      _saveMapInfoBool();
                      setState(() {
                        mapInfoVisibility = !mapInfoVisibility;
                      });
                    }),
              ]),
        )
      ],
    );
  }

  Widget _buildFlutterMap(BuildContext context, userLocationReady) {
    List<Marker> markerList = [];
    double longitude = 0;
    double latitude = 0;

    if (userLocationReady.hasData) {
      userLatitudeData=userLocationReady.data.latitude;
      userLongitudeData=userLocationReady.data.longitude;
    }

    if (userLatitudeData!=0 && userLongitudeData!=0) {
      Marker userMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(userLatitudeData, userLongitudeData),
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (widget.historicalCoordinates.coordinates.isNotEmpty) {
      longitude = widget.historicalCoordinates.coordinates[1];
      latitude = widget.historicalCoordinates.coordinates[0];

      Marker imageMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(latitude, longitude),
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red));
      markerList.add(imageMarker);
    }

    return FlutterMap(
        options: MapOptions(
          bounds: LatLngBounds(LatLng(latitude, longitude),
              LatLng(userLatitudeData, userLongitudeData)),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
          ),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            attributionBuilder: (_) {
              return const Text("© OpenStreetMap contributors");
            },
          ),
          MarkerLayerOptions(
            markers: markerList,
          ),
        ]);
  }
}
