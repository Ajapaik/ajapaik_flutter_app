import 'package:ajapaik_flutter_app/projectlist.dart';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'localization.dart';
import 'sessioncontroller.dart';
import 'package:get/get.dart';
import 'localfileselect.dart';
import 'login.dart';
import 'photoview.dart';
import 'httpcontroller.dart';
import 'preferences.dart';

// ignore: must_be_immutable
class AlbumListPage extends StatefulWidget {
  final sessionController = Get.put(SessionController());

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
  final searchController = TextEditingController();
  final sessionController = Get.put(SessionController());
  final locator = Get.put(AppLocator());
  final prefs = Get.put(Preferences());

  Future<List<Album>>? _albumData;

  Future<List<Album>> getAlbumData(BuildContext context) {
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
                  refreshAlbumData();
                  print("valmista");
                });
              },
              onChanged: onSearchTextChanged,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for images', // <- also needs to be localized
                  prefixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          refreshAlbumData();
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
      refreshAlbumData();
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
      refreshAlbumData();
    });
    pullDownRefreshDone=true;
  }

  void refreshAlbumData() async {
    String url = getDataSourceUrl();

    // TODO: check if there are permissions to use network and/or session is active

    url = addLocationToUrl(url, locator.getLatLong());
    //print("fetchAlbum location: $position.toString()");

    await (_albumData = fetchAlbum(url));
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
    // TODO: check if there are no permissions or no network connection
    //  -> try to work without connection

    sessionController.loadSession().then((_) =>
        setState(() {
          print("Updating login status to screen. Session " +
              sessionController.getSessionId());
        }));
    refreshAlbumData();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    void bottomNavigationBarOnTap(index) {
      if (index == 0) {
        Get.to(DisplayLoginScreen())?.then((_) =>
            setState(() {
            }));
      } else if (index == 1) {
        showPicker(context);
      }
      else if (index == 2) {
        setState(() {
          nameVisibility = !nameVisibility;
          prefs.saveNameVisibility(nameVisibility);
        });
      }
    }

    Color visibilityIconColor = searchVisibility
        ? Theme
        .of(context)
        .disabledColor
        : Theme
        .of(context)
        .primaryColorLight;

    bool loggedIn = !(sessionController.isExpired());

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
                  //prefs.setSearchVisibility(searchVisibility);
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
              future: getAlbumData(context),
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
              label: (loggedIn ? (AppLocalizations.getText(context, 'projectList-navItem4')
              ) : (AppLocalizations.getText(context, 'projectList-navItem3'))
              )),
          BottomNavigationBarItem(
              icon: const Icon(Icons.photo_library),
              label: (AppLocalizations.getText(context, 'projectList-navItem1')
              )),
          BottomNavigationBarItem(
              icon: nameVisibility
                  ? Icon(Icons.visibility_off, color: visibilityIconColor)
                  : Icon(Icons.visibility, color: visibilityIconColor),
              label: (AppLocalizations.getText(context, 'albumList-navItem3')
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

  Photoview getPhotoView(Feature feat) {
    Photoview p = Photoview(
      historicalPhotoId: feat.properties.id.toString(),
      historicalPhotoUri: feat.properties.thumbnail.toString(),
      historicalName: feat.properties.name.toString(),
      historicalDate: feat.properties.date.toString(),
      historicalAuthor: feat.properties.author.toString(),
      historicalSrcUrl: feat.properties.sourceUrl.toString(),
      historicalLabel: feat.properties.sourceLabel.toString(),
      historicalCoordinates: feat.geometry,
      numberOfRephotos: feat.properties.rephotos!.toInt(),
    );
    return p;
  }

  Future<void> showphoto(context, index) async {
    Feature feat = albums!.first.features[index];
    MaterialPageRoute mpr = MaterialPageRoute(
        builder: (context) => getPhotoView(feat));

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

    int caxcount = 4;
    if (height > width) {
      caxcount = 2;
    }
    return MasonryGridView.count(
      crossAxisCount: caxcount,
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
    Feature feat = albums!.first.features[index];

    return GestureDetector(
      onTap: () {
        if (feat.properties.geojson != null &&
            feat.properties.geojson != "") {
          moveToGeoJson(context, index);
        } else {
          showphoto(context, index);
        }
      },
      child: Column(children: [
        CachedNetworkImage(
            imageUrl:
            feat.properties.thumbnail.toString()),
        Visibility(
          child: Text(
            feat.properties.name.toString(),
            textAlign: TextAlign.center,
          ),
          visible: toggle,
        ),
      ]),
    );
  }
}
