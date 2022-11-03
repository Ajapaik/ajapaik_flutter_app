import 'dart:async';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

import 'localization.dart';
import 'imagestorage.dart';

class GeoMap extends StatefulWidget {
  final double imageLatitude;
  final double imageLongitude;
  final String historicalPhotoUri;

  const GeoMap({
    Key? key,
    required this.imageLatitude,
    required this.imageLongitude,
    required this.historicalPhotoUri,
  }) : super(key: key);

  @override
  GeoMapState createState() => GeoMapState();

  LatLng getImagePosition() {
    return LatLng(imageLatitude, imageLongitude);
  }
}

class GeoMapState extends State<GeoMap> {
  final locator = Get.find<AppLocator>();
  final imageStorage = Get.find<ImageStorage>();

  @override
  void initState() {
    super.initState();
    locator.init();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // this builds the full screen view and shows map in it
    // with thumbnail of an image
    Scaffold s = Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.getText(context, 'imageMapScreen-appbarTitle'))),
      body: Stack(children: [
        Positioned(
            child: buildMapWidget(locator, widget.getImagePosition())),
         GestureDetector(
            onTap: () {
              // if user taps on the map, logical result would be to zoom in, right?
              // -> back button is separate
              //Navigator.pop(context);
            },
             child: Padding(
                padding: const EdgeInsets.only(top: 650, left: 10, bottom: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 350,
                  ),
                  // photo is shown as small thumbnail while viewing local area map (street map)
                  child: imageStorage.getCachedNetworkImage(widget.historicalPhotoUri, BoxFit.contain),
                ))),
      ]),
    );
    return s;
  }

  // nearly identical with second case when embedded in view with photo
  // -> combine cases
  static Widget buildMapWidget(AppLocator locator, LatLng imgPos) {
    if (locator.isRealPosition == true) {
      return GeoMapView(imagelocation: imgPos, currentLocation: locator.getLatLong() ).buildFullscreen();
    }
    else {
      return GeoMapView(imagelocation: imgPos).buildFullscreen();
    }
  }

  // this is called when opening map from button on screen (photoview),
  // which for some reason is different from when opening from the dropdown menu..
  // -> should use same code for both, no reason why these are different
  static Widget buildEmbeddedMap(AppLocator locator, LatLng imgPos) {
    if (locator.isRealPosition == true) {
      return GeoMapView(imagelocation: imgPos, currentLocation: locator.getLatLong() ).buildEmbedded();
    }
    else {
      return GeoMapView(imagelocation: imgPos).buildEmbedded();
    }
  }

}

class GeoMapView {
  final LatLng imagelocation;
  LatLng? currentLocation;
  final MapController mapController = MapController();

  GeoMapView({
              required this.imagelocation,
              this.currentLocation}) {
  }

  void initState() {
  }

  void dispose() {
  }

  Marker getMarker(LatLng point, builder) {
    return Marker(
        width: 80.0,
        height: 80.0,
        point: point,
        builder: builder);
  }

  TileLayer getMapTilelayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'ee.ajapaik.ajapaikFlutterApp',
    );
  }

  MapOptions getMapOptions(double? minZoom) {
    MapOptions options;
    if (currentLocation != null) {
      // we know both where the picture was taken and where we are currently
      options = MapOptions(
        bounds: LatLngBounds(imagelocation, currentLocation),
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        zoom: 17.0,
        minZoom: minZoom,
        boundsOptions: const FitBoundsOptions(
          padding: EdgeInsets.all(100),
        ),
      );
    } else {
      // we only know where the picture was taken, not where we are currently
      options = MapOptions(
        center: imagelocation,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        zoom: 17.0,
      );
    }
    return options;
  }

  List<Marker> getMarkerList() {
    List<Marker> markerList = [];
    if (currentLocation != null) {
      Marker userMarker = getMarker(currentLocation!, (ctx) => const Icon(Icons.location_pin, color: Colors.blue));
      markerList.add(userMarker);
    }

    if (imagelocation.latitude != 0 && imagelocation.longitude != 0) {
      Marker imageMarker = getMarker(imagelocation, (ctx) => const Icon(Icons.location_pin, color: Colors.red));
      markerList.add(imageMarker);
    }
    return markerList;
  }

  Widget buildFullscreen() {
    MapOptions options = getMapOptions(2.5);
    List<Marker> markerList = getMarkerList();

    FlutterMap map = FlutterMap(
        mapController: mapController, // is there reason this wasn't included in the other? static map?
        options: options,
        children: [
          getMapTilelayer(),
          MarkerLayer(markers: markerList)
        ]);
    return map;
  }


  Widget buildEmbedded() {
    MapOptions options = getMapOptions(null); // set some min zoom here too?
    List<Marker> markerList = getMarkerList();

    FlutterMap map = FlutterMap(
        mapController: mapController,
        options: options,
        children: [
          getMapTilelayer(),
          MarkerLayer(markers: markerList)
        ]);
    return map;
  }
}
