import 'dart:async';
import 'package:ajapaik_flutter_app/rephoto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';
import 'demolocalization.dart';

class MapScreen extends StatefulWidget {
  final Geometry markerCoordinates;
  final List<Feature> markerCoordinatesList;
  final double userLatitudeData;
  final double userLongitudeData;
  final String historicalPhotoUri;

  const MapScreen({
    Key? key,
    required this.markerCoordinates,
    required this.markerCoordinatesList,
    required this.userLatitudeData,
    required this.userLongitudeData,
    required this.historicalPhotoUri,
  }) : super(key: key);

  @override
  _UserLocationState createState() => _UserLocationState();
}

class _UserLocationState extends State<MapScreen> {
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  int maxClusterRadius = 100;
  List<Marker> markerList = [];
  List<Bounds> boundsList = [];
  bool open = false;
  bool busy = false;
  List<Color> _colors = [];
  late final MapController mapController;

  StreamSubscription<Position>? _positionStream;

  getColorsForIcons() async {
    _colors =
        List.generate(10000, (index) => Colors.red); // here 10 is items.length
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

  void listenCurrentLocation(){

    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 5)
    );
    _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings).listen((Position geoPosition)
    {
      if (geoPosition.latitude != userLatitudeData &&
          geoPosition.longitude != userLongitudeData) {
        return getCurrentLocation();
      }
    });
  }

  getMarkerList(context) {
    List list = widget.markerCoordinatesList;
    markerList.clear();
    for (int x = 0; x < list.length; x++) {
      if (list[x].geometry.coordinates.length > 0) {
        double latitude = list[x].geometry.coordinates[0];
        double longitude = list[x].geometry.coordinates[1];
        var m = Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(latitude, longitude),
            builder: (ctx) => IconButton(
                  icon: Icon(Icons.location_pin, color: _colors[x]),
                  onPressed: () {
                    if (busy == true) {
                      return;
                    } else {
                      if (open == true) {
                        Navigator.of(context).pop();
                        setState(() {
                          _colors[x] = Colors.red;
                        });
                        open = false;
                      }
                    }
                    if (open == false) {
                      busy = true;
                      open = true;
                      setState(() {
                        _colors[x] = Colors.white;
                      });
                      showBottomSheet(
                          context: context,
                          builder: (builder) {
                            busy = false;
                            return Row(children: [
                              Expanded(
                                child: GestureDetector(
                                    child: Image.network(
                                        list[x].properties.thumbnail),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  RephotoScreen(
                                                    historicalPhotoId: list[x]
                                                        .properties
                                                        .id
                                                        .toString(),
                                                    historicalPhotoUri: list[x]
                                                        .properties
                                                        .thumbnail
                                                        .toString(),
                                                    historicalName: list[x]
                                                        .properties
                                                        .name
                                                        .toString(),
                                                    historicalDate: list[x]
                                                        .properties
                                                        .date
                                                        .toString(),
                                                    historicalAuthor: list[x]
                                                        .properties
                                                        .author
                                                        .toString(),
                                                    historicalSurl: list[x]
                                                        .properties
                                                        .sourceUrl
                                                        .toString(),
                                                    historicalLabel: list[x]
                                                        .properties
                                                        .sourceLabel
                                                        .toString(),
                                                    historicalCoordinates:
                                                        list[x].geometry,
                                                  )));
                                    }),
                              )
                            ]);
                          }).closed.then((value) {
                        if (busy == false) {
                          open = false;
                        }
                        setState(() {
                          _colors[x] = Colors.red;
                        });
                        busy = false;
                      });
                    }
                  },
                ));
        markerList.add(m);
      }
    }
    return markerList;
  }

  getBoundsList(context) {
    List list = widget.markerCoordinatesList;
    boundsList.clear();
    for (int x = 0; x < list.length; x++) {
      if (list[x].geometry.coordinates.length > 0) {
        double boundsLatitude = list[x].geometry.coordinates[0];
        double boundsLongitude = list[x].geometry.coordinates[1];
        //var b = Bounds(boundsLatitude, boundsLongitude);
        //boundsList.add(b);
      }
    }
  }

  @override
  void initState() {
    listenCurrentLocation();
    getColorsForIcons();
    mapController = MapController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('map-appbarTitle'))),
      body: Column(children: [
        Expanded(
            child: FutureBuilder(
                future: _location,
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasError) (snapshot.error);
                  return snapshot.hasData
                      ? _buildFlutterMap(context)
                      : Center(
                          child: FlutterMap(
                              options: MapOptions(
                                center: LatLng(widget.userLatitudeData,
                                    widget.userLongitudeData),
                                interactiveFlags: InteractiveFlag.pinchZoom |
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
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 40.0,
                                    height: 40.0,
                                    point: LatLng(widget.userLatitudeData,
                                        widget.userLongitudeData),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.blue)),
                              ])
                            ]));
                })),
      ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    LatLng lastposition = LatLng(userLatitudeData, userLongitudeData);
    getMyZoom() {
      if (mapController.zoom >= 17) {
        maxClusterRadius = 5;
      } else {
        if (mapController.zoom <= 9) {
          maxClusterRadius = 200;
        }
      }
    }

    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onPositionChanged: (mapPosition, boolValue){
              lastposition = mapPosition.center!;
              },
          center: LatLng(widget.userLatitudeData,
              widget.userLongitudeData),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          maxZoom: 18,

        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            attributionBuilder: (_) {
              return const Text("© OpenStreetMap contributors");
            },
          ),
          MarkerLayerOptions(markers: [
            Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(userLatitudeData, userLongitudeData),
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.blue)),
          ])
        ]);
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> markerCoordinatesList) {
    assert(markerCoordinatesList.isNotEmpty);
    double x0 = 0;
    double x1 = 0;
    double y0 = 0;
    double y1 = 0;
    for (LatLng latLng in markerCoordinatesList) {
      if (x0 == 0) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(LatLng(x1, y1), LatLng(x0, y0));
  }
}
