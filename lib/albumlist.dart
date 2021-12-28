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
import 'package:shared_preferences/shared_preferences.dart';

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

bool visibility = false;

class AlbumListPageState extends State<AlbumListPage> {
  String orderBy = "alpha";
  String orderDirection = "desc";
  bool searchDialogVisible = false;
  bool filterBoxOn = false;
  double userLatitudeData = 0;
  double userLongitudeData = 0;
  final myController = TextEditingController();

  Future<List<Album>>? _albumData;

  Future<List<Album>> test(BuildContext context) {
    return _albumData!;
  }

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
    String searchkey=myController.text;
    url += "&search=" + searchkey;
    return url;
  }

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

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    @override
    _saveBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visibility', visibility);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: <Widget>[
/*          IconButton(
              icon: Icon(Icons.search),
              tooltip: "Search",
              onPressed: toggleSearchDialog),*/
          IconButton(
              icon: visibility
                  ? const Icon(Icons.visibility_off)
                  : const Icon(Icons.visibility),
              onPressed: () {
                _saveBool();
                setState(() {
                  visibility = !visibility;
                });
              }),
          IconButton(
              icon: Icon(((orderBy == "alpha")
                  ? Icons.sort_by_alpha
                  : Icons.sort_sharp)),
              tooltip: "Sort",
              onPressed: sorting),
        ],
      ),
      body: Column(children: [
        Visibility(
          visible: visibility,
          child: Column(children: [
                Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      child: Container(
                        height: 50,
                        width: 325,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(10)),
                        child: TextField(
                            controller: myController,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (value) {
                              setState(() {
                                filterBoxOn = true;
                                refresh();
                              });
                            },
                            textAlign: TextAlign.start,
                            onChanged: onSearchTextChanged,
                            decoration: const InputDecoration
                                .collapsed(
                              hintText: 'Search for images',
                            )),
                      )
                  ),
                  IconButton(
                      padding: const EdgeInsets.only(right: 10),
                      onPressed: () {
                        setState(() {
                          refresh();
                          filterBoxOn = true;
                        });
                        onSearchTextChanged('');
                      },
                      icon: const Icon(Icons.search)),
                ]),
            Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      child: Visibility(
                          visible: filterBoxOn,
                          child: Container(
                          height: 50,
                          width: 325,
                              child: TextFormField(
                                  enabled: true,
                                  controller: myController,
                                  decoration: InputDecoration(
                                    prefixIcon: IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed:() {
                                        setState(() {
                                          myController.clear();
                                          filterBoxOn = false;
                                          refresh();
                                        });
                                      }
                                    )
                                  ),
                                  onChanged: (value) {
                                    myController.text;
                                  },
                                  ),
                          )))
                ]),
          ]),
        ),
        Flexible(
            child: FutureBuilder<List<Album>>(
              future: test(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) (snapshot.error);

                return (snapshot.hasData)
                    ? AlbumList(albums: snapshot.data, toggle: visibility)
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
                      builder: (context) =>
                          MapScreen(
                            historicalPhotoUri: a
                                .first.features[index].properties.thumbnail
                                .toString(),
                            userLatitudeData: userLatitudeData,
                            userLongitudeData: userLongitudeData,
                            markerCoordinates: Geometry.empty(),
                            markerCoordinatesList: a.first.features,
                          )));
            }
          }
          if (index == 2) {
            showModalBottomSheet(
                isDismissible: true,
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return Container(
                      alignment: Alignment.topCenter,
                      height: 400,
                      child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: TextField(
                                      autofocus: true,
                                      controller: myController,
                                      textInputAction: TextInputAction.go,
                                      onSubmitted: (value) {
                                        setState(() {
                                          refresh();
                                          Navigator.pop(context);
                                        });
                                      },
                                      textAlign: TextAlign.start,
                                      onChanged: onSearchTextChanged,
                                      decoration: const InputDecoration
                                          .collapsed(
                                        hintText: 'Search for images',
                                      )),
                                )
                            ),
                            IconButton(
                                padding: const EdgeInsets.only(right: 10),
                                onPressed: () {
                                  onSearchTextChanged('');
                                   setState(() {
                                     refresh();
                                   });
                                  myController.clear();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.search)),
                          ]));
                });
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
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }

  onSearchTextChanged(String text) async {
    if (text.isEmpty) {
      setState(() {});
      return;
    }
  }
}

class AlbumList extends StatelessWidget {
  final List<Album>? albums;
  final bool toggle;

  const AlbumList({Key? key, this.albums, this.toggle = true})
      : super(key: key);

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
          builder: (context) => AlbumListPage.network(
              albums!.first.features[index].properties.name!,
              albums!.first.features[index].properties.geojson!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    if (height > width) {
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
    } else {
      return StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        staggeredTileBuilder: (int index) =>
            StaggeredTile.fit(index == 0 ? 4 : 1),
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
}
