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

  LatLng getImagePosition() {
    return LatLng(imageLatitude, imageLongitude);
  }
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
    Scaffold s = Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.getText(context, 'imageMapScreen-appbarTitle'))),
      body: Stack(children: [
        Positioned(
            child: buildMapWidget(context, mapController, locator, widget.getImagePosition())),
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
                  child: Image.network(widget.historicalPhotoUri, fit: BoxFit.contain),
                ))),
      ]),
    );
    return s;
  }

  static Marker getMarker(LatLng point, builder) {
    return Marker(
        width: 80.0,
        height: 80.0,
        point: point,
        builder: builder);
  }

  // nearly identical with second case when embedded in view with photo
  // -> combine cases
  static Widget buildMapWidget(BuildContext context, MapController mapController, AppLocator locator, LatLng imgPos) {
    LatLng locPos = locator.getLatLong();
    List<Marker> markerList = [];

    MapOptions options;
    // TODO: use accuracry instead
    if (locator.isRealPosition == true) {
      // we know both where the picture was taken and where we are currently
      options = MapOptions(
        bounds: LatLngBounds(imgPos, locPos),
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        zoom: 17.0,
        minZoom: 2.5,
        boundsOptions: const FitBoundsOptions(
          padding: EdgeInsets.all(100),
        ),
      );
    } else {
      // we only know where the picture was taken, not where we are currently
      options = MapOptions(
        center: imgPos,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        zoom: 17.0,
      );
    }

    if (locator.isRealPosition == true) {
      Marker userMarker = getMarker(locPos, (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    Marker imageMarker = getMarker(imgPos, (ctx) => const Icon(Icons.location_pin, color: Colors.red));
    markerList.add(imageMarker);

    FlutterMap map = FlutterMap(
        mapController: mapController, // is there reason this wasn't included in the other? static map?
        options: options,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ee.ajapaik.ajapaikFlutterApp',
          ),
          MarkerLayer(markers: markerList)
        ]);
    return map;
  }

  // this is called when opening map from button on screen (photoview),
  // which for some reason is different from when opening from the dropdown menu..
  // -> should use same code for both, no reason why these are different
  static Widget buildMarkedMap(BuildContext context, AppLocator locator, LatLng imgPos) {
    LatLng locPos = locator.getLatLong();
    List<Marker> markerList = [];

    if (locPos.latitude != 0 && locPos.longitude != 0) {
      Marker userMarker = getMarker(locPos, (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (imgPos.latitude != 0 && imgPos.longitude != 0) {
      Marker imageMarker = getMarker(imgPos, (ctx) => const Icon(Icons.location_pin, color: Colors.red));
      markerList.add(imageMarker);
    }

    FlutterMap map = FlutterMap(
        options: MapOptions(
          bounds: LatLngBounds(imgPos, locPos),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ee.ajapaik.ajapaikFlutterApp',
          ),
          MarkerLayer(
            markers: markerList,
          ),
        ]);
    return map;
  }

}
