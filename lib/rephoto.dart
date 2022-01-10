import 'dart:io';
import 'package:ajapaik_flutter_app/settings.dart';
import 'package:ajapaik_flutter_app/upload.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  }) : super();

  @override
  RephotoScreenState createState() => RephotoScreenState();
}

class RephotoScreenState extends State<RephotoScreen> {
  bool boolValue = true;
  bool MapInfoVisibility = false;
  bool newMapInfoValue = true;
  double userLatitudeData = 0;
  double userLongitudeData = 0;

  _getTooltipValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var boolValue = prefs.getBool("tooltip");
    if (boolValue != tooltip) {
      setState(() {
        tooltip = boolValue! == true;
      });
      return boolValue;
    }
  }

  void getMapInfoValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    MapInfoVisibility = prefs.getBool("MapInfoVisibility")!;
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
    const url =
        'https://demo.tify.rocks/demo.html?manifest=https://ajapaik.ee/photo/199152/v2/manifest.json&tify={%22panX%22:0.5,%22panY%22:0.375,%22view%22:%22info%22,%22zoom%22:0.001}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchInfo() async {
    if (await canLaunch(widget.historicalSurl)) {
      await launch(widget.historicalSurl);
    } else {
      throw 'Could not launch $widget.historicalSurl';
    }
  }

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
    () => Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high),
  );

  void getCurrentLocation() async {
    var geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLatitudeData = geoPosition.latitude;
      userLongitudeData = geoPosition.longitude;
    });
  }

  void listenCurrentLocation() {
    Stream<Position> position = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
        distanceFilter: 10);
    position.listen((position) {
      if (position.latitude != userLatitudeData &&
          position.longitude != userLongitudeData) {
        return getCurrentLocation();
      }
    });
  }

  @override
  void initState() {
    listenCurrentLocation();
    getMapInfoValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (!widget.historicalCoordinates.coordinates.isEmpty) {
      latitude = widget.historicalCoordinates.coordinates[0];
      longitude = widget.historicalCoordinates.coordinates[1];
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: const Text('Rephoto application',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              )),
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
                  if (result == 2) {
                    _launchTIFY();
                  }
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
                      const PopupMenuItem(
                          value: 0,
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text(
                              'Jaa kuva',
                            ),
                          )),
                      const PopupMenuItem(
                          value: 1,
                          child: ListTile(
                            leading: Icon(Icons.info),
                            title: Text(
                              'Lisätietoja kuvasta',
                            ),
                          )),
                      const PopupMenuItem(
                        value: 2,
                        child: ListTile(
                          leading: Icon(Icons.enhance_photo_translate),
                          title: Text(
                            'TIFY-demo',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                          value: 3,
                          child: ListTile(
                            leading: Icon(Icons.map),
                            title: Text(
                              'Karttanäkymä',
                            ),
                          )),
                      const PopupMenuItem(
                          value: 4,
                          child: ListTile(
                            leading: Icon(Icons.settings),
                            title: Text(
                              'Asetukset',
                            ),
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

  Widget verticalPreview(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (!widget.historicalCoordinates.coordinates.isEmpty) {
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

    @override
    _saveMapInfoBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('MapInfoVisibility', MapInfoVisibility);
    }

    return Column(children: [
      Expanded(
          flex: 0,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ManiPhoto(
                            historicalPhotoUri: widget.historicalPhotoUri,
                          )));
            },
            child: Image.network(widget.historicalPhotoUri, height: 350, width: 350, fit: BoxFit.contain),
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
                icon: MapInfoVisibility
                    ? const Icon(Icons.info_outline)
                    : const Icon(Icons.map),
                onPressed: () {
                  _saveMapInfoBool();
                  setState(() {
                    MapInfoVisibility = !MapInfoVisibility;
                  });
                }),
          ])),
      Visibility(
        visible: MapInfoVisibility == true,
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
                        future: _location,
                        builder: (BuildContext context,
                            AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) (snapshot.error);
                          return snapshot.hasData
                              ? _buildFlutterMap(context)
                              : Center(
                                  child: FlutterMap(
                                      options: MapOptions(
                                        center: LatLng(latitude, longitude),
                                        interactiveFlags:
                                            InteractiveFlag.pinchZoom |
                                                InteractiveFlag.drag,
                                        zoom: 17.0,
                                      ),
                                      layers: [
                                        TileLayerOptions(
                                          urlTemplate:
                                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                          subdomains: ['a', 'b', 'c'],
                                          attributionBuilder: (_) {
                                            return const Text(
                                                "© OpenStreetMap contributors");
                                          },
                                        ),
                                        MarkerLayerOptions(
                                          markers: [
                                            Marker(
                                                width: 80.0,
                                                height: 80.0,
                                                point:
                                                    LatLng(latitude, longitude),
                                                builder: (ctx) => const Icon(
                                                    Icons.location_pin,
                                                    color: Colors.red)),
                                          ],
                                        ),
                                        MarkerLayerOptions(
                                          markers: [
                                            Marker(
                                                width: 80.0,
                                                height: 80.0,
                                                point: LatLng(userLatitudeData,
                                                    userLongitudeData),
                                                builder: (ctx) => const Icon(
                                                    Icons.location_pin,
                                                    color: Colors.blue)),
                                          ],
                                        ),
                                      ]),
                                );
                        })))),
      ),
      Visibility(
          visible: MapInfoVisibility == false,
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
                        if (await canLaunch(widget.historicalSurl)) {
                          await launch(widget.historicalSurl);
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
    if (!widget.historicalCoordinates.coordinates.isEmpty) {
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

    @override
    _saveMapInfoBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('MapInfoVisibility', MapInfoVisibility);
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
            child: Image.network(widget.historicalPhotoUri),
          ),
        ),
        Visibility(
          visible: MapInfoVisibility == true,
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
                          future: _location,
                          builder: (BuildContext context,
                              AsyncSnapshot<dynamic> snapshot) {
                            if (snapshot.hasError) (snapshot.error);
                            return snapshot.hasData
                                ? _buildFlutterMap(context)
                                : Center(
                                    child: FlutterMap(
                                        options: MapOptions(
                                          center: LatLng(latitude, longitude),
                                          interactiveFlags:
                                              InteractiveFlag.pinchZoom |
                                                  InteractiveFlag.drag,
                                          zoom: 17.0,
                                        ),
                                        layers: [
                                          TileLayerOptions(
                                            urlTemplate:
                                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                            subdomains: ['a', 'b', 'c'],
                                            attributionBuilder: (_) {
                                              return const Text(
                                                  "© OpenStreetMap contributors");
                                            },
                                          ),
                                          MarkerLayerOptions(
                                            markers: [
                                              Marker(
                                                  width: 80.0,
                                                  height: 80.0,
                                                  point: LatLng(
                                                      latitude, longitude),
                                                  builder: (ctx) => const Icon(
                                                      Icons.location_pin,
                                                      color: Colors.red)),
                                            ],
                                          ),
                                          MarkerLayerOptions(
                                            markers: [
                                              Marker(
                                                  width: 80.0,
                                                  height: 80.0,
                                                  point: LatLng(
                                                      userLatitudeData,
                                                      userLongitudeData),
                                                  builder: (ctx) => const Icon(
                                                      Icons.location_pin,
                                                      color: Colors.blue)),
                                            ],
                                          ),
                                        ]),
                                  );
                          })))),
        ),
        Visibility(
            visible: MapInfoVisibility == false,
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
                    icon: MapInfoVisibility
                        ? const Icon(Icons.info_outline)
                        : const Icon(Icons.map),
                    onPressed: () {
                      _saveMapInfoBool();
                      setState(() {
                        MapInfoVisibility = !MapInfoVisibility;
                      });
                    }),
              ]),
        )
      ],
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    double latitude = 0;
    double longitude = 0;
    if (!widget.historicalCoordinates.coordinates.isEmpty) {
      longitude = widget.historicalCoordinates.coordinates[0];
      latitude = widget.historicalCoordinates.coordinates[1];
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
            markers: [
              Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(latitude, longitude),
                  builder: (ctx) =>
                      const Icon(Icons.location_pin, color: Colors.red)),
            ],
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(userLatitudeData, userLongitudeData),
                  builder: (ctx) =>
                      const Icon(Icons.location_pin, color: Colors.blue)),
            ],
          ),
        ]);
  }
}
