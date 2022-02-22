import 'dart:async';
import 'dart:math';
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../albumlist.dart';
import '../getxnavigation.dart';
import '../main_map.dart';

class MainPage extends StatefulWidget {

  final controller = Get.put(Controller());

  String pageTitle = "";
  String dataSourceUrl = "";

  MainPage.network(this.pageTitle, this.dataSourceUrl, {Key? key})
      : super(key: key);

  @override
  MainPageState createState() =>MainPageState();
}

class MainPageState extends State<MainPage> {

  bool nameVisibility = false;
  bool searchVisibility = false;
  bool toggle = false;
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

  Future<List<Album>>? _albumData;

  Future<List<Album>> albumData(BuildContext context) {
    return _albumData!;
  }

  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  void hello(MapPosition mapPosition) {
    print("Hello " + mapPosition.center!.toString());

    if (mapPosition.center != null) {
      var center = mapPosition.center!;
      double lat2 = center.latitude;
      double lon2 = center.longitude;
      if (mapPosition.center != null) {
        var center = mapPosition.center!;
        double lat2 = center.latitude;
        double lon2 = center.longitude;
        double distance = calculateDistance(
            userLatitudeData, userLongitudeData, lat2, lon2);
        print(distance.toString());

        if (distance > 0.05) {
          userLatitudeData = lat2;
          userLongitudeData = lon2;
          print("refresh");
          refresh();
        }
      }
    }
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

  @override
  void initState() {
    listenCurrentLocation();
    getColorsForIcons();
    mapController = MapController();
    refresh();
    super.initState();
  }

  Widget _switchTab(albums) {
    if (renderState == 1 ) {
      return AlbumList(albums: albums);
    } else if (renderState == 2 ) {
      return MainPageBuilder(albums: albums, callbackFunction: hello);
    }
    return const Text("Failed");
  }

  @override
  Widget build(BuildContext context) {

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
                    ? _switchTab(snapshot.data)
                    : const Center(child: CircularProgressIndicator());
              },
            )),
      ],
      ),
    );
  }

//   Widget mapView (context) {
//     getMyZoom() {
//       if (mapController.zoom >= 17) {
//         maxClusterRadius = 5;
//       } else {
//         if (mapController.zoom <= 9) {
//           maxClusterRadius = 200;
//         }
//       }
//     }
//
//     return FlutterMap(
//         mapController: mapController,
//         options: MapOptions(
//           plugins: [
//             MarkerClusterPlugin(),
//           ],
//           center: LatLng(userLatitudeData,
//               userLongitudeData),
//           interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
//           zoom: 17.0,
//           maxZoom: 18,
//         ),
//         layers: [
//           TileLayerOptions(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: ['a', 'b', 'c'],
//             attributionBuilder: (_) {
//               return const Text("© OpenStreetMap contributors");
//             },
//           ),
//           MarkerClusterLayerOptions(
//               maxClusterRadius: maxClusterRadius,
//               size: const Size(30, 30),
//               showPolygon: false,
//               fitBoundsOptions: const FitBoundsOptions(
//                 padding: EdgeInsets.all(50),
//               ),
//               markers: getMarkerList(context),
//               builder: (context, markers) {
//                 return FloatingActionButton(
//                   child: Text(markers.length.toString()),
//                   onPressed: getMyZoom(),
//                 );
//               }),
//           MarkerLayerOptions(markers: [
//             Marker(
//                 width: 40.0,
//                 height: 40.0,
//                 point: LatLng(userLatitudeData, userLongitudeData),
//                 builder: (ctx) =>
//                 const Icon(Icons.location_pin, color: Colors.blue)),
//           ])
//         ]);
//   }
}