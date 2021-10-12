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

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
        () =>  Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high),
  );

  void listToMarkers() {
    List list = widget.markerCoordinatesList;
    setState(() {
      for (int x = 0; x < list.length; x++) {
        double latitude = list[x]['lat'];
        double longitude = list[x]['long'];
        LatLng location = LatLng(latitude, longitude);
        if (list.contains(location)) {
          list.clear();
          list.add(location);
        } else {
          list.add(location);
        }

        //Passing a dynamic marker id as the index here.
        addMarker(list[x], x);
      }
    });
  }

  void addMarker(loc, index) {
    //Making this markerId dynamic
    final MarkerId markerId = MarkerId('Marker $index');

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(loc.latitude, loc.longitude),
      infoWindow: InfoWindow(title: 'test'),
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
      //print(marker);
    });
  }

  @override
  void initState() {
    listToMarkers();
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

    double imagelatitude = 0;
    double imagelongitude = 0;
    if (!widget.markerCoordinates.coordinates.isEmpty) {
      imagelatitude = widget.markerCoordinates.coordinates[0];
      imagelongitude = widget.markerCoordinates.coordinates[1];
    }

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
              Set.of(markers.values),
              Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(userLatitudeData, userLongitudeData),
                  builder: (ctx) => const Icon(Icons.location_pin,
                      color: Colors.red)),
              Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(imagelatitude, imagelongitude),
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


