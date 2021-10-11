import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';

class MapScreen extends StatefulWidget {
  // final List<Album>? albums;

  final Geometry markerCoordinates;

  const MapScreen({Key? key,
    required this.markerCoordinates})
      : super(key: key);

  // Future<void> getAlbumCoordinates(context, index) async {
  //   var albumCoordinates = albums!.first.features[index].geometry;
  // }

  @override
  _UserLocationState createState() => _UserLocationState();
}

class _UserLocationState extends State<MapScreen> {

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
        () =>  Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high),
  );

  // List<Marker> allMarkers =[];

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
  }

  double userLatitudeData = 0;
  double userLongitudeData = 0;

  Future getCurrentLocation() async {
    final geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLatitudeData = geoPosition.latitude;
      userLongitudeData = geoPosition.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Map')),
        body: Column(
            children: [
          Expanded(
              child: FutureBuilder(                 //Instancing 2 different futures, can't pass index 'why?'
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
        ]
        )
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    return FlutterMap(
        options: MapOptions(
          center: LatLng(userLatitudeData, userLongitudeData),
          interactiveFlags:
          InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 13.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate:
            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            attributionBuilder: (_) {
              return const Text("© OpenStreetMap contributors");
            },
          ),
          MarkerLayerOptions(
            markers: [
              //Set.from(allMarkers),
              Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(userLatitudeData, userLongitudeData),
                  builder: (ctx) => const Icon(Icons.location_pin,
                      color: Colors.red)),
            ],
          ),
        ]
    );
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


