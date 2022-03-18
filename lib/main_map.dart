import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/page/main_page.dart';
import 'package:ajapaik_flutter_app/rephoto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';

class MainPageBuilder extends StatefulWidget {

  final List<Album>? albums;
  String pageTitle = "";
  String dataSourceUrl = "";

  Function callbackFunction;
  double mapLatitude;
  double mapLongitude;

  MainPageBuilder({Key? key, this.albums, required this.callbackFunction,
    required this.mapLatitude, required this.mapLongitude})
      : super(key: key);

  @override
  MainPageBuilderState createState() =>MainPageBuilderState();
}

class MainPageBuilderState extends State<MainPageBuilder> {

  bool open = false;
  bool busy = false;
  bool toggle = false;
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  double mapLatitude = 0;
  double mapLongitude = 0;
  int maxClusterRadius = 100;
  String orderBy = "alpha";
  String orderDirection = "desc";
  List<Marker> markerList = [];
  List<Bounds> boundsList = [];
  List<Color> _colors = [];

  late final MapController mapController;
  final myController = TextEditingController();

  StreamSubscription<Position>? _positionStream;

  Future<void> _showphoto(context, index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RephotoScreen(
            historicalPhotoId:
            widget.albums!.first.features[index].properties.id.toString(),
            historicalPhotoUri: widget.albums!
                .first.features[index].properties.thumbnail
                .toString(),
            historicalName:
            widget.albums!.first.features[index].properties.name.toString(),
            historicalDate:
            widget.albums!.first.features[index].properties.date.toString(),
            historicalAuthor:
            widget.albums!.first.features[index].properties.author.toString(),
            historicalSurl: widget.albums!
                .first.features[index].properties.sourceUrl
                .toString(),
            historicalLabel: widget.albums!
                .first.features[index].properties.sourceLabel
                .toString(),
            historicalCoordinates: widget.albums!.first.features[index].geometry,
          )),
    );
  }

  void _moveToGeoJson(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainPage.network(
              widget.albums!.first.features[index].properties.name!,
              widget.albums!.first.features[index].properties.geojson!)),
    );
  }

  Widget photoView (context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    if (height > width) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        itemCount: widget.albums!.first.features.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        },
      );
    } else {
      return MasonryGridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        itemCount: widget.albums!.first.features.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        },
      );
    }
  }

  Widget headerTile(context, index) {
    StatelessWidget headerImage;

    if (widget.albums!.first.image != "") {
      headerImage = CachedNetworkImage(imageUrl: widget.albums!.first.image);
    } else {
      headerImage = Container();
    }

    return Center(
        child:
        Column(children: [headerImage, Text(widget.albums!.first.description)]));
  }

  Widget contentTile(context, index) {
    // Remove header row from index
    index = index - 1;
    return GestureDetector(
      onTap: () {
        if (widget.albums!.first.features[index].properties.geojson != null &&
            widget.albums!.first.features[index].properties.geojson != "") {
          _moveToGeoJson(context, index);
        } else {
          _showphoto(context, index);
        }
      },
      child: Column(children: [
        CachedNetworkImage(
            imageUrl:
            widget.albums!.first.features[index].properties.thumbnail.toString()),
        Visibility(
          child: Text(
            widget.albums!.first.features[index].properties.name.toString(),
            textAlign: TextAlign.center,
          ),
          visible: toggle,
        ),
        // Favorites code snippet for icons to favorite pictures
        // GestureDetector(
        //   onTap: () {
        //
        //   },
        //   child: const Align(
        //     alignment: Alignment.topRight,
        //    child: Icon(Icons.favorite_outlined, color: Colors.white, size: 35),
        // ))
      ]),
    );
  }

  getMarkerList(context) {
    List list = widget.albums!.first.features;
    markerList.clear();
    for (int x = 0; x < list.length; x++) {
      if (list[x].geometry.coordinates.length > 0) {
        double latitude = list[x].geometry.coordinates[0];
        double longitude = list[x].geometry.coordinates[1];
        var m = Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(latitude, longitude),
            builder: (ctx) => IconButton(
              icon: Icon(Icons.location_pin, color: _colors[x]),
              onPressed: () {
                if (busy == true) {
                  return;
                } else {
                  if (open == true) {
                    Navigator.of(context).pop();
                    setState(() {
                      _colors[x] = Colors.red;
                    });
                    open = false;
                  }
                }
                if (open == false) {
                  busy = true;
                  open = true;
                  setState(() {
                    _colors[x] = Colors.white;
                  });
                  showBottomSheet(
                      context: context,
                      builder: (builder) {
                        busy = false;
                        return Row(children: [
                          Expanded(
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
                                                historicalPhotoUri: list[x]
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
                          )
                        ]);
                      }).closed.then((value) {
                    if (busy == false) {
                      open = false;
                    }
                    setState(() {
                      _colors[x] = Colors.red;
                    });
                    busy = false;
                  });
                }
              },
            ));
        markerList.add(m);
      }
    }
    return markerList;
  }

  getBoundsList(context) {
    List list = widget.albums!.first.features;
    boundsList.clear();
    for (int x = 0; x < list.length; x++) {
      if (list[x].geometry.coordinates.length > 0) {
        double boundsLatitude = list[x].geometry.coordinates[0];
        double boundsLongitude = list[x].geometry.coordinates[1];
        //var b = Bounds(boundsLatitude, boundsLongitude);
        //boundsList.add(b);
      }
    }
  }

  getColorsForIcons() async {
    _colors =
        List.generate(10000, (index) => Colors.red); // here 10 is items.length
  }

  void getCurrentLocation() async {
    var geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    setState(() {
      userLatitudeData = geoPosition.latitude;
      userLongitudeData = geoPosition.longitude;
    });
  }

  void listenCurrentLocation(){
    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        // distanceFilter: 10,
        timeLimit: Duration(seconds: 5)
    );
    _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings).listen((Position geoPosition)
    {
      if (geoPosition.latitude != userLatitudeData &&
          geoPosition.longitude != userLongitudeData) {
        return getCurrentLocation();
      }
    });
  }

  @override
  void initState() {
    mapLatitude=widget.mapLatitude;
    mapLongitude=widget.mapLongitude;
    getCurrentLocation();
    listenCurrentLocation();
    getColorsForIcons();
    mapController = MapController();
    super.initState();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: _buildFlutterMap(context)),
      ]),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    LatLng lastposition = LatLng(mapLatitude, mapLongitude);
    getMyZoom() {
      if (mapController.zoom >= 17) {
        maxClusterRadius = 5;
      } else {
        if (mapController.zoom <= 9) {
          maxClusterRadius = 200;
        }
      }
    }

    return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onPositionChanged: (mapPosition, boolValue){
            lastposition = mapPosition.center!;
            if (widget.callbackFunction(mapPosition)==1) {

                print("foo bar");

            }

          },
          plugins: [
            MarkerClusterPlugin(),
          ],
          center: LatLng(mapLatitude,
              mapLongitude),
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          zoom: 17.0,
          maxZoom: 18,
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
              maxClusterRadius: maxClusterRadius,
              size: const Size(30, 30),
              showPolygon: false,
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
              ),
              markers: getMarkerList(context),
              builder: (context, markers) {
                return FloatingActionButton(
                  child: Text(markers.length.toString()),
                  onPressed: getMyZoom(),
                );
              }),
          MarkerLayerOptions(markers: [
            Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(userLatitudeData, userLongitudeData),
                builder: (ctx) =>
                const Icon(Icons.location_pin, color: Colors.blue)),
          ])
        ]);
  }
}
