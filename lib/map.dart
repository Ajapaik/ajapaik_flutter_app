import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';

class MapScreen extends StatefulWidget {

  final Geometry markerCoordinates;
  final List<Feature> markerCoordinatesList;

  const MapScreen({Key? key,
    required this.markerCoordinates,
    required this.markerCoordinatesList,
    })
      : super(key: key);

  @override
  _UserLocationState createState() => _UserLocationState();
}

class _UserLocationState extends State<MapScreen> {

  List<Marker> markerList = [];

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
        () =>  Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high),
  );

  void listToMarkers() {
    List list = widget.markerCoordinatesList;
    setState(() {
      markerList.clear();
      for (int x = 0; x < list.length; x++) {
        if (list[x].geometry.coordinates.length > 0) {
          double latitude = list[x].geometry.coordinates[0];
          double longitude = list[x].geometry.coordinates[1];
          var m = Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(latitude, longitude),
              builder: (ctx) =>
              const Icon(Icons.location_pin,
                  color: Colors.red));
          markerList.add(m);
        }
      }
    });
  }

  // void updateLocation() async {
  //   try {
  //     Future<Position> newPosition = await _location
  //         .getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.bestForNavigation,
  //     )
  //         .timeout(new Duration(seconds: 5));
  //     print(
  //         'updateLocation(): ${newPosition.latitude.toString() + ',' + newPosition.longitude.toString()}');
  //
  //     setState(() {
  //       _location = newPosition;
  //       setMap();
  //     });
  //   } catch (error) {
  //     print('Error updating location: ${error.toString()}');
  //   }
  // }


  @override
  void initState() {
    listToMarkers();
    listenCurrentLocation();
    super.initState();
  }

  double userLatitudeData = 0;
  double userLongitudeData = 0;

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
    LocationAccuracy.high, timeLimit: const Duration(seconds: 5));
    position.listen((position) {
      if(position != userLatitudeData && position != userLongitudeData) {
        return getCurrentLocation();
          }
        }
      );
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
                      : const Center (
                      child: LinearProgressIndicator(value: null));
                })
          ),
        ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {

    // var points = <LatLng>[
    //   LatLng(userLatitudeData, userLongitudeData)
    // ];

    // double imagelatitude = 0;
    // double imagelongitude = 0;
    // if (!widget.markerCoordinates.coordinates.isEmpty) {
    //   imagelatitude = widget.markerCoordinates.coordinates[0];
    //   imagelongitude = widget.markerCoordinates.coordinates[1];
    // }

    return FlutterMap(
        options: MapOptions(
          center: LatLng(userLatitudeData, userLongitudeData),
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
          // PolylineLayerOptions(
          //   polylines: [
          //     Polyline(
          //       points: points,
          //       strokeWidth: 20.0,
          //       color: Colors.blue
          //     )
          //   ]
          // ),
          MarkerLayerOptions(
            markers: markerList,
          ),
          MarkerLayerOptions(markers: [
            Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(userLatitudeData, userLongitudeData),
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.blue)),
          ])
        ]);
  }
}
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//       appBar: AppBar(title: const Text('Map')),
//       body: Column(children: [
//         if (showMap && userLatitudeData != 0 && userLongitudeData != 0)
//           Expanded(
//               child: FlutterMap(
//                   options: MapOptions(
//                     center: LatLng(userLatitudeData, userLongitudeData),
//                     interactiveFlags:
//                         InteractiveFlag.pinchZoom | InteractiveFlag.drag,
//                     zoom: 13.0,
//                   ),
//                   layers: [
//                 TileLayerOptions(
//                   urlTemplate:
//                       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   subdomains: ['a', 'b', 'c'],
//                   attributionBuilder: (_) {
//                     return const Text("© OpenStreetMap contributors");
//                   },
//                 ),
//                 MarkerLayerOptions(
//                   markers: [
//                     Marker(
//                         width: 80.0,
//                         height: 80.0,
//                         point: LatLng(userLatitudeData, userLongitudeData),
//                         builder: (ctx) => const Icon(Icons.location_pin,
//                             color: Colors.red)),
//                   ],
//                 ),
//               ]))
//       ]));
// }


