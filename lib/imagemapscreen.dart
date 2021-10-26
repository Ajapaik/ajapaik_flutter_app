import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ImageMapScreen extends StatefulWidget {

  final double imageLatitude;
  final double imageLongitude;

  const ImageMapScreen({Key? key,
      required this.imageLatitude,
      required this.imageLongitude,
  })
      :super(key: key);



  @override
  ImageMapState createState() => ImageMapState();
}

class ImageMapState extends State<ImageMapScreen> {

  double userLatitudeData = 0;
  double userLongitudeData = 0;

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
        () =>  Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high),
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

    Stream<Position> position = Geolocator.getPositionStream(desiredAccuracy:
    LocationAccuracy.high, timeLimit: const Duration(seconds: 5), distanceFilter: 10);
    position.listen((position) {
      if(position.latitude != userLatitudeData && position.longitude != userLongitudeData ) {
        return getCurrentLocation();
      }
    }
    );
  }

  @override
  void initState() {
    listenCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Column(
          children: [
            Expanded(
                child: FutureBuilder(
                    future: _location,
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasError) (snapshot.error);
                      return snapshot.hasData ?
                      _buildFlutterMap(context)
                          : Center (
                          child: FlutterMap(
                              options: MapOptions(
                                center: LatLng(widget.imageLatitude, widget.imageLongitude),
                                interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                zoom: 13.0,
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
                              ]));
                    })
            ),
          ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {

    return FlutterMap(
        options: MapOptions(
          center: LatLng(widget.imageLatitude, widget.imageLongitude),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 13.0,
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