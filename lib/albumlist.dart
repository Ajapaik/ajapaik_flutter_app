import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'getxnavigation.dart';
import 'package:get/get.dart';
import 'map.dart';
import 'rephoto.dart';

// ignore: must_be_immutable
class AlbumListPage extends StatefulWidget {
  final controller = Get.put(Controller());

  String pageTitle = "";
  String dataSourceUrl = "";

  AlbumListPage({Key? key}) : super(key: key);

  AlbumListPage.network(this.pageTitle, this.dataSourceUrl, {Key? key})
      : super(key: key);

  @override
  AlbumListPageState createState() => AlbumListPageState();
}

class AlbumListPageState extends State<AlbumListPage> {
  String orderBy = "alpha";
  String orderDirection = "desc";
  bool searchDialogVisible = false;

  Future<List<Album>>? _albumData;

  late final List<Album>? albums;

  void sorting() async {
    setState(() {
      orderBy = (orderBy == "alpha") ? "distance" : "alpha";
      refresh();
    });
    Get.snackbar(
      "Sorting",
      "Order by " + orderBy,
      // duration: Duration(seconds: 3),
    );
  }

  void refresh() async {
    String url = getDataSourceUrl();
    await (_albumData = fetchAlbum(http.Client(), url));
  }

  void toggleSearchDialog() {
    searchDialogVisible = searchDialogVisible ? false : true;
  }

  String getDataSourceUrl() {
    String url = widget.dataSourceUrl;
    if (url.contains("?")) {
      url += "&orderby=" + orderBy + "&orderdirection=" + orderDirection;
    } else {
      url += "?orderby=" + orderBy + "&orderdirection=" + orderDirection;
    }

    return url;
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

  @override
  void initState() {
    getCurrentLocation();
    refresh();
    super.initState();
  }

  Future<List<Album>> test(BuildContext context) {
    return _albumData!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: <Widget>[
/*          IconButton(
              icon: Icon(Icons.search),
              tooltip: "Search",
              onPressed: toggleSearchDialog),*/
          IconButton(
              icon: Icon(((orderBy == "alpha")
                  ? Icons.sort_by_alpha
                  : Icons.sort_sharp)),
              tooltip: "Sort",
              onPressed: sorting),
        ],
      ),
      body: Column(children: [
        Flexible(
            child: FutureBuilder<List<Album>>(
              future: test(context),
              builder: (context, snapshot) {
                if (snapshot.hasError) (snapshot.error);

                return (snapshot.hasData)
                    ? AlbumList(albums: snapshot.data)
                    : const Center(child: CircularProgressIndicator());
              },
            )),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) async {
          if (index == 1) {
            var a = await _albumData;
            if (a != null) {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MapScreen(
                        historicalPhotoUri:
                        albums!.first.features[index].properties.thumbnail.toString(),
                        userLatitudeData: userLatitudeData,
                        userLongitudeData: userLongitudeData,
                        markerCoordinates: Geometry.empty(),
                        markerCoordinatesList: a.first.features,
                          )));
            }
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Nearest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Add a photo',
          ),
        ],
      ),
    );
  }
}

//Bottom navigation bar theme - just insert into code
//Necessary for two different bottomnavigationbar locations? Ask if they can be rearranged at main.dart

// Theme(
// data: Theme.of(context).copyWith(
// // sets the background color of the `BottomNavigationBar`
// canvasColor: Colors.green,
// // sets the active color of the `BottomNavigationBar` if `Brightness` is light
// primaryColor: Colors.red,
// textTheme: Theme.of(context)
// .textTheme
//     .copyWith(caption: const TextStyle(color: Colors.yellow))),
// child:

class AlbumList extends StatelessWidget {
  final List<Album>? albums;

  const AlbumList({Key? key, this.albums}) : super(key: key);

  Future<void> _showphoto(context, index) async {
    var rephoto = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RephotoScreen(
            historicalPhotoId:
            albums!.first.features[index].properties.id.toString(),
            historicalPhotoUri:
            albums!.first.features[index].properties.thumbnail.toString(),
            historicalName:
            albums!.first.features[index].properties.name.toString(),
            historicalDate:
            albums!.first.features[index].properties.date.toString(),
            historicalAuthor:
            albums!.first.features[index].properties.author.toString(),
            historicalSurl:
            albums!.first.features[index].properties.sourceUrl.toString(),
            historicalLabel:
            albums!.first.features[index].properties.sourceLabel.toString(),
            historicalCoordinates:
            albums!.first.features[index].geometry,
          )
      ),
    );
  }

  void _moveToGeoJson(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AlbumListPage.network(
              albums!.first.features[index].properties.name!,
              albums!.first.features[index].properties.geojson!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        staggeredTileBuilder: (int index) =>
            StaggeredTile.fit(index == 0 ? 4 : 2),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        itemCount: albums!.first.features.length + 1,
        // Number of items + header row
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        });
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
              imageUrl: albums!.first.features[index].properties.thumbnail
                  .toString()),
          Text(
            albums!.first.features[index].properties.name.toString(),
            textAlign: TextAlign.center,
          )
        ]));
  }
}
