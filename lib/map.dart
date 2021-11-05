import 'dart:async';
import 'package:ajapaik_flutter_app/rephoto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';

class MapScreen extends StatefulWidget {
  final Geometry markerCoordinates;
  final List<Feature> markerCoordinatesList;
  final double userLatitudeData;
  final double userLongitudeData;
  final String historicalPhotoUri;

  const MapScreen({
    Key? key,
    required this.markerCoordinates,
    required this.markerCoordinatesList,
    required this.userLatitudeData,
    required this.userLongitudeData,
    required this.historicalPhotoUri,
  }) : super(key: key);

  @override
  _UserLocationState createState() => _UserLocationState();
}

class _UserLocationState extends State<MapScreen> {
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  List<Marker> markerList = [];
  bool open = false;

  final Future<Position> _location = Future<Position>.delayed(
    const Duration(seconds: 2),
    () => Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high),
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
    Stream<Position> position = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
        distanceFilter: 10);
    position.listen((position) {
      if (position.latitude != userLatitudeData &&
          position.longitude != userLongitudeData) {
        return getCurrentLocation();
      }
    });
  }

  getMarkerList(context) {
    List list = widget.markerCoordinatesList;
    markerList.clear();
    for (int x = 0; x < list.length; x++) {
      if (list[x].geometry.coordinates.length > 0) {
        double latitude = list[x].geometry.coordinates[0];
        double longitude = list[x].geometry.coordinates[1];
        var m = Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(latitude, longitude),
            builder: (ctx) => IconButton(
                  icon: const Icon(Icons.location_pin, color: Colors.red),
                  onPressed: () {
                    if (open == false) {
                      open = true;
                      showBottomSheet(
                          context: context,
                          builder: (builder) {
                            return Container(
                                color: Colors.white,
                                child: Expanded(
                                  child: GestureDetector(
                                      child: Image.network(
                                          list[x].properties.thumbnail),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    RephotoScreen(
                                                      historicalPhotoId: list[x]
                                                          .properties
                                                          .id
                                                          .toString(),
                                                      historicalPhotoUri:
                                                          list[x]
                                                              .properties
                                                              .thumbnail
                                                              .toString(),
                                                      historicalName: list[x]
                                                          .properties
                                                          .name
                                                          .toString(),
                                                      historicalDate: list[x]
                                                          .properties
                                                          .date
                                                          .toString(),
                                                      historicalAuthor: list[x]
                                                          .properties
                                                          .author
                                                          .toString(),
                                                      historicalSurl: list[x]
                                                          .properties
                                                          .sourceUrl
                                                          .toString(),
                                                      historicalLabel: list[x]
                                                          .properties
                                                          .sourceLabel
                                                          .toString(),
                                                      historicalCoordinates:
                                                          list[x].geometry,
                                                    )));
                                      }),
                                ));
                          });
                    } else {
                      Navigator.of(context).pop();
                      open = false;
                    }
                  },
                ));
        markerList.add(m);
      }
    }
    return markerList;
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
      body: Column(children: [
        Expanded(
            child: FutureBuilder(
                future: _location,
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasError) (snapshot.error);
                  return snapshot.hasData
                      ? _buildFlutterMap(context)
                      : Center(
                          child: FlutterMap(
                              options: MapOptions(
                                center: LatLng(widget.userLatitudeData,
                                    widget.userLongitudeData),
                                interactiveFlags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                                zoom: 13.0,
                              ),
                              layers: [
                              TileLayerOptions(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                                attributionBuilder: (_) {
                                  return const Text(
                                      "© OpenStreetMap contributors");
                                },
                              ),
                              MarkerLayerOptions(
                                markers: getMarkerList(context),
                              ),
                              MarkerLayerOptions(markers: [
                                Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(widget.userLatitudeData,
                                        widget.userLongitudeData),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.blue)),
                              ])
                            ]));
                })),
      ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    return FlutterMap(
        options: MapOptions(
          plugins: [
            MarkerClusterPlugin(),
          ],
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
          MarkerClusterLayerOptions(
            maxClusterRadius: 120,
            size: const Size(40, 40),
            fitBoundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(50),
          ),
            markers: markerList,
              builder: (context, markers)
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
