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
  bool tweenCompleted = true;
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  double mapLatitude = 0;
  double mapLongitude = 0;
  int renderState = 1;
  int maxClusterRadius = 100;
  String orderBy = "alpha";
  String orderDirection = "desc";

  List<Marker> markerList = [];
  List<Color> _colors = [];

  late final MapController mapController;
  final myController = TextEditingController();

  Future<List<Album>>? _albumData;

  Future<List<Album>> albumData(BuildContext context) {
    if (_albumData==null) {
      String url = getDataSourceUrl();
      return _albumData = fetchAlbum(http.Client(), url);
    }
    else
    {
      return _albumData!;
    }
  }

  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
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
    if (mapLatitude == 0 || mapLongitude == 0) {
      var geoPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      mapLatitude = geoPosition.latitude;
      mapLongitude = geoPosition.longitude;
    }
    String url = getDataSourceUrl();
    if (tweenCompleted == true) {
      tweenCompleted = false;
      await (_albumData = fetchAlbum(http.Client(), url,
              latitude: mapLatitude, longitude: mapLongitude)
          .whenComplete(() => {
                  tweenCompleted = true
              }));
    }
  }

  Future<List<Album>>? hello(MapPosition mapPosition) {

    if (mapPosition.center != null) {
      var center = mapPosition.center!;
      double lat2 = center.latitude;
      double lon2 = center.longitude;
      if (mapPosition.center != null) {
        var center = mapPosition.center!;
        double lat2 = center.latitude;
        double lon2 = center.longitude;
        double distance = calculateDistance(
            mapLatitude, mapLongitude, lat2, lon2);

        if (distance > 0.1) {
          print("foo");
          Future<List<Album>>? a;
          _albumData=a;
          mapLatitude = lat2;
          mapLongitude = lon2;
          refresh();
        }
      }
    }
    return _albumData;
  }

  getColorsForIcons() async {
    _colors =
        List.generate(10000, (index) => Colors.red); // here 10 is items.length
  }

  @override
  void initState() {
    getColorsForIcons();
    mapController = MapController();
    refresh();
    super.initState();
  }

  Widget _switchTab(albums) {
    if (renderState == 1 ) {
      return AlbumList(albums: albums);
    } else if (renderState == 2 ) {
      return MainPageBuilder(albums: albums, callbackFunction: hello,
          mapLatitude: mapLatitude, mapLongitude: mapLongitude);
    }
    return const Text("Failed");
  }

  @override
  Widget build(BuildContext context) {

    // _saveBool() async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   await prefs.setBool('visibility', nameVisibility);
    // }
    //
    // _searchBool() async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   await prefs.setBool('searchVisibility', searchVisibility);
    // }

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    renderState = 1;
                  });
                },
                child: const Text('Photos'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    renderState = 2;
                  });
                },
                child: const Text('Map'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    renderState = 3;
                  });
                },
                child: const Text('Albums'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        Flexible(
            child: FutureBuilder<List<Album>>(
              future: albumData(context),
              builder: (context, snapshot) {

                print("Future: main_page.dart)");
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
}