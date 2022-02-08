import 'dart:async';

import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../getxnavigation.dart';
import '../rephoto.dart';

class MainPage extends StatefulWidget {

  final controller = Get.put(Controller());

  String pageTitle = "";
  String dataSourceUrl = "";

  MainPage({Key? key}) : super(key: key);

  MainPage.network(this.pageTitle, this.dataSourceUrl, {Key? key})
      : super(key: key);

  @override
  MainPageState createState() =>MainPageState();
}

class MainPageState extends State<MainPage> {

  bool nameVisibility = false;
  bool searchVisibility = false;
  bool toggle = false;
  bool open = false;
  bool busy = false;
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  int renderState = 1;
  int maxClusterRadius = 100;
  String orderBy = "alpha";
  String orderDirection = "desc";

  List<Marker> markerList = [];
  List<Color> _colors = [];

  late final MapController mapController;
  final myController = TextEditingController();

  StreamSubscription<Position>? _positionStream;

  late final List<Album>? albums;
  Future<List<Album>>? _albumData;

  Future<List<Album>> albumData(BuildContext context) {
    return _albumData!;
  }

  String getDataSourceUrl() {
    String url = widget.dataSourceUrl;
    if (url.contains("?")) {
      url += "&orderby=" + orderBy + "&orderdirection=" + orderDirection;
    } else {
      url += "?orderby=" + orderBy + "&orderdirection=" + orderDirection;
    }
    String searchkey=myController.text;
    url += "&search=" + searchkey;
    return url;
  }

  void refresh() async {
    String url = getDataSourceUrl();
    await (_albumData = fetchAlbum(http.Client(), url));
  }

  getColorsForIcons() async {
    _colors =
        List.generate(10000, (index) => Colors.red); // here 10 is items.length
  }

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

  void listenCurrentLocation(){
    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
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

  Future<void> _showphoto(context, index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RephotoScreen(
            historicalPhotoId:
            albums!.first.features[index].properties.id.toString(),
            historicalPhotoUri: albums!
                .first.features[index].properties.thumbnail
                .toString(),
            historicalName:
            albums!.first.features[index].properties.name.toString(),
            historicalDate:
            albums!.first.features[index].properties.date.toString(),
            historicalAuthor:
            albums!.first.features[index].properties.author.toString(),
            historicalSurl: albums!
                .first.features[index].properties.sourceUrl
                .toString(),
            historicalLabel: albums!
                .first.features[index].properties.sourceLabel
                .toString(),
            historicalCoordinates: albums!.first.features[index].geometry,
          )),
    );
  }

  void _moveToGeoJson(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainPage.network(
              albums!.first.features[index].properties.name!,
              albums!.first.features[index].properties.geojson!)),
    );
  }

  getMarkerList(context) {
    List list = albums!.first.features;
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

  @override
  void initState() {
    listenCurrentLocation();
    getColorsForIcons();
    mapController = MapController();
    refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(renderState == 1) {
      return photoView(context);
    }
    if (renderState == 2){
      return mapView(context);
    }

    _saveBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visibility', nameVisibility);
    }

    _searchBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('searchVisibility', searchVisibility);
    }
    return Scaffold(
      body: Column(children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () { setState(() {
              renderState = 1;
            }); },
            child: const Text('Photos'),),
            ElevatedButton(onPressed: () {
              setState(() {
                renderState = 2;
              });
            },
              child: const Text('Map'),),
            ElevatedButton(onPressed: () {
              setState(() {
                renderState = 3;
              });
            },
              child: const Text('Albums'),),
          ],
        ),
        const SizedBox(height: 20),
        Flexible(
            child: FutureBuilder<List<Album>>(
              future: albumData(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) (snapshot.error);

                return (snapshot.hasData)
                    ? MainPage(
                    albums: snapshot.data,
                    : const Center(child: CircularProgressIndicator());
              },
            )),
      ],
      ),
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
        itemCount: albums!.first.features.length + 1,
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
        itemCount: albums!.first.features.length + 1,
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

    if (albums!.first.image != "") {
      headerImage = CachedNetworkImage(imageUrl: albums!.first.image);
    } else {
      headerImage = Container();
    }

    return Center(
        child:
        Column(children: [headerImage, Text(albums!.first.description)]));
  }

  Widget contentTile(context, index) {
    // Remove header row from index
    index = index - 1;
    return GestureDetector(
      onTap: () {
        if (albums!.first.features[index].properties.geojson != null &&
            albums!.first.features[index].properties.geojson != "") {
          _moveToGeoJson(context, index);
        } else {
          _showphoto(context, index);
        }
      },
      child: Column(children: [
        CachedNetworkImage(
            imageUrl:
            albums!.first.features[index].properties.thumbnail.toString()),
        Visibility(
          child: Text(
            albums!.first.features[index].properties.name.toString(),
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

  Widget mapView (context) {
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
          plugins: [
            MarkerClusterPlugin(),
          ],
          center: LatLng(userLatitudeData,
              userLongitudeData),
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