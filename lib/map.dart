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

const String streetmapUrlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

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
    LatLng widgetPos = LatLng(widget.imageLatitude, widget.imageLongitude);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.getText(context, 'imageMapScreen-appbarTitle'))),
      body: Stack(children: [
        Positioned(
            child: FutureBuilder(
                future: AppLocator().getPosition(),
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasError) (snapshot.error);
                  return snapshot.hasData
                      ? buildMapWidget(context, snapshot)
                      : Center(
                          child: FlutterMap(
                              options: MapOptions(
                                center: widgetPos,
                                interactiveFlags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                                zoom: 17.0,
                              ),
                              layers: [
                              TileLayerOptions(
                                urlTemplate: streetmapUrlTemplate,
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: locator.getLatLong(),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.blue)),
                              ]),
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: widgetPos,
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

  Widget buildMapWidget(BuildContext context, snapshot) {
    LatLng imgPos = locator.getLatLong();
    if (snapshot.hasData) {
      imgPos = LatLng(snapshot.data.latitude, snapshot.data.longitude);
    }
    LatLng wdgLatLong = LatLng(widget.imageLatitude, widget.imageLongitude);
    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          bounds: LatLngBounds(wdgLatLong, imgPos),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          minZoom: 2.5,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(100),
          ),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: streetmapUrlTemplate,
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(markers: [
            Marker(
                width: 80.0,
                height: 80.0,
                point: imgPos,
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

  // currently doesn't use any members, just moved out of the way
  static Widget buildMarkedMap(LatLng locPos, LatLng imgPos) {
    List<Marker> markerList = [];

    if (locPos.latitude != 0 && locPos.longitude != 0) {
      Marker userMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: locPos,
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (imgPos.latitude != 0 && imgPos.longitude != 0) {
      Marker imageMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: imgPos,
          builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red));
      markerList.add(imageMarker);
    }

    return FlutterMap(
        options: MapOptions(
          bounds: LatLngBounds(imgPos, locPos),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
          ),
        ),
        layers: [
          TileLayerOptions(
              urlTemplate: streetmapUrlTemplate,
              subdomains: ['a', 'b', 'c']
          ),
          MarkerLayerOptions(
            markers: markerList,
          ),
        ]);
  }

}
