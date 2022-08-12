import 'dart:async';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

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
  late final MapController mapController;
  final locator = Get.put(AppLocator());

  @override
  void initState() {
    super.initState();
    locator.init();
    mapController = MapController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('imageMapScreen-appbarTitle'))),
      body: Stack(children: [
        Positioned(
            child: FutureBuilder(
                future: AppLocator().getPosition(),
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
                                        locator.getLatitude(), locator.getLongitude()),
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
    double imageLatitude = locator.getLatitude();
    double imageLongitude = locator.getLongitude();
    if (snapshot.hasData) {
      imageLatitude = snapshot.data.latitude;
      imageLongitude = snapshot.data.longitude;
    }
    LatLng imgLatLng = LatLng(imageLatitude, imageLongitude);
    LatLng wdgLatLong = LatLng(widget.imageLatitude, widget.imageLongitude);
    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          bounds: LatLngBounds(wdgLatLong, imgLatLng),
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
                point: imgLatLng,
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.blue)),
          ]),
          MarkerLayerOptions(markers: [
            Marker(
                width: 80.0,
                height: 80.0,
                point: wdgLatLong,
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.red)),
          ])
        ]);
  }
}
