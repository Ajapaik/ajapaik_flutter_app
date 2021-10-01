import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _UserLocationState createState() => _UserLocationState();
}
class _UserLocationState extends State <MapScreen> {

  double userLatitudeData = 0;
  double userLongitudeData = 0;

  @override
  void initState(){
    getCurrentLocation();
    super.initState();
  }

  void getCurrentLocation() async {
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
        body: Center(
            child: FlutterMap(
                options: MapOptions(
                  center: LatLng(userLatitudeData, userLongitudeData),
                  zoom: 3.0,
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
                  Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(userLatitudeData, userLongitudeData),
                      builder: (ctx) =>
                          const Icon(Icons.location_pin, color: Colors.red)),
                ],
              ),
            ])
        )
    );
  }
}