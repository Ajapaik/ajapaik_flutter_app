import 'package:ajapaik_flutter_app/projectlist.dart';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'localization.dart';
import 'sessioncontroller.dart';
import 'package:get/get.dart';
import 'localfileselect.dart';
import 'login.dart';
import 'photoview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class AlbumListPage extends StatefulWidget {
  final controller = Get.put(SessionController());

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
  bool nameVisibility = false;
  bool searchVisibility = false;
  bool searchDialogVisible = false;
  bool filterBoxOn = false;
  bool pullDownRefreshDone=true;
  final myController = TextEditingController();
  final searchController = TextEditingController();
  final controller = Get.put(SessionController());

  Future<List<Album>>? _albumData;

  Future<List<Album>> test(BuildContext context) {
    return _albumData!;
  }

  Widget titleSearchBar() {
    return Container(
        alignment: Alignment.topLeft,
        width: 500,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        child: Container(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.go,
              textAlign: TextAlign.start,
              onSubmitted: (value) {
                setState(() {
                  refresh();
                  print("valmista");
                });
              },
              onChanged: onSearchTextChanged,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for images',
                  prefixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          refresh();
                        });
                        onSearchTextChanged('');
                      }, icon: const Icon(Icons.search)),
                  suffixIcon: IconButton(
                      onPressed: () {
                        searchController.clear();
                      }, icon: const Icon(Icons.clear))),
            )));
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
  Future<void> RefreshIndicatorOnRefresh() async {
    pullDownRefreshDone=false;
    setState(() {
      refresh();
    });
    pullDownRefreshDone=true;
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
    String searchkey = searchController.text;
    url += "&search=" + searchkey;
    return url;
  }

  @override
  void initState() {
    controller.loadSession().then((_) =>
        setState(() {
          print("Updating login status to screen. Session " +
              controller.getSession());
        }));
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    _saveNameVisibility() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visibility', nameVisibility);
    }

    void bottomNavigationBarOnTap(index) {
      if (index == 0) {
        Get.to(DisplayLoginScreen())?.then((_) =>
            setState(() {
              ("session: " + controller.getSession());
            }));
      } else if (index == 1) {
        showPicker(context);
      }
      else if (index == 2) {
        setState(() {
          nameVisibility = !nameVisibility;
          _saveNameVisibility();
        });
      }
    }


    _searchBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('searchVisibility', searchVisibility);
    }

    Color visibilityIconColor = searchVisibility
        ? Theme
        .of(context)
        .disabledColor
        : Theme
        .of(context)
        .primaryColorLight;

    bool loggedIn = !(controller.isExpired());

    return Scaffold(
      appBar: AppBar(
        title: searchVisibility ? titleSearchBar() : Text(widget.pageTitle),
        leading: IconButton(icon: const BackButtonIcon(), onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProjectListPage(title: "Albums")));
        }),
        actions: <Widget>[
/*          IconButton(
              icon: Icon(Icons.search),
              tooltip: "Search",
              onPressed: toggleSearchDialog),*/
          IconButton(
              icon: searchVisibility
                  ? const Icon(Icons.search, color: Color(0xff03dac6))
                  : const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  searchVisibility = !searchVisibility;
                  _searchBool();
                });
              }),
         /* IconButton(
              icon: Icon(((orderBy == "alpha")
                  ? Icons.sort_by_alpha
                  : Icons.sort_sharp)),
              tooltip: "Sort",
              onPressed: sorting),*/
        ],
      ),
      body: Column(children: [
        Flexible(
      child:RefreshIndicator(
        onRefresh:RefreshIndicatorOnRefresh ,
            child: FutureBuilder<List<Album>>(
              future: test(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done && pullDownRefreshDone) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) (snapshot.error);

                return (snapshot.hasData)
                    ? AlbumList(
                    albums: snapshot.data,
                    toggle: nameVisibility | searchVisibility)
                              : const Text("Loading");
      //              : const Center(child: CircularProgressIndicator());
              },
            ))),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        onTap: bottomNavigationBarOnTap,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon((loggedIn ? Icons.person : Icons.login)),
              label: (loggedIn ? (AppLocalizations.of(context)!.translate(
                  'projectList-navItem4')
              ) : (AppLocalizations.of(context)!.translate(
                  'projectList-navItem3'))
              )),
          BottomNavigationBarItem(
              icon: const Icon(Icons.photo_library),
              label: (AppLocalizations.of(context)!.translate(
                  'projectList-navItem1')
              )),
          BottomNavigationBarItem(
              icon: nameVisibility
                  ? Icon(Icons.visibility_off, color: visibilityIconColor)
                  : Icon(Icons.visibility, color: visibilityIconColor),
              label: (AppLocalizations.of(context)!.translate(
                  'albumList-navItem3')
              )),
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

  Future<void> showphoto(context, index) async {
    MaterialPageRoute mpr = MaterialPageRoute(
        builder: (context) =>
            Photoview(
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
              numberOfRephotos: albums!.first.features[index].properties.rephotos!.toInt(),
            ));

    await Navigator.push(context, mpr);
  }

  void moveToGeoJson(context, index) {
    MaterialPageRoute mpr = MaterialPageRoute(
        builder: (context) =>
            AlbumListPage.network(
                albums!.first.features[index].properties.name!,
                albums!.first.features[index].properties.geojson!));
    Navigator.push(context, mpr);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery
        .of(context)
        .size
        .width;
    double height = MediaQuery
        .of(context)
        .size
        .height;

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
          moveToGeoJson(context, index);
        } else {
          showphoto(context, index);
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
      ]),
    );
  }
}
