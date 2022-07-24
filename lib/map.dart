import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'localization.dart';

class Map extends StatefulWidget {
  final double imageLatitude;
  final double imageLongitude;
  final String historicalPhotoUri;

  const Map({
    Key? key,
    required this.imageLatitude,
    required this.imageLongitude,
    required this.historicalPhotoUri,
  }) : super(key: key);

  @override
  MapState createState() => MapState();
}

class MapState extends State<Map> {
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  late final MapController mapController;
  StreamSubscription<Position>? _positionStream;



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

  @override
  void initState() {
    listenCurrentLocation();
    super.initState();
    mapController = MapController();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('imageMapScreen-appbarTitle'))),
      body: Stack(children: [
        Positioned(
            child: FutureBuilder(
                future: Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high),
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasError) (snapshot.error);
                  return snapshot.hasData
                      ? _buildFlutterMap(context, snapshot)
                      : Center(
                          child: FlutterMap(
                              options: MapOptions(
                                center: LatLng(widget.imageLatitude,
                                    widget.imageLongitude),
                                interactiveFlags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                                zoom: 17.0,
                              ),
                              layers: [
                              TileLayerOptions(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(
                                        userLatitudeData, userLongitudeData),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.blue)),
                              ]),
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(widget.imageLatitude,
                                        widget.imageLongitude),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.red)),
                              ])
                            ]));
                })),
         GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
             child: Padding(
                padding: const EdgeInsets.only(top: 650, left: 10, bottom: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 350,
                  ),
                  child: Image.network(widget.historicalPhotoUri,
                      fit: BoxFit.contain),
                ))),
      ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context, snapshot) {
    if (snapshot.hasData) {
      userLatitudeData = snapshot.data.latitude;
      userLongitudeData = snapshot.data.longitude;
    }
    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          bounds: LatLngBounds(LatLng(widget.imageLatitude, widget.imageLongitude), LatLng(userLatitudeData, userLongitudeData)),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          minZoom: 2.5,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(100),
          ),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(markers: [
            Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(userLatitudeData, userLongitudeData),
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.blue)),
          ]),
          MarkerLayerOptions(markers: [
            Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(widget.imageLatitude, widget.imageLongitude),
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.red)),
          ])
        ]);
  }
}
