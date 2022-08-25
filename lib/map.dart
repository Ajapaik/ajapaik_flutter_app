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
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  // this used to expect Position in snapshot?
                  // TODO: see if this thing can be simplified further (no "future", just build it)
                  if (snapshot.hasError) (snapshot.error);

                  return snapshot.hasData
                      ? buildMapWidgetSnapshot(context, widgetPos)
                      : Center(
                          child: buildMapWidget(context, widgetPos));
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

  static Marker getMarker(LatLng point, builder) {
    return Marker(
        width: 80.0,
        height: 80.0,
        point: point,
        builder: builder);
  }

  Widget buildMapWidget(BuildContext context, LatLng widgetPos) {
    LatLng imgPos = locator.getLatLong();
    return FlutterMap(
        options: MapOptions(
          center: widgetPos,
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: streetmapUrlTemplate,
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(markers: [
            getMarker(imgPos, (ctx) => const Icon(Icons.location_pin, color: Colors.blue)),
          ]),
          MarkerLayerOptions(markers: [
            getMarker(widgetPos, (ctx) => const Icon(Icons.location_pin, color: Colors.red)),
          ])
        ]);
  }

  // this version expects Position from locator().getPosition(),
  // but this only uses latitude and longitude from it..
  //
  Widget buildMapWidgetSnapshot(BuildContext context, LatLng widgetPos) {

    // this is now the same as was used from the Position given in snapshot
    // -> simplify
    LatLng imgPos = locator.getLatLong();
    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          bounds: LatLngBounds(widgetPos, imgPos),
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
            getMarker(imgPos, (ctx) => const Icon(Icons.location_pin, color: Colors.blue)),
          ]),
          MarkerLayerOptions(markers: [
            getMarker(widgetPos, (ctx) => const Icon(Icons.location_pin, color: Colors.red)),
          ])
        ]);
  }

  // currently doesn't use any members, just moved out of the way
  static Widget buildMarkedMap(BuildContext context, LatLng locPos, LatLng imgPos) {
    List<Marker> markerList = [];

    if (locPos.latitude != 0 && locPos.longitude != 0) {
      Marker userMarker = getMarker(locPos, (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (imgPos.latitude != 0 && imgPos.longitude != 0) {
      Marker imageMarker = getMarker(imgPos, (ctx) => const Icon(Icons.location_pin, color: Colors.red));
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
